# frozen_string_literal: true

module FinishedGoodsApp
  class GovtInspectionSheetInteractor < BaseInteractor # rubocop:disable ClassLength
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
      success_response("Created govt inspection sheet #{instance.booking_reference}", instance)
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
      success_response("Updated govt inspection sheet #{instance.booking_reference}", instance)
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

    def update_govt_inspection_add_pallets(params)
      res = validate_govt_inspection_add_pallet_params(params)
      return res unless res.success

      repo.transaction do
        repo.create_govt_inspection_pallet(res.instance)
      end
      success_response('Added pallet to sheet.')
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { failure_remarks: ['This govt inspection pallet already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def complete_govt_inspection_sheet(id)
      res = repo.exists?(:govt_inspection_pallets, govt_inspection_sheet_id: id)
      return failed_response('Must have at least one pallet attached.') unless res

      update_table_with_status(:govt_inspection_sheets,
                               id,
                               'FINDING_SHEET_COMPLETED',
                               field_changes: { completed: true })
    end

    def reopen_govt_inspection_sheet(id)
      update_table_with_status(:govt_inspection_sheets,
                               id,
                               'FINDING_SHEET_REOPENED',
                               field_changes: { completed: false })
    end

    def update_pallet_statuses(sheet_id, status)
      repo.all_hash(:govt_inspection_pallets, { govt_inspection_sheet_id: sheet_id }, true).select_map(:id).each do |id|
        instance = repo.find_hash(:govt_inspection_pallets, id)
        update_table_with_status(:pallets,
                                 instance[:pallet_id],
                                 status,
                                 field_changes: { inspected: true,
                                                  govt_inspection_passed: instance[:passed],
                                                  govt_first_inspection_at: Time.now,
                                                  last_govt_inspection_pallet_id: id })
      end
    end

    def complete_inspection_govt_inspection_sheet(id)
      res = repo.validate_govt_inspection_sheet_inspected(id)
      return res unless res.success

      attrs = { inspected: true, results_captured: true, results_captured_at: Time.now }
      repo.transaction do
        repo.update_govt_inspection_sheet(id, attrs)
        log_status(:govt_inspection_sheets, id, 'MANUALLY_INSPECTED_BY_GOVT')
        update_pallet_statuses(id, 'MANUALLY_INSPECTED_BY_GOVT')
        log_transaction
      end
      success_response('Inspection Completed')
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::GovtInspectionSheet.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    private

    def repo
      @repo ||= GovtInspectionRepo.new
    end

    def govt_inspection_sheet(id)
      repo.find_govt_inspection_sheet(id)
    end

    def validate_govt_inspection_sheet_params(params)
      GovtInspectionSheetSchema.call(params)
    end

    def validate_govt_inspection_add_pallet_params(params)
      res = GovtInspectionAddPalletSchema.call(params)
      return validation_failed_response(res) unless res.messages.empty?

      attrs = res.to_h
      res = repo.validate_pallet_number(attrs.delete(:pallet_number))
      return res unless res.success

      attrs[:pallet_id] = res.instance
      success_response('ok', attrs)
    end
  end
end
