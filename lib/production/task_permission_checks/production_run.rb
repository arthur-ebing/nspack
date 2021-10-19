# frozen_string_literal: true

module ProductionApp
  module TaskPermissionCheck
    class ProductionRun < BaseService # rubocop:disable Metrics/ClassLength
      attr_reader :task, :entity, :repo

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
        re_configure: :re_configure_check,
        complete_setup: :complete_setup_check,
        allocate_setups: :allocate_setups_check,
        complete_run_stage: :complete_run_stage_check,
        execute_run: :execute_check,
        re_execute_run: :re_execute_check,
        close: :close_check
      }.freeze

      def call
        return failed_response 'Record not found' unless @entity || %i[create create_new_pallet add_sequence_to_pallet edit_pallet].include?(task)

        check = CHECKS[task]
        raise ArgumentError, "Task \"#{task}\" is unknown for #{self.class}" if check.nil?

        send(check)
      end

      private

      def create_check
        all_ok
      end

      def edit_check
        return failed_response 'Run has been closed' if entity.closed
        return failed_response 'Run is active' if entity.running && !entity.reconfiguring
        return failed_response 'Setup is complete' if entity.setup_complete

        all_ok
      end

      def delete_check
        return failed_response 'Run has been closed' if entity.closed
        # No if any pseq or ctn exists referencing the run...
        return failed_response 'Run is active' if entity.running && !entity.reconfiguring

        all_ok
      end

      def complete_setup_check
        return failed_response 'No product setup template has been set' if entity.product_setup_template_id.nil?

        if entity.allocation_required
          return failed_response 'No product setup has been allocated yet' unless any_allocated_setup?
        end

        all_ok
      end

      def allocate_setups_check
        return failed_response 'No product setup template has been set' if entity.product_setup_template_id.nil?

        all_ok
      end

      def execute_check
        return failed_response 'Setup is not yet complete' unless entity.setup_complete # || entity.reconfiguring
        return failed_response 'There is a tipping run already active on this line' if line_has_active_tipping_run?
        return failed_response 'Bintip control data must be set before executing the run' if entity.legacy_data.nil? && AppConst::CLIENT_CODE == 'kr'

        res = check_orchard_tests_for_run
        return res unless res.success

        all_ok
      end

      def re_execute_check
        return failed_response 'Run is not in a re-configure state' unless entity.reconfiguring

        res = check_orchard_tests_for_run
        return res unless res.success

        all_ok
      end

      def close_check
        return failed_response 'Run is not yet complete' unless entity.completed
        return failed_response 'Run has been closed' if entity.closed

        all_ok
      end

      def re_configure_check
        return failed_response 'This is not an active run' unless entity.running
        return failed_response 'Run is already re-configuring' if entity.reconfiguring

        all_ok
      end

      def complete_run_stage_check
        return failed_response 'This is not an active run' unless entity.running
        return failed_response 'Run is already re-configuring' if entity.reconfiguring

        if entity.tipping
          complete_tipping_stage_check
        else
          return failed_response 'This run is not in a valid state (RUNNING, but not TIPPING or LABELING)' unless entity.labeling

          all_ok
        end
      end

      def complete_tipping_stage_check
        running_id = repo.labeling_run_for_line(entity.production_line_id)
        return failed_response 'There is another run currently LABELING on this line' unless running_id.nil? || running_id == entity.id

        all_ok
      end

      def any_allocated_setup?
        repo.any_allocated_setup?(entity.id)
      end

      def line_has_active_tipping_run?
        repo.line_has_active_tipping_run?(entity.production_line_id)
      end

      def check_orchard_tests_for_run
        # If no orchard/cultivar chosen (i.e. mixed run) we do not check orchard tests
        return ok_response if @entity.orchard_id.nil? || @entity.cultivar_id.nil?

        tm_ids = @repo.target_market_ids_for_run(@id)
        QualityApp::CanPackOrchardForTms.call(orchard_id: @entity.orchard_id, cultivar_id: @entity.cultivar_id, tm_group_ids: tm_ids)
      end
    end
  end
end
