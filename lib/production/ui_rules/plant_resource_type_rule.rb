# frozen_string_literal: true

module UiRules
  class PlantResourceTypeRule < Base
    def generate_rules
      @repo = ProductionApp::ResourceRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields common_fields

      set_show_fields if %i[show reopen].include? @mode

      form_name 'plant_resource_type'
    end

    def set_show_fields
      fields[:plant_resource_type_code] = { renderer: :label }
      fields[:description] = { renderer: :label }
      fields[:active] = { renderer: :label, as_boolean: true }
      fields[:packpoint] = { renderer: :label, as_boolean: true }
      fields[:represents_plant_resource_type_id] = { renderer: :label, with_value: represents_type }
      rules[:icon_render] = render_icon(@form_object.icon)
    end

    def common_fields
      {
        plant_resource_type_code: { required: true },
        description: { required: true },
        packpoint: { requred: true }
      }
    end

    def represents_type
      return nil if @form_object.represents_plant_resource_type_id.nil?

      @repo.get(:plant_resource_types, @form_object.represents_plant_resource_type_id, :plant_resource_type_code)
    end

    def make_form_object
      @form_object = @repo.find_plant_resource_type(@options[:id])
    end
  end
end
