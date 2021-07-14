# frozen_string_literal: true

module UiRules
  class BinLoadProductRule < Base # rubocop:disable Metrics/ClassLength
    def generate_rules
      set_repo
      make_form_object
      apply_form_values

      common_values_for_fields common_fields

      set_show_fields if %i[show].include? @mode

      if @mode == :scan_bins
        make_scan_bins_header_table
        set_scan_bins_fields
      end

      add_behaviours

      form_name 'bin_load_product'
    end

    def set_show_fields # rubocop:disable Metrics/AbcSize
      fields[:bin_load_id] = { renderer: :label, with_value: @form_object.bin_load_id, caption: 'Bin Load' }
      fields[:qty_bins] = { renderer: :label }
      fields[:cultivar_id] = { renderer: :label, with_value: @form_object.cultivar_name, caption: 'Cultivar' }
      fields[:cultivar_group_id] = { renderer: :label, with_value: @form_object.cultivar_group_code, caption: 'Cultivar Group' }
      fields[:rmt_container_material_type_id] = { renderer: :label, with_value: @form_object.container_material_type_code, caption: 'Container Type' }
      fields[:rmt_material_owner_party_role_id] = { renderer: :label, with_value: @form_object.container_material_owner, caption: 'Container Owner' }
      fields[:farm_id] = { renderer: :label, with_value: @form_object.farm_code, caption: 'Farm' }
      fields[:puc_id] = { renderer: :label, with_value: @form_object.puc_code, caption: 'PUC' }
      fields[:orchard_id] = { renderer: :label, with_value: @form_object.orchard_code, caption: 'Orchard' }
      fields[:rmt_class_id] = { renderer: :label, with_value: @form_object.rmt_class_code, caption: 'RMT Class' }
      fields[:active] = { renderer: :label, as_boolean: true }
    end

    def common_fields # rubocop:disable Metrics/AbcSize
      {
        bin_load_id: { renderer: :hidden,
                       with_value: @form_object.bin_load_id,
                       caption: 'Bin Load' },
        qty_bins: { renderer: :integer,
                    maxvalue: AppConst::CR_FG.max_bin_count_for_load?,
                    minvalue: 1,
                    required: true },
        cultivar_group_id: { renderer: :select,
                             options: @cultivar_repo.for_select_cultivar_groups,
                             disabled_options: @cultivar_repo.for_select_inactive_cultivar_groups,
                             prompt: true,
                             caption: 'Cultivar Group',
                             required: true },
        cultivar_id: { renderer: :select,
                       options: @cultivar_repo.for_select_cultivars(where: { cultivar_group_id: @form_object.cultivar_group_id }),
                       disabled_options: @cultivar_repo.for_select_inactive_cultivars,
                       prompt: true,
                       caption: 'Cultivar' },
        rmt_container_material_type_id: { renderer: :select,
                                          options: @container.for_select_rmt_container_material_types,
                                          disabled_options: @container.for_select_inactive_rmt_container_material_types,
                                          prompt: true,
                                          caption: 'Container Type' },
        rmt_material_owner_party_role_id: { renderer: :select,
                                            options: @party_repo.for_select_party_roles(AppConst::ROLE_RMT_BIN_OWNER),
                                            prompt: true,
                                            caption: 'Container Owner' },
        farm_id: { renderer: :select,
                   options: @farm_repo.for_select_farms,
                   disabled_options: @farm_repo.for_select_inactive_farms,
                   prompt: true,
                   caption: 'Farm' },
        puc_id: { renderer: :select,
                  options: @farm_repo.for_select_pucs,
                  disabled_options: @farm_repo.for_select_inactive_pucs,
                  prompt: true,
                  caption: 'PUC' },
        orchard_id: { renderer: :select,
                      options: @farm_repo.for_select_orchards(where: { puc_id: @form_object.puc_id }),
                      disabled_options: @farm_repo.for_select_inactive_orchards,
                      prompt: true,
                      hide_on_load: @form_object.puc_id.nil?,
                      caption: 'Orchard' },
        rmt_class_id: { renderer: :select,
                        options: @fruit_repo.for_select_rmt_classes,
                        disabled_options: @fruit_repo.for_select_inactive_rmt_classes,
                        prompt: true,
                        caption: 'RMT Class' }
      }
    end

    def make_scan_bins_header_table(columns = nil, display_columns = 3)
      compact_header(columns: columns || %i[qty_bins cultivar_group_code cultivar_name container_material_type_code
                                            container_material_owner farm_code puc_code orchard_code rmt_class_code],
                     display_columns: display_columns,
                     header_captions: {
                       cultivar_group_code: 'Cultivar Group',
                       cultivar_name: 'Cultivar',
                       container_material_type_code: 'Material Type',
                       container_material_owner: 'Material Owner',
                       farm_code: 'Farm',
                       puc_code: 'Puc',
                       orchard_code: 'Orchard',
                       rmt_class_code: 'Class'
                     })
    end

    def set_scan_bins_fields
      fields[:bin_ids] = { renderer: :textarea,
                           rows: 12,
                           placeholder: 'Scan bins here',
                           caption: 'RMT Bins',
                           required: true }
    end

    def make_form_object
      if @mode == :new
        make_new_form_object
        return
      end

      @form_object = @repo.find_bin_load_product_flat(@options[:id])
      @form_object = OpenStruct.new(@form_object.to_h.merge(bin_ids: nil)) if @mode == :scan_bins
    end

    def make_new_form_object
      @form_object = OpenStruct.new(bin_load_id: @options[:bin_load_id],
                                    qty_bins: nil,
                                    cultivar_id: nil,
                                    cultivar_group_id: nil,
                                    rmt_container_material_type_id: nil,
                                    rmt_material_owner_party_role_id: nil,
                                    farm_id: nil,
                                    puc_id: nil,
                                    orchard_id: nil,
                                    rmt_class_id: nil)
    end

    private

    def set_repo
      @repo = RawMaterialsApp::BinLoadRepo.new
      @party_repo = MasterfilesApp::PartyRepo.new
      @cultivar_repo = MasterfilesApp::CultivarRepo.new
      @farm_repo = MasterfilesApp::FarmRepo.new
      @fruit_repo = MasterfilesApp::FruitRepo.new
      @container = MasterfilesApp::RmtContainerMaterialTypeRepo.new
    end

    def add_behaviours
      behaviours do |behaviour|
        behaviour.dropdown_change :cultivar_group_id, notify: [{ url: '/raw_materials/dispatch/bin_load_products/cultivar_group_changed' }]
        behaviour.dropdown_change :rmt_container_material_type_id, notify: [{ url: '/raw_materials/dispatch/bin_load_products/rmt_container_material_type_changed' }]
        behaviour.dropdown_change :farm_id, notify: [{ url: '/raw_materials/dispatch/bin_load_products/farm_changed' }]
        behaviour.dropdown_change :puc_id, notify: [{ url: '/raw_materials/dispatch/bin_load_products/puc_changed' }]
      end
    end
  end
end
