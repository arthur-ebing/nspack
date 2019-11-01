# frozen_string_literal: true

module FinishedGoodsApp
  module TaskPermissionCheck
    class LoadVehicle < BaseService
      attr_reader :task, :entity
      def initialize(task, load_vehicle_id = nil)
        @task = task
        @repo = LoadVehicleRepo.new
        @id = load_vehicle_id
        @entity = @id ? @repo.find_load_vehicle(@id) : nil
      end

      CHECKS = {
        create: :create_check,
        edit: :edit_check,
        delete: :delete_check
        # complete: :complete_check,
        # approve: :approve_check,
        # reopen: :reopen_check
      }.freeze

      def call
        return failed_response 'Load Vehicle record not found' unless @entity || task == :create

        check = CHECKS[task]
        raise ArgumentError, "Task \"#{task}\" is unknown for #{self.class}" if check.nil?

        send(check)
      end

      private

      def create_check
        all_ok
      end

      def edit_check
        # return failed_response 'LoadVehicle has been completed' if completed?

        all_ok
      end

      def delete_check
        # return failed_response 'LoadVehicle has been completed' if completed?

        all_ok
      end

      # def complete_check
      #   return failed_response 'LoadVehicle has already been completed' if completed?

      #   all_ok
      # end

      # def approve_check
      #   return failed_response 'LoadVehicle has not been completed' unless completed?
      #   return failed_response 'LoadVehicle has already been approved' if approved?

      #   all_ok
      # end

      # def reopen_check
      #   return failed_response 'LoadVehicle has not been approved' unless approved?

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
