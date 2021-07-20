# frozen_string_literal: true

module UiRules
  class CartonsPerPalletRule < Base
    def generate_rules
      @repo = MasterfilesApp::PackagingRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields common_fields

      set_show_fields if %i[show].include? @mode
      edit_label_fields if %i[edit].include? @mode

      form_name 'cartons_per_pallet'
    end

    def set_show_fields
      fields[:description] = { renderer: :label }
      fields[:cartons_per_pallet] = { renderer: :label }
      fields[:layers_per_pallet] = { renderer: :label }
      fields[:active] = { renderer: :label, as_boolean: true }
      edit_label_fields
    end

    def edit_label_fields
      fields[:pallet_format_id] = { renderer: :label,
                                    with_value: @form_object.pallet_formats_description,
                                    include_hidden_field: true,
                                    hidden_value: @form_object.pallet_format_id,
                                    caption: 'Pallet Format' }
      fields[:basic_pack_id] = { renderer: :label,
                                 with_value: @form_object.basic_pack_code,
                                 include_hidden_field: true,
                                 hidden_value: @form_object.basic_pack_id,
                                 caption: 'Basic Pack' }
    end

    def common_fields
      {
        description: {},
        pallet_format_id: { renderer: :select,
                            options: @repo.for_select_pallet_formats,
                            disabled_options: @repo.for_select_inactive_pallet_formats,
                            caption: 'Pallet Format',
                            required: true },
        basic_pack_id: { renderer: :select,
                         options: MasterfilesApp::FruitSizeRepo.new.for_select_basic_packs,
                         disabled_options: MasterfilesApp::FruitSizeRepo.new.for_select_inactive_basic_packs,
                         caption: 'Basic Pack',
                         required: true },
        cartons_per_pallet: { renderer: :integer, required: true },
        layers_per_pallet: { renderer: :integer, required: true }
      }
    end

    def make_form_object
      if @mode == :new
        make_new_form_object
        return
      end

      @form_object = @repo.find_cartons_per_pallet(@options[:id])
    end

    def make_new_form_object
      @form_object = OpenStruct.new(description: nil,
                                    pallet_format_id: nil,
                                    basic_pack_id: nil,
                                    cartons_per_pallet: nil,
                                    layers_per_pallet: nil)
    end
  end
end
