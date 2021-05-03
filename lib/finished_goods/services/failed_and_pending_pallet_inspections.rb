# frozen_string_literal: true

module FinishedGoodsApp
  class FailedAndPendingPalletInspections < BaseService
    attr_reader :repo, :pallet_number, :pallet_id

    def initialize(pallet_number)
      @pallet_number = pallet_number.to_s
      @repo = InspectionRepo.new
    end

    def call
      res = InspectionPalletSchema.call({ pallet_number: pallet_number })
      return validation_failed_response(res) if res.failure?

      @pallet_id = repo.get_id(:pallets, pallet_number: pallet_number)
      repo.create_inspection(res)

      check_errors
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    private

    def check_errors
      errors = {}
      failed_inspections.each { |failed| errors[failed.to_sym] = ['failed inspection'] }
      pending_inspections.each { |pending| errors[pending.to_sym] = ['inspection still pending'] }
      return success_response('Inspections: Pallet passed.', { pallet_number: pallet_number }) if errors.empty?

      OpenStruct.new(success: false,
                     instance: { pallet_number: pallet_number },
                     errors: errors,
                     message: 'Validation error')
    end

    def failed_inspections
      inspection_types = []
      inspection_type_ids = DB[:inspections]
                            .where(pallet_id: pallet_id, passed: false)
                            .exclude(inspector_id: nil)
                            .select_map(:inspection_type_id)
      inspection_type_ids.each do |id|
        inspection_types << repo.get(:inspection_types, id, :inspection_type_code)
      end
      inspection_types
    end

    def pending_inspections
      inspection_types = []
      inspection_type_ids = DB[:inspections]
                            .where(pallet_id: pallet_id, inspector_id: nil)
                            .select_map(:inspection_type_id)
      inspection_type_ids.each do |id|
        inspection_types << repo.get(:inspection_types, id, :inspection_type_code)
      end
      inspection_types
    end
  end
end
