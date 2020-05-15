# frozen_string_literal: true

module RawMaterialsApp
  module TaskPermissionCheck
    class BinLoadProduct < BaseService
      attr_reader :task, :repo, :bin_load_product, :bin_load, :rmt_bin
      def initialize(task, id = nil, bin_asset_number = nil)
        @repo = BinLoadRepo.new
        unless id.nil?
          @bin_load_product = repo.find_bin_load_product_flat(id)
          @bin_load = repo.find_bin_load_flat(@bin_load_product&.bin_load_id)
        end
        unless bin_asset_number.nil?
          bin_id = repo.get_id(:rmt_bins, bin_asset_number: bin_asset_number)
          @rmt_bin = RawMaterialsApp::RmtDeliveryRepo.new.find_rmt_bin_flat(bin_id)
        end
        @task = task
      end

      CHECKS = {
        create: :create_check,
        edit: :edit_check,
        delete: :delete_check
      }.freeze

      def call
        return failed_response 'Bin Load Product record not found' unless bin_load_product || task == :create

        check = CHECKS[task]
        raise ArgumentError, "Task \"#{task}\" is unknown for #{self.class}" if check.nil?

        send(check)
      end

      private

      def create_check
        all_ok
      end

      def edit_check
        return failed_response 'Bin Load has been completed' if bin_load_completed?

        all_ok
      end

      def delete_check
        return failed_response 'Bin Load has been completed' if bin_load_completed?

        all_ok
      end

      def bin_load_completed?
        @bin_load&.completed
      end
    end
  end
end
