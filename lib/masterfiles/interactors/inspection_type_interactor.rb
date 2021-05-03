# frozen_string_literal: true

module MasterfilesApp
  class InspectionTypeInteractor < BaseInteractor
    def create_inspection_type(params) # rubocop:disable Metrics/AbcSize
      res = validate_inspection_type_params(params)
      return validation_failed_response(res) if res.failure?

      id = nil
      repo.transaction do
        id = repo.create_inspection_type(res)
        log_status(:inspection_types, id, 'CREATED')
        log_transaction
      end
      instance = inspection_type(id)
      success_response("Created inspection type #{instance.inspection_type_code}", instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { inspection_type_code: ['This inspection type already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_inspection_type(id, params)
      res = validate_inspection_type_params(params)
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        repo.update_inspection_type(id, res)
        log_transaction
      end
      instance = inspection_type(id)
      success_response("Updated inspection type #{instance.inspection_type_code}", instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_inspection_type(id) # rubocop:disable Metrics/AbcSize
      name = inspection_type(id).inspection_type_code
      repo.transaction do
        repo.delete_inspection_type(id)
        log_status(:inspection_types, id, 'DELETED')
        log_transaction
      end
      success_response("Deleted inspection type #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    rescue Sequel::ForeignKeyConstraintViolation => e
      puts e.message
      failed_response("Unable to delete inspection type. It is still referenced#{e.message.partition('referenced').last}")
    end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::InspectionType.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    private

    def repo
      @repo ||= QualityRepo.new
    end

    def inspection_type(id)
      repo.find_inspection_type(id)
    end

    def validate_inspection_type_params(params)
      params[:applicable_tm_ids] = nil if params[:applicable_tm_ids].nil_or_empty?
      params[:applicable_tm_customer_ids] = nil if params[:applicable_tm_customer_ids].nil_or_empty?
      params[:applicable_grade_ids] = nil if params[:applicable_grade_ids].nil_or_empty?
      params[:applicable_marketing_org_party_role_ids] = nil if params[:applicable_marketing_org_party_role_ids].nil_or_empty?
      InspectionTypeSchema.call(params)
    end
  end
end
