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
      return failed_response('Inspection sheet must have at least one pallet attached.') unless res

      repo.update_govt_inspection_sheet(id, completed: true)
      log_status(:govt_inspection_sheets, id, 'FINDING_SHEET_COMPLETED')

      success_response('Completed sheet.')
    end

    def reopen_govt_inspection_sheet(id)
      repo.update_govt_inspection_sheet(id, completed: false)
      log_status(:govt_inspection_sheets, id, 'FINDING_SHEET_REOPENED')

      success_response('Reopened sheet.')
    end

    def finish_govt_inspection_sheet(id) # rubocop:disable Metrics/AbcSize
      res = repo.validate_govt_inspection_sheet_inspect_params(id)
      return res unless res.success

      attrs = { inspected: true, results_captured: true, results_captured_at: Time.now }
      repo.transaction do
        repo.update_govt_inspection_sheet(id, attrs)
        log_status(:govt_inspection_sheets, id, 'MANUALLY_INSPECTED_BY_GOVT')

        repo.all_hash(:govt_inspection_pallets, govt_inspection_sheet_id: id).each do |govt_inspection_pallet|
          pallet = repo.find_hash(:pallets, govt_inspection_pallet[:pallet_id])
          params = { inspected: true, govt_inspection_passed: govt_inspection_pallet[:passed], last_govt_inspection_pallet_id: govt_inspection_pallet[:id] }
          params[:govt_first_inspection_at] = Time.now if pallet[:govt_first_inspection_at].nil?
          params[:in_stock] = govt_inspection_pallet[:passed]
          params[:stock_created_at] = Time.now if govt_inspection_pallet[:passed]

          repo.update(:pallets, pallet[:id], params)
          log_status(:pallets, pallet[:id], 'MANUALLY_INSPECTED_BY_GOVT')
        end
        log_transaction
      end
      success_response('Finished Inspection')
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def clone_govt_inspection_sheet(id) # rubocop:disable Metrics/AbcSize
      repo.transaction do
        attrs = (repo.where_hash(:govt_inspection_sheets, id: id) || {})
        attrs = attrs.slice(:inspector_id,
                            :inspection_billing_party_role_id,
                            :exporter_party_role_id,
                            :booking_reference,
                            :inspection_point,
                            :destination_country_id)
        attrs[:cancelled_id] = id
        clone_id = repo.create_govt_inspection_sheet(attrs)
        log_status(:govt_inspection_sheets, clone_id, 'CREATED_FROM_CANCELLED')

        repo.all_hash(:govt_inspection_pallets, govt_inspection_sheet_id: id).each do |govt_inspection_pallet|
          params = { pallet_id: govt_inspection_pallet[:pallet_id],  govt_inspection_sheet_id: clone_id }
          repo.create_govt_inspection_pallet(params)
        end

        log_transaction
      end
      success_response('Cancelled Inspection')
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def cancel_govt_inspection_sheet(id) # rubocop:disable Metrics/AbcSize
      attrs = { cancelled: true, cancelled_at: Time.now }
      repo.transaction do
        clone_govt_inspection_sheet(id)
        repo.update_govt_inspection_sheet(id, attrs)
        log_status(:govt_inspection_sheets, id, 'CANCELLED')
        govt_inspection_pallets = repo.all_hash(:govt_inspection_pallets,  govt_inspection_sheet_id: id)
        govt_inspection_pallets.each do |govt_inspection_pallet|
          attrs = { inspected: nil, govt_inspection_passed: nil, last_govt_inspection_pallet_id: nil, in_stock: nil, stock_created_at: nil }
          repo.update(:pallets, govt_inspection_pallet[:pallet_id], attrs)
          log_status(:pallets, govt_inspection_pallet[:pallet_id], 'INSPECTION_CANCELLED')
        end
        log_transaction
      end
      success_response('Cancelled Inspection')
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

    def validate_govt_inspection_add_pallet_params(params) # rubocop:disable Metrics/AbcSize
      res = GovtInspectionAddPalletSchema.call(params)
      return validation_failed_response(res) unless res.messages.empty?

      attrs = res.to_h
      pallet_number = attrs.delete(:pallet_number)

      pallet_id = repo.get_id(:pallets, pallet_number: pallet_number)
      return failed_response("Pallet: #{pallet_number} doesn't exist.") if id.nil?

      res = repo.exists_on_inspection_sheet(pallet_id)
      return failed_response("Pallet: #{pallet_number} is already on an inspection sheet.") if res

      res = repo.exists?(:pallet_sequences, pallet_id: pallet_id, failed_otmc_results: nil)
      return failed_response("Pallet: #{pallet_number} failed a OTMC test.") unless res

      attrs[:pallet_id] = id
      success_response('Passed Validation', attrs)
    end
  end
end
