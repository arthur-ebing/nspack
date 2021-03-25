# frozen_string_literal: true

module MasterfilesApp
  class OrganizationInteractor < BaseInteractor
    def create_organization(params) # rubocop:disable Metrics/AbcSize
      res = validate_organization_params(params)
      return validation_failed_response(res) if res.failure?

      res = res.to_h
      target_market_ids = res.delete(:target_market_ids)

      id = nil
      repo.transaction do
        id = repo.create_organization(res)
      end
      link_target_markets(organization_target_customer_party_role_id(id), target_market_ids) if AppConst::CR_PROD.kromco_target_markets_customers_link?

      instance = organization(id)
      success_response("Created organization #{instance.party_name}", instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { short_description: ['This organization already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_organization(id, params) # rubocop:disable Metrics/AbcSize
      res = validate_organization_params(params)
      return validation_failed_response(res) if res.failure?

      res = res.to_h
      target_market_ids = res.delete(:target_market_ids)

      repo.transaction do
        repo.update_organization(id, res)
      end
      link_target_markets(organization_target_customer_party_role_id(id), target_market_ids) if AppConst::CR_PROD.kromco_target_markets_customers_link?

      instance = organization(id)
      success_response("Updated organization #{instance.party_name}", instance)
    rescue Sequel::ForeignKeyConstraintViolation => e
      failed_response("Unable to update organization. Still referenced #{e.message.partition('referenced').last}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_organization(id)
      instance = organization(id)
      repo.transaction do
        repo.delete_organization(id)
      end
      success_response("Deleted organization #{instance.party_name}")
    rescue Sequel::ForeignKeyConstraintViolation => e
      failed_response("Unable to delete organization. Still referenced #{e.message.partition('referenced').last}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def associate_farm_puc_orgs(organization_id, farm_puc_ids)
      return validation_failed_response(OpenStruct.new(messages: { farm_puc_ids: ['You did not choose a farm_puc record'] })) if farm_puc_ids.empty?

      repo.transaction do
        repo.associate_farm_puc_orgs(organization_id, farm_puc_ids)
      end
      success_response('Marketing Organization => farm_pucs associated successfully')
    end

    def link_target_markets(target_customer_party_role_id, target_market_ids)
      repo.transaction do
        repo.link_target_markets(target_customer_party_role_id, target_market_ids)
      end

      success_response('Target Markets linked successfully')
    end

    private

    def repo
      @repo ||= PartyRepo.new
    end

    def organization(id)
      repo.find_organization(id)
    end

    def validate_organization_params(params)
      params[:role_ids] ||= ''
      OrganizationSchema.call(params)
    end

    def organization_target_customer_party_role_id(id)
      party_id = repo.get(:organizations, id, :party_id)
      repo.party_role_id_from_role_and_party_id(AppConst::ROLE_TARGET_CUSTOMER, party_id)
    end
  end
end
