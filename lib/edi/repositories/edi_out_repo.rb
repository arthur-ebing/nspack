# frozen_string_literal: true

module EdiApp
  class EdiOutRepo < BaseRepo
    crud_calls_for :edi_out_transactions, name: :edi_out_transaction, wrapper: EdiOutTransaction
    crud_calls_for :edi_out_rules, name: :edi_out_rule, wrapper: EdiOutRule

    def load_config
      @load_config ||= begin
                         config_path = File.expand_path('../../../config/edi_out_config.yml', __dir__)
                         raise Crossbeams::FrameworkError, 'There is no EDI config file named "config/edi_out_config.yml"' unless File.exist?(config_path)

                         YAML.load_file(config_path)
                       end
    end

    def schema_record_sizes
      yml_path = File.expand_path('../schemas/schema_record_sizes.yml', __dir__)
      raise 'There is no schema_record_sizes.yml file' unless File.exist?(yml_path)

      YAML.load_file(yml_path)
    end

    # Are there any rules for a flow type?
    #
    # @param flow_type [string] the EDI flow type
    # @return [Crossbeams::Response]
    def flow_has_destination?(flow_type)
      return failed_response("There is no destination for flow type #{flow_type}") if DB[:edi_out_rules].where(flow_type: flow_type, active: true).count.zero?

      ok_response
    end

    # Get the rules for an out flow that match any combination of depot/party role?
    #
    # @param flow_type [string] the EDI flow type
    # @param depot_ids [array of int] depot ids
    # @param party_role_ids [array of int] party_role ids
    # @return [Crossbeams::Response] with an array of edi_out_rules.id that are applicable
    def flow_has_matching_rule(flow_type, depot_ids: [], party_role_ids: [])
      ar = []
      ar += DB[:edi_out_rules].where(flow_type: flow_type, depot_id: depot_ids, active: true).select_map(:id) unless depot_ids.empty?
      ar += DB[:edi_out_rules].where(flow_type: flow_type, party_role_id: party_role_ids, active: true).select_map(:id) unless party_role_ids.empty?

      return success_response('ok', ar) unless ar.empty?

      failed_response("There is no destination for flow type #{flow_type}")
    end

    def hub_address_for(edi_out_rule_id)
      DB[:edi_out_rules].where(id: edi_out_rule_id).get(:hub_address)
    end

    def edi_directory_keys(edi_out_rule_id)
      DB[:edi_out_rules].where(id: edi_out_rule_id).get(:directory_keys)
    end

    def create_edi_out_transaction(changeset)
      org_code = MasterfilesApp::PartyRepo.new.org_code_for_party_role(changeset[:party_role_id]) || 'N/A'
      DB[:edi_out_transactions].insert(changeset.merge(org_code: org_code))
    end

    def log_edi_out_complete(id, edi_filename, message)
      if edi_filename == {}
        update_edi_out_transaction(id, complete: true, error_message: message)
      else
        update_edi_out_transaction(id, complete: true, edi_out_filename: edi_filename)
      end
    end

    def log_edi_out_failed(id, message)
      update_edi_out_transaction(id, error_message: message)
    end

    def log_edi_out_error(id, exception)
      update_edi_out_transaction(id, error_message: exception.message, backtrace: exception.backtrace.join("\n"))
    end

    def new_sequence_for_flow(flow_type)
      next_document_sequence_number("edi_out_#{flow_type.downcase}")
    end

    def for_select_directory_keys
      config = load_config
      config[:out_dirs].keys + config[:mail_recipients].keys.map { |m| "mail:#{m}" }
    end

    def format_targets(targets) # rubocop:disable Metrics/AbcSize
      formatted_targets = []
      config = load_config
      targets.each do |target|
        if target.include?('mail:')
          email_target = config[:mail_recipients][target.sub('mail:', '').to_sym]
          formatted_targets << "#{target.sub('mail:', '')}: #{email_target[:to]} , #{email_target[:cc]}"
        else
          formatted_targets << "#{target}: #{config[:out_dirs][target.to_sym].sub('$ROOT', ENV['HOME'])}"
        end
      end

      formatted_targets
    end

    def can_transform_for_depot?(flow_type)
      AppConst::EDI_OUT_RULES_TEMPLATE[flow_type][:depot]
    end

    def can_transform_for_party?(flow_type)
      !AppConst::EDI_OUT_RULES_TEMPLATE[flow_type][:roles].nil_or_empty?
    end

    def destinations_for_flow(flow_type)
      sel = []
      sel << AppConst::DEPOT_DESTINATION_TYPE if AppConst::EDI_OUT_RULES_TEMPLATE[flow_type][:depot]
      sel << AppConst::PARTY_ROLE_DESTINATION_TYPE unless AppConst::EDI_OUT_RULES_TEMPLATE[flow_type][:roles].empty?
      sel
    end

    def find_edi_out_rule_flat(id)
      query = <<~SQL
        SELECT e.id, flow_type, depots.depot_code, fn_party_role_name(party_role_id) AS party
        , roles.name AS role, hub_address, directory_keys, array_to_string(directory_keys, '; ') AS targets, depot_id
        , party_role_id, e.active
        FROM edi_out_rules e
        LEFT JOIN depots ON depots.id = e.depot_id
        LEFT JOIN party_roles ON party_roles.id = party_role_id
        LEFT JOIN roles ON roles.id = party_roles.role_id
        where e.id = ?
      SQL
      hash = DB[query, id].first

      EdiOutRuleFlat.new(hash)
    end
  end
end
