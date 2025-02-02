# frozen_string_literal: true

module MasterfilesApp
  module TaskPermissionCheck
    class RmtClassificationType < BaseService
      attr_reader :task, :entity
      def initialize(task, rmt_classification_type_id = nil)
        @task = task
        @repo = MasterfilesApp::AdvancedClassificationsRepo.new
        @id = rmt_classification_type_id
        @entity = @id ? @repo.find(:rmt_classification_types, MasterfilesApp::RmtClassificationType, @id) : nil
      end

      CHECKS = {
        create: :create_check,
        edit: :edit_check,
        delete: :delete_check
      }.freeze

      def call
        return failed_response 'Rmt Classification Type record not found' unless @entity || task == :create

        check = CHECKS[task]
        raise ArgumentError, "Task \"#{task}\" is unknown for #{self.class}" if check.nil?

        send(check)
      end

      private

      def create_check
        all_ok
      end

      def edit_check
        # return failed_response 'RmtClassificationType has been completed' if completed?

        all_ok
      end

      def delete_check
        return failed_response "Rmt Classification Type: #{entity.rmt_classification_type_code} could not be deleted. It has children" if @repo.exists?(:rmt_classifications, rmt_classification_type_id: @id)

        all_ok
      end
    end
  end
end
