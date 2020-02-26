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
      fields[:active] = { renderer: :label, as_boolean: true }
    end

    def common_fields
      {
        city_id: { renderer: :select,
                   options: MasterfilesApp::DestinationRepo.new.for_select_destination_cities,
                   caption: 'City',
                   prompt: 'Optional' },
        depot_code: { required: true },
        description: {}
      }
    end

    def make_form_object
      make_new_form_object && return if @mode == :new

      @form_object = @repo.find_depot(@options[:id])
    end

    def make_new_form_object
      @form_object = OpenStruct.new(city_id: nil,
                                    depot_code: nil,
                                    description: nil)
    end
  end
end
