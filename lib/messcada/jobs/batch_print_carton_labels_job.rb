# frozen_string_literal: true

module MesscadaApp
  module Job
    class BatchPrintCartonLabels < BaseQueJob
      include LabelPrintingApp::LabelContent

      attr_reader :label_name, :instance, :repo, :messerver_repo, :carton_label_ids, :printer_id, :packhouse_no, :request_ip

      def run(params, carton_label_ids, request_ip)
        setup_repos
        @printer_id = params[:printer_id]
        @request_ip = request_ip
        @packhouse_no = repo.find_resource_packhouse_no(params[:packhouse_resource_id])
        @supporting_data = resolve_supporting_data(params[:supporting_data] || {})

        find_label(params[:label_template_id])
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
        @label_name = repo.get(:label_templates, :label_template_name, label_template_id)
      end

      def send_label_to_printer(vars)
        res = messerver_repo.print_published_label(label_name, vars, 1, printer_code(printer_id), request_ip)
        raise Crossbeams::InfoError, res.message unless res.success
      end

      def print_labels(carton_label_ids)
        lbl_required = fields_for_label
        field_positions = special_field_positions(lbl_required, %w[carton_label_id pick_ref])

        vars = values_from(lbl_required)

        carton_label_ids.each do |carton_label_id|
          # field_positions.each { |key| vars["F#{key + 1}".to_sym] = carton_label_id }
          field_positions.each do |key, name|
            vars["F#{key + 1}".to_sym] = if name == 'pick_ref'
                                           UtilityFunctions.calculate_pick_ref(packhouse_no)
                                         else
                                           carton_label_id
                                         end
          end
          send_label_to_printer(vars)
        end
      end

      def printer_code(printer_id)
        # For a robot printing to an attached printer, we don't know the actual printer code: use 'DEFAULT'
        return 'DEFAULT' if printer_id.nil?

        repo.get(:printers, :printer_code, printer_id)
      end

      def resolve_supporting_data(hash)
        return hash unless hash.key?(:packed_date)

        hash.merge(packed_date: Date.parse(hash[:packed_date]))
      end
    end
  end
end
