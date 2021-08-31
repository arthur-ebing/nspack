# frozen_string_literal: true

module RawMaterialsApp
  module TaskPermissionCheck
    class PresortStagingRunChild < BaseService
      attr_reader :task, :entity
      def initialize(task, presort_staging_run_child_id = nil)
        @task = task
        @repo = PresortStagingRunRepo.new
        @id = presort_staging_run_child_id
        @entity = @id ? @repo.find_presort_staging_run_child(@id) : nil
      end

      CHECKS = {
        create: :create_check,
        activate_child: :activate_child_check,
        delete: :delete_check
      }.freeze

      def call
        return failed_response 'Presort Staging Run Child record not found' unless @entity || task == :create

        check = CHECKS[task]
        raise ArgumentError, "Task \"#{task}\" is unknown for #{self.class}" if check.nil?

        send(check)
      end

      private

      def create_check
        all_ok
      end

      def activate_child_check
        parent_id, plant_resource_id = @repo.child_run_parent_id_and_plant_resource_id(@id)
        return failed_response("Cannot activate run: #{@id}. There's already an active child on this run", parent_id) if @repo.exists?(:presort_staging_run_children, presort_staging_run_id: parent_id, running: true)
        return failed_response("Cannot activate run: #{@id}. There already an active child run for this plant unit", parent_id) if @repo.running_child_run_for_plant_resource_id?(plant_resource_id)

        success_response('ok', parent_id)
      end

      def delete_check
        all_ok
      end
    end
  end
end
