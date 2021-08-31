# frozen_string_literal: true

module UiRules
  class BasicPackRule < Base
    def generate_rules
      @repo = MasterfilesApp::FruitSizeRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields common_fields

      set_show_fields if @mode == :show

      add_behaviours if %i[new edit].include? @mode

      form_name 'basic_pack'
    end

    def set_show_fields
      fields[:basic_pack_code] = { renderer: :label }
      fields[:description] = { renderer: :label }
      fields[:length_mm] = { renderer: :label, caption: 'Length (mm)' }
      fields[:width_mm] = { renderer: :label, caption: 'Width (mm)' }
      fields[:height_mm] = { renderer: :label, caption: 'Height (mm)' }
      fields[:active] = { renderer: :label, as_boolean: true }
      fields[:bin] = { renderer: :label, as_boolean: true }
      fields[:footprint_code] = { renderer: :label }
      fields[:standard_pack_codes] = { renderer: :list,
                                       caption: 'Standard Packs',
                                       hide_on_load: @form_object.standard_pack_codes.empty?,
                                       items: @form_object.standard_pack_codes }
    end

    def common_fields
      {
        basic_pack_code: { required: true },
        description: {},
        length_mm: { renderer: :integer, caption: 'Length (mm)' },
        width_mm: { renderer: :integer, caption: 'Width (mm)' },
        height_mm: { renderer: :integer, caption: 'Height (mm)' },
        footprint_code: {},
        standard_pack_ids: { renderer: :multi,
                             caption: 'Standard Packs',
                             options: @repo.for_select_standard_packs,
                             selected: @form_object.standard_pack_ids,
                             hide_on_load: AppConst::CR_MF.basic_pack_equals_standard_pack?,
                             required: false },
        bin: { renderer: :checkbox }
      }
    end

    def make_form_object
      make_new_form_object && return if @mode == :new

      @form_object = @repo.find_basic_pack(@options[:id])
    end

    def make_new_form_object
      @form_object = OpenStruct.new(basic_pack_code: nil,
                                    description: nil,
                                    length_mm: nil,
                                    width_mm: nil,
                                    height_mm: nil,
                                    footprint_code: nil,
                                    standard_pack_ids: [])
    end

    private

    def add_behaviours
      behaviours do |behaviour|
        if AppConst::CR_MF.kromco_calculate_basic_pack_code?
          behaviour.lose_focus :height_mm,
                               notify: [{ url: '/masterfiles/fruit/basic_pack_codes/height_changed',
                                          param_keys: %i[basic_pack_basic_pack_code basic_pack_footprint_code] }]
          behaviour.lose_focus :footprint_code,
                               notify: [{ url: '/masterfiles/fruit/basic_pack_codes/footprint_code_changed',
                                          param_keys: %i[basic_pack_basic_pack_code basic_pack_height_mm] }]
        end
      end
    end
  end
end
