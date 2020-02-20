# frozen_string_literal: true

module UiRules
  class WageLevelRule < Base
    def generate_rules
      @repo = MasterfilesApp::HumanResourcesRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields common_fields

      set_show_fields if %i[show reopen].include? @mode

      form_name 'wage_level'
    end

    def set_show_fields
      fields[:wage_level] = { renderer: :label }
      fields[:description] = { renderer: :label }
    end

    def common_fields
      {
        wage_level: { renderer: :numeric, required: true },
        description: {}
      }
    end

    def make_form_object
      if @mode == :new
        make_new_form_object
        return
      end

      @form_object = @repo.find_wage_level(@options[:id])
    end

    def make_new_form_object
      @form_object = OpenStruct.new(wage_level: nil,
                                    description: nil)
    end
  end
end
