# frozen_string_literal: true

module MasterfilesApp
  class SeasonGroupInteractor < BaseInteractor
    def repo
      @repo ||= CalendarRepo.new
    end

    def season_group(id)
      repo.find_season_group(id)
    end

    def validate_season_group_params(params)
      SeasonGroupSchema.call(params)
    end

    def create_season_group(params) # rubocop:disable Metrics/AbcSize
      res = validate_season_group_params(params)
      return validation_failed_response(res) if res.failure?

      id = nil
      repo.transaction do
        id = repo.create_season_group(res)
        log_transaction
      end
      instance = season_group(id)
      success_response("Created season group #{instance.season_group_code}",
                       instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { season_group_code: ['This season group already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_season_group(id, params)
      res = validate_season_group_params(params)
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        repo.update_season_group(id, res)
        log_transaction
      end
      instance = season_group(id)
      success_response("Updated season group #{instance.season_group_code}",
                       instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_season_group(id)
      name = season_group(id).season_group_code
      repo.transaction do
        repo.delete_season_group(id)
        log_transaction
      end
      success_response("Deleted season group #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::SeasonGroup.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end
  end
end
