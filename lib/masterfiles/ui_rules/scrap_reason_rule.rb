# frozen_string_literal: true

module UiRules
  class ScrapReasonRule < Base
    def generate_rules
      @repo = MasterfilesApp::QualityRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields common_fields

      set_show_fields if %i[show reopen].include? @mode

      form_name 'scrap_reason'
    end

    def set_show_fields
      fields[:scrap_reason] = { renderer: :label }
      fields[:description] = { renderer: :label }
      fields[:active] = { renderer: :label, as_boolean: true }
      fields[:applies_to_pallets] = { renderer: :label, as_boolean: true }
      fields[:applies_to_bins] = { renderer: :label, as_boolean: true }
    end

    def common_fields
      {
        scrap_reason: { required: true },
        description: {},
        applies_to_pallets: { renderer: :checkbox },
        applies_to_bins: { renderer: :checkbox }
      }
    end

    def make_form_object
      if @mode == :new
        make_new_form_object
        return
      end

      @form_object = @repo.find_scrap_reason(@options[:id])
    end

    def make_new_form_object
      @form_object = OpenStruct.new(scrap_reason: nil,
                                    description: nil,
                                    applies_to_pallets: true,
                                    applies_to_bins: false)
    end
  end
end
