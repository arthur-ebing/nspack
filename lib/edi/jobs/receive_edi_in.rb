# frozen_string_literal: true

module EdiApp
  module Job
    class ReceiveEdiIn < BaseQueJob
      attr_reader :repo, :file_path, :file_name, :flow_type, :email_notifiers

      # No point in retrying
      self.maximum_retry_count = 0

      def run(file_path) # rubocop:disable Metrics/AbcSize
        @file_path = File.expand_path(file_path)
        raise ArgumentError, "File \"#{@file_path}\" does not exist" unless File.exist?(@file_path)

        @email_notifiers = DevelopmentApp::UserRepo.new.email_addresses(user_email_group: AppConst::EMAIL_GROUP_EDI_NOTIFIERS)
        @file_name = File.basename(file_path)
        @repo = EdiInRepo.new
        @edi_result = build_result_object
        id = repo.create_edi_in_transaction(file_name: file_name)
        work_out_flow_type
        repo.update_edi_in_transaction(id, flow_type: flow_type)
        # Make this the only "active" transaction if there were previous failures
        repo.mark_incomplete_transactions_as_reprocessed(id, flow_type, file_name)

        klass = "#{flow_type.capitalize}In"

        begin
          raise Crossbeams::InfoError, "There is no EDI in processor for flow \"#{flow_type}\"" unless EdiApp.const_defined?(klass)

          repo.transaction do
            res = EdiApp.const_get(klass).send(:call, id, @file_path, logger, @edi_result)
            if res.success
              log "Completed: #{res.message}"
              repo.log_edi_in_complete(id, res.message, @edi_result)
              move_to_success_dir
            else
              log "Failed: #{res.message}"
              repo.log_edi_in_failed(id, res.message, res.instance, @edi_result)
              msg = res.instance.empty? ? res.message : "\n#{res.message}\n#{res.instance}"
              ErrorMailer.send_error_email(subject: "EDI in #{flow_type} transform failed (#{file_name})",
                                           message: msg,
                                           append_recipients: email_notifiers)
              move_to_failed_dir
            end
            finish
          end
        rescue StandardError => e
          log_err(e.message)
          repo.log_edi_in_error(id, e, @edi_result)
          move_to_failed_dir
          ErrorMailer.send_exception_email(e, subject: "EDI in transform failed (#{file_name})", append_recipients: email_notifiers)
          expire
        end
      end

      private

      def build_result_object
        OpenStruct.new(schema_valid: false,
                       newer_edi_received: false,
                       has_missing_master_files: false,
                       valid: false,
                       has_discrepancies: false,
                       notes: nil)
      end

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

      def work_out_flow_type # rubocop:disable Metrics/AbcSize
        # Ensure longest flow types are matched first
        # (in case of something like flows: PO and POS)
        keys = config.keys.sort_by(&:length).reverse

        keys.each do |key|
          next unless file_name.upcase.start_with?(key.upcase)

          @flow_type = if config[key].is_a?(String)
                         config[key]
                       else
                         key.upcase
                       end
          break
        end
        raise Crossbeams::InfoError, "There is no EDI in flow type to match file #{file_name}" unless @flow_type
      end

      def config
        @config ||= EdiOutRepo.new.schema_record_sizes
      end

      def log(msg)
        logger.info "#{file_name}: #{msg}"
      end

      def log_err(msg)
        logger.error "#{file_name}: #{msg}"
      end

      def logger
        @logger ||= Logger.new(File.join(ENV['ROOT'], 'log', 'edi_in.log'), 'weekly')
      end
    end
  end
end
