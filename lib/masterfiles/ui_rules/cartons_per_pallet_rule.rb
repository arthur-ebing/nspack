# frozen_string_literal: true

module UiRules
  class CartonsPerPalletRule < Base
    def generate_rules
      @repo = MasterfilesApp::PackagingRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields common_fields

      set_show_fields if %i[show reopen].include? @mode

      form_name 'cartons_per_pallet'
    end

    def set_show_fields # rubocop:disable Metrics/AbcSize
      pallet_format_id_label = @repo.find_hash(:pallet_formats, @form_object.pallet_format_id)[:description]
      basic_pack_id_label = MasterfilesApp::FruitSizeRepo.new.find_hash(:basic_pack_codes,  @form_object.basic_pack_id)[:basic_pack_code]
      fields[:description] = { renderer: :label }
      fields[:pallet_format_id] = { renderer: :label, with_value: pallet_format_id_label, caption: 'Pallet Format' }
      fields[:basic_pack_id] = { renderer: :label, with_value: basic_pack_id_label, caption: 'Basic Pack' }
      fields[:cartons_per_pallet] = { renderer: :label }
      fields[:layers_per_pallet] = { renderer: :label }
      fields[:active] = { renderer: :label, as_boolean: true }
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
