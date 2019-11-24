# frozen_string_literal: true

module UiRules
  class CultivarGroupRule < Base
    def generate_rules
      @repo = MasterfilesApp::CultivarRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields common_fields

      set_show_fields if @mode == :show

      form_name 'cultivar_group'
    end

    def set_show_fields
      commodity_id_label = MasterfilesApp::CommodityRepo.new.find_commodity(@form_object.commodity_id)&.code
      fields[:commodity_id] = { renderer: :label, with_value: commodity_id_label }
      fields[:cultivar_group_code] = { renderer: :label }
      fields[:description] = { renderer: :label }
      fields[:active] = { renderer: :label, as_boolean: true }
    end

    def common_fields
      {
        commodity_id: { renderer: :select, options: MasterfilesApp::CommodityRepo.new.for_select_commodities, required: true },
        cultivar_group_code: { required: true },
        description: {}
      }
    end

    def make_form_object
      make_new_form_object && return if @mode == :new

      @form_object = @repo.find_cultivar_group(@options[:id])
    end

    def make_new_form_object
      @form_object = OpenStruct.new(commodity_id: nil,
                                    cultivar_group_code: nil,
                                    description: nil)
    end
  end
end
