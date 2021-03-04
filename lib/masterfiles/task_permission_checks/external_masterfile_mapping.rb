# frozen_string_literal: true

module MasterfilesApp
  module TaskPermissionCheck
    class ExternalMasterfileMapping < BaseService
      attr_reader :task, :entity
      def initialize(task, external_masterfile_mapping_id = nil)
        @task = task
        @repo = GeneralRepo.new
        @id = external_masterfile_mapping_id
        @entity = @id ? @repo.find_external_masterfile_mapping(@id) : nil
      end

      CHECKS = {
        create: :create_check,
        edit: :edit_check,
        delete: :delete_check
      }.freeze

      def call
        return failed_response 'External Masterfile Mapping record not found' unless @entity || task == :create

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
