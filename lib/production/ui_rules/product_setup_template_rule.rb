# frozen_string_literal: true

module UiRules
  class ProductSetupTemplateRule < Base
    def generate_rules
      @repo = ProductionApp::ProductSetupRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields common_fields

      set_show_fields if %i[show reopen].include? @mode

      add_behaviours if %i[new edit].include? @mode

      form_name 'product_setup_template'
    end

    def set_show_fields  # rubocop:disable Metrics/AbcSize
      cultivar_group_id_label = @repo.find_hash(:cultivar_groups, @form_object.cultivar_group_id)[:cultivar_group_code]
      cultivar_id_label = MasterfilesApp::CultivarRepo.new.find_cultivar(@form_object.cultivar_id)&.cultivar_name
      packhouse_resource_id_label = ProductionApp::ResourceRepo.new.find_plant_resource(@form_object.packhouse_resource_id)&.plant_resource_code
      production_line_resource_id_label = ProductionApp::ResourceRepo.new.find_plant_resource(@form_object.production_line_resource_id)&.plant_resource_code
      season_group_id_label = MasterfilesApp::CalendarRepo.new.find_season_group(@form_object.season_group_id)&.season_group_code
      season_id_label = MasterfilesApp::CalendarRepo.new.find_season(@form_object.season_id)&.season_code
      fields[:template_name] = { renderer: :label }
      fields[:description] = { renderer: :label }
      fields[:cultivar_group_id] = { renderer: :label, with_value: cultivar_group_id_label, caption: 'Cultivar Group' }
      fields[:cultivar_id] = { renderer: :label, with_value: cultivar_id_label, caption: 'Cultivar' }
      fields[:packhouse_resource_id] = { renderer: :label, with_value: packhouse_resource_id_label, caption: 'Packhouse Resource' }
      fields[:production_line_resource_id] = { renderer: :label, with_value: production_line_resource_id_label, caption: 'Production Line Resource' }
      fields[:season_group_id] = { renderer: :label, with_value: season_group_id_label, caption: 'Season Group' }
      fields[:season_id] = { renderer: :label, with_value: season_id_label, caption: 'Season' }
      fields[:active] = { renderer: :label, as_boolean: true }
    end

    def common_fields  # rubocop:disable Metrics/AbcSize
      cultivar_group_id = @repo.find_product_setup_template(@options[:id])&.cultivar_group_id || @repo.cultivar_group_id
      {
        template_name: { required: true },
        description: {},
        cultivar_group_id: { renderer: :select,
                             options: MasterfilesApp::CultivarRepo.new.for_select_cultivar_groups,
                             disabled_options: MasterfilesApp::CultivarRepo.new.for_select_inactive_cultivar_groups,
                             caption: 'Cultivar Group',
                             required: true,
                             searchable: true,
                             remove_search_for_small_list: false },
        cultivar_id: { renderer: :select, options: MasterfilesApp::CultivarRepo.new.for_select_cultivars(where: { cultivar_group_id: cultivar_group_id }),
                       disabled_options: MasterfilesApp::CultivarRepo.new.for_select_inactive_cultivars,
                       caption: 'Cultivar',
                       prompt: 'Select Cultivar',
                       searchable: true,
                       remove_search_for_small_list: false },
        packhouse_resource_id: { renderer: :select, options: @repo.for_select_plant_resources('PACKHOUSE'),
                                 disabled_options: ProductionApp::ResourceRepo.new.for_select_inactive_plant_resources,
                                 caption: 'Packhouse',
                                 prompt: 'Select Packhouse',
                                 searchable: true,
                                 remove_search_for_small_list: false },
        production_line_resource_id: { renderer: :select, options: @repo.for_select_plant_resources('LINE'),
                                       disabled_options: ProductionApp::ResourceRepo.new.for_select_inactive_plant_resources,
                                       caption: 'Production Line',
                                       prompt: 'Select Production Line',
                                       searchable: true,
                                       remove_search_for_small_list: false },
        season_group_id: { renderer: :select, options: MasterfilesApp::CalendarRepo.new.for_select_season_groups,
                           disabled_options: MasterfilesApp::CalendarRepo.new.for_select_inactive_season_groups,
                           caption: 'Season Group',
                           prompt: 'Select Season Group',
                           searchable: true,
                           remove_search_for_small_list: false },
        season_id: { renderer: :select, options: MasterfilesApp::CalendarRepo.new.for_select_seasons,
                     disabled_options: MasterfilesApp::CalendarRepo.new.for_select_inactive_seasons,
                     caption: 'Season',
                     prompt: 'Select Season',
                     searchable: true,
                     remove_search_for_small_list: false }
      }
    end

    def make_form_object
      if @mode == :new
        make_new_form_object
        return
      end

      @form_object = @repo.find_product_setup_template(@options[:id])
    end

    def make_new_form_object
      @form_object = OpenStruct.new(template_name: nil,
                                    description: nil,
                                    cultivar_group_id: nil,
                                    cultivar_id: nil,
                                    packhouse_resource_id: nil,
                                    production_line_resource_id: nil,
                                    season_group_id: nil,
                                    season_id: nil)
    end

    private

    def add_behaviours
      behaviours do |behaviour|
        behaviour.dropdown_change :cultivar_group_id,
                                  notify: [{ url: '/production/product_setups/product_setup_templates/cultivar_group_changed' }]
        behaviour.dropdown_change :packhouse_resource_id,
                                  notify: [{ url: '/production/product_setups/product_setup_templates/packhouse_resource_changed' }]
        behaviour.dropdown_change :season_group_id,
                                  notify: [{ url: '/production/product_setups/product_setup_templates/season_group_changed' }]
      end
    end
  end
end
