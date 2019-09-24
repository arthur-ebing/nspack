# frozen_string_literal: true

module UiRules
  class ProductionRunRule < Base # rubocop:disable Metrics/ClassLength
    def generate_rules
      @repo = ProductionApp::ProductionRunRepo.new
      @resource_repo = ProductionApp::ResourceRepo.new
      @farm_repo = MasterfilesApp::FarmRepo.new
      @delivery_repo = RawMaterialsApp::RmtDeliveryRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields common_fields

      set_show_fields if %i[show reopen template].include? @mode
      set_select_template_fields if @mode == :template

      add_new_behaviours if @mode == :new

      form_name 'production_run'
    end

    def set_show_fields # rubocop:disable Metrics/AbcSize
      farm_id_label = @farm_repo.find_farm(@form_object.farm_id)&.farm_code
      puc_id_label = @farm_repo.find_puc(@form_object.puc_id)&.puc_code
      packhouse_resource_id_label = @resource_repo.find_plant_resource(@form_object.packhouse_resource_id)&.plant_resource_code
      production_line_id_label = @resource_repo.find_plant_resource(@form_object.production_line_id)&.plant_resource_code
      season_id_label = @repo.find(:seasons, MasterfilesApp::Season, @form_object.season_id)&.season_code
      orchard_id_label = @farm_repo.find_orchard(@form_object.orchard_id)&.orchard_code
      cultivar_group_id_label = MasterfilesApp::CultivarRepo.new.find_cultivar_group(@form_object.cultivar_group_id)&.cultivar_group_code
      cultivar_id_label = MasterfilesApp::CultivarRepo.new.find_cultivar(@form_object.cultivar_id)&.cultivar_name
      product_setup_template_id_label = ProductionApp::ProductSetupRepo.new.find_product_setup_template(@form_object.product_setup_template_id)&.template_name
      cloned_from_run_id_label = @repo.find_production_run_with_assoc(@form_object.cloned_from_run_id)&.production_run_code

      fields[:farm_id] = { renderer: :label, with_value: farm_id_label, caption: 'Farm' }
      fields[:puc_id] = { renderer: :label, with_value: puc_id_label, caption: 'Puc' }
      fields[:packhouse_resource_id] = { renderer: :label, with_value: packhouse_resource_id_label, caption: 'Packhouse Resource' }
      fields[:production_line_id] = { renderer: :label, with_value: production_line_id_label, caption: 'Production Line' }
      fields[:season_id] = { renderer: :label, with_value: season_id_label, caption: 'Season' }
      fields[:orchard_id] = { renderer: :label, with_value: orchard_id_label, caption: 'Orchard' }
      fields[:cultivar_group_id] = { renderer: :label, with_value: cultivar_group_id_label, caption: 'Cultivar Group' }
      fields[:cultivar_id] = { renderer: :label, with_value: cultivar_id_label, caption: 'Cultivar' }
      fields[:product_setup_template_id] = { renderer: :label, with_value: product_setup_template_id_label, caption: 'Product Setup Template' }
      fields[:cloned_from_run_id] = { renderer: :label, with_value: cloned_from_run_id_label, caption: 'Cloned From Run' }
      fields[:active_run_stage] = { renderer: :label }
      fields[:started_at] = { renderer: :label }
      fields[:closed_at] = { renderer: :label }
      fields[:re_executed_at] = { renderer: :label }
      fields[:completed_at] = { renderer: :label }
      fields[:allow_cultivar_mixing] = { renderer: :label, as_boolean: true }
      fields[:allow_orchard_mixing] = { renderer: :label, as_boolean: true }
      fields[:reconfiguring] = { renderer: :label, as_boolean: true }
      fields[:running] = { renderer: :label, as_boolean: true }
      fields[:closed] = { renderer: :label, as_boolean: true }
      fields[:setup_complete] = { renderer: :label, as_boolean: true }
      fields[:completed] = { renderer: :label, as_boolean: true }
      fields[:active] = { renderer: :label, as_boolean: true }
    end

    def set_select_template_fields
      fields[:product_setup_template_id] = { renderer: :lookup,
                                             lookup_name: :product_setup_templates_for_runs,
                                             lookup_key: :standard,
                                             param_values: { run_id: @options[:id] },
                                             hidden_fields: %i[product_setup_template_id],
                                             show_field: :template_name,
                                             caption: 'Select Template' }
    end

    def common_fields # rubocop:disable Metrics/AbcSize
      {
        packhouse_resource_id: { renderer: :select,
                                 options: ProductionApp::ResourceRepo.new.for_select_plant_resources_of_type(Crossbeams::Config::ResourceDefinitions::PACKHOUSE),
                                 disabled_options: ProductionApp::ResourceRepo.new.for_select_plant_resources_of_type(Crossbeams::Config::ResourceDefinitions::PACKHOUSE, active: false),
                                 caption: 'Packhouse',
                                 required: true },
        production_line_id: { renderer: :select,
                              options: @resource_repo.packhouse_lines(@form_object.packhouse_resource_id),
                              disabled_options: @resource_repo.packhouse_lines(@form_object.packhouse_resource_id, active: false),
                              caption: 'Production line',
                              required: true },
        farm_id: { renderer: :select,
                   options: @farm_repo.for_select_farms,
                   disabled_options: @farm_repo.for_select_inactive_farms,
                   caption: 'Farm',
                   required: true },
        puc_id: { renderer: :select,
                  options: @farm_repo.for_select_pucs,
                  disabled_options: @farm_repo.for_select_inactive_pucs,
                  caption: 'Puc',
                  required: true },
        season_id: { renderer: :select,
                     options: MasterfilesApp::CalendarRepo.new.for_select_seasons,
                     disabled_options: MasterfilesApp::CalendarRepo.new.for_select_inactive_seasons,
                     caption: 'Season',
                     required: true },
        orchard_id: { renderer: :select,
                      options: @farm_repo.for_select_orchards,
                      disabled_options: @farm_repo.for_select_inactive_orchards,
                      caption: 'Orchard' },
        cultivar_group_id: { renderer: :select,
                             options: MasterfilesApp::CultivarRepo.new.for_select_cultivar_groups,
                             disabled_options: MasterfilesApp::CultivarRepo.new.for_select_inactive_cultivar_groups,
                             caption: 'Cultivar group' },
        cultivar_id: { renderer: :select,
                       options: MasterfilesApp::CultivarRepo.new.for_select_cultivars,
                       disabled_options: MasterfilesApp::CultivarRepo.new.for_select_inactive_cultivars,
                       caption: 'Cultivar' },
        product_setup_template_id: { renderer: :select,
                                     options: ProductionApp::ProductSetupRepo.new.for_select_product_setup_templates,
                                     disabled_options: ProductionApp::ProductSetupRepo.new.for_select_inactive_product_setup_templates,
                                     caption: 'Product setup template' },
        cloned_from_run_id: { renderer: :select,
                              options: @repo.for_select_production_runs,
                              disabled_options: @repo.for_select_inactive_production_runs,
                              caption: 'Cloned from run' },
        active_run_stage: {},
        started_at: {},
        closed_at: {},
        re_executed_at: {},
        completed_at: {},
        allow_cultivar_mixing: { renderer: :checkbox },
        allow_orchard_mixing: { renderer: :checkbox },
        reconfiguring: { renderer: :checkbox },
        running: { renderer: :checkbox },
        closed: { renderer: :checkbox },
        setup_complete: { renderer: :checkbox },
        completed: { renderer: :checkbox }
      }
    end

    def make_form_object
      if @mode == :new
        make_new_form_object
        return
      end

      @form_object = @repo.find_production_run_with_assoc(@options[:id])
    end

    def make_new_form_object
      packhouse_id = @resource_repo.for_select_plant_resources_of_type(Crossbeams::Config::ResourceDefinitions::PACKHOUSE)&.first&.last
      line_id = @resource_repo.packhouse_lines(packhouse_id)&.first&.last if packhouse_id
      res = @delivery_repo.default_farm_puc
      @form_object = OpenStruct.new(farm_id: res[:farm_id],
                                    puc_id: res[:puc_id],
                                    packhouse_resource_id: packhouse_id,
                                    production_line_id: line_id,
                                    season_id: nil,
                                    orchard_id: nil,
                                    cultivar_group_id: nil,
                                    cultivar_id: nil,
                                    product_setup_template_id: nil,
                                    cloned_from_run_id: nil,
                                    active_run_stage: nil,
                                    started_at: nil,
                                    closed_at: nil,
                                    re_executed_at: nil,
                                    completed_at: nil,
                                    allow_cultivar_mixing: nil,
                                    allow_orchard_mixing: nil,
                                    reconfiguring: nil,
                                    running: nil,
                                    closed: nil,
                                    setup_complete: nil,
                                    completed: nil)
    end

    private

    def add_new_behaviours
      behaviours do |behaviour|
        behaviour.dropdown_change :packhouse_resource_id,
                                  notify: [{ url: '/production/runs/production_runs/changed/packhouse' }]
        behaviour.dropdown_change :farm_id,
                                  notify: [{ url: '/production/runs/production_runs/changed/farm' }]
        behaviour.dropdown_change :puc_id,
                                  notify: [{ url: '/production/runs/production_runs/changed/puc',
                                             param_keys: %i[production_run_farm_id] }]
        behaviour.dropdown_change :orchard_id,
                                  notify: [{ url: '/production/runs/production_runs/changed/orchard' }]
        behaviour.dropdown_change :cultivar_group_id,
                                  notify: [{ url: '/production/runs/production_runs/changed/cultivar_group' }]
      end
    end
  end
end
