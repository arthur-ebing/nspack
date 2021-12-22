# frozen_string_literal: true

module MasterfilesApp
  class MrlSampleTypeInteractor < BaseInteractor
    def create_mrl_sample_type(params)
      res = validate_mrl_sample_type_params(params)
      return validation_failed_response(res) if res.failure?

      id = nil
      repo.transaction do
        id = repo.create_mrl_sample_type(res)
        log_status(:mrl_sample_types, id, 'CREATED')
        log_transaction
      end
      instance = mrl_sample_type(id)
      success_response("Created mrl sample type #{instance.sample_type_code}", instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { sample_type_code: ['This mrl sample type already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_mrl_sample_type(id, params)
      res = validate_mrl_sample_type_params(params)
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        repo.update_mrl_sample_type(id, res)
        log_transaction
      end
      instance = mrl_sample_type(id)
      success_response("Updated mrl sample type #{instance.sample_type_code}", instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_mrl_sample_type(id) # rubocop:disable Metrics/AbcSize
      name = mrl_sample_type(id).sample_type_code
      repo.transaction do
        repo.delete_mrl_sample_type(id)
        log_status(:mrl_sample_types, id, 'DELETED')
        log_transaction
      end
      success_response("Deleted mrl sample type #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    rescue Sequel::ForeignKeyConstraintViolation => e
      puts e.message
      failed_response("Unable to delete mrl sample type. It is still referenced#{e.message.partition('referenced').last}")
    end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::MrlSampleType.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    private

    def repo
      @repo ||= QualityRepo.new
    end

    def mrl_sample_type(id)
      repo.find_mrl_sample_type(id)
    end

    def validate_mrl_sample_type_params(params)
      MrlSampleTypeSchema.call(params)
    end
  end
end
