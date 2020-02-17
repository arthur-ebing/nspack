# frozen_string_literal: true

module EdiApp
  class EdiOutRepo < BaseRepo
    crud_calls_for :edi_out_transactions, name: :edi_out_transaction, wrapper: EdiOutTransaction

    def load_config
      @load_config ||= begin
                         raise Crossbeams::FrameworkError, 'There is no EDI config file named "config/edi_out_config.yml"' unless File.exist?('config/edi_out_config.yml')

                         YAML.load_file('config/edi_out_config.yml')
                       end
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
      org_code = MasterfilesApp::PartyRepo.new.fn_party_role_name(changeset[:party_role_id]) || 'N/A'
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
  end
end
