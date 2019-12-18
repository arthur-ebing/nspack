# frozen_string_literal: true

module UiRules
  class FruitSizeReferenceRule < Base
    def generate_rules
      @repo = MasterfilesApp::FruitSizeRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields common_fields

      set_show_fields if @mode == :show

      form_name 'fruit_size_reference'
    end

    def set_show_fields
      fields[:size_reference] = { renderer: :label }
      fields[:edi_out_code] = { renderer: :label }
      fields[:active] = { renderer: :label, as_boolean: true }
    end

    def common_fields
      {
        size_reference: { required: true },
        edi_out_code: {}
      }
    end

    def make_form_object
      make_new_form_object && return if @mode == :new

      @form_object = @repo.find_fruit_size_reference(@options[:id])
    end

    def make_new_form_object
      @form_object = OpenStruct.new(size_reference: nil,
                                    edi_out_code: nil)
    end
  end
end
