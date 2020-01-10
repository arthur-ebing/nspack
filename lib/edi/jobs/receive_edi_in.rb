# frozen_string_literal: true

module EdiApp
  module Job
    class ReceiveEdiIn < BaseQueJob
      attr_reader :repo, :file_path, :file_name, :flow_type

      # No point in retrying
      self.maximum_retry_count = 0

      def run(file_path) # rubocop:disable Metrics/AbcSize
        @file_path = File.expand_path(file_path)
        raise ArgumentError, "File \"#{@file_path}\" does not exist" unless File.exist?(@file_path)

        @file_name = File.basename(file_path)
        @repo = EdiInRepo.new
        id = repo.create_edi_in_transaction(file_name: file_name)
        work_out_flow_type
        repo.update_edi_in_transaction(id, flow_type: flow_type)

        klass = "#{flow_type.capitalize}In"

        begin
          repo.transaction do
            res = EdiApp.const_get(klass).send(:call, id, @file_path)
            if res.success
              repo.log_edi_in_complete(id, res.message)
              move_to_success_dir
            else
              repo.log_edi_in_failed(id, res.message)
              move_to_failed_dir
            end
            finish
          end
        rescue StandardError => e
          repo.log_edi_in_error(id, e)
          move_to_failed_dir
          ErrorMailer.send_exception_email(e, subject: "EDI in transform failed (#{file_name})")
          expire
        end
      end

      private

      def move_to_success_dir
        move_to_dir('processed')
      end

      def move_to_failed_dir
        move_to_dir('process_errors')
      end

      def move_to_dir(name)
        dir = File.expand_path("../../#{name}", file_path)
        new_path = File.join(dir, file_name)

        FileUtils.mkdir_p(File.path(dir))
        FileUtils.mv(file_path, new_path)
      end

      def work_out_flow_type
        # Ensure longest flow types are matched first
        # (in case of something like flows: PO and POS)
        keys = config.keys.sort_by(&:length).reverse

        keys.each do |key|
          if file_name.upcase.start_with?(key.upcase)
            @flow_type = key.upcase
            break
          end
        end
        raise Crossbeams::InfoError, "There is no EDI in flow type to match file #{file_name}" unless @flow_type
      end

      def config
        yml_path = File.expand_path('../schemas/schema_record_sizes.yml', __dir__)
        raise 'There is no schema_record_sizes.yml file' unless File.exist?(yml_path)

        YAML.load_file(yml_path)
      end
    end
  end
end
