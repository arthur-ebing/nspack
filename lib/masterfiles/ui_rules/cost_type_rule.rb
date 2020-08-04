# frozen_string_literal: true

module UiRules
  class CostTypeRule < Base
    def generate_rules
      @repo = RawMaterialsApp::RmtDeliveryRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields common_fields

      set_show_fields if %i[show reopen].include? @mode

      form_name 'cost_type'
    end

    def set_show_fields
      fields[:cost_type_code] = { renderer: :label }
      fields[:cost_unit] = { renderer: :label }
      fields[:description] = { renderer: :label }
    end

    def common_fields
      {
        cost_type_code: { required: true },
        cost_unit: { renderer: :select, options: AppConst::COST_UNITS, prompt: 'Select Cost Unit' },
        description: {}
      }
    end

    def make_form_object
      if @mode == :new
        make_new_form_object
        return
      end

      @form_object = @repo.find_cost_type(@options[:id])
    end

    def make_new_form_object
      @form_object = OpenStruct.new(cost_type_code: nil,
                                    cost_unit: nil,
                                    description: nil)
    end
  end
end
