# frozen_string_literal: true

module MasterfilesApp
  module TaskPermissionCheck
    class RmtCode < BaseService
      attr_reader :task, :entity
      def initialize(task, rmt_code_id = nil)
        @task = task
        @repo = AdvancedClassificationsRepo.new
        @id = rmt_code_id
        @entity = @id ? @repo.find(:rmt_codes, MasterfilesApp::RmtCode, @id) : nil
      end

      CHECKS = {
        create: :create_check,
        edit: :edit_check,
        delete: :delete_check
      }.freeze

      def call
        return failed_response 'Rmt Code record not found' unless @entity || task == :create

        check = CHECKS[task]
        raise ArgumentError, "Task \"#{task}\" is unknown for #{self.class}" if check.nil?

        send(check)
      end

      private

      def create_check
        all_ok
      end

      def edit_check
        # return failed_response 'RmtCode has been completed' if completed?

        all_ok
      end

      def delete_check
        return failed_response("Rmt Code: #{entity.rmt_code} could not be deleted. It is referenced by rmt_bin records") if @repo.exists?(:rmt_bins, rmt_code_id: @id)

        all_ok
      end
    end
  end
end
