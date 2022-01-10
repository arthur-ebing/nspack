# frozen_string_literal: true

module RawMaterialsApp
  module TaskPermissionCheck
    class RmtDelivery < BaseService
      attr_reader :task, :entity
      def initialize(task, rmt_delivery_id = nil)
        @task = task
        @repo = RmtDeliveryRepo.new
        @id = rmt_delivery_id
        @entity = @id ? @repo.find_rmt_delivery(@id) : nil
      end

      CHECKS = {
        create: :create_check,
        edit: :edit_check,
        delete: :delete_check,
        exists: :delivery_exists_check,
        delivery_tipped: :delivery_tipped_check
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
        return failed_response 'Bins on this delivery have been tipped' if bins_tipped?

        all_ok
      end

      def delete_check
        all_ok
      end

      def delivery_exists_check
        return failed_response("RMT Delivery : #{@id} does not exist") unless delivery_exists?

        all_ok
      end

      def delivery_tipped_check
        # return failed_response("RMT Delivery : #{@id} already tipped") if delivery_tipped?
        # return failed_response("RMT Delivery : #{@id} tipped date out of range") unless delivery_tipped_date_in_range?

        all_ok
      end

      def bins_tipped?
        @repo.exists?(:rmt_bins, rmt_delivery_id: @id, bin_tipped: true)
      end

      def delivery_exists?
        @repo.exists?(:rmt_deliveries, id: @id)
      end

      def delivery_tipped?
        @repo.get(:rmt_deliveries, :delivery_tipped, @id)
      end

      def delivery_tipped_date_in_range?
        @repo.exists?(:rmt_deliveries, Sequel.lit(" id = #{@id} AND tipping_complete_date_time > '2022-01-01 00:00'"))
      end
    end
  end
end
