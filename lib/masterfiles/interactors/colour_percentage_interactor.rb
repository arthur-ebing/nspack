# frozen_string_literal: true

module MasterfilesApp
  class ColourPercentageInteractor < BaseInteractor
    def create_colour_percentage(params)
      res = validate_colour_percentage_params(params)
      return validation_failed_response(res) if res.failure?

      id = nil
      repo.transaction do
        id = repo.create_colour_percentage(res)
        log_status(:colour_percentages, id, 'CREATED')
        log_transaction
      end
      instance = colour_percentage(id)
      success_response("Created colour percentage #{instance.description}", instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { description: ['This colour percentage already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_colour_percentage(id, params)
      res = validate_colour_percentage_params(params)
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        repo.update_colour_percentage(id, res)
        log_transaction
      end
      instance = colour_percentage(id)
      success_response("Updated colour percentage #{instance.description}", instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_colour_percentage(id) # rubocop:disable Metrics/AbcSize
      name = colour_percentage(id).description
      repo.transaction do
        repo.delete_colour_percentage(id)
        log_status(:colour_percentages, id, 'DELETED')
        log_transaction
      end
      success_response("Deleted colour percentage #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    rescue Sequel::ForeignKeyConstraintViolation => e
      puts e.message
      failed_response("Unable to delete colour percentage. It is still referenced#{e.message.partition('referenced').last}")
    end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::ColourPercentage.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    def inline_update_colour_percentage(id, params)
      res = validate_inline_update_colour_percentage_params(params)
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        repo.update_colour_percentage(id, colour_percentage: res[:column_value])
        log_transaction
      end

      instance = colour_percentage(id)
      success_response('Updated colour percentage', instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    private

    def repo
      @repo ||= CommodityRepo.new
    end

    def colour_percentage(id)
      repo.find_colour_percentage(id)
    end

    def validate_colour_percentage_params(params)
      ColourPercentageSchema.call(params)
    end

    def validate_inline_update_colour_percentage_params(params)
      ColourPercentageInlineUpdateSchema.call(params)
    end
  end
end
