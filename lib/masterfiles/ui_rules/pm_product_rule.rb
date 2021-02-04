# frozen_string_literal: true

module UiRules
  class PmProductRule < Base # rubocop:disable Metrics/ClassLength
    def generate_rules
      @repo = MasterfilesApp::BomRepo.new
      @fruit_size_repo = MasterfilesApp::FruitSizeRepo.new
      make_form_object
      apply_form_values
      apply_form_rules

      common_values_for_fields common_fields
      set_hide_on_load

      set_show_fields if %i[show].include? @mode

      add_behaviours if %i[new edit].include? @mode

      form_name 'pm_product'
    end

    def set_show_fields # rubocop:disable Metrics/AbcSize
      fields[:pm_type_code] = { renderer: :label, caption: 'PKG Type' }
      fields[:pm_subtype_code] = { renderer: :label, caption: 'PKG Subtype' }
      fields[:erp_code] = { renderer: :label, caption: 'ERP Code' }
      fields[:product_code] = { renderer: :label }
      fields[:description] = { renderer: :label }
      fields[:composition_level] = { renderer: :label }
      fields[:basic_pack_code] = { renderer: :label, caption: 'Basic Pack' }
      fields[:material_mass] = { renderer: :label, caption: 'Material Mass (kg)' }
      fields[:height_mm] = { renderer: :label, caption: 'Height (mm)' }
      fields[:gross_weight_per_unit] = { renderer: :label, caption: 'Gross Weight per Unit (kg)' }
      fields[:items_per_unit] = { renderer: :label }
      fields[:items_per_unit_client_description] = { renderer: :label }
      fields[:marketing_size_range_mm] = { renderer: :label, caption: 'Marketing Size Range (mm)' }
      fields[:minimum_size_mm] = { renderer: :label, caption: 'Minimum Size (mm)' }
      fields[:maximum_size_mm] = { renderer: :label, caption: 'Maximum Size (mm)' }
      fields[:average_size_mm] = { renderer: :label, caption: 'Average Size (mm)' }
      fields[:marketing_weight_range] = { renderer: :label, caption: 'Marketing Weight Range (mm)' }
      fields[:minimum_weight_gm] = { renderer: :label, caption: 'Minimum Weight (kg)' }
      fields[:maximum_weight_gm] = { renderer: :label, caption: 'Maximum Weight (kg)' }
      fields[:average_weight_gm] = { renderer: :label, caption: 'Average Weight (kg)' }
      fields[:active] = { renderer: :label, as_boolean: true }
    end

    def common_fields
      {
        pm_subtype_id: { renderer: :select,
                         options: @repo.for_select_pm_subtypes(grouped: true),
                         disabled_options: @repo.for_select_inactive_pm_subtypes,
                         caption: 'PKG Subtype',
                         prompt: true,
                         searchable: true,
                         required: true },
        pm_subtype: { renderer: :label,
                      with_value: @form_object.subtype_code,
                      caption: 'PKG Subtype' },
        erp_code: { caption: 'ERP Code' },
        product_code: { renderer: :label },
        description: {},
        composition_level: { renderer: :label },
        basic_pack_id: { renderer: :select,
                         options: @fruit_size_repo.for_select_basic_packs,
                         disabled_options: @fruit_size_repo.for_select_inactive_basic_packs,
                         caption: 'Basic Pack',
                         prompt: 'Select Basic Pack',
                         searchable: true,
                         remove_search_for_small_list: false },
        material_mass: { renderer: :numeric, caption: 'Material Mass (kg)' },
        height_mm: { renderer: :integer, caption: 'Height (mm)' },
        gross_weight_per_unit: { renderer: :numeric, caption: 'Gross Weight per Unit (kg)' },
        items_per_unit: { renderer: :integer, caption: 'Items per Unit' },
        items_per_unit_client_description: {}
      }
    end

    def make_form_object # rubocop:disable Metrics/AbcSize
      if @mode == :new
        make_new_form_object
        return
      end

      pm_product = @repo.find_pm_product(@options[:id])
      pm_subtype = @repo.find_pm_subtype(pm_product.pm_subtype_id)
      std_fruit_size_count = @fruit_size_repo.find_std_fruit_size_count(pm_product.std_fruit_size_count_id)
      @form_object = OpenStruct.new(pm_product.to_h
                                      .merge(@options[:form_values].to_h)
                                      .merge(pm_subtype.to_h)
                                      .merge(std_fruit_size_count.to_h))
    end

    def make_new_form_object
      hash = { pm_subtype_id: nil,
               erp_code: nil,
               product_code: nil,
               description: nil,
               material_mass: nil,
               height_mm: nil,
               basic_pack_id: nil,
               gross_weight_per_unit: nil,
               items_per_unit: nil,
               items_per_unit_client_description: nil }
      pm_subtype = @repo.find_pm_subtype(@options[:form_values][:pm_subtype_id]) if @options[:form_values]
      @form_object = OpenStruct.new(hash
                                      .merge(@options[:form_values].to_h)
                                      .merge(pm_subtype.to_h))
    end

    private

    def add_behaviours
      behaviours do |behaviour|
        behaviour.dropdown_change :pm_subtype_id, notify: [{ url: '/masterfiles/packaging/pm_products/pm_subtype_changed' }]
        behaviour.dropdown_change :basic_pack_id, notify: [{ url: '/masterfiles/packaging/pm_products/basic_pack_changed' }]
      end
    end

    def apply_form_rules
      @rules[:require_extended_packaging] = AppConst::REQUIRE_EXTENDED_PACKAGING
      @rules[:minimum_composition_level] = @form_object.minimum_composition_level
      @rules[:fruit_composition_level] = @form_object.fruit_composition_level
      @rules[:show_extra_fields] = !(@rules[:minimum_composition_level] || @rules[:fruit_composition_level])
    end

    def set_hide_on_load # rubocop:disable Metrics/AbcSize
      field_keys = %i[composition_level
                      description
                      pm_subtype
                      erp_code]
      (field_keys & fields.keys).each do |field|
        fields[field][:show_element] ||= true
      end

      fields[:pm_subtype_id][:show_element] = @mode != :edit

      field_keys = %i[marketing_size_range_mm
                      minimum_size_mm
                      maximum_size_mm
                      average_size_mm
                      marketing_weight_range
                      minimum_weight_gm
                      maximum_weight_gm
                      average_weight_gm]
      (field_keys & fields.keys).each do |field|
        fields[field][:show_element] ||= @rules[:fruit_composition_level]
      end

      field_keys = %i[gross_weight_per_unit
                      items_per_unit
                      items_per_unit_client_description]
      (field_keys & fields.keys).each do |field|
        fields[field][:show_element] ||= @rules[:show_extra_fields]
      end

      field_keys = %i[basic_pack_id
                      material_mass
                      height_mm]
      (field_keys & fields.keys).each do |field|
        fields[field][:show_element] ||= @rules[:minimum_composition_level]
      end

      fields.each_key do |key|
        fields[key][:hide_on_load] = !fields[key].delete(:show_element)
      end
    end
  end
end
