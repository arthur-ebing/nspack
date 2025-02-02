# frozen_string_literal: true

module FinishedGoodsApp
  class FailedAndPendingPalletInspections < BaseService
    attr_reader :repo, :pallet_number, :pallet_id, :match_grade, :match_packed_tm_group, :check_status

    def initialize(pallet_number, check_status: false)
      @pallet_number = pallet_number.to_s
      @check_status = check_status
      @repo = InspectionRepo.new
    end

    def call
      res = InspectionPalletSchema.call({ pallet_number: pallet_number })
      return validation_failed_response(res) if res.failure?

      @pallet_id = repo.get_id(:pallets, pallet_number: pallet_number)
      repo.create_inspection(res) unless check_status

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
      packed_tm_group_ids = repo.select_values(:pallet_sequences, :packed_tm_group_id, pallet_id: pallet_id).uniq
      grade_ids = repo.select_values(:pallet_sequences, :grade_id, pallet_id: pallet_id).uniq
      inspection_type = repo.govt_inspection_type_check_attrs
      @match_packed_tm_group = inspection_type[:applies_to_all_packed_tm_groups] || (inspection_type[:applicable_packed_tm_group_ids].nil? ? false : (inspection_type[:applicable_packed_tm_group_ids] & packed_tm_group_ids).any?)
      @match_grade = inspection_type[:applies_to_all_grades] || (inspection_type[:applicable_grade_ids].nil? ? false : (inspection_type[:applicable_grade_ids] & grade_ids).any?)
    end

    def failed_inspections
      inspection_types = []
      repo.open_ended_failed_inspections_for(pallet_id).each do |id|
        inspection_types << repo.get(:inspection_types, :inspection_type_code, id)
      end
      inspection_types << AppConst::GOVT_INSPECTION_AGENCY if failed_govt_inspection?
      inspection_types
    end

    def pending_inspections
      inspection_types = []
      repo.open_ended_pending_inspections_for(pallet_id).each do |id|
        inspection_types << repo.get(:inspection_types, :inspection_type_code, id)
      end
      inspection_types << AppConst::GOVT_INSPECTION_AGENCY if pending_govt_inspection?
      inspection_types
    end

    def failed_govt_inspection?
      # failed PPECB inspections is true if
      # pallet has been inspected(pallets.inspected is true) AND
      # pallet.govt_inspection_passed is false AND
      # PPECB inspection_type's applies_to_all_grades and/or applies_to_all_packed_tm_groups is true OR
      # pallet's grade and/or packed_tm_group is part of the PPECB domain
      return false unless match_packed_tm_group && match_grade

      inspected, govt_inspection_passed = repo.get_value(:pallets, %i[inspected govt_inspection_passed], id: pallet_id)
      inspected && !govt_inspection_passed
    end

    def pending_govt_inspection?
      # pending PPECB inspections is true if
      # pallet has not been inspected(pallets.inspected is false) AND
      # PPECB inspection_type's applies_to_all_grades and/or applies_to_all_packed_tm_groups is true OR
      # pallet's grade and/or packed_tm_group is part of the PPECB domain
      return false if repo.get(:pallets, :inspected, pallet_id)

      match_packed_tm_group && match_grade
    end
  end
end
