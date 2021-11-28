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
        return failed_response 'No password set for provisioning' unless AppConst::PROVISION_PW

        if configurable_device?
          all_ok
        else
          failed_response "This system resource is of the wrong distro type to be provisioned. (#{distro})"
        end
      end

      def deploy_config_check
        return failed_response 'No password set for provisioning' unless AppConst::PROVISION_PW

        if configurable_device?
          all_ok
        else
          failed_response "This system resource is of the wrong distro type to be configured. (#{distro})"
        end
      end

      def distro
        (entity.extended_config || {})['distro_type']
      end

      def configurable_device?
        Crossbeams::Config::ResourceDefinitions.can_be_provisioned?(distro)
      end
    end
  end
end
