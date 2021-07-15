# frozen_string_literal: true

module MesscadaApp
  module TaskPermissionCheck
    class PalletSequence < BaseService
      attr_reader :tasks, :repo, :pallet_sequence_ids
      def initialize(tasks, args)
        @tasks = Array(tasks)
        @args = args
        @repo = MesscadaRepo.new
        @check_pallet_sequence_ids = Array(@args[:pallet_sequence_id] || @args[:pallet_sequence_ids]).flatten
      end

      CHECKS = {
        exists: :exists_check
      }.freeze

      def call
        res = exists_check
        return res unless res.success

        tasks.each do |task|
          check = CHECKS[task]
          raise ArgumentError, "Task \"#{task}\" is unknown for #{self.class}." if check.nil?

          res = send(check)
          return res unless res.success
        end
        all_ok
      end

      private

      def exists_check
        unless @check_pallet_sequence_ids.empty?
          @pallet_sequence_ids = repo.select_values(:pallet_sequences, :id, id: @check_pallet_sequence_ids)
          errors = @check_pallet_sequence_ids - pallet_sequence_ids
          return failed_response "Pallet sequence id: #{errors.join(', ')} doesn't exist." unless errors.empty?
        end

        return failed_response 'No pallet sequences where given to check.' if pallet_sequence_ids.nil_or_empty?

        all_ok
      end
    end
  end
end
