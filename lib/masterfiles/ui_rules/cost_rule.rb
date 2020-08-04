# frozen_string_literal: true

module UiRules
  class CostRule < Base
    def generate_rules
      @repo = RawMaterialsApp::RmtDeliveryRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields common_fields

      set_show_fields if %i[show reopen].include? @mode

      form_name 'cost'
    end

    def set_show_fields
      # cost_type_id_label = MasterfilesApp::CostTypeRepo.new.find_cost_type(@form_object.cost_type_id)&.cost_type_code
      cost_type_id_label = @repo.find(:cost_types, MasterfilesApp::CostType, @form_object.cost_type_id)&.cost_type_code
      fields[:cost_type_id] = { renderer: :label, with_value: cost_type_id_label, caption: 'Cost Type' }
      fields[:cost_code] = { renderer: :label }
      fields[:default_amount] = { renderer: :label }
      fields[:description] = { renderer: :label }
    end

    def common_fields
      {
        cost_type_id: { renderer: :select, options: @repo.for_select_cost_types, caption: 'Cost Type', prompt: 'Select Cost Type', required: true },
        cost_code: {},
        default_amount: {},
        description: {}
      }
    end

    def make_form_object
      if @mode == :new
        make_new_form_object
        return
      end

      @form_object = @repo.find_cost(@options[:id])
    end

    def make_new_form_object
      @form_object = OpenStruct.new(cost_type_id: nil,
                                    default_amount: nil)
    end
  end
end
