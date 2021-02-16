# frozen_string_literal: true

module UiRules
  class InspectionRule < Base
    def generate_rules
      @repo = FinishedGoodsApp::InspectionRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields common_fields

      set_show_fields if %i[show].include? @mode
      add_behaviours if %i[edit].include? @mode

      form_name 'inspection'
    end

    def set_show_fields
      fields[:inspection_type_code] = { renderer: :label, caption: 'Inspection Type' }
      fields[:pallet_number] = { renderer: :label, caption: 'Pallet Number' }
      fields[:inspector] = { renderer: :label, caption: 'Inspector' }
      fields[:inspected] = { renderer: :label, as_boolean: true }
      fields[:failure_reasons] = { renderer: :label, caption: 'Failure Reasons',
                                   with_value: @form_object.failure_reasons.join(', ') }
      fields[:passed] = { renderer: :label, as_boolean: true }
      fields[:remarks] = { renderer: :label }
      fields[:active] = { renderer: :label, as_boolean: true }
    end

    def common_fields
      {
        inspection_type_code: { renderer: :label, caption: 'Inspection Type' },
        pallet_number: { renderer: :label, caption: 'Pallet Number' },
        inspector_id: { renderer: :select, caption: 'Inspector',
                        options: MasterfilesApp::InspectorRepo.new.for_select_inspectors,
                        disabled_options: MasterfilesApp::InspectorRepo.new.for_select_inactive_inspectors,
                        required: true,
                        prompt: true },
        passed: { renderer: :checkbox },
        inspection_failure_reason_ids: { renderer: :multi, caption: 'Failure Reasons',
                                         options: MasterfilesApp::QualityRepo.new.for_select_inspection_failure_reasons,
                                         selected: @form_object.inspection_failure_reason_ids,
                                         hide_on_load: @form_object.passed },
        remarks: { hide_on_load: @form_object.passed }
      }
    end

    def make_form_object
      if @mode == :new
        make_new_form_object
        return
      end

      hash = @repo.find_inspection(@options[:id]).to_h
      hash[:inspector_id] ||= FinishedGoodsApp::GovtInspectionRepo.new.get_last(:inspections, :inspector_id, :updated_at)
      @form_object = OpenStruct.new(hash)
    end

    def make_new_form_object
      @form_object = OpenStruct.new(pallet_number: nil)
    end

    def add_behaviours
      behaviours do |behaviour|
        behaviour.input_change :passed, notify: [{ url: '/finished_goods/inspection/inspections/passed_changed' }]
      end
    end
  end
end
