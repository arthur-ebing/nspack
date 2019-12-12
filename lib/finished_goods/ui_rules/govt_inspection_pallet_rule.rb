# frozen_string_literal: true

module UiRules
  class GovtInspectionPalletRule < Base
    def generate_rules
      @repo = FinishedGoodsApp::GovtInspectionRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields common_fields

      set_show_fields if %i[show reopen].include? @mode

      set_capture_result_fields if @mode == :capture_result

      form_name 'govt_inspection_pallet'
    end

    def set_show_fields # rubocop:disable Metrics/AbcSize
      pallet_id_label = FinishedGoodsApp::LoadRepo.new.find_pallet_numbers_from(pallet_id: @form_object.pallet_id).first
      govt_inspection_sheet_id_label = FinishedGoodsApp::GovtInspectionRepo.new.find_govt_inspection_sheet(@form_object.govt_inspection_sheet_id)&.booking_reference
      failure_reason_id_label = MasterfilesApp::InspectionFailureReasonRepo.new.find_inspection_failure_reason(@form_object.failure_reason_id)&.failure_reason
      fields[:pallet_id] = { renderer: :label, with_value: pallet_id_label, caption: 'Pallet' }
      fields[:govt_inspection_sheet_id] = { renderer: :label, with_value: govt_inspection_sheet_id_label, caption: 'Govt Inspection Sheet' }
      fields[:passed] = { renderer: :label, as_boolean: true }
      fields[:inspected] = { renderer: :label, as_boolean: true }
      fields[:inspected_at] = { renderer: :label }
      fields[:failure_reason_id] = { renderer: :label, with_value: failure_reason_id_label, caption: 'Inspection Failure Reason' }
      fields[:failure_remarks] = { renderer: :label }
      fields[:active] = { renderer: :label, as_boolean: true }
    end

    def set_capture_result_fields
      pallet_id_label = FinishedGoodsApp::LoadRepo.new.find_pallet_numbers_from(id: @form_object.pallet_id).first
      fields[:pallet_id] = { renderer: :label, with_value: pallet_id_label, caption: 'Pallet' }
    end

    def common_fields
      {
        passed: { renderer: :checkbox },
        inspected: { renderer: :checkbox },
        inspected_at: { renderer: :input,
                        subtype: :datetime },
        failure_reason_id: { renderer: :select,
                             options: MasterfilesApp::InspectionFailureReasonRepo.new.for_select_inspection_failure_reasons,
                             disabled_options: MasterfilesApp::InspectionFailureReasonRepo.new.for_select_inactive_inspection_failure_reasons,
                             caption: 'Failure Reason',
                             prompt: true,
                             required: true },
        failure_remarks: {}
      }
    end

    def make_form_object
      return make_new_form_object if @mode == :new

      @form_object = @repo.find_govt_inspection_pallet(@options[:id])
    end

    def make_new_form_object
      @form_object = OpenStruct.new(pallet_id: nil,
                                    govt_inspection_sheet_id: nil,
                                    passed: nil,
                                    inspected: nil,
                                    inspected_at: nil,
                                    failure_reason_id: nil,
                                    failure_remarks: nil)
    end
  end
end
