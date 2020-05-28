# frozen_string_literal: true

module MasterfilesApp
  module TaskPermissionCheck
    class PersonnelIdentifier < BaseService
      attr_reader :task, :entity
      def initialize(task, personnel_identifier_id = nil)
        @task = task
        @repo = HumanResourcesRepo.new
        @id = personnel_identifier_id
        @entity = @id ? @repo.find_personnel_identifier(@id) : nil
      end

      CHECKS = {
        create: :create_check,
        edit: :edit_check,
        delete: :delete_check,
        link: :link_check,
        de_link: :de_link_check
      }.freeze

      def call
        return failed_response 'Personnel Identifier record not found' unless @entity || task == :create

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

      def link_check
        cw_id = @repo.find_contract_worker_id_by_identifier_id(@id)
        return failed_response('There is already a contract worker linked to this identifier') unless cw_id.nil?

        all_ok
      end

      def de_link_check
        cw_id = @repo.find_contract_worker_id_by_identifier_id(@id)
        return failed_response('There is no contract worker linked to this identifier') if cw_id.nil?

        all_ok
      end
    end
  end
end
