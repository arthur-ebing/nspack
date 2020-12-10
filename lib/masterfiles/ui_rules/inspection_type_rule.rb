# frozen_string_literal: true

module UiRules
  class InspectionTypeRule < Base
    def generate_rules
      @repo = MasterfilesApp::QualityRepo.new
      make_form_object
      apply_form_values

      add_behaviours

      common_values_for_fields common_fields

      set_show_fields if %i[show].include? @mode

      form_name 'inspection_type'
    end

    def set_show_fields # rubocop:disable Metrics/AbcSize
      inspection_failure_type_id_label = @repo.find(:inspection_failure_types, MasterfilesApp::InspectionFailureType, @form_object.inspection_failure_type_id)&.failure_type_code
      fields[:inspection_type_code] = { renderer: :label }
      fields[:description] = { renderer: :label }
      fields[:inspection_failure_type_id] = { renderer: :label,
                                              with_value: inspection_failure_type_id_label,
                                              caption: 'Inspection Failure Type' }

      fields[:applies_to_all_tm_groups] = { renderer: :label, as_boolean: true }
      fields[:applicable_tm_group_ids] = { renderer: :label }

      fields[:applies_to_all_cultivars] = { renderer: :label, as_boolean: true }
      fields[:applicable_cultivar_ids] = { renderer: :label }

      fields[:applies_to_all_orchards] = { renderer: :label, as_boolean: true }
      fields[:applicable_orchard_ids] = { renderer: :label }

      fields[:active] = { renderer: :label, as_boolean: true }
    end

    def common_fields # rubocop:disable Metrics/AbcSize
      {
        inspection_type_code: { required: true },
        description: {},
        inspection_failure_type_id: { renderer: :select,
                                      options: MasterfilesApp::QualityRepo.new.for_select_inspection_failure_types,
                                      disabled_options: MasterfilesApp::QualityRepo.new.for_select_inactive_inspection_failure_types,
                                      caption: 'Inspection Failure Type',
                                      required: true },

        applies_to_all_tm_groups: { renderer: :checkbox, caption: 'Applies to all TM Groups' },
        applicable_tm_group_ids: { renderer: :multi,
                                   options: MasterfilesApp::TargetMarketRepo.new.for_select_tm_groups,
                                   selected: @form_object.applicable_tm_group_ids,
                                   hide_on_load: @form_object.applies_to_all_tm_groups,
                                   caption: 'Target Market Groups' },
        applies_to_all_cultivars: { renderer: :checkbox, caption: 'Applies to all Cultivars' },
        applicable_cultivar_ids: { renderer: :multi,
                                   options: MasterfilesApp::CultivarRepo.new.for_select_cultivar_codes,
                                   selected: @form_object.applicable_cultivar_ids,
                                   hide_on_load: @form_object.applies_to_all_cultivars,
                                   caption: 'Cultivars' },
        applies_to_all_orchards: { renderer: :checkbox, caption: 'Applies to all Orchards' },
        applicable_orchard_ids: { renderer: :multi,
                                  options: MasterfilesApp::FarmRepo.new.for_select_orchards,
                                  selected: @form_object.applicable_orchard_ids,
                                  hide_on_load: @form_object.applies_to_all_orchards,
                                  caption: 'Orchards' }
      }
    end

    def make_form_object
      if @mode == :new
        make_new_form_object
        return
      end

      hash = @repo.find_inspection_type(@options[:id]).to_h
      hash[:applies_to_all_tm_groups] = hash[:applicable_tm_group_ids].nil?
      hash[:applies_to_all_cultivars] = hash[:applicable_cultivar_ids].nil?
      hash[:applies_to_all_orchards] = hash[:applicable_orchard_ids].nil?
      @form_object = OpenStruct.new(hash)
    end

    def make_new_form_object
      @form_object = OpenStruct.new(inspection_type_code: nil,
                                    description: nil,
                                    inspection_failure_type_id: nil,
                                    applies_to_all_tm_groups: true,
                                    applicable_tm_group_ids: nil,
                                    applies_to_all_cultivars: true,
                                    applicable_cultivar_ids: nil,
                                    applies_to_all_orchards: true,
                                    applicable_orchard_ids: nil)
    end

    private

    def add_behaviours
      behaviours do |behaviour|
        behaviour.input_change :applies_to_all_tm_groups, notify: [{ url: '/masterfiles/quality/inspection_types/applies_to_all_tm_groups' }]
        behaviour.input_change :applies_to_all_cultivars, notify: [{ url: '/masterfiles/quality/inspection_types/applies_to_all_cultivars' }]
        behaviour.input_change :applies_to_all_orchards, notify: [{ url: '/masterfiles/quality/inspection_types/applies_to_all_orchards' }]
      end
    end
  end
end
