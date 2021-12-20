# frozen_string_literal: true

module ProductionApp
  module TaskPermissionCheck
    class GrowerGradingRuleItem < BaseService
      attr_reader :task, :entity
      def initialize(task, grower_grading_rule_item_id = nil)
        @task = task
        @repo = GrowerGradingRepo.new
        @id = grower_grading_rule_item_id
        @entity = @id ? @repo.find_grower_grading_rule_item(@id) : nil
      end

      CHECKS = {
        create: :create_check,
        edit: :edit_check,
        delete: :delete_check,
        activate: :activate_check,
        deactivate: :deactivate_check,
        apply_rule_item: :apply_rule_item_check
      }.freeze

      def call
        return failed_response 'Grower Grading Rule Item record not found' unless @entity || task == :create

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

      def activate_check
        return failed_response 'Rule Item is already Active' if active?

        all_ok
      end

      def deactivate_check
        return failed_response 'Rule Item has already been de-activated' unless active?

        all_ok
      end

      def apply_rule_item_check
        changes = @repo.select_values(:grower_grading_rule_items, :changes, id: @id)
        return failed_response 'Rule item changes not yet set.' if changes.nil_or_empty?

        all_ok
      end

      def active?
        @entity.active
      end
    end
  end
end
