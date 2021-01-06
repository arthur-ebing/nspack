# frozen_string_literal: true

module UiRules
  class SupplierGroupRule < Base
    def generate_rules
      @repo = MasterfilesApp::SupplierRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields common_fields

      set_show_fields if %i[show reopen].include? @mode

      form_name 'supplier_group'
    end

    def set_show_fields
      fields[:supplier_group_code] = { renderer: :label }
      fields[:description] = { renderer: :label }
      fields[:active] = { renderer: :label, as_boolean: true }
    end

    def common_fields
      {
        supplier_group_code: { required: true },
        description: {}
      }
    end

    def make_form_object
      if @mode == :new
        make_new_form_object
        return
      end

      @form_object = @repo.find_supplier_group(@options[:id])
    end

    def make_new_form_object
      @form_object = OpenStruct.new(supplier_group_code: nil,
                                    description: nil)
    end
  end
end
