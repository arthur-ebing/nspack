# frozen_string_literal: true

module UiRules
  class PmProductRule < Base # rubocop:disable Metrics/ClassLength
    def generate_rules # rubocop:disable Metrics/AbcSize
      @repo = MasterfilesApp::BomsRepo.new
      @fruit_size_repo = MasterfilesApp::FruitSizeRepo.new
      make_form_object
      apply_form_values

      @rules[:is_new_mode] = @mode == :new
      @rules[:require_extended_packaging] = AppConst::REQUIRE_EXTENDED_PACKAGING
      unless @form_object.pm_subtype_id.nil_or_empty?
        @rules[:minimum_composition_level] = @repo.minimum_composition_level?(@form_object.pm_subtype_id)
        @rules[:fruit_composition_level] = @repo.fruit_composition_level?(@form_object.pm_subtype_id)
        @rules[:show_extra_fields] = @repo.one_level_up_fruit_composition?(@form_object.pm_subtype_id)
      end

      common_values_for_fields common_fields

      set_show_fields if %i[show reopen].include? @mode

      add_behaviours if %i[new edit].include? @mode

      form_name 'pm_product'
    end

    def set_show_fields  # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
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
      fields[:composition_level] = { renderer: :label }
      fields[:basic_pack_id] = { renderer: :label,
                                 with_value: basic_pack_id_label,
                                 caption: 'Basic Pack',
                                 hide_on_load: @rules[:require_extended_packaging] && @rules[:minimum_composition_level] ? false : true }
      fields[:material_mass] = { renderer: :label,
                                 hide_on_load: @rules[:require_extended_packaging] && !@rules[:fruit_composition_level] ? false : true  }
      fields[:height_mm] = { renderer: :label,
                             hide_on_load: @rules[:require_extended_packaging] && !@rules[:fruit_composition_level] ? false : true  }
      fields[:gross_weight_per_unit] = { renderer: :label,
                                         hide_on_load: @rules[:require_extended_packaging] && @rules[:show_extra_fields] ? false : true  }
      fields[:items_per_unit] = { renderer: :label,
                                  hide_on_load: @rules[:require_extended_packaging] && @rules[:show_extra_fields] ? false : true  }
      fields[:marketing_size_range_mm] = { renderer: :label,
                                           hide_on_load: @rules[:require_extended_packaging] && @rules[:fruit_composition_level] ? false : true  }
      fields[:marketing_weight_range] = { renderer: :label,
                                          hide_on_load: @rules[:require_extended_packaging] && @rules[:fruit_composition_level] ? false : true  }
      fields[:minimum_size_mm] = { renderer: :label,
                                   hide_on_load: @rules[:require_extended_packaging] && @rules[:fruit_composition_level] ? false : true  }
      fields[:maximum_size_mm] = { renderer: :label,
                                   hide_on_load: @rules[:require_extended_packaging] && @rules[:fruit_composition_level] ? false : true  }
      fields[:average_size_mm] = { renderer: :label,
                                   hide_on_load: @rules[:require_extended_packaging] && @rules[:fruit_composition_level] ? false : true  }
      fields[:minimum_weight_gm] = { renderer: :label,
                                     hide_on_load: @rules[:require_extended_packaging] && @rules[:fruit_composition_level] ? false : true  }
      fields[:maximum_weight_gm] = { renderer: :label,
                                     hide_on_load: @rules[:require_extended_packaging] && @rules[:fruit_composition_level] ? false : true  }
      fields[:average_weight_gm] = { renderer: :label,
                                     hide_on_load: @rules[:require_extended_packaging] && @rules[:fruit_composition_level] ? false : true  }
    end

    def common_fields # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/AbcSize
      pm_subtypes = @rules[:is_new_mode] ? @repo.for_select_non_fruit_composition_subtypes : @repo.for_select_pm_type_subtypes
      {
        pm_subtype_id: { renderer: :select,
                         options: pm_subtypes,
                         disabled_options: @repo.for_select_inactive_pm_subtypes,
                         caption: 'Type and Subtype',
                         prompt: 'Select Type and Subtype',
                         searchable: true,
                         remove_search_for_small_list: false,
                         required: true },
        erp_code: {},
        product_code: @repo.can_edit_product_code?(@form_object.pm_subtype_id) ? { force_uppercase: true } : { renderer: :label },
        description: {},
        composition_level: { renderer: :label },
        basic_pack_id: { renderer: :select,
                         options: @fruit_size_repo.for_select_basic_pack_codes,
                         disabled_options: @fruit_size_repo.for_select_inactive_basic_pack_codes,
                         caption: 'Basic Pack',
                         prompt: 'Select Basic Pack',
                         searchable: true,
                         remove_search_for_small_list: false,
                         hide_on_load: @rules[:require_extended_packaging] && @rules[:minimum_composition_level] ? false : true },
        material_mass: { renderer: :numeric,
                         hide_on_load: @rules[:require_extended_packaging] && !@rules[:fruit_composition_level] ? false : true  },
        height_mm: { renderer: :integer,
                     hide_on_load: @rules[:require_extended_packaging] && !@rules[:fruit_composition_level] ? false : true  },
        gross_weight_per_unit: { renderer: :numeric,
                                 hide_on_load: @rules[:require_extended_packaging] && @rules[:show_extra_fields] ? false : true  },
        items_per_unit: { renderer: :integer,
                          hide_on_load: @rules[:require_extended_packaging] && @rules[:show_extra_fields] ? false : true  }
      }
    end

    def make_form_object
      if @mode == :new
        make_new_form_object
        return
      end

      res = @repo.find_pm_product(@options[:id])
      attrs = @repo.fruit_composition_level?(res.pm_subtype_id) ? @repo.find_std_fruit_size_by_product_code(res.product_code) : {}
      @form_object = OpenStruct.new(res.to_h.merge(attrs))
    end

    def make_new_form_object
      @form_object = OpenStruct.new(pm_subtype_id: nil,
                                    erp_code: nil,
                                    product_code: nil,
                                    description: nil,
                                    material_mass: nil,
                                    height_mm: nil,
                                    basic_pack_id: nil,
                                    gross_weight_per_unit: nil,
                                    items_per_unit: nil)
    end

    private

    def add_behaviours
      behaviours do |behaviour|
        behaviour.dropdown_change :pm_subtype_id, notify: [{ url: '/masterfiles/packaging/pm_products/pm_subtype_changed' }]
      end
    end
  end
end
