# frozen_string_literal: true

module UiRules
  class PalletFormatRule < Base
    def generate_rules
      @repo = MasterfilesApp::PackagingRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields common_fields

      set_show_fields if %i[show].include? @mode

      form_name 'pallet_format'
    end

    def set_show_fields
      fields[:description] = { renderer: :label }
      fields[:pallet_base_id] = { renderer: :label,
                                  with_value: @form_object.pallet_base_code,
                                  caption: 'Pallet Base' }
      fields[:pallet_stack_type_id] = { renderer: :label,
                                        with_value: @form_object.stack_type_code,
                                        caption: 'Pallet Stack Type' }
      fields[:active] = { renderer: :label, as_boolean: true }
      fields[:bin] = { renderer: :label, as_boolean: true }
    end

    def common_fields
      {
        description: { required: true },
        pallet_base_id: { renderer: :select,
                          options: @repo.for_select_pallet_bases,
                          disabled_options: @repo.for_select_inactive_pallet_bases,
                          caption: 'Pallet Base',
                          required: true },
        pallet_stack_type_id: { renderer: :select,
                                options: @repo.for_select_pallet_stack_types,
                                disabled_options: @repo.for_select_inactive_pallet_stack_types,
                                caption: 'Pallet Stack Type',
                                required: true },
        bin: { renderer: :checkbox }
      }
    end

    def make_form_object
      if @mode == :new
        make_new_form_object
        return
      end

      @form_object = @repo.find_pallet_format(@options[:id])
    end

    def make_new_form_object
      @form_object = OpenStruct.new(description: nil,
                                    pallet_base_id: nil,
                                    pallet_stack_type_id: nil)
    end
  end
end
