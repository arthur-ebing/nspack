# frozen_string_literal: true

module UiRules
  class DepotRule < Base
    def generate_rules
      @repo = MasterfilesApp::DepotRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields common_fields

      set_show_fields if %i[show].include? @mode
      form_name 'depot'
    end

    def set_show_fields
      city_id_label = MasterfilesApp::DestinationRepo.new.find_city(@form_object.city_id)&.city_name
      fields[:city_id] = { renderer: :label, with_value: city_id_label, caption: 'City' }
      fields[:depot_code] = { renderer: :label }
      fields[:description] = { renderer: :label }
      fields[:bin_depot] = { renderer: :label, as_boolean: true }
      fields[:active] = { renderer: :label, as_boolean: true }
      fields[:magisterial_district] = { renderer: :label }
    end

    def common_fields
      {
        city_id: { renderer: :select,
                   options: MasterfilesApp::DestinationRepo.new.for_select_destination_cities,
                   caption: 'City',
                   prompt: 'Optional' },
        depot_code: { required: true },
        description: {},
        bin_depot: { renderer: :checkbox },
        magisterial_district: {}
      }
    end

    def make_form_object
      make_new_form_object && return if @mode == :new

      @form_object = @repo.find_depot(@options[:id])
    end

    def make_new_form_object
      @form_object = new_form_object_from_struct(MasterfilesApp::Depot)
    end
  end
end
