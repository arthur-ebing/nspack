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
        all_ok
      end

      def delete_check
        all_ok
      end
    end
  end
end
