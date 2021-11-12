# frozen_string_literal: true

module UiRules
  class ReworksRunPrintRule < Base
    def generate_rules
      @repo = ProductionApp::ReworksRepo.new
      @print_repo = LabelApp::PrinterRepo.new
      @template_repo = MasterfilesApp::LabelTemplateRepo.new
      make_form_object
      apply_form_values

      @rules[:carton_label] = @form_object[:carton_label]
      @rules[:print_app] = @form_object[:carton_label] ? AppConst::PRINT_APP_CARTON : AppConst::PRINT_APP_PALLET

      common_values_for_fields common_fields

      form_name 'reworks_run_print'
    end

    def common_fields
      {
        pallet_sequence_id: { renderer: :hidden },
        pallet_number: { renderer: :hidden },
        printer: { renderer: :select,
                   options: @print_repo.select_printers_for_application(rules[:print_app]),
                   required: true,
                   invisible: print_to_robot? },
        no_of_prints: { renderer: :integer, required: true, readonly: @mode == :print_seq_cartons },
        label_template_id: { renderer: :select,
                             options: @template_repo.for_select_label_templates(where: { application: rules[:print_app] }),
                             required: true }
      }
    end

    def make_form_object
      default = { pallet_sequence_id: @options[:id],
                  pallet_number: @options[:pallet_number],
                  carton_label: @options[:carton_label],
                  printer: @print_repo.default_printer_for_application(rules[:print_app]),
                  no_of_prints: 1 }
      @form_object = OpenStruct.new(default)
    end

    def print_to_robot?
      @print_repo.print_to_robot?(@options[:request_ip])
    end
  end
end
