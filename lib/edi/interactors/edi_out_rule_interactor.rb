# frozen_string_literal: true

module EdiApp
  class EdiOutRuleInteractor < BaseInteractor
    def create_edi_out_rule(params) # rubocop:disable Metrics/AbcSize
      res = validate_edi_out_rule_params(params)
      return validation_failed_response(res) if res.failure?

      vres = validate_singleton(params[:flow_type], nil)
      return vres unless vres.success

      id = nil
      repo.transaction do
        params[:directory_keys] = "{#{res[:directory_keys].join(',')}}"
        id = repo.create_edi_out_rule(flow_type: params[:flow_type], depot_id: params[:depot_id], party_role_id: params[:party_role_id], hub_address: params[:hub_address], directory_keys: params[:directory_keys])
        log_status(:edi_out_rules, id, 'CREATED')
        log_transaction
      end
      instance = edi_out_rule(id)
      success_response('Created EDI out rule', instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { flow_type: ['This EDI out rule already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_edi_out_rule(id, params) # rubocop:disable Metrics/AbcSize
      res = validate_edi_out_rule_params(params)
      return validation_failed_response(res) if res.failure?

      vres = validate_singleton(params[:flow_type], id)
      return vres unless vres.success

      repo.transaction do
        params.delete_if { |_k, v| v.nil_or_empty? }
        params[:directory_keys] = "{#{res[:directory_keys].join(',')}}"
        repo.update_edi_out_rule(id, flow_type: params[:flow_type], depot_id: params[:depot_id], party_role_id: params[:party_role_id], hub_address: params[:hub_address], directory_keys: params[:directory_keys])
        log_transaction
      end
      instance = edi_out_rule(id)
      success_response('Updated EDI out rule', instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_edi_out_rule(id)
      repo.transaction do
        repo.delete_edi_out_rule(id)
        log_status(:edi_out_rules, id, 'DELETED')
        log_transaction
      end
      success_response('Deleted EDI out rule')
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def validate_singleton(flow_type, id)
      return ok_response unless repo.can_transform_only_one_destination?(flow_type)

      existing = repo.existing_singleton?(flow_type, id)
      return validation_failed_message_response(flow_type: ['can only be set to one destination.']) if existing

      ok_response
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
      return EdiOutRuleSingletonSchema.call(params) if repo.can_transform_only_one_destination?(params[:flow_type])

      if repo.can_transform_for_depot?(params[:flow_type])
        return EdiOutRuleDestSchema.call(params) if params[:destination_type].nil_or_empty?
        return EdiOutRuleDepotSchema.call(params) if params[:destination_type] == AppConst::DEPOT_DESTINATION_TYPE
        return EdiOutRulePartyRoleSchema.call(params) if params[:destination_type] == AppConst::PARTY_ROLE_DESTINATION_TYPE
      end

      EdiOutRulePartyRoleSchema.call(params)
    end
  end
end
