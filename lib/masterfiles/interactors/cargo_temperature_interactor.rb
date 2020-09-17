# frozen_string_literal: true

module MasterfilesApp
  class CargoTemperatureInteractor < BaseInteractor
    def create_cargo_temperature(params) # rubocop:disable Metrics/AbcSize
      res = validate_cargo_temperature_params(params)
      return validation_failed_response(res) if res.failure?

      id = nil
      repo.transaction do
        id = repo.create_cargo_temperature(res)
        log_status('cargo_temperatures', id, 'CREATED')
        log_transaction
      end
      instance = cargo_temperature(id)
      success_response("Created cargo temperature #{instance.temperature_code}",
                       instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { temperature_code: ['This cargo temperature already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_cargo_temperature(id, params)
      res = validate_cargo_temperature_params(params)
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        repo.update_cargo_temperature(id, res)
        log_transaction
      end
      instance = cargo_temperature(id)
      success_response("Updated cargo temperature #{instance.temperature_code}",
                       instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_cargo_temperature(id)
      name = cargo_temperature(id).temperature_code
      repo.transaction do
        repo.delete_cargo_temperature(id)
        log_status('cargo_temperatures', id, 'DELETED')
        log_transaction
      end
      success_response("Deleted cargo temperature #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    # def complete_a_cargo_temperature(id, params)
    #   res = complete_a_record(:cargo_temperatures, id, params.merge(enqueue_job: false))
    #   if res.success
    #     success_response(res.message, cargo_temperature(id))
    #   else
    #     failed_response(res.message, cargo_temperature(id))
    #   end
    # end

    # def reopen_a_cargo_temperature(id, params)
    #   res = reopen_a_record(:cargo_temperatures, id, params.merge(enqueue_job: false))
    #   if res.success
    #     success_response(res.message, cargo_temperature(id))
    #   else
    #     failed_response(res.message, cargo_temperature(id))
    #   end
    # end

    # def approve_or_reject_a_cargo_temperature(id, params)
    #   res = if params[:approve_action] == 'a'
    #           approve_a_record(:cargo_temperatures, id, params.merge(enqueue_job: false))
    #         else
    #           reject_a_record(:cargo_temperatures, id, params.merge(enqueue_job: false))
    #         end
    #   if res.success
    #     success_response(res.message, cargo_temperature(id))
    #   else
    #     failed_response(res.message, cargo_temperature(id))
    #   end
    # end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::CargoTemperature.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    private

    def repo
      @repo ||= CargoTemperatureRepo.new
    end

    def cargo_temperature(id)
      repo.find_cargo_temperature(id)
    end

    def validate_cargo_temperature_params(params)
      CargoTemperatureSchema.call(params)
    end
  end
end
