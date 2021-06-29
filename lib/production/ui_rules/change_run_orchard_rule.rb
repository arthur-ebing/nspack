# frozen_string_literal: true

module UiRules
  class ChangeRunOrchardRule < Base # rubocop:disable Metrics/ClassLength
    def generate_rules
      @repo = ProductionApp::ReworksRepo.new
      @farm_repo = MasterfilesApp::FarmRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields common_fields

      if @mode == :details
        make_run_header_table(%i[production_run_code packhouse_code line_code started_at
                                 cultivar_group_code cultivar_name farm_code puc_code orchard_code
                                 bins_tipped bins_tipped_weight rebins_created rebins_weight
                                 carton_labels_printed carton_weight cartons_verified cartons_verified_weight
                                 pallets_palletized_full pallets_palletized_partial pallet_weight inspected_pallets verified_pallets])
        set_change_run_orchard_details
        add_behaviours
      end

      form_name 'change_run_orchard'
    end

    def common_fields
      reworks_run_type_id_label = @form_object.reworks_run_type_id.nil_or_empty? ? '' : @repo.find_hash(:reworks_run_types, @form_object.reworks_run_type_id)[:run_type]
      {
        reworks_run_type_id: { renderer: :hidden },
        reworks_run_type: { renderer: :label,
                            with_value: reworks_run_type_id_label,
                            caption: 'Reworks Run Type' },
        production_run_id: { renderer: :integer,
                             required: true,
                             caption: 'Production Run Id' }
      }
    end

    def make_run_header_table(columns = nil, display_columns = 3)
      compact_header(columns: columns || %i[production_run_code packhouse_code line_code started_at
                                            cultivar_group_code cultivar_name farm_code puc_code orchard_code
                                            bins_tipped bins_tipped_weight rebins_created rebins_weight
                                            carton_labels_printed carton_weight cartons_verified cartons_verified_weight
                                            pallets_palletized_full pallets_palletized_partial pallet_weight inspected_pallets verified_pallets
                                            active_run_stage re_executed_at],
                     display_columns: display_columns,
                     header_captions: {
                       packhouse_code: 'Packhouse',
                       line_code: 'Line',
                       cultivar_group_code: 'Cultivar Group',
                       cultivar_name: 'Cultivar',
                       farm_code: 'Farm',
                       puc_code: 'Puc',
                       orchard_code: 'Orchard'
                     })
    end

    def set_change_run_orchard_details # rubocop:disable Metrics/AbcSize
      reworks_run_type_id_label = @form_object.reworks_run_type_id.nil_or_empty? ? '' : @repo.find_hash(:reworks_run_types, @form_object.reworks_run_type_id)[:run_type]
      fields[:reworks_run_type_id] = { renderer: :hidden }
      fields[:reworks_run_type] = { renderer: :label,
                                    with_value: reworks_run_type_id_label,
                                    caption: 'Reworks Run Type' }
      fields[:production_run_id] = { renderer: :hidden }
      fields[:orchard_id] = { renderer: :select,
                              options: @farm_repo.for_select_orchards(where: { puc_id: @form_object.puc_id }),
                              disabled_options: @farm_repo.for_select_inactive_orchards,
                              caption: 'Orchard',
                              required: true,
                              searchable: true,
                              remove_search_for_small_list: false }
      fields[:description] = { renderer: :list,
                               items: [],
                               scroll_height: :medium,
                               caption: '' }
      fields[:allow_orchard_mixing] = if @form_object.allow_orchard_mixing
                                        { renderer: :label,
                                          as_boolean: true }
                                      else
                                        { renderer: :checkbox,
                                          hide_on_load: true }
                                      end
      fields[:allow_cultivar_mixing] = if @form_object.allow_cultivar_mixing
                                         { renderer: :label,
                                           as_boolean: true }
                                       else
                                         { renderer: :checkbox,
                                           hide_on_load: true }
                                       end
      fields[:allow_cultivar_group_mixing] = { renderer: :label,
                                               as_boolean: true }
      fields[:from_orchard_id] = { renderer: :hidden }
    end

    def make_form_object
      if %i[new].include? @mode
        make_new_form_object
        return
      end

      hash = @repo.details_for_production_run(@options[:attrs][:production_run_id].to_i).to_h
      hash = hash.merge(reworks_run_type_id: @options[:reworks_run_type_id])
      @form_object = OpenStruct.new(hash)
    end

    def make_new_form_object
      @form_object = OpenStruct.new(reworks_run_type_id: @options[:reworks_run_type_id],
                                    reworks_run_type: nil,
                                    production_run_id: nil)
    end

    private

    def add_behaviours
      behaviours do |behaviour|
        behaviour.dropdown_change :orchard_id,
                                  notify: [{ url: '/production/reworks/change_run_orchard/orchard_changed',
                                             param_keys: %i[change_run_orchard_production_run_id] }]
        behaviour.input_change :allow_orchard_mixing,
                               notify: [{ url: '/production/reworks/change_run_orchard/allow_orchard_mixing_changed',
                                          param_keys: %i[change_run_orchard_production_run_id change_run_orchard_orchard_id] }]
        behaviour.input_change :allow_cultivar_mixing,
                               notify: [{ url: '/production/reworks/change_run_orchard/allow_cultivar_mixing_changed',
                                          param_keys: %i[change_run_orchard_production_run_id change_run_orchard_orchard_id] }]
      end
    end
  end
end
