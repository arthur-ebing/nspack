# frozen_string_literal: true

module UiRules
  class BinLoadProductRule < Base # rubocop:disable Metrics/ClassLength
    def generate_rules
      set_repo
      make_form_object
      apply_form_values

      common_values_for_fields common_fields

      set_show_fields if %i[show reopen].include? @mode

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
      fields[:puc_id] = { renderer: :label, with_value: @form_object.puc_code, caption: 'Puc' }
      fields[:orchard_id] = { renderer: :label, with_value: @form_object.orchard_code, caption: 'Orchard' }
      fields[:rmt_class_id] = { renderer: :label, with_value: @form_object.rmt_class_code, caption: 'Rmt Class' }
      fields[:active] = { renderer: :label, as_boolean: true }
    end

    def common_fields # rubocop:disable Metrics/AbcSize
      cultivar_ids = @repo.select_values(:rmt_bins, :cultivar_id, exit_ref: nil)
      cultivar_group_ids = @repo.select_values(:cultivars, :cultivar_group_id, id: cultivar_ids)

      farm_ids = @repo.select_values(:rmt_bins, :farm_id, exit_ref: nil)
      puc_ids = @repo.select_values(:rmt_bins, :puc_id, exit_ref: nil)
      orchard_ids = @repo.select_values(:rmt_bins, :orchard_id, exit_ref: nil)

      {
        bin_load_id: { renderer: :select,
                       options: @repo.for_select_bin_loads,
                       disabled_options: @repo.for_select_inactive_bin_loads,
                       caption: 'Bin Load',
                       hide_on_load: true,
                       required: true },
        qty_bins: { renderer: :numeric,
                    required: true },
        cultivar_group_id: { renderer: :select,
                             options: @cultivar_repo.for_select_cultivar_groups(where: { id: cultivar_group_ids }),
                             disabled_options: @cultivar_repo.for_select_inactive_cultivar_groups,
                             prompt: true,
                             caption: 'Cultivar Group',
                             required: true },
        cultivar_id: { renderer: :select,
                       options: @cultivar_repo.for_select_cultivars(where: { cultivar_group_id: @form_object.cultivar_group_id,  id: cultivar_ids }),
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
                   options: @farm_repo.for_select_farms(where: { id: farm_ids }),
                   disabled_options: @farm_repo.for_select_inactive_farms,
                   prompt: true,
                   caption: 'Farm' },
        puc_id: { renderer: :select,
                  options: @farm_repo.for_select_pucs(where: { id: puc_ids }),
                  disabled_options: @farm_repo.for_select_inactive_pucs,
                  prompt: true,
                  caption: 'Puc' },
        orchard_id: { renderer: :select,
                      options: @farm_repo.for_select_orchards(where: { puc_id: @form_object.puc_id, id: orchard_ids }),
                      disabled_options: @farm_repo.for_select_inactive_orchards,
                      prompt: true,
                      hide_on_load: @form_object.puc_id.nil?,
                      caption: 'Orchard' },
        rmt_class_id: { renderer: :select,
                        options: @fruit_repo.for_select_rmt_classes,
                        disabled_options: @fruit_repo.for_select_inactive_rmt_classes,
                        prompt: true,
                        caption: 'Rmt Class' }
      }
    end

    def make_form_object
      if @mode == :new
        make_new_form_object
        return
      end

      @form_object = @repo.find_bin_load_product_flat(@options[:id])
    end

    def make_new_form_object
      @form_object = OpenStruct.new(bin_load_id: nil,
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
