# frozen_string_literal: true

module UiRules
  class ChangeRunDetailsRule < Base
    def generate_rules
      @repo = ProductionApp::ReworksRepo.new
      @cultivar_repo = MasterfilesApp::CultivarRepo.new
      @farm_repo = MasterfilesApp::FarmRepo.new

      make_form_object
      apply_form_values

      common_values_for_fields common_fields

      if @mode == :cultivar_details
        make_run_header_table(%i[production_run_code packhouse_code line_code started_at
                                 cultivar_group_code cultivar_name farm_code puc_code orchard_code
                                 bins_tipped bins_tipped_weight rebins_created rebins_weight
                                 carton_labels_printed carton_weight cartons_verified cartons_verified_weight
                                 pallets_palletized_full pallets_palletized_partial pallet_weight inspected_pallets verified_pallets
                                 allow_orchard_mixing allow_cultivar_mixing allow_cultivar_group_mixing])
        set_change_run_cultivar_details
      end

      form_name 'change_run_details'
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
                                            active_run_stage re_executed_at allow_orchard_mixing allow_cultivar_mixing allow_cultivar_group_mixing],
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

    def set_change_run_cultivar_details # rubocop:disable Metrics/AbcSize
      reworks_run_type_id_label = @form_object.reworks_run_type_id.nil_or_empty? ? '' : @repo.find_hash(:reworks_run_types, @form_object.reworks_run_type_id)[:run_type]
      where = @form_object.orchard_id.nil_or_empty? ? { cultivar_group_id: @form_object.cultivar_group_id } : { id: @farm_repo.find_orchard(@form_object.orchard_id.to_i)&.cultivar_ids.to_a }

      fields[:reworks_run_type_id] = { renderer: :hidden }
      fields[:reworks_run_type] = { renderer: :label,
                                    with_value: reworks_run_type_id_label,
                                    caption: 'Reworks Run Type' }
      fields[:production_run_id] = { renderer: :hidden }
      fields[:cultivar_id] = { renderer: :select,
                               options: @cultivar_repo.for_select_cultivars(where: where),
                               disabled_options: @cultivar_repo.for_select_inactive_cultivars,
                               prompt: 'Select Cultivar',
                               caption: 'Cultivar',
                               required: true,
                               searchable: true,
                               remove_search_for_small_list: false }
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
  end
end
