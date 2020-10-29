# frozen_string_literal: true

module UiRules
  class PmCompositionLevelRule < Base
    def generate_rules
      @repo = MasterfilesApp::BomsRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields common_fields

      set_show_fields if %i[show reopen].include? @mode

      form_name 'pm_composition_level'
    end

    def set_show_fields
      fields[:composition_level] = { renderer: :label }
      fields[:description] = { renderer: :label }
      fields[:active] = { renderer: :label, as_boolean: true }
      fields[:pm_types] = { renderer: :list, items: pm_types }
    end

    def common_fields
      {
        composition_level: { required: true },
        description: { required: true,
                       force_uppercase: true }
      }
    end

    def make_form_object
      if @mode == :new
        make_new_form_object
        return
      end

      @form_object = @repo.find_pm_composition_level(@options[:id])
    end

    def make_new_form_object
      @form_object = OpenStruct.new(composition_level: nil,
                                    description: nil)
    end

    def pm_types
      @repo.find_composition_level_pm_types(@options[:id])
    end
  end
end
