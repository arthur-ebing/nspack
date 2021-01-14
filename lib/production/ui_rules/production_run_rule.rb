# frozen_string_literal: true

module UiRules
  class ProductionRunRule < Base # rubocop:disable Metrics/ClassLength
    def generate_rules # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      @repo = ProductionApp::ProductionRunRepo.new
      @resource_repo = ProductionApp::ResourceRepo.new
      @farm_repo = MasterfilesApp::FarmRepo.new
      @delivery_repo = RawMaterialsApp::RmtDeliveryRepo.new
      @cultivar_repo = MasterfilesApp::CultivarRepo.new
      make_form_object
      apply_form_values

      @rules[:allow_cultivar_group_mixing] = AppConst::ALLOW_CULTIVAR_GROUP_MIXING
      @rules[:show_bin_tipping_control_data] = (AppConst::CLIENT_CODE == 'kr')
      @rules[:show_bin_tipping_criteria] = (AppConst::CLIENT_CODE == 'kr')

      common_values_for_fields common_fields unless %i[allocate_setups allocate_target_customers complete_stage confirm].include?(@mode)

      set_show_fields if %i[show reopen template show_stats].include? @mode
      set_select_template_fields if @mode == :template
      make_header_table if @mode == :template
      make_header_table(%i[production_run_code template_name packhouse_code line_code status active_run_stage]) if %i[allocate_setups allocate_target_customers complete_stage show_stats confirm].include?(@mode)
      build_stats_table if @mode == :show_stats
      set_stage_fields if @mode == :complete_stage

      @rules[:locked_allocations] = true
      @rules[:locked_allocations] = false if @form_object.reconfiguring || !@form_object.setup_complete

      add_new_behaviours if @mode == :new
      add_edit_behaviours if @mode == :edit

      form_name 'production_run'
    end

    def set_show_fields # rubocop:disable Metrics/AbcSize
      farm_id_label = @farm_repo.find_farm(@form_object.farm_id)&.farm_code
      puc_id_label = @farm_repo.find_puc(@form_object.puc_id)&.puc_code
      season_id_label = MasterfilesApp::CalendarRepo.new.find_season(@form_object.season_id)&.season_code
      orchard_id_label = @farm_repo.find_orchard(@form_object.orchard_id)&.orchard_code
      cultivar_group_id_label = @cultivar_repo.find_cultivar_group(@form_object.cultivar_group_id)&.cultivar_group_code
      cultivar_id_label = @cultivar_repo.find_cultivar(@form_object.cultivar_id)&.cultivar_name

      fields[:farm_id] = { renderer: :label, with_value: farm_id_label, caption: 'Farm' }
      fields[:puc_id] = { renderer: :label, with_value: puc_id_label, caption: 'Puc' }
      fields[:season_id] = { renderer: :label, with_value: season_id_label, caption: 'Season' }
      fields[:orchard_id] = { renderer: :label, with_value: orchard_id_label, caption: 'Orchard' }
      fields[:cultivar_group_id] = { renderer: :label, with_value: cultivar_group_id_label, caption: 'Cultivar Group' }
      fields[:cultivar_id] = { renderer: :label, with_value: cultivar_id_label, caption: 'Cultivar' }
      fields[:allow_cultivar_mixing] = { renderer: :label, as_boolean: true }
      fields[:allow_orchard_mixing] = { renderer: :label, as_boolean: true }
      fields[:active] = { renderer: :label, as_boolean: true }
      fields[:allow_cultivar_group_mixing] = { renderer: :label,
                                               as_boolean: true,
                                               hide_on_load: @rules[:allow_cultivar_group_mixing] ? false : true }
    end

    def make_header_table(columns = nil, display_columns = 2)
      compact_header(columns: columns || %i[production_run_code template_name packhouse_code
                                            line_code farm_code puc_code orchard_code season_code
                                            cultivar_group_code cultivar_name allow_cultivar_group_mixing
                                            allow_cultivar_mixing allow_orchard_mixing status active_run_stage],
                     display_columns: display_columns,
                     header_captions: {
                       production_run_code: 'Run',
                       template_name: 'Template',
                       packhouse_code: 'Packhouse',
                       line_code: 'Line',
                       farm_code: 'Farm',
                       puc_code: 'PUC',
                       orchard_code: 'Orchard',
                       season_code: 'Season',
                       cultivar_group_code: 'Cultivar group',
                       cultivar_code: 'Cultivar',
                       allow_cultivar_group_mixing: 'Mix Cultivar Group?',
                       allow_cultivar_mixing: 'Mix Cultivar?',
                       allow_orchard_mixing: 'Mix Orchard?',
                       status: 'Status',
                       active_run_stage: 'Run stage'
                     })
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

    def set_stage_fields
      fields[:current_stage] = { renderer: :label, with_value: current_stage }
      fields[:new_stage] = { renderer: :label, with_value: next_stage }
    end

    def common_fields # rubocop:disable Metrics/AbcSize, Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
      if @mode == :new
        ph_renderer = { renderer: :select,
                        options: ProductionApp::ResourceRepo.new.for_select_plant_resources_of_type(Crossbeams::Config::ResourceDefinitions::PACKHOUSE),
                        disabled_options: ProductionApp::ResourceRepo.new.for_select_plant_resources_of_type(Crossbeams::Config::ResourceDefinitions::PACKHOUSE, active: false),
                        caption: 'Packhouse',
                        required: true }
        line_renderer = { renderer: :select,
                          options: @resource_repo.packhouse_lines(@form_object.packhouse_resource_id),
                          disabled_options: @resource_repo.packhouse_lines(@form_object.packhouse_resource_id, active: false),
                          caption: 'Production line',
                          required: true }
      else
        ph_renderer = { renderer: :label, with_value: @form_object.packhouse_code }
        line_renderer = { renderer: :label, with_value: @form_object.line_code }
      end

      if @form_object.reconfiguring
        farm_renderer = { renderer: :label, with_value: @form_object.farm_code }
        puc_renderer = { renderer: :label, with_value: @form_object.puc_code }
        orchard_renderer = { renderer: :label, with_value: @form_object.orchard_code }
      else
        farm_renderer = {
          renderer: :select,
          options: @farm_repo.for_select_farms,
          disabled_options: @farm_repo.for_select_inactive_farms,
          caption: 'Farm',
          prompt: true,
          required: true
        }
        puc_renderer = {
          renderer: :select,
          options: @farm_repo.selected_farm_pucs(where: { farm_id: @form_object.farm_id }),
          disabled_options: @farm_repo.for_select_inactive_pucs,
          caption: 'Puc',
          required: true
        }
        orchards = if @form_object.farm_id.nil_or_empty? || @form_object.puc_id.nil_or_empty?
                     []
                   else
                     @farm_repo.selected_farm_orchard_codes(@form_object.farm_id, @form_object.puc_id)
                   end
        orchard_renderer = {
          renderer: :select,
          options: orchards,
          disabled_options: @farm_repo.for_select_inactive_orchards,
          caption: 'Orchard'
        }
      end
      cultivar_groups = if @form_object.orchard_id.nil_or_empty?
                          []
                        else
                          orchard = @farm_repo.find_orchard(@form_object.orchard_id)
                          group_ids = @cultivar_repo.all_hash(:cultivars, id: orchard.cultivar_ids.to_a).map { |rec| rec[:cultivar_group_id] }.uniq
                          @cultivar_repo.for_select_cultivar_groups(where: { id: group_ids })
                        end
      cultivars = if @form_object.cultivar_group_id.nil_or_empty?
                    []
                  elsif @form_object.orchard_id.nil_or_empty?
                    @cultivar_repo.for_select_cultivars(where: { cultivar_group_id: @form_object.cultivar_group_id })
                  else
                    orchard = @farm_repo.find_orchard(@form_object.orchard_id)
                    @cultivar_repo.for_select_cultivars(where: { id: orchard.cultivar_ids.to_a })
                  end
      seasons = if @form_object.cultivar_group_id.nil_or_empty?
                  []
                else
                  MasterfilesApp::CalendarRepo.new.for_select_seasons_for_cultivar_group(@form_object.cultivar_group_id)
                end

      {
        packhouse_resource_id: ph_renderer,
        production_line_id: line_renderer,
        farm_id: farm_renderer,
        puc_id: puc_renderer,
        orchard_id: orchard_renderer,
        season_id: { renderer: :select,
                     options: seasons,
                     disabled_options: MasterfilesApp::CalendarRepo.new.for_select_inactive_seasons,
                     caption: 'Season',
                     required: true },
        cultivar_group_id: { renderer: :select,
                             options: cultivar_groups,
                             disabled_options: MasterfilesApp::CultivarRepo.new.for_select_inactive_cultivar_groups,
                             caption: 'Cultivar group' },
        cultivar_id: { renderer: :select,
                       options: cultivars,
                       disabled_options: MasterfilesApp::CultivarRepo.new.for_select_inactive_cultivars,
                       caption: 'Cultivar' },
        product_setup_template_id: { renderer: :label,
                                     with_value: product_setup_template_name,
                                     caption: 'Product setup template' },
        cloned_from_run_id: { renderer: :label,
                              with_value: cloned_run_label,
                              caption: 'Cloned from run' },
        active_run_stage: { renderer: :label },
        started_at: { renderer: :label, format: :without_timezone_or_seconds },
        closed_at: { renderer: :label, format: :without_timezone_or_seconds },
        re_executed_at: { renderer: :label, format: :without_timezone_or_seconds },
        completed_at: { renderer: :label, format: :without_timezone_or_seconds },
        allow_cultivar_mixing: { renderer: :checkbox },
        allow_orchard_mixing: { renderer: :checkbox },
        reconfiguring: { renderer: :label, as_boolean: true },
        running: { renderer: :label, as_boolean: true },
        tipping: { renderer: :label, as_boolean: true },
        labeling: { renderer: :label, as_boolean: true },
        closed: { renderer: :label, as_boolean: true },
        setup_complete: { renderer: :label, as_boolean: true },
        completed: { renderer: :label, as_boolean: true },
        allow_cultivar_group_mixing: { renderer: :checkbox,
                                       hide_on_load: @rules[:allow_cultivar_group_mixing] ? false : true }
      }
    end

    def build_stats_table
      stats = @repo.where_hash(:production_run_stats, production_run_id: @options[:id])
      rules[:detail_cols] = %i[
        bins_tipped
        bins_tipped_weight
        carton_labels_printed
        cartons_verified
        cartons_verified_weight
        inspected_pallets
        pallets_palletized_full
        pallets_palletized_partial
        pallet_weight
        rebins_created
        rebins_weight
      ]
      rules[:detail_rows] = [stats]
      rules[:detail_alignment] = {
        bins_tipped: :right,
        bins_tipped_weight: :right,
        carton_labels_printed: :right,
        cartons_verified: :right,
        cartons_verified_weight: :right,
        inspected_pallets: :right,
        pallets_palletized_full: :right,
        pallets_palletized_partial: :right,
        pallet_weight: :right,
        rebins_created: :right,
        rebins_weight: :right
      }
      rules[:cell_transformers] = {
        bins_tipped_weight: :decimal,
        cartons_verified_weight: :decimal,
        pallet_weight: :decimal,
        rebins_weight: :decimal
      }
    end

    def make_form_object
      if @mode == :new
        make_new_form_object
        return
      end

      @form_object = @repo.find_production_run_flat(@options[:id])
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
                                    tipping: nil,
                                    labeling: nil,
                                    closed: nil,
                                    setup_complete: nil,
                                    completed: nil,
                                    allow_cultivar_group_mixing: nil)
    end

    private

    def current_stage
      if @form_object.tipping && @form_object.labeling
        'TIPPING AND LABELING'
      elsif @form_object.tipping
        'TIPPING'
      else
        'LABELING'
      end
    end

    def next_stage
      if @options[:complete_run] || (@form_object.labeling && !@form_object.tipping)
        'COMPLETED'
      else
        'LABELING'
      end
    end

    def cloned_run_label
      return '' if @form_object.cloned_from_run_id.nil_or_empty?

      @form_object.cloned_from_run_code
    end

    def product_setup_template_name
      return '' if @form_object.product_setup_template_id.nil_or_empty?

      @form_object.template_name
    end

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
                                  notify: [{ url: '/production/runs/production_runs/changed/cultivar_group',
                                             param_keys: %i[production_run_orchard_id] }]
      end
    end

    def add_edit_behaviours
      if @form_object.reconfiguring
        behaviours do |behaviour|
          behaviour.dropdown_change :cultivar_group_id,
                                    notify: [{ url: '/production/runs/production_runs/changed/cultivar_group',
                                               param_keys: %i[production_run_orchard_id] }]
        end
      else
        behaviours do |behaviour|
          behaviour.dropdown_change :farm_id,
                                    notify: [{ url: '/production/runs/production_runs/changed/farm' }]
          behaviour.dropdown_change :puc_id,
                                    notify: [{ url: '/production/runs/production_runs/changed/puc',
                                               param_keys: %i[production_run_farm_id] }]
          behaviour.dropdown_change :orchard_id,
                                    notify: [{ url: '/production/runs/production_runs/changed/orchard' }]
          behaviour.dropdown_change :cultivar_group_id,
                                    notify: [{ url: '/production/runs/production_runs/changed/cultivar_group',
                                               param_keys: %i[production_run_orchard_id] }]
        end
      end
    end
  end
end
