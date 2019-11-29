# frozen_string_literal: true

module UiRules
  class GovtInspectionApiResultRule < Base
    def generate_rules
      @repo = FinishedGoodsApp::GovtInspectionApiResultRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields common_fields

      set_show_fields if %i[show reopen].include? @mode

      form_name 'govt_inspection_api_result'
    end

    def set_show_fields # rubocop:disable Metrics/AbcSize
      govt_inspection_sheet_id_label = FinishedGoodsApp::GovtInspectionSheetRepo.new.find_govt_inspection_sheet(@form_object.govt_inspection_sheet_id)&.booking_reference
      fields[:govt_inspection_sheet_id] = { renderer: :label, with_value: govt_inspection_sheet_id_label, caption: 'Govt Inspection Sheet' }
      fields[:govt_inspection_request_doc] = { renderer: :label }
      fields[:govt_inspection_result_doc] = { renderer: :label }
      fields[:results_requested] = { renderer: :label, as_boolean: true }
      fields[:results_requested_at] = { renderer: :label }
      fields[:results_received] = { renderer: :label, as_boolean: true }
      fields[:results_received_at] = { renderer: :label }
      fields[:upn_number] = { renderer: :label }
      fields[:active] = { renderer: :label, as_boolean: true }
    end

    def common_fields
      {
        govt_inspection_sheet_id: { renderer: :select, options: FinishedGoodsApp::GovtInspectionSheetRepo.new.for_select_govt_inspection_sheets, disabled_options: FinishedGoodsApp::GovtInspectionSheetRepo.new.for_select_inactive_govt_inspection_sheets, caption: 'Govt Inspection Sheet' },
        govt_inspection_request_doc: {},
        govt_inspection_result_doc: {},
        results_requested: { renderer: :checkbox },
        results_requested_at: { renderer: :date },
        results_received: { renderer: :checkbox },
        results_received_at: { renderer: :date },
        upn_number: {}
      }
    end

    def make_form_object
      if @mode == :new
        make_new_form_object
        return
      end

      @form_object = @repo.find_govt_inspection_api_result(@options[:id])
    end

    def make_new_form_object
      @form_object = OpenStruct.new(govt_inspection_sheet_id: nil,
                                    govt_inspection_request_doc: nil,
                                    govt_inspection_result_doc: nil,
                                    results_requested: nil,
                                    results_requested_at: nil,
                                    results_received: nil,
                                    results_received_at: nil,
                                    upn_number: nil)
    end
  end
end
