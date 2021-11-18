# frozen_string_literal: true

module UiRules
  class ProductionRegionRule < Base
    def generate_rules
      @repo = MasterfilesApp::FarmRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields common_fields

      set_show_fields if %i[show reopen].include? @mode

      form_name 'production_region'
    end

    def set_show_fields
      fields[:production_region_code] = { renderer: :label }
      fields[:description] = { renderer: :label }
      fields[:active] = { renderer: :label, as_boolean: true }
      fields[:inspection_region] = { renderer: :label }
    end

    def common_fields
      {
        production_region_code: { required: true },
        description: {},
        inspection_region: {}
      }
    end

    def make_form_object
      if @mode == :new
        make_new_form_object
        return
      end

      @form_object = @repo.find_production_region(@options[:id])
    end

    def make_new_form_object
      @form_object = new_form_object_from_struct(MasterfilesApp::ProductionRegion)
    end
  end
end
