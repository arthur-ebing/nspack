# frozen_string_literal: true

module FinishedGoodsApp
  module TaskPermissionCheck
    class GovtInspectionSheet < BaseService
      attr_reader :task, :entity, :repo, :id
      def initialize(task, govt_inspection_sheet_id = nil)
        @task = task
        @repo = GovtInspectionRepo.new
        @id = govt_inspection_sheet_id
        @entity = @id ? @repo.find_govt_inspection_sheet(@id) : nil
      end

      CHECKS = {
        create: :create_check,
        edit: :edit_check,
        delete: :delete_check,
        capture: :capture_check,
        complete: :complete_check,
        finish: :finish_check,
        cancel: :cancel_check,
        reopen: :reopen_check
      }.freeze

      def call
        return failed_response 'Govt Inspection Sheet record not found' unless @entity || task == :create

        check = CHECKS[task]
        raise ArgumentError, "Task \"#{task}\" is unknown for #{self.class}" if check.nil?

        send(check)
      end

      private

      def create_check
        all_ok
      end

      def edit_check
        return failed_response 'Govt Inspection Sheet has been completed' if inspected?

        all_ok
      end

      def delete_check
        return failed_response 'Govt Inspection Sheet has been completed' if completed?

        all_ok
      end

      def complete_check
        return failed_response 'Govt Inspection Sheet has already been completed' if completed?
        return failed_response('Inspection sheet must have at least one pallet attached.') unless allocated?

        all_ok
      end

      def reopen_check
        return failed_response 'Govt Inspection Sheet is not completed' unless completed?

        all_ok
      end

      def capture_check
        return failed_response 'Govt Inspection Sheet has already been inspected' if inspected?

        all_ok
      end

      def finish_check
        pallet_ids = @repo.select_values(:govt_inspection_pallets, :pallet_id, govt_inspection_sheet_id: id, inspected: false)
        pallet_numbers = @repo.select_values(:pallets, :pallet_number, id: pallet_ids)
        return failed_response("Pallet: #{pallet_numbers.first(3).join(', ')}, results not captured.") unless pallet_numbers.empty?

        all_ok
      end

      def cancel_check
        return failed_response 'Govt Inspection Sheet has not been inspected' unless inspected?

        all_ok
      end

      def completed?
        @entity&.completed
      end

      def allocated?
        @entity&.allocated
      end

      def inspected?
        @entity&.inspected
      end

      def approved?
        @entity&.approved
      end
    end
  end
end
