# frozen_string_literal: true

module MasterfilesApp
  class PmMarkInteractor < BaseInteractor
    def create_pm_mark(params) # rubocop:disable Metrics/AbcSize
      params[:packaging_marks] = resolve_packaging_marks(params)
      res = validate_pm_mark_params(params)
      return validation_failed_response(res) if res.failure?

      packaging_marks = nil
      attrs = res.to_h
      packaging_marks = attrs.delete(:packaging_marks) unless attrs[:packaging_marks].nil_or_empty?

      id = nil
      repo.transaction do
        id = repo.create_pm_mark(attrs.merge(packaging_marks: repo.array_of_text_for_db_col(packaging_marks)))
        log_status(:pm_marks, id, 'CREATED')
        log_transaction
      end
      instance = pm_mark(id)
      success_response("Created pm mark #{instance.description}",
                       instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { mark_id: ['This pm mark already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def resolve_packaging_marks(params)
      arr = []
      repo.pm_composition_levels.each do |key, _val|
        arr << params[key.to_s.to_sym]
      end
      arr
    end

    def update_pm_mark(id, params) # rubocop:disable Metrics/AbcSize
      params[:packaging_marks] = resolve_packaging_marks(params)
      res = validate_pm_mark_params(params)
      return validation_failed_response(res) if res.failure?

      attrs = res.to_h
      packaging_marks = attrs.delete(:packaging_marks)

      repo.transaction do
        repo.update_pm_mark(id, attrs.merge(packaging_marks: repo.array_of_text_for_db_col(packaging_marks)))
        log_transaction
      end
      instance = pm_mark(id)
      success_response("Updated pm mark #{instance.description}",
                       instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_pm_mark(id) # rubocop:disable Metrics/AbcSize
      name = pm_mark(id).description
      repo.transaction do
        repo.delete_pm_mark(id)
        log_status(:pm_marks, id, 'DELETED')
        log_transaction
      end
      success_response("Deleted pm mark #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    rescue Sequel::ForeignKeyConstraintViolation => e
      puts e.message
      failed_response("Unable to delete pm mark. It is still referenced#{e.message.partition('referenced').last}")
    end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::PmMark.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    private

    def repo
      @repo ||= BomsRepo.new
    end

    def pm_mark(id)
      repo.find_pm_mark(id)
    end

    def validate_pm_mark_params(params)
      PmMarkSchema.call(params)
    end
  end
end
