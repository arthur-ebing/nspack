# frozen_string_literal: true

module MasterfilesApp
  module TaskPermissionCheck
    class BasicPackCode < BaseService
      attr_reader :task, :entity
      def initialize(task, basic_pack_code_id = nil)
        @task = task
        @repo = FruitSizeRepo.new
        @id = basic_pack_code_id
        @entity = @id ? @repo.find_basic_pack_code(@id) : nil
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
        return failed_response 'Basic pack codes must be created via Standard pack codes' if AppConst::BASE_PACK_EQUALS_STD_PACK

        all_ok
      end

      def edit_check
        # return failed_response 'BasicPackCode has been completed' if completed?

        all_ok
      end

      def delete_check
        # return failed_response 'BasicPackCode has been completed' if completed?

        all_ok
      end
    end
  end
end
