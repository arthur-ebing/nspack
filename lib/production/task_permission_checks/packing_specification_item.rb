# frozen_string_literal: true

module ProductionApp
  module TaskPermissionCheck
    class PackingSpecificationItem < BaseService
      attr_reader :task, :entity, :id, :repo
      def initialize(task, packing_specification_item_id = nil)
        @task = task
        @repo = PackingSpecificationRepo.new
        @id = packing_specification_item_id
        @entity = @id ? @repo.find_packing_specification_item(@id) : nil
      end

      CHECKS = {
        create: :create_check,
        edit: :edit_check,
        delete: :delete_check,
        activate: :activate_check,
        deactivate: :deactivate_check
      }.freeze

      def call
        return failed_response 'Packing Specification Item record not found' unless @entity || task == :create

        check = CHECKS[task]
        raise ArgumentError, "Task \"#{task}\" is unknown for #{self.class}" if check.nil?

        send(check)
      end

      private

      def create_check
        return failed_response 'Unable to create packing specification, this item already exists' if duplicates

        all_ok
      end

      def edit_check
        return failed_response 'Unable to edit, another similar packing specification item already exists' if duplicates

        all_ok
      end

      def activate_check
        return failed_response 'Packing Specification is already Active' if active?

        all_ok
      end

      def deactivate_check
        return failed_response 'Packing Specification has already been de-activated' unless active?

        all_ok
      end

      def delete_check
        all_ok
      end

      def duplicates
        hash = repo.find_hash(:packing_specification_items, id).to_h.reject { |k, _| %i[id created_at updated_at legacy_data].include?(k) }
        args = hash.transform_values { |v| v.is_a?(Array) ? Sequel.pg_array(v, :integer) : v }
        ids = DB[:packing_specification_items].where(args).select_map(:id)
        ids.length > 1
      end

      def active?
        @entity.active
      end
    end
  end
end
