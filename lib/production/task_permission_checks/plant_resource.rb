# frozen_string_literal: true

module ProductionApp
  module TaskPermissionCheck
    class PlantResource < BaseService
      attr_reader :task, :entity
      def initialize(task, plant_resource_id = nil)
        @task = task
        @repo = ResourceRepo.new
        @id = plant_resource_id
        @entity = @id ? @repo.find_plant_resource(@id) : nil
      end

      CHECKS = {
        create: :create_check,
        edit: :edit_check,
        delete: :delete_check,
        add_child: :add_child_check,
        bulk_add_clm: :bulk_add_clm_check,
        bulk_add_ptm: :bulk_add_ptm_check
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

      def add_child_check
        if Crossbeams::Config::ResourceDefinitions.can_have_children?(@repo.plant_resource_type_code_for(@id))
          all_ok
        else
          failed_response 'This plant resource cannot have sub-resources'
        end
      end

      def bulk_add_clm_check
        if Crossbeams::Config::ResourceDefinitions.can_have_children_of_type?(@repo.plant_resource_type_code_for(@id), Crossbeams::Config::ResourceDefinitions::CLM_ROBOT)
          all_ok
        else
          failed_response 'This plant resource cannot have CLM sub-resources'
        end
      end

      def bulk_add_ptm_check
        if Crossbeams::Config::ResourceDefinitions.can_have_children_of_type?(@repo.plant_resource_type_code_for(@id), Crossbeams::Config::ResourceDefinitions::PALLETIZING_ROBOT)
          all_ok
        else
          failed_response 'This plant resource cannot have PTM sub-resources'
        end
      end
    end
  end
end
