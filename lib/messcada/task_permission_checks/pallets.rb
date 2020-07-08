# frozen_string_literal: true

module MesscadaApp
  module TaskPermissionCheck
    class Pallets < BaseService # rubocop:disable Metrics/ClassLength
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
        inspected: :inspected_check,
        not_inspected: :not_inspected_check,
        not_failed_otmc: :not_failed_otmc_check,
        verification_passed: :verification_passed_check,
        pallet_weight: :pallet_weight_check,
        allocate: :allocate_check
      }.freeze

      def call
        check = CHECKS[task]
        raise ArgumentError, "Task \"#{task}\" is unknown for #{self.class}." if check.nil?

        return failed_response 'Pallet number not given.' if pallet_numbers.nil_or_empty?

        res = exists_check
        return failed_response res.message unless res.success

        send(check)
      end

      private

      def exists_check
        pallets_exists = repo.select_values(:pallets, :pallet_number, pallet_number: pallet_numbers)
        errors = pallet_numbers - pallets_exists
        return failed_response "Pallet: #{errors.join(', ')} doesn't exist." unless errors.empty?

        all_ok
      end

      def not_shipped_check
        errors = repo.select_values(:pallets, :pallet_number, pallet_number: pallet_numbers, shipped: true)
        return failed_response "Pallet: #{errors.join(', ')} already shipped." unless errors.empty?

        all_ok
      end

      def shipped_check
        errors = repo.select_values(:pallets, :pallet_number, pallet_number: pallet_numbers, shipped: false)
        return failed_response "Pallet: #{errors.join(', ')} not shipped." unless errors.empty?

        all_ok
      end

      def in_stock_check
        errors = repo.select_values(:pallets, :pallet_number, pallet_number: pallet_numbers, in_stock: false)
        return failed_response "Pallet: #{errors.join(', ')} not in stock." unless errors.empty?

        all_ok
      end

      def nett_weight_check
        pallets_with_nett_weight = repo.select_values(:pallets, :pallet_number, Sequel.lit('nett_weight IS NOT NULL'))
        errors = pallet_numbers - pallets_with_nett_weight
        return failed_response "Pallet: #{errors.join(', ')} does not have nett weight." unless errors.empty?

        all_ok
      end

      def gross_weight_check
        pallets_with_gross_weight = repo.select_values(:pallets, :pallet_number, Sequel.lit('gross_weight IS NOT NULL'))
        errors = pallet_numbers - pallets_with_gross_weight
        return failed_response "Pallet: #{errors.join(', ')} does not have gross weight." unless errors.empty?

        all_ok
      end

      def not_on_load_check
        pallets_on_load = if load_id.nil?
                            []
                          else
                            repo.select_values(:pallets, :pallet_number, load_id: load_id)
                          end
        available_pallets = repo.select_values(:pallets, :pallet_number, load_id: nil)

        errors = pallet_numbers - pallets_on_load - available_pallets
        return failed_response "Pallet: #{errors.join(', ')} already allocated to other loads." unless errors.empty?

        all_ok
      end

      def not_failed_otmc_check
        return success_response('failed otmc check bypassed') if AppConst::BYPASS_QUALITY_TEST_LOAD_CHECK

        passed_pallets = repo.select_values(:pallet_sequences, :pallet_number, pallet_number: pallet_numbers, failed_otmc_results: nil).uniq
        errors = pallet_numbers - passed_pallets
        return failed_response "Pallet: #{errors.join(', ')} failed a OTMC test." unless errors.empty?

        all_ok
      end

      def not_on_inspection_sheet_check
        errors, sheet = @inspection_repo.exists_on_inspection_sheet(pallet_numbers).first
        return failed_response "Pallet: #{errors} is already on inspection sheet #{sheet}." unless errors.nil_or_empty?

        all_ok
      end

      def inspected_check
        errors = @repo.select_values(:pallets, :pallet_number, pallet_number: pallet_numbers, inspected: false).uniq
        return failed_response "Pallet: #{errors.join(', ')}, not previously inspected." unless errors.empty?

        all_ok
      end

      def not_inspected_check
        errors = @repo.select_values(:pallets, :pallet_number, pallet_number: pallet_numbers, inspected: true).uniq
        return failed_response "Pallet: #{errors.join(', ')}, has already been inspected." unless errors.empty?

        all_ok
      end

      def verification_passed_check
        errors = pallet_numbers - @repo.select_values(:pallet_sequences, :pallet_number, pallet_number: pallet_numbers, verification_passed: true).uniq
        return failed_response "Pallet: #{errors.join(', ')}, verification not passed." unless errors.empty?

        all_ok
      end

      def pallet_weight_check
        return all_ok unless AppConst::PALLET_WEIGHT_REQUIRED_FOR_INSPECTION

        errors = @repo.select_values(:pallets, :pallet_number, pallet_number: pallet_numbers, gross_weight: nil).uniq
        return failed_response "Pallet: #{errors.join(', ')}, gross weight not filled." unless errors.empty?

        all_ok
      end

      def allocate_check
        res = not_on_load_check
        return res unless res.success

        res = not_shipped_check
        return res unless res.success

        res = in_stock_check
        return res unless res.success

        res = not_failed_otmc_check
        return res unless res.success

        all_ok
      end
    end
  end
end
