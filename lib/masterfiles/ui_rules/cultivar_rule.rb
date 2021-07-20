# frozen_string_literal: true

module UiRules
  class CultivarRule < Base
    def generate_rules
      @repo = MasterfilesApp::CultivarRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields common_fields

      set_show_fields if @mode == :show

      form_name 'cultivar'
    end

    def set_show_fields
      fields[:commodity_code] = { renderer: :label }
      fields[:cultivar_group_code] = { renderer: :label }
      fields[:cultivar_name] = { renderer: :label }
      fields[:cultivar_code] = { renderer: :label }
      fields[:description] = { renderer: :label }
      fields[:active] = { renderer: :label, as_boolean: true }
      fields[:marketing_varieties] = { renderer: :list, items: @form_object.marketing_varieties }
    end

    def common_fields
      {
        cultivar_group_id: { renderer: :select,
                             options: @repo.for_select_cultivar_groups,
                             disabled_options: @repo.for_select_inactive_cultivar_groups,
                             required: true,
                             prompt: 'Select Cultivar Group' },
        cultivar_name: { required: true },
        cultivar_code: { hint: 'Formal code registered with external systems. <br>
                                This code must be correct in order to communicate with external systems such as phytclean.' },
        description: {}
      }
    end

    def make_form_object
      make_new_form_object && return if @mode == :new

      @form_object = @repo.find_cultivar(@options[:id])
    end

    def make_new_form_object
      @form_object = OpenStruct.new(cultivar_group_id: nil,
                                    cultivar_code: nil,
                                    cultivar_name: nil,
                                    description: nil)
    end
  end
end
