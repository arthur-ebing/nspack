# frozen_string_literal: true

module RawMaterialsApp
  module TaskPermissionCheck
    class RmtBin < BaseService
      attr_reader :task, :entity
      def initialize(task, rmt_bin_id = nil)
        @task = task
        @repo = RmtDeliveryRepo.new
        @id = rmt_bin_id
        @entity = @id ? @repo.find_rmt_bin_flat(@id) : nil
      end

      CHECKS = {
        create: :create_check,
        edit: :edit_check,
        delete: :delete_check,
        receive: :receive_check
      }.freeze

      def call
        return failed_response 'Record not found' unless @entity || task == :create

        check = CHECKS[task]
        raise ArgumentError, "Task \"#{task}\" is unknown for #{self.class}" if check.nil?

        send(check)
      end

      private

      def create_check
        all_ok
      end

      def edit_check
        # return failed_response 'RmtBin has been completed' if completed?

        all_ok
      end

      def delete_check
        # return failed_response 'RmtBin has been completed' if completed?

        all_ok
      end

      def receive_check
        return failed_response "Bin: #{entity.bin_asset_number} already received." if entity.received

        all_ok
      end
    end
  end
end
