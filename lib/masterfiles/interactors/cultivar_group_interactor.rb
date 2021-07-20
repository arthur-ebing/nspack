# frozen_string_literal: true

module MasterfilesApp
  class CultivarGroupInteractor < BaseInteractor
    def create_cultivar_group(params)
      res = validate_cultivar_group_params(params)
      return validation_failed_response(res) if res.failure?

      id = nil
      repo.transaction do
        id = repo.create_cultivar_group(res)
        log_status(:cultivar_groups, id, 'CREATED')
        log_transaction
      end
      instance = cultivar_group(id)
      success_response("Created cultivar group #{instance.cultivar_group_code}", instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { cultivar_group_code: ['This cultivar group already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_cultivar_group(id, params)
      res = validate_cultivar_group_params(params)
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        repo.update_cultivar_group(id, res)
        log_transaction
      end
      instance = cultivar_group(id)
      success_response("Updated cultivar group #{instance.cultivar_group_code}", instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_cultivar_group(id) # rubocop:disable Metrics/AbcSize
      name = cultivar_group(id).cultivar_group_code

      repo.transaction do
        cultivar_group = repo.find_cultivar_group(id)
        cultivar_group.cultivar_ids.each do |cultivar_id|
          repo.delete_cultivar(cultivar_id)
        end
        repo.delete_cultivar_group(id)
      end
      success_response("Deleted cultivar group #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    rescue Sequel::ForeignKeyConstraintViolation => e
      failed_response("Unable to delete cultivar group. It is still referenced#{e.message.partition('referenced').last}")
    end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::CultivarGroup.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    private

    def repo
      @repo ||= CultivarRepo.new
    end

    def cultivar_group(id)
      repo.find_cultivar_group(id)
    end

    def validate_cultivar_group_params(params)
      CultivarGroupSchema.call(params)
    end
  end
end
