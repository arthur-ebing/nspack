# frozen_string_literal: true

module RawMaterialsApp
  module TaskPermissionCheck
    class BinAssetTransaction < BaseService
      attr_reader :task, :entity
      def initialize(task, bin_asset_transaction_id = nil)
        @task = task
        @repo = BinAssetsRepo.new
        @id = bin_asset_transaction_id
        @entity = @id ? @repo.find_bin_asset_transaction(@id) : nil
      end

      CHECKS = {
        create: :create_check,
        edit: :edit_check,
        delete: :delete_check
      }.freeze

      def call
        return failed_response 'Bin Asset Transaction record not found' unless @entity || task == :create

        check = CHECKS[task]
        raise ArgumentError, "Task \"#{task}\" is unknown for #{self.class}" if check.nil?

        send(check)
      end

      private

      def create_check
        all_ok
      end

      def edit_check
        all_ok
      end

      def delete_check
        all_ok
      end
    end
  end
end
