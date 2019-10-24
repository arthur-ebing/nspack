# frozen_string_literal: true

module FinishedGoodsApp
  module TaskPermissionCheck
    class Load < BaseService
      attr_reader :task, :entity
      def initialize(task, load_id = nil)
        @task = task
        @repo = LoadRepo.new
        @id = load_id
        @entity = @id ? @repo.find_load(@id) : nil
      end

      CHECKS = {
        create: :create_check,
        edit: :edit_check,
        delete: :delete_check
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
        all_ok
      end

      def delete_check
        all_ok
      end
    end
  end
end
