# frozen_string_literal: true

module RawMaterialsApp
  module TaskPermissionCheck
    class BinLoadProduct < BaseService
      attr_reader :task, :entity
      def initialize(task, bin_load_product_id = nil)
        @task = task
        @repo = BinLoadRepo.new
        @id = bin_load_product_id
        @entity = @id ? @repo.find_bin_load_product_flat(@id) : nil
      end

      CHECKS = {
        create: :create_check,
        edit: :edit_check,
        delete: :delete_check
      }.freeze

      def call
        return failed_response 'Bin Load Product record not found' unless entity || task == :create

        check = CHECKS[task]
        raise ArgumentError, "Task \"#{task}\" is unknown for #{self.class}" if check.nil?

        send(check)
      end

      private

      def create_check
        all_ok
      end

      def edit_check
        return failed_response 'Bin Load has been shipped' if shipped?

        all_ok
      end

      def delete_check
        return failed_response 'Bin Load has been shipped' if shipped?

        all_ok
      end

      def shipped?
        entity.shipped
      end
    end
  end
end
