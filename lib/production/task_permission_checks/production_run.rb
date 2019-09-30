# frozen_string_literal: true

module ProductionApp
  module TaskPermissionCheck
    class ProductionRun < BaseService
      attr_reader :task, :entity
      def initialize(task, production_run_id = nil)
        @task = task
        @repo = ProductionRunRepo.new
        @id = production_run_id
        @entity = @id ? @repo.find_production_run(@id) : nil
      end

      CHECKS = {
        create: :create_check,
        edit: :edit_check,
        delete: :delete_check,
        allocate_setups: :allocate_setups_check
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
        all_ok
      end

      def delete_check
        all_ok
      end

      def allocate_setups_check
        return failed_response 'No product setup template has been set' if @entity.product_setup_template_id.nil?

        all_ok
      end
    end
  end
end
