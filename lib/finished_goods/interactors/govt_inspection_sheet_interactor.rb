# frozen_string_literal: true

module FinishedGoodsApp
  class GovtInspectionSheetInteractor < BaseInteractor
    def create_govt_inspection_sheet(params) # rubocop:disable Metrics/AbcSize
      res = validate_govt_inspection_sheet_params(params)
      return validation_failed_response(res) unless res.messages.empty?

      id = nil
      repo.transaction do
        id = repo.create_govt_inspection_sheet(res)
        log_status(:govt_inspection_sheets, id, 'FINDING_SHEET_CREATED')
        log_transaction
      end
      instance = govt_inspection_sheet(id)
      success_response("Created govt inspection sheet #{instance.booking_reference}",
                       instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { booking_reference: ['This govt inspection sheet already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_govt_inspection_sheet(id, params)
      res = validate_govt_inspection_sheet_params(params)
      return validation_failed_response(res) unless res.messages.empty?

      repo.transaction do
        repo.update_govt_inspection_sheet(id, res)
        log_transaction
      end
      instance = govt_inspection_sheet(id)
      success_response("Updated govt inspection sheet #{instance.booking_reference}",
                       instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_govt_inspection_sheet(id)
      name = govt_inspection_sheet(id).booking_reference
      repo.transaction do
        repo.delete_govt_inspection_sheet(id)
        log_status(:govt_inspection_sheets, id, 'DELETED')
        log_transaction
      end
      success_response("Deleted govt inspection sheet #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def complete_govt_inspection_sheet(id)
      update_table_with_status(:govt_inspection_sheets,
                               id,
                               'FINDING_SHEET_COMPLETED',
                               field_changes: { completed: true })
    end

    def uncomplete_govt_inspection_sheet(id)
      update_table_with_status(:govt_inspection_sheets,
                               id,
                               'FINDING_SHEET_UNCOMPLETED',
                               field_changes: { completed: false })
    end

    def complete_inspection_govt_inspection_sheet(id) # rubocop:disable Metrics/AbcSize
      res = repo.validate_govt_inspection_sheet_inspected(id)
      return res unless res.success

      field_changes = { inspected: true, results_captured: true, results_captured_at: Time.now }
      repo.transaction do
        repo.update_govt_inspection_sheet(id, field_changes)
        log_status(:govt_inspection_sheets, id, 'INSPECTION_COMPLETED')
        pallet_ids = repo.find_govt_inspection_sheet_pallet_ids(id)
        log_multiple_statuses(:pallets, pallet_ids, 'INSPECTED')
        log_transaction
      end
      success_response('INSPECTION_COMPLETED')
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::GovtInspectionSheet.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    private

    def repo
      @repo ||= GovtInspectionSheetRepo.new
    end

    def govt_inspection_sheet(id)
      repo.find_govt_inspection_sheet(id)
    end

    def validate_govt_inspection_sheet_params(params)
      GovtInspectionSheetSchema.call(params)
    end
  end
end
