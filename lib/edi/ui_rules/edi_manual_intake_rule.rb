# frozen_string_literal: true

module UiRules
  class EdiManualIntakeRule < Base
    def generate_rules
      @repo = EdiApp::EdiInRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields common_fields
      rules[:new_edi] = @form_object.depot_id.nil?

      form_name 'manual_intake'
    end

    def common_fields
      {
        depot_id: { renderer: :select, options: MasterfilesApp::DepotRepo.new.for_select_depots, required: true },
        edi_in_inspection_point: { required: true },
        edi_in_load_number: { required: true }
      }
    end

    def make_form_object
      rec = @repo.find_edi_in_transaction(@options[:id])
      @form_object = OpenStruct.new(rec.manual_header || { depot_id: nil, edi_in_inspection_point: nil, edi_in_load_number: nil })
    end
  end
end
