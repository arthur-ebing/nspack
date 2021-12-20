# frozen_string_literal: true

module MasterfilesApp
  module TaskPermissionCheck
    class RmtClassification < BaseService
      attr_reader :task, :entity
      def initialize(task, rmt_classification_id = nil)
        @task = task
        @repo = MasterfilesApp::AdvancedClassificationsRepo.new
        @id = rmt_classification_id
        @entity = @id ? @repo.find(:rmt_classifications, MasterfilesApp::RmtClassification, @id) : nil
      end

      CHECKS = {
        create: :create_check,
        edit: :edit_check,
        delete: :delete_check
      }.freeze

      def call
        return failed_response 'Rmt Classification record not found' unless @entity || task == :create

        check = CHECKS[task]
        raise ArgumentError, "Task \"#{task}\" is unknown for #{self.class}" if check.nil?

        send(check)
      end

      private

      def create_check
        all_ok
      end

      def edit_check
        # return failed_response 'RmtClassification has been completed' if completed?

        all_ok
      end

      def delete_check
        return failed_response "Rmt Classification: #{entity[:rmt_classification]} could not be deleted. It is still referenced by rmt_bins records" if @repo.classification_belongs_to_bin?(@id)

        all_ok
      end
    end
  end
end
