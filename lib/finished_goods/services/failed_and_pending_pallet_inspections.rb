# frozen_string_literal: true

module FinishedGoodsApp
  class FailedAndPendingPalletInspections < BaseService
    attr_reader :repo, :pallet_number, :pallet_id, :match_tm, :match_grade

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
      resolve_govt_inspection_checks
      failed = failed_inspections
      pending = pending_inspections
      return success_response('Inspections: Pallet passed.', { pallet_number: pallet_number }) if (failed + pending).empty?

      OpenStruct.new(success: false,
                     instance: { pallet_number: pallet_number },
                     errors: { failed: failed, pending: pending },
                     message: 'Inspections Failed')
    end

    def resolve_govt_inspection_checks # rubocop:disable Metrics/AbcSize
      tm_ids = repo.select_values(:pallet_sequences, :target_market_id, pallet_id: pallet_id).uniq
      grade_ids = repo.select_values(:pallet_sequences, :grade_id, pallet_id: pallet_id).uniq
      inspection_type = repo.govt_inspection_type_check_attrs
      @match_tm = inspection_type[:applies_to_all_tms] || (inspection_type[:applicable_tm_ids] & tm_ids).any?
      @match_grade = inspection_type[:applies_to_all_grades] || (inspection_type[:applicable_grade_ids] & grade_ids).any?
    end

    def failed_inspections
      inspection_types = []
      repo.open_ended_failed_inspections_for(pallet_id).each do |id|
        inspection_types << repo.get(:inspection_types, id, :inspection_type_code)
      end
      inspection_types << AppConst::GOVT_INSPECTION_AGENCY if failed_govt_inspection?
      inspection_types
    end

    def pending_inspections
      inspection_types = []
      repo.open_ended_pending_inspections_for(pallet_id).each do |id|
        inspection_types << repo.get(:inspection_types, id, :inspection_type_code)
      end
      inspection_types << AppConst::GOVT_INSPECTION_AGENCY if pending_govt_inspection?
      inspection_types
    end

    def failed_govt_inspection?
      # failed PPECB inspections is true if
      # PPECB inspection_type's applies_to_all_grades is true and/or applies_to_all_tms is true OR
      # pallet's grade and/or packed_tm_group is part of the PPECB domain AND
      # pallet.govt_inspection_passed is false
      return false unless match_tm || match_grade

      !repo.get(:pallets, pallet_id, :govt_inspection_passed)
    end

    def pending_govt_inspection?
      # pending PPECB inspections is true if
      # pallet has not been inspected(pallets.inspected is false) AND
      # PPECB inspection_type's applies_to_all_grades is true and/or applies_to_all_tms is true OR
      # pallet's grade and/or packed_tm_group is part of the PPECB domain
      return false if repo.get(:pallets, pallet_id, :inspected)

      match_tm || match_grade
    end
  end
end
