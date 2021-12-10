# frozen_string_literal: true

module MasterfilesApp
  module TaskPermissionCheck
    class RmtVariant < BaseService
      attr_reader :task, :entity
      def initialize(task, rmt_variant_id = nil)
        @task = task
        @repo = MasterfilesApp::AdvancedClassificationsRepo.new
        @id = rmt_variant_id
        @entity = @id ? @repo.find(:rmt_variants, MasterfilesApp::RmtVariant, @id) : nil
      end

      CHECKS = {
        create: :create_check,
        edit: :edit_check,
        delete: :delete_check
      }.freeze

      def call
        return failed_response 'Rmt Variant record not found' unless @entity || task == :create

        check = CHECKS[task]
        raise ArgumentError, "Task \"#{task}\" is unknown for #{self.class}" if check.nil?

        send(check)
      end

      private

      def create_check
        all_ok
      end

      def edit_check
        # return failed_response 'RmtVariant has been completed' if completed?

        all_ok
      end

      def delete_check
        return failed_response "Rmt variant: #{entity.rmt_variant_code} could not be deleted. It has children" if @repo.exists?(:rmt_codes, rmt_variant_id: @id)

        all_ok
      end
    end
  end
end
