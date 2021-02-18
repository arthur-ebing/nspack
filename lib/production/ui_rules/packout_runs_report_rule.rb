# frozen_string_literal: true

module UiRules
  class PackoutRunsReportRule < Base # rubocop:disable Metrics/ClassLength
    def generate_rules
      @resource_repo = ProductionApp::ResourceRepo.new
      # @farm_repo = MasterfilesApp::FarmRepo.new
      # @cultivar_repo = MasterfilesApp::CultivarRepo.new
      @prod_setup_repo = ProductionApp::ProductSetupRepo.new
      @calender_repo = MasterfilesApp::CalendarRepo.new
      make_new_form_object
      common_values_for_fields common_fields
      add_behaviours
      form_name 'packout_runs_report'
    end

    def common_fields # rubocop:disable Metrics/AbcSize
      {
        farm_id: { renderer: :select,
                   options: farm_repo.for_select_farms,
                   disabled_options: farm_repo.for_select_inactive_farms,
                   prompt: 'Select Farm',
                   caption: 'Farm' },
        puc_id: { renderer: :select,
                  options: farm_repo.for_select_pucs,
                  disabled_options: farm_repo.for_select_inactive_pucs,
                  prompt: 'Select PUC',
                  caption: 'PUC' },
        orchard_id: { renderer: :select,
                      options: [], # farm_repo.for_select_orchards,
                      prompt: 'Select Orchard',
                      caption: 'Orchard' },
        cultivar_group_id: { renderer: :select,
                             options: cultivar_repo.for_select_cultivar_groups,
                             disabled_options: cultivar_repo.for_select_inactive_cultivar_groups,
                             prompt: 'Select Cultivar Group',
                             caption: 'Cultivar Group' },
        cultivar_id: { renderer: :select,
                       options: cultivar_repo.for_select_cultivars,
                       disabled_options: cultivar_repo.for_select_inactive_cultivars,
                       prompt: 'Select Cultivar',
                       caption: 'Cultivar' },
        packhouse_resource_id: { renderer: :select,
                                 options: @resource_repo.for_select_plant_resources_of_type(Crossbeams::Config::ResourceDefinitions::PACKHOUSE),
                                 disabled_options: @resource_repo.for_select_plant_resources_of_type(Crossbeams::Config::ResourceDefinitions::PACKHOUSE, active: false),
                                 prompt: 'Select Packhouse',
                                 caption: 'Packhouse' },
        production_line_id: { renderer: :select, options: [], # @prod_setup_repo.for_select_plant_resources(Crossbeams::Config::ResourceDefinitions::LINE),
                              caption: 'Production Line',
                              prompt: 'Select Production Line',
                              searchable: true,
                              remove_search_for_small_list: false },
        season_id: { renderer: :select, options: @calender_repo.for_select_seasons,
                     disabled_options: @calender_repo.for_select_inactive_seasons,
                     caption: 'Season',
                     prompt: 'Select Season',
                     searchable: true,
                     remove_search_for_small_list: false },
        dispatches_only: { renderer: :checkbox },
        use_derived_weight: { renderer: :checkbox }
      }
    end

    def make_new_form_object
      @form_object = OpenStruct.new(farm_id: nil,
                                    puc_id: nil,
                                    packhouse_resource_id: nil,
                                    production_line_id: nil,
                                    orchard_id: nil,
                                    cultivar_group_id: nil,
                                    cultivar_id: nil,
                                    dispatches_only: nil,
                                    use_derived_weight: nil,
                                    season_id: nil)
    end

    def handle_behaviour
      case @mode
      when :farm
        farm_change
      when :puc
        puc_change
      when :orchard
        orchard_change
      when :cultivar_group
        cultivar_group_change
      when :packhouse
        packhouse_change
      else
        unhandled_behaviour!
      end
    end

    private

    def farm_change
      where = @params[:changed_value].nil_or_empty? ? {} : { farm_id: @params[:changed_value] }
      pucs = farm_repo.for_select_pucs(where: where)

      json_actions([OpenStruct.new(type: :replace_select_options,
                                   dom_id: 'packout_runs_report_puc_id',
                                   options_array: pucs),
                    OpenStruct.new(type: :replace_select_options,
                                   dom_id: 'packout_runs_report_orchard_id',
                                   options_array: []),
                    OpenStruct.new(type: :replace_select_options,
                                   dom_id: 'packout_runs_report_cultivar_id',
                                   options_array: cultivar_repo.for_select_cultivars),
                    OpenStruct.new(type: :replace_select_options,
                                   dom_id: 'packout_runs_report_cultivar_group_id',
                                   options_array: cultivar_repo.for_select_cultivar_groups)])
    end

    def puc_change # rubocop:disable Metrics/AbcSize
      if @params[:changed_value].nil_or_empty?
        for_select_orchards = []
        for_select_cultivars = cultivar_repo.for_select_cultivar_groups
        for_select_cultivar_groups = cultivar_repo.for_select_cultivars
      else
        orchards = cultivar_repo.all_hash(:orchards,  puc_id: @params[:changed_value])
        for_select_orchards = orchards.map { |i| [i[:orchard_code], i[:id]] }
        cultivars = cultivar_repo.all_hash(:cultivars,  id: orchards.map { |o| o[:cultivar_ids] }.flatten)
        for_select_cultivars = cultivars.map { |i| [i[:cultivar_name], i[:id]] }
        for_select_cultivar_groups = cultivar_repo.all_hash(:cultivar_groups,  id: cultivars.map { |i| i[:cultivar_group_id] }).map { |i| [i[:cultivar_group_code], i[:id]] }
      end

      json_actions([OpenStruct.new(type: :replace_select_options,
                                   dom_id: 'packout_runs_report_orchard_id',
                                   options_array: for_select_orchards),
                    OpenStruct.new(type: :replace_select_options,
                                   dom_id: 'packout_runs_report_cultivar_id',
                                   options_array: for_select_cultivars),
                    OpenStruct.new(type: :replace_select_options,
                                   dom_id: 'packout_runs_report_cultivar_group_id',
                                   options_array: for_select_cultivar_groups)])
    end

    def orchard_change # rubocop:disable Metrics/AbcSize
      cultivar_ids = cultivar_repo.all_hash(:orchards,  id: params[:changed_value]).map { |o| o[:cultivar_ids] }.flatten
      cultivars = cultivar_repo.all_hash(:cultivars,  id: cultivar_ids)
      for_select_cultivars = cultivars.map { |i| [i[:cultivar_name], i[:id]] }
      for_select_cultivar_groups = cultivar_repo.all_hash(:cultivar_groups,  id: cultivars.map { |i| i[:cultivar_group_id] }).map { |i| [i[:cultivar_group_code], i[:id]] }

      json_actions([OpenStruct.new(type: :replace_select_options,
                                   dom_id: 'packout_runs_report_cultivar_id',
                                   options_array: for_select_cultivars),
                    OpenStruct.new(type: :replace_select_options,
                                   dom_id: 'packout_runs_report_cultivar_group_id',
                                   options_array: for_select_cultivar_groups)])
    end

    def cultivar_group_change
      where = params[:changed_value].nil_or_empty? ? {} : { cultivar_group_id: params[:changed_value] }
      cultivars = cultivar_repo.for_select_cultivars(where: where)

      json_replace_select_options('packout_runs_report_cultivar_id', cultivars)
    end

    def packhouse_change
      packhouse_resource_lines = if params[:changed_value].blank?
                                   []
                                 else
                                   ProductionApp::ProductSetupRepo.new.for_select_packhouse_lines(params[:changed_value])
                                 end
      json_replace_select_options('packout_runs_report_production_line_id', packhouse_resource_lines)
    end

    def cultivar_repo
      @cultivar_repo ||= MasterfilesApp::CultivarRepo.new
    end

    def farm_repo
      @farm_repo ||= MasterfilesApp::FarmRepo.new
    end

    def rmt_repo
      @rmt_repo ||= RawMaterialsApp::RmtDeliveryRepo.new
    end

    def add_behaviours
      behaviours do |behaviour|
        behaviour.dropdown_change :farm_id, notify: [{ url: '/production/runs/packout_runs_search/farm_combo_changed' }]
        behaviour.dropdown_change :puc_id, notify: [{ url: '/production/runs/packout_runs_search/puc_combo_changed' }]
        behaviour.dropdown_change :cultivar_group_id, notify: [{ url: '/production/runs/packout_runs_search/cultivar_group_combo_changed' }]
        behaviour.dropdown_change :orchard_id, notify: [{ url: '/production/runs/packout_runs_search/orchard_combo_changed' }]
        behaviour.dropdown_change :packhouse_resource_id, notify: [{ url: '/production/runs/packout_runs_search/packhouse_resource_changed' }]
      end
    end
  end
end
