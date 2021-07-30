# frozen_string_literal: true

module MasterfilesApp
  class ColorPercentageInteractor < BaseInteractor
    def create_color_percentage(params)
      res = validate_color_percentage_params(params)
      return validation_failed_response(res) if res.failure?

      id = nil
      repo.transaction do
        id = repo.create_color_percentage(res)
        log_status(:color_percentages, id, 'CREATED')
        log_transaction
      end
      instance = color_percentage(id)
      success_response("Created color percentage #{instance.description}", instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { description: ['This color percentage already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_color_percentage(id, params)
      res = validate_color_percentage_params(params)
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        repo.update_color_percentage(id, res)
        log_transaction
      end
      instance = color_percentage(id)
      success_response("Updated color percentage #{instance.description}", instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_color_percentage(id) # rubocop:disable Metrics/AbcSize
      name = color_percentage(id).description
      repo.transaction do
        repo.delete_color_percentage(id)
        log_status(:color_percentages, id, 'DELETED')
        log_transaction
      end
      success_response("Deleted color percentage #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    rescue Sequel::ForeignKeyConstraintViolation => e
      puts e.message
      failed_response("Unable to delete color percentage. It is still referenced#{e.message.partition('referenced').last}")
    end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::ColorPercentage.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    def inline_update_color_percentage(id, params)
      res = validate_inline_update_color_percentage_params(params)
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        repo.update_color_percentage(id, color_percentage: res[:column_value])
        log_transaction
      end

      instance = color_percentage(id)
      success_response('Updated color percentage', instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    private

    def repo
      @repo ||= CommodityRepo.new
    end

    def color_percentage(id)
      repo.find_color_percentage(id)
    end

    def validate_color_percentage_params(params)
      ColorPercentageSchema.call(params)
    end

    def validate_inline_update_color_percentage_params(params)
      ColorPercentageInlineUpdateSchema.call(params)
    end
  end
end
