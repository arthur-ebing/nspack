# frozen_string_literal: true

module UiRules
  class PmProductRule < Base # rubocop:disable Metrics/ClassLength
    def generate_rules # rubocop:disable Metrics/AbcSize
      @repo = MasterfilesApp::BomRepo.new
      @fruit_size_repo = MasterfilesApp::FruitSizeRepo.new
      make_form_object
      apply_form_values

      @rules[:require_extended_packaging] = AppConst::REQUIRE_EXTENDED_PACKAGING
      unless @form_object.pm_subtype_id.nil_or_empty?
        @rules[:minimum_composition_level] = @repo.minimum_composition_level?(@form_object.pm_subtype_id)
        @rules[:fruit_composition_level] = @repo.fruit_composition_level?(@form_object.pm_subtype_id)
        @rules[:show_extra_fields] = @repo.one_level_up_fruit_composition?(@form_object.pm_subtype_id)
      end

      common_values_for_fields common_fields

      set_show_fields if %i[show].include? @mode

      add_behaviours if %i[new edit].include? @mode

      set_hide_on_load

      form_name 'pm_product'
    end

    def set_show_fields # rubocop:disable Metrics/AbcSize
      pm_type_id = @repo.get(:pm_subtypes, @form_object.pm_subtype_id, :pm_type_id)
      pm_type_id_label = @repo.find_hash(:pm_types, pm_type_id)[:pm_type_code]
      pm_subtype_id_label = @repo.find_hash(:pm_subtypes, @form_object.pm_subtype_id)[:subtype_code]
      basic_pack_id_label = @fruit_size_repo.find_basic_pack_code(@form_object.basic_pack_id)&.basic_pack_code
      fields[:pm_type_id] = { renderer: :label, with_value: pm_type_id_label, caption: 'PM Type' }
      fields[:pm_subtype_id] = { renderer: :label, with_value: pm_subtype_id_label, caption: 'PM Subtype' }
      fields[:erp_code] = { renderer: :label, caption: 'ERP Code' }
      fields[:product_code] = { renderer: :label }
      fields[:description] = { renderer: :label }
      fields[:active] = { renderer: :label, as_boolean: true }
      fields[:composition_level] = { renderer: :label }
      fields[:basic_pack_id] = { renderer: :label, with_value: basic_pack_id_label, caption: 'Basic Pack' }
      fields[:material_mass] = { renderer: :label }
      fields[:height_mm] = { renderer: :label }
      fields[:gross_weight_per_unit] = { renderer: :label }
      fields[:items_per_unit] = { renderer: :label }
      fields[:items_per_unit_client_description] = { renderer: :label }
      fields[:marketing_size_range_mm] = { renderer: :label }
      fields[:minimum_size_mm] = { renderer: :label }
      fields[:maximum_size_mm] = { renderer: :label }
      fields[:average_size_mm] = { renderer: :label }
      fields[:marketing_weight_range] = { renderer: :label }
      fields[:minimum_weight_gm] = { renderer: :label }
      fields[:maximum_weight_gm] = { renderer: :label }
      fields[:average_weight_gm] = { renderer: :label }
    end

    def common_fields
      pm_subtypes = @repo.for_select_pm_type_subtypes
      pm_subtypes = @repo.for_select_non_fruit_composition_subtypes if @mode == :new
      {
        pm_subtype_id: { renderer: :select,
                         options: pm_subtypes,
                         disabled_options: @repo.for_select_inactive_pm_subtypes,
                         caption: 'PM Type and Subtype',
                         prompt: 'Select Type and Subtype',
                         searchable: true,
                         remove_search_for_small_list: false,
                         required: true },
        erp_code: { caption: 'ERP Code' },
        product_code: @repo.can_edit_product_code?(@form_object.pm_subtype_id) ? { force_uppercase: true } : { renderer: :label },
        description: {},
        composition_level: { renderer: :label },
        basic_pack_id: { renderer: :select,
                         options: @fruit_size_repo.for_select_basic_pack_codes,
                         disabled_options: @fruit_size_repo.for_select_inactive_basic_pack_codes,
                         caption: 'Basic Pack',
                         prompt: 'Select Basic Pack',
                         searchable: true,
                         remove_search_for_small_list: false },
        material_mass: { renderer: :numeric },
        height_mm: { renderer: :integer },
        gross_weight_per_unit: { renderer: :numeric },
        items_per_unit: { renderer: :integer },
        items_per_unit_client_description: {}
      }
    end

    def make_form_object
      if @mode == :new
        make_new_form_object
        return
      end

      pm_product = @repo.find_pm_product(@options[:id])
      extended_attrs = {}
      extended_attrs = @fruit_size_repo.find_std_fruit_size_count(pm_product.std_fruit_size_count_id).to_h if @repo.fruit_composition_level?(pm_product.pm_subtype_id)
      @form_object = OpenStruct.new(pm_product.to_h.merge(extended_attrs))
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
                                    items_per_unit: nil,
                                    items_per_unit_client_description: nil)
    end

    private

    def add_behaviours
      behaviours do |behaviour|
        behaviour.dropdown_change :pm_subtype_id, notify: [{ url: '/masterfiles/packaging/pm_products/pm_subtype_changed' }]
      end
    end

    def set_hide_on_load # rubocop:disable Metrics/AbcSize
      require_extended_packaging = %i[basic_pack_id
                                      material_mass
                                      height_mm
                                      gross_weight_per_unit
                                      items_per_unit
                                      items_per_unit_client_description
                                      marketing_size_range_mm
                                      minimum_size_mm
                                      maximum_size_mm
                                      average_size_mm
                                      marketing_weight_range
                                      minimum_weight_gm
                                      maximum_weight_gm
                                      average_weight_gm]
      (require_extended_packaging & fields.keys).each do |field|
        fields[field][:hide_on_load] ||= !@rules[:require_extended_packaging]
      end

      not_fruit_composition_level = %i[marketing_size_range_mm
                                       minimum_size_mm
                                       maximum_size_mm
                                       average_size_mm
                                       marketing_weight_range
                                       minimum_weight_gm
                                       maximum_weight_gm
                                       average_weight_gm]
      (not_fruit_composition_level & fields.keys).each do |field|
        fields[field][:hide_on_load] ||= !@rules[:fruit_composition_level]
      end

      fruit_composition_level = %i[material_mass
                                   height_mm]
      (fruit_composition_level & fields.keys).each do |field|
        fields[field][:hide_on_load] ||= @rules[:fruit_composition_level]
      end

      show_extra_fields = %i[gross_weight_per_unit
                             items_per_unit
                             items_per_unit_client_description]
      (show_extra_fields & fields.keys).each do |field|
        fields[field][:hide_on_load] ||= !@rules[:show_extra_fields]
      end

      minimum_composition_level = %i[basic_pack_id]
      (minimum_composition_level & fields.keys).each do |field|
        fields[field][:hide_on_load] ||= !@rules[:minimum_composition_level]
      end
    end
  end
end
