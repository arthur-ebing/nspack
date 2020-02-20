# frozen_string_literal: true

module UiRules
  class PalletBaseRule < Base
    def generate_rules
      @repo = MasterfilesApp::PackagingRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields common_fields

      set_show_fields if %i[show reopen].include? @mode

      form_name 'pallet_base'
    end

    def set_show_fields
      fields[:pallet_base_code] = { renderer: :label }
      fields[:description] = { renderer: :label }
      fields[:length] = { renderer: :label }
      fields[:width] = { renderer: :label }
      fields[:edi_in_pallet_base] = { renderer: :label }
      fields[:edi_out_pallet_base] = { renderer: :label }
      fields[:cartons_per_layer] = { renderer: :label }
      fields[:material_mass] = { renderer: :label }
      fields[:active] = { renderer: :label, as_boolean: true }
      fields[:pallet_formats] = { renderer: :list, items: pallet_base_pallet_formats }
    end

    def common_fields
      {
        pallet_base_code: { required: true },
        description: {},
        length: { renderer: :integer },
        width: { renderer: :integer },
        edi_in_pallet_base: {},
        edi_out_pallet_base: {},
        cartons_per_layer: { renderer: :integer },
        material_mass: { required: true,
                         renderer: :numeric }
      }
    end

    def make_form_object
      if @mode == :new
        make_new_form_object
        return
      end

      @form_object = @repo.find_pallet_base(@options[:id])
    end

    def make_new_form_object
      @form_object = OpenStruct.new(pallet_base_code: nil,
                                    description: nil,
                                    length: nil,
                                    width: nil,
                                    edi_in_pallet_base: nil,
                                    edi_out_pallet_base: nil,
                                    cartons_per_layer: nil,
                                    material_mass: nil)
    end

    def pallet_base_pallet_formats
      @repo.find_pallet_base_pallet_formats(@options[:id])
    end
  end
end
