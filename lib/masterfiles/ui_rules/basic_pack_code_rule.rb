# frozen_string_literal: true

module UiRules
  class BasicPackCodeRule < Base
    def generate_rules
      @this_repo = MasterfilesApp::FruitSizeRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields common_fields

      set_show_fields if @mode == :show

      calculate_basic_pack_code = AppConst::CR_MF.kromco_calculate_basic_pack_code?
      calculate_basic_pack_code = false unless %i[new edit].include? @mode

      add_basic_pack_behaviours if calculate_basic_pack_code

      form_name 'basic_pack_code'
    end

    def set_show_fields
      fields[:basic_pack_code] = { renderer: :label }
      fields[:description] = { renderer: :label }
      fields[:length_mm] = { renderer: :label }
      fields[:width_mm] = { renderer: :label }
      fields[:height_mm] = { renderer: :label }
      fields[:active] = { renderer: :label, as_boolean: true }
      fields[:footprint_code] = { renderer: :label }
    end

    def common_fields
      {
        basic_pack_code: { required: true },
        description: {},
        length_mm: { renderer: :integer },
        width_mm: { renderer: :integer },
        height_mm: { renderer: :integer },
        footprint_code: {}
      }
    end

    def make_form_object
      make_new_form_object && return if @mode == :new

      @form_object = @this_repo.find_basic_pack_code(@options[:id])
    end

    def make_new_form_object
      @form_object = OpenStruct.new(basic_pack_code: nil,
                                    description: nil,
                                    length_mm: nil,
                                    width_mm: nil,
                                    height_mm: nil,
                                    footprint_code: nil)
    end

    private

    def add_basic_pack_behaviours
      behaviours do |behaviour|
        behaviour.lose_focus :height_mm,
                             notify: [{ url: '/masterfiles/fruit/basic_pack_codes/height_changed',
                                        param_keys: %i[basic_pack_code_basic_pack_code basic_pack_code_footprint_code] }]
        behaviour.lose_focus :footprint_code,
                             notify: [{ url: '/masterfiles/fruit/basic_pack_codes/footprint_code_changed',
                                        param_keys: %i[basic_pack_code_basic_pack_code basic_pack_code_height_mm] }]
      end
    end
  end
end
