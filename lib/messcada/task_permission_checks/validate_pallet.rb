# frozen_string_literal: true

module MesscadaApp
  module TaskPermissionCheck
    class ValidatePallets < BaseService
      attr_reader :task, :pallet_numbers, :repo, :load_id
      def initialize(task, pallet_numbers, load_id = nil)
        @task = task
        @repo = MesscadaRepo.new
        @inspection_repo = FinishedGoodsApp::GovtInspectionRepo.new
        @pallet_numbers = Array(pallet_numbers)
        @load_id = load_id
      end

      CHECKS = {
        exists: :exists_check,
        not_shipped: :not_shipped_check,
        shipped: :shipped_check,
        in_stock: :in_stock_check,
        has_nett_weight: :nett_weight_check,
        has_gross_weight: :gross_weight_check,
        not_on_load: :not_on_load_check,
        not_on_inspection_sheet: :not_on_inspection_sheet_check,
        not_inspected: :not_inspected_check,
        not_failed_otmc: :not_failed_otmc_check,
        verification_passed: :verification_passed_check,
        pallet_weight: :pallet_weight_check
      }.freeze

      def call
        check = CHECKS[task]
        raise ArgumentError, "Task \"#{task}\" is unknown for #{self.class}." if check.nil?

        raise ArgumentError, 'Validation empty.' if pallet_numbers.nil_or_empty?

        exists_check

        send(check)
      end

      private

      def exists_check
        errors = (pallet_numbers - repo.where_pallets(pallet_number: pallet_numbers)).uniq
        raise Crossbeams::InfoError, "Pallet: #{errors.join(', ')} doesn't exist." unless errors.empty?

        all_ok
      end

      def not_shipped_check
        errors = repo.where_pallets(pallet_number: pallet_numbers, shipped: true).uniq
        raise Crossbeams::InfoError, "Pallet: #{errors.join(', ')} already shipped." unless errors.empty?

        all_ok
      end

      def shipped_check
        errors = repo.where_pallets(pallet_number: pallet_numbers, shipped: false).uniq
        raise Crossbeams::InfoError, "Pallet: #{errors.join(', ')} not shipped." unless errors.empty?

        all_ok
      end

      def in_stock_check
        errors = repo.where_pallets(pallet_number: pallet_numbers, in_stock: false).uniq
        raise Crossbeams::InfoError, "Pallet: #{errors.join(', ')} not in stock." unless errors.empty?

        all_ok
      end

      def nett_weight_check
        errors = repo.where_pallets(pallet_number: pallet_numbers, has_nett_weight: true).uniq
        raise Crossbeams::InfoError, "Pallet: #{errors.join(', ')} does not have nett weight." unless errors.empty?

        all_ok
      end

      def gross_weight_check
        errors = repo.where_pallets(pallet_number: pallet_numbers, has_gross_weight: true).uniq
        raise Crossbeams::InfoError, "Pallet: #{errors.join(', ')} does not have gross weight." unless errors.empty?

        all_ok
      end

      def not_on_load_check
        raise ArgumentError, 'Load Id is nil.' if load_id.nil?

        errors = repo.where_pallets(pallet_number: pallet_numbers, on_load: load_id).uniq
        raise Crossbeams::InfoError, "Pallet: #{errors.join(', ')} already allocated to other load." unless errors.empty?

        all_ok
      end

      def not_failed_otmc_check
        return success_response('failed otmc check bypassed') if AppConst::BYPASS_QUALITY_TEST_LOAD_CHECK

        errors = pallet_numbers - repo.select_values(:pallet_sequences, :pallet_number, pallet_number: pallet_numbers, failed_otmc_results: nil).uniq
        raise Crossbeams::InfoError, "Pallet: #{errors.join(', ')} failed a OTMC test." unless errors.empty?

        all_ok
      end

      def not_on_inspection_sheet_check
        errors = @inspection_repo.exists_on_inspection_sheet(pallet_numbers)
        raise Crossbeams::InfoError, "Pallet: #{errors.join(', ')} is already on an inspection sheet." unless errors.empty?

        all_ok
      end

      def not_inspected_check
        errors = @repo.select_values(:pallets, :pallet_number, pallet_number: pallet_numbers, inspected: false).uniq
        raise Crossbeams::InfoError, "Pallet: #{errors.join(', ')}, not previously inspected." unless errors.empty?

        all_ok
      end

      def verification_passed_check
        errors = pallet_numbers - @repo.select_values(:pallet_sequences, :pallet_number, pallet_number: pallet_numbers, verification_passed: true).uniq
        raise Crossbeams::InfoError, "Pallet: #{errors.join(', ')}, verification not passed." unless errors.empty?

        all_ok
      end

      def pallet_weight_check
        return all_ok unless AppConst::PALLET_WEIGHT_REQUIRED_FOR_INSPECTION

        errors = @repo.select_values(:pallets, :pallet_number, pallet_number: pallet_numbers, gross_weight: nil).uniq
        raise Crossbeams::InfoError, "Pallet: #{errors.join(', ')}, gross weight not filled." unless errors.empty?

        all_ok
      end
    end
  end
end
