# frozen_string_literal: true

module UiRules
  class BulkTipBinProcessRule < Base
    def generate_rules
      @resource_repo = ProductionApp::ResourceRepo.new
      make_new_form_object
      apply_form_values

      common_values_for_fields common_fields
      # add_behaviours
      add_progress_step

      form_name 'search_form'
    end

    def add_progress_step
      @form_object[:steps] = ['select bins', 'bulk apply suggested runs', 'edit suggested runs', 'Summary']
    end

    def common_fields
      {
        rmt_delivery_id: { renderer: :input,
                           caption: 'Delivery Id' },
        puc_id: { renderer: :select,
                  options: farm_repo.for_select_pucs,
                  prompt: 'Select PUC',
                  caption: 'PUC' },
        orchard_id: { renderer: :select,
                      options: farm_repo.for_select_orchards,
                      prompt: 'Select Orchard',
                      caption: 'Orchard' },
        cultivar_id: { renderer: :select,
                       options: cultivar_repo.for_select_cultivars,
                       disabled_options: cultivar_repo.for_select_inactive_cultivars,
                       prompt: 'Select Cultivar',
                       caption: 'Cultivar' },
        from: { renderer: :date,
                required: false },
        to: { renderer: :date,
              required: false }
      }
    end

    def make_new_form_object
      @form_object = OpenStruct.new(rmt_delivery_id: nil,
                                    puc_id: nil,
                                    orchard_id: nil,
                                    cultivar_id: nil,
                                    from: nil,
                                    to: nil)
    end

    private

    def cultivar_repo
      @cultivar_repo ||= MasterfilesApp::CultivarRepo.new
    end

    def farm_repo
      @farm_repo ||= MasterfilesApp::FarmRepo.new
    end
  end
end
