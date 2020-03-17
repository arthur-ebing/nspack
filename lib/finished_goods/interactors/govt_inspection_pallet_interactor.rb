# frozen_string_literal: true

module FinishedGoodsApp
  class GovtInspectionPalletInteractor < BaseInteractor
    def create_govt_inspection_pallet(params)
      res = validate_govt_inspection_pallet_params(params)
      return validation_failed_response(res) unless res.messages.empty?

      id = nil
      repo.transaction do
        id = repo.create_govt_inspection_pallet(res)
      end
      instance = govt_inspection_pallet(id)
      success_response('Created govt inspection pallet', instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { failure_remarks: ['This govt inspection pallet already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def fail_govt_inspection_pallet(id, params) # rubocop:disable Metrics/AbcSize
      res = validate_govt_inspection_failed_pallet_params(params)
      return validation_failed_response(res) unless res.messages.empty?

      attrs = res.to_h
      attrs[:inspected] = true
      attrs[:passed] = false
      attrs[:inspected_at] = Time.now

      repo.transaction do
        repo.update_govt_inspection_pallet(id, attrs)
      end
      instance = govt_inspection_pallet(id)
      success_response('Govt inspection: pallet failed.', instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def pass_govt_inspection_pallet(ids)
      attrs = { inspected: true,
                inspected_at: Time.now,
                passed: true,
                failure_reason_id: nil,
                failure_remarks: nil }
      repo.transaction do
        [ids].each do |id|
          repo.update_govt_inspection_pallet(id, attrs)
        end
      end
      success_response('Govt inspection: pallets passed.')
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_govt_inspection_pallet(id, params) # rubocop:disable Metrics/AbcSize
      res = validate_govt_inspection_pallet_params(params)
      return validation_failed_response(res) unless res.messages.empty?

      govt_inspection_sheet_id = repo.get_id(:govt_inspection_pallets, govt_inspection_sheet_id: id)
      reinspection = repo.get_with_args(:govt_inspection_sheets, :reinspection, id: govt_inspection_sheet_id)

      attrs = res.to_h
      if reinspection
        attrs[:reinspected] = true
        attrs[:reinspected_at] = Time.now
      end

      repo.transaction do
        repo.update_govt_inspection_pallet(id, attrs)
      end
      instance = govt_inspection_pallet(id)
      success_response('Updated govt inspection pallet', instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_govt_inspection_pallet(id)
      repo.transaction do
        repo.delete_govt_inspection_pallet(id)
      end
      success_response('Deleted govt inspection pallet')
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::GovtInspectionPallet.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    private

    def repo
      @repo ||= GovtInspectionRepo.new
    end

    def govt_inspection_pallet(id)
      repo.find_govt_inspection_pallet_flat(id)
    end

    def validate_govt_inspection_pallet_params(params)
      GovtInspectionPalletSchema.call(params)
    end

    def validate_govt_inspection_failed_pallet_params(params)
      GovtInspectionFailedPalletSchema.call(params)
    end
  end
end
