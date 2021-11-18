# frozen_string_literal: true

module UiRules
  class RmtLocationRule < Base
    def generate_rules
      @repo = RawMaterialsApp::LocationRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields common_fields

      set_show_fields if @mode == :show
      form_name 'location'
    end

    def set_show_fields
      fields[:location_long_code] = { renderer: :label }
      fields[:status] = { renderer: :label }
      fields[:current_status] = { renderer: :label }
    end

    def common_fields
      {
        status: { renderer: :select, options: AppConst::CA_TREATMENT_LOCATION_STATUSES, required: true, min_charwidth: 30 },
        current_status: { renderer: :label },
        location_long_code: { renderer: :label }
      }
    end

    def make_form_object
      hash = @repo.find_location(@options[:id])
      @form_object = OpenStruct.new(hash.to_h.merge(status: hash[:current_status]))
    end
  end
end
