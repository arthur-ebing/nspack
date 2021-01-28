# frozen_string_literal: true

module UiRules
  class PackoutReportRule < Base
    def generate_rules
      @resource_repo = ProductionApp::ResourceRepo.new
      @farm_repo = MasterfilesApp::FarmRepo.new
      @cultivar_repo = MasterfilesApp::CultivarRepo.new
      make_new_form_object
      common_values_for_fields common_fields

      add_behaviours

      form_name 'packout_report'
    end

    def common_fields
      {
        from_date: { renderer: :date,
                     required: true,
                     width: 1 },
        to_date: { renderer: :date,
                   required: true },
        detail_level: { renderer: :checkbox,
                        caption: 'Show detail' },
        dispatched_only: { renderer: :checkbox,
                           caption: 'Show dispatched only' },
        packhouse_resource_id: { renderer: :select,
                                 options: @resource_repo.for_select_plant_resources_of_type(Crossbeams::Config::ResourceDefinitions::PACKHOUSE),
                                 disabled_options: @resource_repo.for_select_plant_resources_of_type(Crossbeams::Config::ResourceDefinitions::PACKHOUSE, active: false),
                                 prompt: 'Select Packhouse',
                                 caption: 'Packhouse' },
        line_resource_id: { renderer: :select,
                            options: @resource_repo.for_select_plant_resources_of_type(Crossbeams::Config::ResourceDefinitions::LINE),
                            disabled_options: @resource_repo.for_select_plant_resources_of_type(Crossbeams::Config::ResourceDefinitions::LINE, active: false),
                            prompt: 'Select Line',
                            caption: 'Production Line' },
        puc_id: { renderer: :select,
                  options: @farm_repo.for_select_pucs,
                  disabled_options: @farm_repo.for_select_inactive_pucs,
                  prompt: 'Select PUC',
                  caption: 'PUC' },
        orchard_id: { renderer: :select,
                      options: [],
                      disabled_options: @farm_repo.for_select_inactive_orchards,
                      prompt: 'Select Orchard',
                      caption: 'Orchard' },
        cultivar_id: { renderer: :select,
                       options: @cultivar_repo.for_select_cultivars,
                       disabled_options: @cultivar_repo.for_select_inactive_cultivars,
                       prompt: 'Select Cultivar',
                       caption: 'Cultivar' }
      }
    end

    def make_new_form_object
      @form_object = OpenStruct.new(from_date: nil,
                                    to_date: nil,
                                    detail_level: true,
                                    dispatched_only: false,
                                    packhouse_resource_id: nil,
                                    line_resource_id: nil,
                                    puc_id: nil,
                                    orchard_id: nil,
                                    cultivar_id: nil)
    end

    private

    def add_behaviours
      behaviours do |behaviour|
        behaviour.dropdown_change :packhouse_resource_id,
                                  notify: [{ url: '/production/reports/packhouse_changed' }]
        behaviour.dropdown_change :puc_id,
                                  notify: [{ url: '/production/reports/puc_changed' }]
        behaviour.dropdown_change :orchard_id,
                                  notify: [{ url: '/production/reports/orchard_changed' }]
      end
    end
  end
end
