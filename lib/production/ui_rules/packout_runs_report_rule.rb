# frozen_string_literal: true

module UiRules
  class PackoutRunsReportRule < Base
    def generate_rules
      @resource_repo = ProductionApp::ResourceRepo.new
      @farm_repo = MasterfilesApp::FarmRepo.new
      @cultivar_repo = MasterfilesApp::CultivarRepo.new
      @prod_setup_repo = ProductionApp::ProductSetupRepo.new
      @calender_repo = MasterfilesApp::CalendarRepo.new
      make_new_form_object
      common_values_for_fields common_fields
      add_behaviours
      form_name 'packout_runs_report'
    end

    def common_fields
      {
        farm_id: { renderer: :select,
                   options: @farm_repo.for_select_farms,
                   disabled_options: @farm_repo.for_select_inactive_farms,
                   prompt: 'Select Farm',
                   caption: 'Farm' },
        puc_id: { renderer: :select,
                  options: @farm_repo.for_select_pucs,
                  disabled_options: @farm_repo.for_select_inactive_pucs,
                  prompt: 'Select Puc',
                  caption: 'Puc' },
        orchard_id: { renderer: :select,
                      options: [], # @farm_repo.for_select_orchards,
                      prompt: 'Select Orchard',
                      caption: 'Orchard' },
        cultivar_group_id: { renderer: :select,
                             options: @cultivar_repo.for_select_cultivar_groups,
                             disabled_options: @cultivar_repo.for_select_inactive_cultivar_groups,
                             prompt: 'Select Cultivar Group',
                             caption: 'Cultivar Group' },
        cultivar_id: { renderer: :select,
                       options: @cultivar_repo.for_select_cultivars,
                       disabled_options: @cultivar_repo.for_select_inactive_cultivars,
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

    private

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
