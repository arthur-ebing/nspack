# frozen_string_literal: true

module UiRules
  class PmTypeRule < Base
    def generate_rules
      @repo = MasterfilesApp::BomsRepo.new
      make_form_object
      apply_form_values

      @rules[:require_extended_packaging] = AppConst::REQUIRE_EXTENDED_PACKAGING

      common_values_for_fields common_fields

      set_show_fields if %i[show reopen].include? @mode

      form_name 'pm_type'
    end

    def set_show_fields
      pm_composition_level_id_label = @repo.find_pm_composition_level(@form_object.pm_composition_level_id)&.description
      fields[:pm_composition_level_id] = { renderer: :label,
                                           with_value: pm_composition_level_id_label,
                                           caption: 'Composition Level',
                                           hide_on_load: @rules[:require_extended_packaging] ? false : true }
      fields[:pm_type_code] = { renderer: :label }
      fields[:description] = { renderer: :label }
      fields[:active] = { renderer: :label, as_boolean: true }
      fields[:pm_subtypes] = { renderer: :list, items: pm_subtypes }
      fields[:short_code] = { renderer: :label }
    end

    def common_fields
      {
        pm_composition_level_id: { renderer: :select,
                                   options: @repo.for_select_pm_composition_levels,
                                   disabled_options: @repo.for_select_inactive_pm_composition_levels,
                                   caption: 'Composition Level',
                                   prompt: 'Select Composition Level',
                                   searchable: true,
                                   remove_search_for_small_list: false,
                                   hide_on_load: @rules[:require_extended_packaging] ? false : true,
                                   required: true },
        pm_type_code: { required: true,
                        force_uppercase: true },
        description: { required: true },
        short_code: { required: true,
                      force_uppercase: true }
      }
    end

    def make_form_object
      if @mode == :new
        make_new_form_object
        return
      end

      @form_object = @repo.find_pm_type(@options[:id])
    end

    def make_new_form_object
      @form_object = OpenStruct.new(pm_composition_level_id: nil,
                                    pm_type_code: nil,
                                    description: nil,
                                    short_code: nil)
    end

    def pm_subtypes
      @repo.find_pm_type_subtypes(@options[:id])
    end
  end
end
