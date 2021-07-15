# frozen_string_literal: true

module MesscadaApp
  module TaskPermissionCheck
    class CartonLabel < BaseService
      attr_reader :tasks, :repo, :carton_label_ids
      def initialize(tasks, args)
        @tasks = Array(tasks)
        @args = args
        @repo = MesscadaRepo.new
        @check_carton_label_ids = Array(@args[:carton_label_id] || @args[:carton_label_ids]).flatten
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
        unless @check_carton_label_ids.empty?
          @carton_label_ids = repo.select_values(:carton_labels, :id, id: @check_carton_label_ids)
          errors = @check_carton_label_ids - carton_label_ids
          return failed_response "Carton label: #{errors.join(', ')} doesn't exist." unless errors.empty?
        end

        return failed_response 'No carton labels where given to check.' if carton_label_ids.nil_or_empty?

        all_ok
      end
    end
  end
end
