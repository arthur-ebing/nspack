# frozen_string_literal: true

module RawMaterialsApp
  class BinLoadPurposeInteractor < BaseInteractor
    def create_bin_load_purpose(params) # rubocop:disable Metrics/AbcSize
      res = validate_bin_load_purpose_params(params)
      return validation_failed_response(res) unless res.messages.empty?

      id = nil
      repo.transaction do
        id = repo.create_bin_load_purpose(res)
        log_status(:bin_load_purposes, id, 'CREATED')
        log_transaction
      end
      instance = bin_load_purpose(id)
      success_response("Created bin load purpose #{instance.purpose_code}",
                       instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { purpose_code: ['This bin load purpose already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_bin_load_purpose(id, params)
      res = validate_bin_load_purpose_params(params)
      return validation_failed_response(res) unless res.messages.empty?

      repo.transaction do
        repo.update_bin_load_purpose(id, res)
        log_transaction
      end
      instance = bin_load_purpose(id)
      success_response("Updated bin load purpose #{instance.purpose_code}",
                       instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_bin_load_purpose(id) # rubocop:disable Metrics/AbcSize
      name = bin_load_purpose(id).purpose_code
      repo.transaction do
        repo.delete_bin_load_purpose(id)
        log_status(:bin_load_purposes, id, 'DELETED')
        log_transaction
      end
      success_response("Deleted bin load purpose #{name}")
    rescue Sequel::ForeignKeyConstraintViolation => e
      failed_response("Unable to delete bin load purpose. Still referenced #{e.message.partition('referenced').last}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::BinLoadPurpose.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    private

    def repo
      @repo ||= BinLoadRepo.new
    end

    def bin_load_purpose(id)
      repo.find_bin_load_purpose(id)
    end

    def validate_bin_load_purpose_params(params)
      BinLoadPurposeSchema.call(params)
    end
  end
end
