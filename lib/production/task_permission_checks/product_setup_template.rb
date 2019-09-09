# frozen_string_literal: true

module ProductionApp
  module TaskPermissionCheck
    class ProductSetupTemplate < BaseService
      attr_reader :task, :entity
      def initialize(task, product_setup_template_id = nil)
        @task = task
        @repo = ProductSetupRepo.new
        @id = product_setup_template_id
        @entity = @id ? @repo.find_product_setup_template(@id) : nil
      end

      CHECKS = {
        create: :create_check,
        edit: :edit_check,
        delete: :delete_check,
        activate: :activate_check,
        deactivate: :deactivate_check
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
        # return failed_response 'ProductSetupTemplate has been completed' if completed?

        all_ok
      end

      def delete_check
        # return failed_response 'ProductSetupTemplate has been completed' if completed?

        all_ok
      end

      def activate_check
        return failed_response 'Product Setup Template is already Active' if active?

        all_ok
      end

      def deactivate_check
        return failed_response 'Product Setup Template has already been de-activated' unless active?

        all_ok
      end

      def active?
        @entity.active
      end
    end
  end
end
