# frozen_string_literal: true

module EdiApp
  class EdiOutRuleInteractor < BaseInteractor
    def create_edi_out_rule(params) # rubocop:disable Metrics/AbcSize
      res = validate_edi_out_rule_params(params)
      return validation_failed_response(res) if res.failure?

      id = nil
      repo.transaction do
        params[:directory_keys] = "{#{res[:directory_keys].join(',')}}"
        id = repo.create_edi_out_rule(flow_type: params[:flow_type], depot_id: params[:depot_id], party_role_id: params[:party_role_id], hub_address: params[:hub_address], directory_keys: params[:directory_keys])
        log_status(:edi_out_rules, id, 'CREATED')
        log_transaction
      end
      instance = edi_out_rule(id)
      success_response('Created edi out rule',
                       instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { flow_type: ['This edi out rule already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_edi_out_rule(id, params) # rubocop:disable Metrics/AbcSize
      res = validate_edi_out_rule_params(params)
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        params.delete_if { |_k, v| v.nil_or_empty? }
        params[:directory_keys] = "{#{res[:directory_keys].join(',')}}"
        repo.update_edi_out_rule(id, flow_type: params[:flow_type], depot_id: params[:depot_id], party_role_id: params[:party_role_id], hub_address: params[:hub_address], directory_keys: params[:directory_keys])
        log_transaction
      end
      instance = edi_out_rule(id)
      success_response('Updated edi out rule',
                       instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_edi_out_rule(id)
      repo.transaction do
        repo.delete_edi_out_rule(id)
        log_status(:edi_out_rules, id, 'DELETED')
        log_transaction
      end
      success_response('Deleted edi out rule')
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::EdiOutRule.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    private

    def repo
      @repo ||= EdiOutRepo.new
    end

    def edi_out_rule(id)
      repo.find_edi_out_rule_flat(id)
    end

    def validate_edi_out_rule_params(params)
      if repo.can_transform_for_depot?(params[:flow_type])
        if params[:destination_type].nil_or_empty?
          EdiOutRuleDestSchema.call(params)
        elsif params[:destination_type] == AppConst::DEPOT_DESTINATION_TYPE
          EdiOutRuleDepotSchema.call(params)
        elsif params[:destination_type] == AppConst::PARTY_ROLE_DESTINATION_TYPE
          EdiOutRulePartyRoleSchema.call(params)
        end
      else
        EdiOutRulePartyRoleSchema.call(params)
      end
    end
  end
end
