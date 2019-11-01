# frozen_string_literal: true

module MesscadaApp
  module Job
    class BatchPrintCartonLabels < BaseQueJob
      include LabelPrintingApp::LabelContent

      attr_reader :label_name, :instance, :repo, :messerver_repo, :carton_label_ids, :printer_id, :packhouse_no, :request_ip

      def run(packhouse_resource_id, carton_label_ids, label_template_id, printer_id, request_ip)
        setup_repos
        @printer_id = printer_id
        @request_ip = request_ip
        @packhouse_no = repo.find_resource_packhouse_no(packhouse_resource_id)

        find_label(label_template_id)
        @instance = repo.carton_label_printing_instance(carton_label_ids.first)

        print_labels(carton_label_ids)
        finish
      end

      private

      def setup_repos
        @messerver_repo = MesserverApp::MesserverRepo.new
        @repo = MesscadaApp::MesscadaRepo.new
      end

      def find_label(label_template_id)
        @label_name = repo.get(:label_templates, label_template_id, :label_template_name)
      end

      def send_label_to_printer(vars)
        res = messerver_repo.print_published_label(label_name, vars, 1, printer_code(printer_id), request_ip)
        raise Crossbeams::InfoError, res.message unless res.success
      end

      def print_labels(carton_label_ids)
        lbl_required = fields_for_label
        field_positions = special_field_positions(lbl_required, %w[carton_label_id pick_ref])

        vars = values_from(lbl_required)

        # NOTE: Temporary delay to get around issues with timing for USB printers.
        #       - Remove when MesServer handles the timing problem.
        needs_delay = carton_label_ids.length > 1
        carton_label_ids.each do |carton_label_id|
          # field_positions.each { |key| vars["F#{key + 1}".to_sym] = carton_label_id }
          field_positions.each do |key, name|
            vars["F#{key + 1}".to_sym] = if name == 'pick_ref'
                                           UtilityFunctions.calculate_pick_ref(packhouse_no)
                                         else
                                           carton_label_id
                                         end
          end
          sleep 1 if needs_delay
          send_label_to_printer(vars)
        end
      end

      def printer_code(printer_id)
        # For a robot printing to an attached printer, we don't know the actual printer code: use 'DEFAULT'
        return 'DEFAULT' if printer_id.nil?

        repo.get(:printers, printer_id, :printer_code)
      end
    end
  end
end
