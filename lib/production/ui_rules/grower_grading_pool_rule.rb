# frozen_string_literal: true

module UiRules
  class GrowerGradingPoolRule < Base # rubocop:disable Metrics/ClassLength
    def generate_rules # rubocop:disable Metrics/AbcSize
      @repo = ProductionApp::GrowerGradingRepo.new

      make_form_object

      @rules[:legacy_data_fields] = AppConst::CR_PROD.grower_grading_json_fields[:legacy_data]
      @rules[:show_legacy_data_fields] = !@rules[:legacy_data_fields].empty?
      if @mode == :manage
        @rules[:complete_grading] = @repo.complete_pool_objects_grading?(@options[:id], @options[:object_name])
        @rules[:reopen_grading] = @repo.reopen_pool_objects_grading?(@options[:id], @options[:object_name])
      end
      @rules[:completed] = @form_object.completed

      apply_form_values

      common_values_for_fields common_fields

      set_show_fields if %i[show].include? @mode
      set_manage_pool_details if %i[manage confirm].include? @mode

      form_name 'grower_grading_pool'
    end

    def set_show_fields # rubocop:disable Metrics/AbcSize
      grower_grading_rule_id_label = @repo.get(:grower_grading_rules, @form_object.grower_grading_rule_id, :rule_name)
      season_id_label = @repo.get(:seasons, @form_object.season_id, :season_code)
      cultivar_group_id_label = @repo.get(:cultivar_groups, @form_object.cultivar_group_id, :cultivar_group_code)
      cultivar_id_label = @repo.get(:cultivars, @form_object.cultivar_id, :cultivar_name)
      commodity_id_label = @repo.get(:commodities, @form_object.commodity_id, :code)
      farm_id_label = @repo.get(:farms, @form_object.farm_id, :farm_code)
      inspection_type_id_label = @repo.get(:inspection_types, @form_object.inspection_type_id, :inspection_type_code)
      fields[:grower_grading_rule_id] = { renderer: :label,
                                          with_value: grower_grading_rule_id_label,
                                          caption: 'Grower Grading Rule' }
      fields[:pool_name] = { renderer: :label }
      fields[:description] = { renderer: :label }
      fields[:production_run_code] = { renderer: :label,
                                       caption: 'Production Run' }
      fields[:season_id] = { renderer: :label,
                             with_value: season_id_label,
                             caption: 'Season' }
      fields[:cultivar_group_id] = { renderer: :label,
                                     with_value: cultivar_group_id_label,
                                     caption: 'Cultivar Group' }
      fields[:cultivar_id] = { renderer: :label,
                               with_value: cultivar_id_label,
                               caption: 'Cultivar' }
      fields[:commodity_id] = { renderer: :label,
                                with_value: commodity_id_label,
                                caption: 'Commodity' }
      fields[:farm_id] = { renderer: :label,
                           with_value: farm_id_label,
                           caption: 'Farm' }
      fields[:inspection_type_id] = { renderer: :label,
                                      with_value: inspection_type_id_label,
                                      caption: 'Inspection Type' }
      fields[:bin_quantity] = { renderer: :label }
      fields[:gross_weight] = { renderer: :label }
      fields[:nett_weight] = { renderer: :label }
      fields[:pro_rata_factor] = { renderer: :label }
      fields[:completed] = { renderer: :label,
                             as_boolean: true }
      fields[:rule_applied] = { renderer: :label,
                                as_boolean: true }
      fields[:active] = { renderer: :label,
                          as_boolean: true }
      fields[:created_by] = { renderer: :label }
      fields[:updated_by] = { renderer: :label }
      fields[:rule_applied_by] = { renderer: :label }
      fields[:rule_applied_at] = { renderer: :label,
                                   format: :without_timezone_or_seconds }

      return fields unless @rules[:show_legacy_data_fields]

      @rules[:legacy_data_fields].each do |v|
        fields[v.to_sym] = { renderer: :label,
                             caption: v.to_s,
                             with_value: @form_object.legacy_data.to_h[v.to_s]  }
      end
    end

    def common_fields
      {
        id: { renderer: :hidden,
              value: @options[:id] },
        pool_name: { required: true },
        description: {},
        production_run_code: { renderer: :label,
                               caption: 'Production Run' },
        production_run_id: { renderer: :integer,
                             required: true,
                             caption: 'Production Run Id' },
        inspection_type_id: { renderer: :select,
                              options: MasterfilesApp::QualityRepo.new.for_select_inspection_types,
                              disabled_options: MasterfilesApp::QualityRepo.new.for_select_inactive_inspection_types,
                              caption: 'Inspection Type',
                              prompt: 'Select Inspection Type',
                              searchable: true,
                              remove_search_for_small_list: false  },
        bin_quantity: { renderer: :label },
        gross_weight: { renderer: :label },
        nett_weight: { renderer: :label },
        pro_rata_factor: { renderer: :label }
      }
    end

    def set_manage_pool_details(columns = nil, display_columns = 3)
      compact_header(columns: columns || %i[pool_name description production_run_code season_code cultivar_group_code cultivar_name
                                            commodity_code farm_code inspection_type_code bin_quantity
                                            gross_weight nett_weight active completed rule_applied created_by updated_by
                                            rule_applied_by created_at updated_at rule_applied_at],
                     display_columns: display_columns,
                     header_captions: {
                       pool_name: 'Pool',
                       description: 'Description',
                       production_run_code: 'Production Run',
                       season_code: 'Season',
                       cultivar_group_code: 'Cultivar group',
                       cultivar_name: 'Cultivar',
                       commodity_code: 'Commodity',
                       farm_code: 'Farm',
                       inspection_type_code: 'Inspection type'
                     })
    end

    def make_form_object
      if @mode == :new
        make_new_form_object
        return
      end

      hash = @repo.find_grower_grading_pool(@options[:id])
      legacy_data = AppConst::CR_PROD.grower_grading_json_fields[:legacy_data].map { |f| [f, hash.legacy_data.to_h[f.to_s]] }
      @form_object = OpenStruct.new(hash.to_h.merge(Hash[legacy_data]))
    end

    def make_new_form_object
      @form_object = new_form_object_from_struct(ProductionApp::GrowerGradingPool)
    end
  end
end
