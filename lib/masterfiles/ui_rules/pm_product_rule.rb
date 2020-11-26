# frozen_string_literal: true

module UiRules
  class PmProductRule < Base
    def generate_rules # rubocop:disable Metrics/AbcSize
      @repo = MasterfilesApp::BomsRepo.new
      @fruit_size_repo = MasterfilesApp::FruitSizeRepo.new
      make_form_object
      apply_form_values

      @rules[:require_extended_packaging] = AppConst::REQUIRE_EXTENDED_PACKAGING
      @rules[:show_basic_pack] = false
      @rules[:show_extra_fields] = false
      unless @form_object.pm_subtype_id.nil_or_empty?
        @rules[:show_basic_pack] = @repo.can_show_pm_product_basic_pack?(@form_object.pm_subtype_id)
        @rules[:show_extra_fields] = @repo.can_show_pm_product_extra_fields?(@form_object.pm_subtype_id)
      end

      common_values_for_fields common_fields

      set_show_fields if %i[show reopen].include? @mode

      add_behaviours if %i[new edit].include? @mode

      form_name 'pm_product'
    end

    def set_show_fields  # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity
      pm_type_id = @repo.get(:pm_subtypes, @form_object.pm_subtype_id, :pm_type_id)
      pm_type_id_label = @repo.find_hash(:pm_types, pm_type_id)[:pm_type_code]
      pm_subtype_id_label = @repo.find_hash(:pm_subtypes, @form_object.pm_subtype_id)[:subtype_code]
      basic_pack_id_label = @fruit_size_repo.find_basic_pack_code(@form_object.basic_pack_id)&.basic_pack_code
      fields[:pm_type_id] = { renderer: :label, with_value: pm_type_id_label, caption: 'Pm Type' }
      fields[:pm_subtype_id] = { renderer: :label, with_value: pm_subtype_id_label, caption: 'Pm Subtype' }
      fields[:erp_code] = { renderer: :label }
      fields[:product_code] = { renderer: :label }
      fields[:description] = { renderer: :label }
      fields[:active] = { renderer: :label, as_boolean: true }
      fields[:material_mass] = { renderer: :label,
                                 hide_on_load: @rules[:require_extended_packaging] && @rules[:show_extra_fields] ? false : true  }
      fields[:basic_pack_id] = { renderer: :label,
                                 with_value: basic_pack_id_label,
                                 caption: 'Basic Pack',
                                 hide_on_load: @rules[:require_extended_packaging] && @rules[:show_basic_pack] ? false : true }
      fields[:height_mm] = { renderer: :label,
                             hide_on_load: @rules[:require_extended_packaging] && @rules[:show_extra_fields] ? false : true  }
    end

    def common_fields # rubocop:disable Metrics/CyclomaticComplexity
      {
        pm_subtype_id: { renderer: :select,
                         options: @repo.for_select_pm_type_subtypes,
                         disabled_options: @repo.for_select_inactive_pm_subtypes,
                         caption: 'Pm Subtype',
                         prompt: 'Select Pm Subtype',
                         searchable: true,
                         remove_search_for_small_list: false,
                         required: true },
        erp_code: {},
        product_code: { required: true,
                        force_uppercase: true },
        description: {},
        material_mass: { renderer: :numeric,
                         hide_on_load: @rules[:require_extended_packaging] && @rules[:show_extra_fields] ? false : true  },
        basic_pack_id: { renderer: :select,
                         options: @fruit_size_repo.for_select_basic_pack_codes,
                         disabled_options: @fruit_size_repo.for_select_inactive_basic_pack_codes,
                         caption: 'Basic Pack',
                         prompt: 'Select Basic Pack',
                         searchable: true,
                         remove_search_for_small_list: false,
                         hide_on_load: @rules[:require_extended_packaging] && @rules[:show_basic_pack] ? false : true },
        height_mm: { renderer: :integer,
                     hide_on_load: @rules[:require_extended_packaging] && @rules[:show_extra_fields] ? false : true  }
      }
    end

    def make_form_object
      if @mode == :new
        make_new_form_object
        return
      end

      @form_object = @repo.find_pm_product(@options[:id])
    end

    def make_new_form_object
      @form_object = OpenStruct.new(pm_subtype_id: nil,
                                    erp_code: nil,
                                    product_code: nil,
                                    description: nil,
                                    material_mass: nil,
                                    height_mm: nil,
                                    basic_pack_id: nil)
    end

    private

    def add_behaviours
      behaviours do |behaviour|
        behaviour.dropdown_change :pm_subtype_id, notify: [{ url: '/masterfiles/packaging/pm_products/pm_subtype_changed' }]
      end
    end
  end
end
