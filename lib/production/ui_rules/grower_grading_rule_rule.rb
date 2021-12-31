# frozen_string_literal: true

module UiRules
  class GrowerGradingRuleRule < Base
    def generate_rules
      @repo = ProductionApp::GrowerGradingRepo.new
      @setup_repo = ProductionApp::ProductSetupRepo.new
      @resource_repo = ProductionApp::ResourceRepo.new
      @cultivar_repo = MasterfilesApp::CultivarRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields common_fields

      set_show_fields if %i[show].include? @mode
      set_manage_rule_fields if @mode == :manage

      add_behaviours if %i[new edit clone].include? @mode

      form_name 'grower_grading_rule'
    end

    def set_show_fields # rubocop:disable Metrics/AbcSize
      packhouse_resource_id_label = @repo.get(:plant_resources, :plant_resource_code, @form_object.packhouse_resource_id)
      line_resource_id_label = @repo.get(:plant_resources, :plant_resource_code, @form_object.line_resource_id)
      season_id_label = @repo.get(:seasons, :season_code, @form_object.season_id)
      cultivar_group_id_label = @repo.get(:cultivar_groups, :cultivar_group_code, @form_object.cultivar_group_id)
      cultivar_id_label = @repo.get(:cultivars, :cultivar_name, @form_object.cultivar_id)
      fields[:rule_name] = { renderer: :label }
      fields[:description] = { renderer: :label }
      fields[:file_name] = { renderer: :label }
      fields[:packhouse_resource_id] = { renderer: :label,
                                         with_value: packhouse_resource_id_label,
                                         caption: 'Packhouse Resource' }
      fields[:line_resource_id] = { renderer: :label,
                                    with_value: line_resource_id_label,
                                    caption: 'Line Resource' }
      fields[:season_id] = { renderer: :label,
                             with_value: season_id_label,
                             caption: 'Season' }
      fields[:cultivar_group_id] = { renderer: :label,
                                     with_value: cultivar_group_id_label,
                                     caption: 'Cultivar Group' }
      fields[:cultivar_id] = { renderer: :label,
                               with_value: cultivar_id_label,
                               caption: 'Cultivar' }
      fields[:rebin_rule] = { renderer: :label,
                              as_boolean: true }
      fields[:active] = { renderer: :label,
                          as_boolean: true }
      fields[:created_by] = { renderer: :label }
      fields[:updated_by] = { renderer: :label }
    end

    def common_fields
      {
        id: { renderer: :hidden,
              value: @options[:id] },
        created_by: { renderer: :hidden },
        updated_by: { renderer: :hidden },
        rule_name: { required: true },
        description: {},
        file_name: {},
        packhouse_resource_id: { renderer: :select,
                                 options: @setup_repo.for_select_plant_resources(Crossbeams::Config::ResourceDefinitions::PACKHOUSE),
                                 disabled_options: @resource_repo.for_select_inactive_plant_resources,
                                 caption: 'Packhouse',
                                 prompt: 'Select Packhouse',
                                 searchable: true,
                                 remove_search_for_small_list: false },
        line_resource_id: { renderer: :select,
                            options: @setup_repo.for_select_plant_resources(Crossbeams::Config::ResourceDefinitions::LINE),
                            disabled_options: @resource_repo.for_select_inactive_plant_resources,
                            caption: 'Production Line',
                            prompt: 'Select Production Line',
                            searchable: true,
                            remove_search_for_small_list: false },
        season_id: { renderer: :select,
                     options: MasterfilesApp::CalendarRepo.new.for_select_seasons,
                     disabled_options: MasterfilesApp::CalendarRepo.new.for_select_inactive_seasons,
                     caption: 'Season',
                     prompt: 'Select Season',
                     searchable: true,
                     remove_search_for_small_list: false },
        cultivar_group_id: { renderer: :select,
                             options: @cultivar_repo.for_select_cultivar_groups,
                             disabled_options: @cultivar_repo.for_select_inactive_cultivar_groups,
                             caption: 'Cultivar Group',
                             required: true,
                             searchable: true,
                             remove_search_for_small_list: false },
        cultivar_id: { renderer: :select,
                       options: @cultivar_repo.for_select_cultivars(
                         where: { cultivar_group_id: @form_object.cultivar_group_id }
                       ),
                       disabled_options: @cultivar_repo.for_select_inactive_cultivars,
                       caption: 'Cultivar',
                       prompt: 'Select Cultivar',
                       searchable: true,
                       remove_search_for_small_list: false },
        rebin_rule: { renderer: :checkbox }
      }
    end

    def set_manage_rule_fields(columns = nil, display_columns = 3)
      compact_header(columns: columns || %i[rule_name description file_name packhouse_resource_code line_resource_code season_code
                                            cultivar_group_code cultivar_name created_by updated_by active rebin_rule ],
                     display_columns: display_columns,
                     header_captions: {
                       rule_name: 'Rule',
                       description: 'Description',
                       file_name: 'File Name',
                       packhouse_resource_code: 'Packhouse',
                       line_resource_code: 'Line',
                       cultivar_group_code: 'Cultivar group',
                       cultivar_name: 'Cultivar',
                       season_code: 'Season'
                     })
    end

    def make_form_object
      if @mode == :new
        make_new_form_object
        return
      elsif @mode == :clone
        hash = @repo.find_grower_grading_rule(@options[:id]).to_h.reject { |k, _| k == :rule_name }
        @form_object = OpenStruct.new(hash)
        return
      end

      @form_object = @repo.find_grower_grading_rule(@options[:id])
    end

    def make_new_form_object
      @form_object = new_form_object_from_struct(ProductionApp::GrowerGradingRule)
    end

    def handle_behaviour
      case @mode
      when :packhouse_resource
        packhouse_resource_change
      when :cultivar_group
        cultivar_group_change
      when :cultivar
        cultivar_change
      else
        unhandled_behaviour!
      end
    end

    private

    def add_behaviours
      behaviours do |behaviour|
        behaviour.dropdown_change :packhouse_resource_id,
                                  notify: [{ url: '/production/grower_grading/grower_grading_rules/ui_change/packhouse_resource' }]
        behaviour.dropdown_change :cultivar_group_id,
                                  notify: [{ url: '/production/grower_grading/grower_grading_rules/ui_change/cultivar_group' }]
        behaviour.dropdown_change :cultivar_id,
                                  notify: [{ url: '/production/grower_grading/grower_grading_rules/ui_change/cultivar' }]
      end
    end

    def packhouse_resource_change
      packhouse_lines = if params[:changed_value].blank?
                          []
                        else
                          ProductionApp::ProductSetupRepo.new.for_select_packhouse_lines(params[:changed_value])
                        end
      json_replace_select_options('grower_grading_rule_line_resource_id', packhouse_lines)
    end

    def cultivar_group_change
      if params[:changed_value].blank?
        seasons = []
        cultivars = []
      else
        cultivars = MasterfilesApp::CultivarRepo.new.for_select_cultivars(
          where: { cultivar_group_id: params[:changed_value] }
        )
        seasons = MasterfilesApp::CalendarRepo.new.for_select_seasons(
          where: { cultivar_group_id: params[:changed_value] }
        )
      end
      json_actions([OpenStruct.new(type: :replace_select_options,
                                   dom_id: 'grower_grading_rule_cultivar_id',
                                   options_array: cultivars),
                    OpenStruct.new(type: :replace_select_options,
                                   dom_id: 'grower_grading_rule_season_id',
                                   options_array: seasons)])
    end

    def cultivar_change
      seasons = if params[:changed_value].blank?
                  []
                else
                  MasterfilesApp::CalendarRepo.new.for_select_seasons(
                    where: { Sequel[:cultivars][:id] => params[:changed_value] }
                  )
                end
      json_replace_select_options('grower_grading_rule_season_id', seasons)
    end
  end
end
