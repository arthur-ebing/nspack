# frozen_string_literal: true

module ProductionApp
  module TaskPermissionCheck
    class SystemResource < BaseService
      attr_reader :task, :entity

      def initialize(task, system_resource_id = nil)
        @task = task
        @repo = ResourceRepo.new
        @id = system_resource_id
        @entity = @id ? @repo.find_system_resource(@id) : nil
      end

      CHECKS = {
        provision: :provision_check,
        deploy_config: :deploy_config_check
      }.freeze

      def call
        return failed_response 'Record not found' unless @entity || task == :create

        check = CHECKS[task]
        raise ArgumentError, "Task \"#{task}\" is unknown for #{self.class}" if check.nil?

        send(check)
      end

      private

      def provision_check
        if configurable_device?
          all_ok
        else
          failed_response 'This system resource is of the wrong type to be provisioned.'
        end
      end

      def deploy_config_check
        if configurable_device?
          all_ok
        else
          failed_response 'This system resource is of the wrong type to be configured.'
        end
      end

      def configurable_device?
        [Crossbeams::Config::ResourceDefinitions::MODULE_EQUIPMENT_TYPE_NSPI,
         Crossbeams::Config::ResourceDefinitions::MODULE_EQUIPMENT_TYPE_NSRE,
         Crossbeams::Config::ResourceDefinitions::MODULE_EQUIPMENT_TYPE_NSPI_V,
         Crossbeams::Config::ResourceDefinitions::MODULE_EQUIPMENT_TYPE_RPI].include?(entity.equipment_type)
      end
    end
  end
end
