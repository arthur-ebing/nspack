# frozen_string_literal: true

module ProductionApp
  module TaskPermissionCheck
    class PackingSpecificationItem < BaseService
      attr_reader :task, :entity
      def initialize(task, packing_specification_item_id = nil)
        @task = task
        @repo = PackingSpecificationRepo.new
        @id = packing_specification_item_id
        @entity = @id ? @repo.find_packing_specification_item(@id) : nil
      end

      CHECKS = {
        create: :create_check,
        edit: :edit_check,
        delete: :delete_check
      }.freeze

      def call
        return failed_response 'Packing Specification Item record not found' unless @entity || task == :create

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
