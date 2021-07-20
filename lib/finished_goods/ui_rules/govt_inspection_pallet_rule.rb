# frozen_string_literal: true

module UiRules
  class GovtInspectionPalletRule < Base
    def generate_rules
      @repo = FinishedGoodsApp::GovtInspectionRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields common_fields

      set_show_fields if %i[show].include? @mode

      form_name 'govt_inspection_pallet'
    end

    def set_show_fields
      fields[:pallet_id] = { renderer: :label,
                             with_value: @form_object.pallet_number,
                             caption: 'Pallet' }
      fields[:passed] = { renderer: :label,
                          as_boolean: true }
      fields[:inspected] = { renderer: :label,
                             as_boolean: true }
      fields[:inspected_at] = { renderer: :label }
      fields[:failure_reason_id] = { renderer: :label,
                                     with_value: @form_object.failure_reason,
                                     caption: 'Inspection Failure Reason' }
      fields[:failure_remarks] = { renderer: :label }
      fields[:active] = { renderer: :label,
                          as_boolean: true }
    end

    def common_fields
      {
        govt_inspection_sheet_id: { renderer: :hidden },
        pallet_id: { renderer: :hidden },
        pallet_number: { renderer: :label,
                         with_value: @form_object.pallet_number,
                         caption: 'Pallet' },
        marketing_varieties: { renderer: :label,
                               with_value: @form_object.marketing_varieties.join(','),
                               caption: 'Marketing Varieties' },
        packed_tm_groups: { renderer: :label,
                            with_value: @form_object.packed_tm_groups.join(','),
                            caption: 'Packed TM Groups' },
        passed: { renderer: :checkbox },
        inspected: { renderer: :checkbox },
        inspected_at: { renderer: :date },
        failure_reason_id: { renderer: :select,
                             options: MasterfilesApp::QualityRepo.new.for_select_inspection_failure_reasons,
                             disabled_options: MasterfilesApp::QualityRepo.new.for_select_inactive_inspection_failure_reasons,
                             caption: 'Failure Reason',
                             prompt: true },
        failure_remarks: {}
      }
    end

    def make_form_object
      return make_new_form_object if @mode == :new

      @form_object = @repo.find_govt_inspection_pallet(@options[:id])
    end

    def make_new_form_object
      @form_values = OpenStruct.new(@options[:form_values])
      pallet_values = @repo.find_pallet_flat(@form_values.pallet_id)
      @form_object = OpenStruct.new(govt_inspection_sheet_id: @form_values.govt_inspection_sheet_id,
                                    passed: true,
                                    inspected: true,
                                    inspected_at: Time.now,
                                    failure_reason_id: nil,
                                    failure_remarks: nil,
                                    pallet_id: @form_values.pallet_id,
                                    pallet_number: pallet_values.pallet_number,
                                    marketing_varieties: pallet_values.marketing_varieties,
                                    packed_tm_groups: pallet_values.packed_tm_groups)
    end
  end
end
