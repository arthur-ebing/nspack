# frozen_string_literal: true

module UiRules
  class ShiftTypeRule < Base
    def generate_rules
      @repo = MasterfilesApp::HumanResourcesRepo.new
      @resource_repo = ProductionApp::ResourceRepo.new
      make_form_object
      apply_form_values
      add_behaviours
      common_values_for_fields case @mode
                               when :swap
                                 swap_fields
                               when :move
                                 swap_fields
                               else
                                 common_fields
                               end

      set_show_fields if %i[show reopen].include? @mode

      form_name 'shift_type'
    end

    def set_show_fields
      fields[:employment_type_id] = { renderer: :label,
                                      with_value: @form_object.employment_type_code,
                                      caption: 'Employment Type' }
      fields[:start_hour] = { renderer: :label }
      fields[:end_hour] = { renderer: :label }
      fields[:day_night_or_custom] = { renderer: :label }
      fields[:shift_type_code] = { renderer: :label,
                                   with_value: @form_object.shift_type_code }
    end

    def swap_fields
      {
        from_shift_type_id: { renderer: :select,
                              options: @repo.for_select_shift_types_with_codes,
                              required: true },
        to_shift_type_id: { renderer: :select,
                            options: @repo.for_select_shift_types_with_codes,
                            required: true }
      }
    end

    def common_fields
      {
        ph_plant_resource_id: { renderer: :select,
                                options: packhouse_plant_resources,
                                caption: 'PH Plant Resource',
                                required: true,
                                prompt: true },
        line_plant_resource_id: { renderer: :select,
                                  options: @resource_repo.for_select_plant_resources_of_type(Crossbeams::Config::ResourceDefinitions::LINE),
                                  caption: 'Line Plant Resource',
                                  required: true,
                                  prompt: true },
        employment_type_id: { renderer: :select,
                              options: @repo.for_select_employment_types,
                              caption: 'Employment Type',
                              required: true },
        start_hour: { renderer: :select,
                      options: (0..23).step(1).to_a,
                      required: true,
                      sort_items: false },
        end_hour: { renderer: :select,
                    options: (0..23).step(1).to_a,
                    required: true,
                    sort_items: false },
        day_night_or_custom: { renderer: :select,
                               options: [%w[Day D], %w[Night N],  %w[Custom C]],
                               required: true,
                               min_charwidth: 30 }
      }
    end

    def make_form_object
      @form_object = case @mode
                     when :new
                       make_new_form_object
                     when :swap
                       make_shift_types_form_object
                     when :move
                       make_shift_types_form_object
                     else
                       @repo.find_shift_type(@options[:id])
                     end
    end

    def make_shift_types_form_object
      OpenStruct.new(from_shift_type_id: nil,
                     to_shift_type_id: nil)
    end

    def make_new_form_object
      OpenStruct.new(plant_resource_id: nil,
                     employment_type_id: nil,
                     start_hour: nil,
                     end_hour: nil,
                     day_night_or_custom: nil)
    end

    private

    def packhouse_plant_resources
      @resource_repo.for_select_plant_resources_of_type(Crossbeams::Config::ResourceDefinitions::PACKHOUSE)
    end

    def add_behaviours
      behaviours do |behaviour|
        behaviour.dropdown_change :ph_plant_resource_id, notify: [{ url: '/masterfiles/human_resources/shift_types/ph_plant_resource_changed' }]
      end
    end
  end
end
