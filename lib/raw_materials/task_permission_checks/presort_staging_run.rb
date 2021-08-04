# frozen_string_literal: true

module RawMaterialsApp
  module TaskPermissionCheck
    class PresortStagingRun < BaseService
      attr_reader :task, :entity
      def initialize(task, presort_staging_run_id = nil)
        @task = task
        @repo = PresortStagingRunRepo.new
        @id = presort_staging_run_id
        @entity = @id ? @repo.find_presort_staging_run(@id) : nil
      end

      CHECKS = {
        create: :create_check,
        edit: :edit_check,
        delete: :delete_check,
        complete_setup: :complete_setup_check,
        complete_staging: :complete_staging_check,
        activate_run: :activate_run_check
        # reopen: :reopen_check
      }.freeze

      def call
        return failed_response 'Presort Staging Run record not found' unless @entity || task == :create

        check = CHECKS[task]
        raise ArgumentError, "Task \"#{task}\" is unknown for #{self.class}" if check.nil?

        send(check)
      end

      private

      def create_check
        all_ok
      end

      def edit_check
        # return failed_response 'PresortStagingRun has been completed' if completed?

        all_ok
      end

      def delete_check
        return failed_response('Cannot delete. Run has children') unless @repo.select_values(:presort_staging_run_children, :id, presort_staging_run_id: @id).count.zero?

        all_ok
      end

      def complete_setup_check
        return failed_response('Cannot complete setup. Run must have children') unless @repo.select_values(:presort_staging_run_children, :id, presort_staging_run_id: @id).count.positive?

        all_ok
      end

      def complete_staging_check
        return failed_response('Cannot complete staging. Run has editing children') if @repo.exists?(:presort_staging_run_children, presort_staging_run_id: @id, editing: true)

        all_ok
      end

      def activate_run_check
        resource_id = @repo.get(:presort_staging_runs, @id, :presort_unit_plant_resource_id)
        return failed_response("Cannot activate presort_run: #{@id}. There already exists an active run for this plant unit") if @repo.exists?(:presort_staging_runs, presort_unit_plant_resource_id: resource_id, running: true)

        all_ok
      end

      # def reopen_check
      #   return failed_response 'PresortStagingRun has not been approved' unless approved?

      #   all_ok
      # end

      # def completed?
      #   @entity.completed
      # end

      # def approved?
      #   @entity.approved
      # end
    end
  end
end
