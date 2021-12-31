# frozen_string_literal: true

module FinishedGoodsApp
  module TaskPermissionCheck
    class GovtInspectionValidation < BaseService
      attr_reader :task, :repo, :pallet_number
      attr_accessor :params

      def initialize(task, params = {})
        @task = task
        @repo = GovtInspectionRepo.new
        @params = params
        @pallet_number = params[:pallet_number]
      end

      CHECKS = {
        pallet_exists: :pallet_exists_check,
        pallet_not_on_inspection: :pallet_not_on_inspection_check,
        pallet_not_shipped: :pallet_not_shipped_check,
        pallets_inspected: :pallets_inspected_check
      }.freeze

      def call
        check = CHECKS[task]
        raise ArgumentError, "Task \"#{task}\" is unknown for #{self.class}" if check.nil?

        send(check)
      end

      private

      def pallet_exists_check # rubocop:disable Metrics/AbcSize
        raise ArgumentError, 'Pallet number is nil.' if pallet_number.nil_or_empty?

        params[:pallet_id] = repo.get_id(:pallets, pallet_number: pallet_number)
        return failed_response "Pallet: #{pallet_number} doesn't exist." if params[:pallet_id].nil?

        params[:pallet_id] = repo.get_id(:pallets, pallet_number: pallet_number, scrapped: false)
        return failed_response "Pallet: #{pallet_number} scrapped." if params[:pallet_id].nil?

        success_response('ok', params[:pallet_id])
      end

      def pallet_not_on_inspection_check
        params[:govt_inspection_pallet_id] = repo.get_id(:govt_inspection_pallets, pallet_id: params[:pallet_id])
        return failed_response "Pallet: #{pallet_number} already on inspection." unless params[:govt_inspection_pallet_id].nil?

        ok_response
      end

      def pallet_not_shipped_check
        shipped = repo.get(:pallets, :shipped, params[:pallet_id])
        return failed_response "Pallet: #{pallet_number} already shipped." if shipped

        ok_response
      end

      def pallets_inspected_check
        pallet_ids = repo.select_values(:govt_inspection_pallets, :pallet_id, govt_inspection_sheet_id: params[:govt_inspection_sheet_id], inspected: false)
        pallet_numbers = repo.select_values(:pallets, :pallet_number, id: pallet_ids).join(', ')
        return failed_response("Pallet: #{pallet_numbers}, results not captured.") unless pallet_numbers.empty?

        ok_response
      end
    end
  end
end
