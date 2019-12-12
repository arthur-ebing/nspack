# frozen_string_literal: true

module UiRules
  class GovtInspectionPalletApiResultRule < Base
    def generate_rules
      @repo = FinishedGoodsApp::GovtInspectionRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields common_fields

      set_show_fields if %i[show reopen].include? @mode
      form_name 'govt_inspection_pallet_api_result'
    end

    def set_show_fields
      govt_inspection_pallet_id_label = FinishedGoodsApp::GovtInspectionRepo.new.find_govt_inspection_pallet(@form_object.govt_inspection_pallet_id)&.failure_remarks
      govt_inspection_api_result_id_label = FinishedGoodsApp::GovtInspectionRepo.new.find_govt_inspection_api_result(@form_object.govt_inspection_api_result_id)&.upn_number
      fields[:passed] = { renderer: :label, as_boolean: true }
      fields[:failure_reasons] = { renderer: :label }
      fields[:govt_inspection_pallet_id] = { renderer: :label, with_value: govt_inspection_pallet_id_label, caption: 'Govt Inspection Pallet' }
      fields[:govt_inspection_api_result_id] = { renderer: :label, with_value: govt_inspection_api_result_id_label, caption: 'Govt Inspection Api Result' }
      fields[:active] = { renderer: :label, as_boolean: true }
    end

    def common_fields
      {
        passed: { renderer: :checkbox },
        failure_reasons: {},
        govt_inspection_pallet_id: { renderer: :select, options: FinishedGoodsApp::GovtInspectionRepo.new.for_select_govt_inspection_pallets, disabled_options: FinishedGoodsApp::GovtInspectionRepo.new.for_select_inactive_govt_inspection_pallets, caption: 'Govt Inspection Pallet' },
        govt_inspection_api_result_id: { renderer: :select, options: FinishedGoodsApp::GovtInspectionRepo.new.for_select_govt_inspection_api_results, disabled_options: FinishedGoodsApp::GovtInspectionRepo.new.for_select_inactive_govt_inspection_api_results, caption: 'Govt Inspection Api Result' }
      }
    end

    def make_form_object
      if @mode == :new
        make_new_form_object
        return
      end

      @form_object = @repo.find_govt_inspection_pallet_api_result(@options[:id])
    end

    def make_new_form_object
      @form_object = OpenStruct.new(passed: nil,
                                    failure_reasons: nil,
                                    govt_inspection_pallet_id: nil,
                                    govt_inspection_api_result_id: nil)
    end
  end
end
