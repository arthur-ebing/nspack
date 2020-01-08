# frozen_string_literal: true

module FinishedGoodsApp
  module TaskPermissionCheck
    class Load < BaseService
      attr_reader :task, :entity, :user
      def initialize(task, load_id = nil, user = nil)
        @task = task
        @repo = LoadRepo.new
        @id = load_id
        @user = user
        @entity = @id ? @repo.find_load(@id) : nil
      end

      CHECKS = {
        create: :create_check,
        edit: :edit_check,
        unship: :unship_check,
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
        return all_ok if !@entity&.shipped || Crossbeams::Config::UserPermissions.can_user?(@user, :load, :can_unship)

        failed_response "Load#{@id} has already been shipped"
      end

      def unship_check
        all_ok
      end

      def delete_check
        all_ok
      end
    end
  end
end
