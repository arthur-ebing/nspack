# frozen_string_literal: true

module MasterfilesApp
  class SeasonInteractor < BaseInteractor
    def create_season(params) # rubocop:disable Metrics/AbcSize
      params[:season_year] = season_year(params[:end_date])
      attrs = params.merge(season_code: season_code(params[:season_year], params[:commodity_id]))
      res = validate_season_params(attrs)
      return validation_failed_response(res) if res.failure?

      id = nil
      repo.transaction do
        id = repo.create_season(res)
        log_status('seasons', id, 'CREATED')
        log_transaction
      end
      instance = season(id)
      success_response("Created season #{instance.season_code}",
                       instance)
    rescue Sequel::UniqueConstraintViolation
      failed_response("This season code #{res[:season_code]} already exists")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_season(id, params) # rubocop:disable Metrics/AbcSize
      params[:season_year] = season_year(params[:end_date])
      attrs = params.merge(season_code: season_code(params[:season_year], params[:commodity_id]))
      res = validate_season_params(attrs)
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        repo.update_season(id, res)
        log_transaction
      end
      instance = season(id)
      success_response("Updated season #{instance.season_code}",
                       instance)
    rescue Sequel::UniqueConstraintViolation
      failed_response("This season code #{res[:season_code]} already exists")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_season(id)
      name = season(id).season_code
      repo.transaction do
        repo.delete_season(id)
        log_status('seasons', id, 'DELETED')
        log_transaction
      end
      success_response("Deleted season #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::Season.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    def season_code(season_year, commodity_id)
      repo.season_code(season_year, commodity_id)
    end

    def one_year_from_start_date(start_date)
      repo.one_year_from_start_date(start_date)
    end

    def season_year(end_date)
      Date.parse(end_date.to_s).year
    end

    private

    def repo
      @repo ||= CalendarRepo.new
    end

    def season(id)
      repo.find_season(id)
    end

    def validate_season_params(params)
      SeasonSchema.call(params)
    end
  end
end
