# frozen_string_literal: true

module UiRules
  class MrlResultRule < Base
    def generate_rules # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      @repo = QualityApp::MrlResultRepo.new
      @cultivar_repo = MasterfilesApp::CultivarRepo.new
      @farm_repo = MasterfilesApp::FarmRepo.new
      @calender_repo = MasterfilesApp::CalendarRepo.new
      @quality_repo = MasterfilesApp::QualityRepo.new
      @print_repo = LabelApp::PrinterRepo.new

      make_form_object
      @rules[:hide_pre_harvest_fields] = @form_object.pre_harvest_result ? false : true
      @rules[:delivery_result] = if @mode == :new
                                   @options[:attrs][:delivery_result]
                                 else
                                   false
                                 end
      apply_form_values

      common_values_for_fields common_fields

      set_show_fields if %i[show].include? @mode
      set_mrl_result_override_details if %i[override].include? @mode
      set_print_mrl_labels_fields if @mode == :print_mrl_label

      add_behaviours if %i[new edit].include? @mode

      form_name 'mrl_result'
    end

    def set_show_fields # rubocop:disable Metrics/AbcSize
      post_harvest_parent_mrl_result_id_label = @repo.get(:mrl_results, @form_object.post_harvest_parent_mrl_result_id, :waybill_number)
      cultivar_id_label = @repo.get(:cultivars, @form_object.cultivar_id, :cultivar_name)
      puc_id_label = @repo.get(:pucs, @form_object.puc_id, :puc_code)
      season_id_label = @repo.get(:seasons, @form_object.season_id, :season_code)
      farm_id_label = @repo.get(:farms, @form_object.farm_id, :farm_code)
      laboratory_id_label = @repo.get(:laboratories, @form_object.laboratory_id, :lab_code)
      mrl_sample_type_id_label = @repo.get(:mrl_sample_types, @form_object.mrl_sample_type_id, :sample_type_code)
      orchard_id_label = @repo.get(:orchards, @form_object.orchard_id, :orchard_code)
      production_run_id_label = ProductionApp::ProductionRunRepo.new.production_run_code(@form_object.production_run_id) unless @form_object.production_run_id.nil?
      fields[:farm_id] = { renderer: :label,
                           with_value: farm_id_label,
                           caption: 'Farm',
                           invisible: @rules[:hide_pre_harvest_fields] }
      fields[:orchard_id] = { renderer: :label,
                              with_value: orchard_id_label,
                              caption: 'Orchard',
                              invisible: @rules[:hide_pre_harvest_fields] }
      fields[:cultivar_id] = { renderer: :label,
                               with_value: cultivar_id_label,
                               caption: 'Cultivar',
                               invisible: @rules[:hide_pre_harvest_fields] }
      fields[:puc_id] = { renderer: :label,
                          with_value: puc_id_label,
                          caption: 'Puc',
                          invisible: @rules[:hide_pre_harvest_fields] }
      fields[:rmt_delivery_id] = { renderer: :label,
                                   with_value: @form_object.rmt_delivery_id,
                                   caption: 'Delivery Id',
                                   invisible: @rules[:hide_pre_harvest_fields] }
      fields[:production_run_id] = { renderer: :label,
                                     with_value: production_run_id_label,
                                     caption: 'Production Run',
                                     invisible: !@rules[:hide_pre_harvest_fields] }
      fields[:post_harvest_parent_mrl_result_id] = { renderer: :label,
                                                     with_value: post_harvest_parent_mrl_result_id_label,
                                                     caption: 'Post Harvest Parent Mrl Result' }
      fields[:season_id] = { renderer: :label,
                             with_value: season_id_label,
                             caption: 'Season' }
      fields[:laboratory_id] = { renderer: :label,
                                 with_value: laboratory_id_label,
                                 caption: 'Laboratory' }
      fields[:mrl_sample_type_id] = { renderer: :label,
                                      with_value: mrl_sample_type_id_label,
                                      caption: 'Mrl Sample Type' }
      fields[:waybill_number] = { renderer: :label }
      fields[:reference_number] = { renderer: :label }
      fields[:sample_number] = { renderer: :label }
      fields[:ph_level] = { renderer: :label }
      fields[:num_active_ingredients] = { renderer: :label }
      fields[:max_num_chemicals_passed] = { renderer: :label, as_boolean: true }
      fields[:mrl_sample_passed] = { renderer: :label, as_boolean: true }
      fields[:pre_harvest_result] = { renderer: :label, as_boolean: true }
      fields[:post_harvest_result] = { renderer: :label, as_boolean: true }
      fields[:active] = { renderer: :label, as_boolean: true }
      fields[:fruit_received_at] = { renderer: :label, format: :without_timezone_or_seconds }
      fields[:sample_submitted_at] = { renderer: :label, format: :without_timezone_or_seconds }
      fields[:result_received_at] = { renderer: :label, format: :without_timezone_or_seconds }
    end

    def common_fields # rubocop:disable Metrics/AbcSize
      if @rules[:delivery_result]
        farm_renderer = { renderer: :hidden }
        puc_renderer = { renderer: :hidden }
        orchard_renderer = { renderer: :hidden }
        cultivar_renderer = { renderer: :hidden }
        rmt_delivery_renderer = { renderer: :hidden }
        season_renderer = { renderer: :hidden }
      else
        farm_renderer = { renderer: :select,
                          options: @farm_repo.for_select_farms,
                          disabled_options: @farm_repo.for_select_inactive_farms,
                          prompt: 'Select Farm',
                          caption: 'Farm',
                          searchable: true,
                          remove_search_for_small_list: false,
                          invisible: @rules[:hide_pre_harvest_fields] }
        puc_renderer = { renderer: :select,
                         options: @farm_repo.for_select_pucs(
                           where: { farm_id: @form_object.farm_id }
                         ),
                         disabled_options: @farm_repo.for_select_inactive_pucs,
                         prompt: 'Select PUC',
                         caption: 'PUC',
                         invisible: @rules[:hide_pre_harvest_fields] }
        orchard_renderer = { renderer: :select,
                             options: @farm_repo.for_select_orchards(
                               where: { farm_id: @form_object.farm_id }
                             ),
                             disabled_options: @farm_repo.for_select_inactive_orchards,
                             prompt: 'Select Orchard',
                             caption: 'Orchard',
                             searchable: true,
                             remove_search_for_small_list: false,
                             invisible: @rules[:hide_pre_harvest_fields] }
        cultivar_renderer = { renderer: :select,
                              options: @cultivar_repo.for_select_cultivars,
                              disabled_options: @cultivar_repo.for_select_inactive_cultivars,
                              prompt: 'Select Cultivar',
                              caption: 'Cultivar',
                              required: true,
                              invisible: @rules[:hide_pre_harvest_fields] }
        rmt_delivery_renderer = { renderer: :select,
                                  required: true,
                                  prompt: 'Select Delivery',
                                  options: @repo.for_select_rmt_deliveries(
                                    where: { Sequel[:rmt_deliveries][:orchard_id] => @form_object.orchard_id }
                                  ),
                                  caption: 'Delivery',
                                  searchable: true,
                                  remove_search_for_small_list: false,
                                  invisible: @rules[:hide_pre_harvest_fields] }
        season_renderer = { renderer: :select,
                            options: @calender_repo.for_select_seasons,
                            disabled_options: @calender_repo.for_select_inactive_seasons,
                            caption: 'Season',
                            prompt: 'Select Season',
                            searchable: true,
                            remove_search_for_small_list: false,
                            required: true }
      end
      fields = {
        farm_id: farm_renderer,
        orchard_id: orchard_renderer,
        cultivar_id: cultivar_renderer,
        puc_id: puc_renderer,
        rmt_delivery_id: rmt_delivery_renderer,
        production_run_id: { renderer: :integer,
                             required: true,
                             caption: 'Production Run Id',
                             invisible: !@rules[:hide_pre_harvest_fields] },
        post_harvest_parent_mrl_result_id: { renderer: :select,
                                             options: @repo.for_select_mrl_results,
                                             disabled_options: @repo.for_select_inactive_mrl_results,
                                             prompt: 'Select Parent Mrl Result',
                                             caption: 'Post Harvest Parent Mrl Result',
                                             searchable: true,
                                             remove_search_for_small_list: false },
        season_id: season_renderer,
        laboratory_id: { renderer: :select,
                         options: @quality_repo.for_select_laboratories,
                         disabled_options: @quality_repo.for_select_inactive_laboratories,
                         prompt: 'Select Laboratory',
                         caption: 'Laboratory',
                         searchable: true,
                         remove_search_for_small_list: false,
                         required: true },
        mrl_sample_type_id: { renderer: :select,
                              options: @quality_repo.for_select_mrl_sample_types,
                              disabled_options: @quality_repo.for_select_inactive_mrl_sample_types,
                              prompt: 'Select Sample Type',
                              caption: 'Mrl Sample Type',
                              searchable: true,
                              remove_search_for_small_list: false,
                              required: true },
        waybill_number: {},
        reference_number: {},
        sample_number: { required: true },
        ph_level: {},
        num_active_ingredients: {},
        max_num_chemicals_passed: { renderer: :checkbox },
        mrl_sample_passed: { renderer: :checkbox },
        pre_harvest_result: { renderer: :hidden },
        post_harvest_result: { renderer: :hidden },
        fruit_received_at: { renderer: :input,
                             subtype: :date,
                             required: true },
        sample_submitted_at: { renderer: :input,
                               subtype: :date,
                               required: true },
        result_received_at: { renderer: :input,
                              subtype: :date }
      }
      if @rules[:delivery_result]
        fields[:farm_code] = { renderer: :label,
                               with_value: @repo.get(:farms, @form_object.farm_id, :farm_code),
                               caption: 'Farm' }
        fields[:orchard_code] = { renderer: :label,
                                  with_value: @repo.get(:orchards, @form_object.orchard_id, :orchard_code),
                                  caption: 'Orchard' }
        fields[:cultivar_name] = { renderer: :label,
                                   with_value: @repo.get(:cultivars, @form_object.cultivar_id, :cultivar_name),
                                   caption: 'Cultivar' }
        fields[:puc_code] = { renderer: :label,
                              with_value: @repo.get(:pucs, @form_object.puc_id, :puc_code),
                              caption: 'Puc' }
        fields[:rmt_delivery] = { renderer: :label,
                                  with_value: @form_object.rmt_delivery_id,
                                  caption: 'Delivery Id' }
        fields[:season_code] = { renderer: :label,
                                 with_value: @repo.get(:seasons, @form_object.season_id, :season_code),
                                 caption: 'Season' }
      end
      fields
    end

    def set_mrl_result_override_details # rubocop:disable Metrics/AbcSize
      rules[:left_record] = @repo.mrl_result_data(@repo.where_hash(:mrl_results, id: @options[:id]))
      rules[:right_record] = @repo.mrl_result_data(@options[:attrs])
      rules[:no_changes_made] = rules[:left_record] == rules[:right_record]
      fields[:changes_made] = {
        left_caption: 'Before',
        right_caption: 'After',
        left_record: rules[:left_record].sort.to_h,
        right_record: rules[:right_record].sort.to_h
      }
    end

    def set_print_mrl_labels_fields
      fields[:printer] = { renderer: :select,
                           options: @print_repo.select_printers_for_application(AppConst::PRINT_APP_MRL),
                           required: true }
      fields[:label_template_id] = { renderer: :select,
                                     options: MasterfilesApp::LabelTemplateRepo.new.for_select_label_templates(
                                       where: { application: AppConst::PRINT_APP_MRL }
                                     ),
                                     required: true }
      fields[:no_of_prints] = { renderer: :integer,
                                required: true }
    end

    def make_form_object
      if @mode == :new
        make_new_form_object
        return
      end

      if @mode == :print_mrl_label
        @form_object = OpenStruct.new(printer: @print_repo.default_printer_for_application(AppConst::PRINT_APP_MRL),
                                      label_template_id: nil,
                                      no_of_prints: 1)
        return
      end

      @form_object = @repo.find_mrl_result(@options[:id])
    end

    def make_new_form_object
      @form_object = new_form_object_from_struct(QualityApp::MrlResult,
                                                 merge_hash: { pre_harvest_result: @options[:attrs][:pre_harvest_result],
                                                               post_harvest_result: @options[:attrs][:post_harvest_result],
                                                               fruit_received_at: Time.now,
                                                               sample_submitted_at: Time.now,
                                                               result_received_at: nil })
    end

    def handle_behaviour # rubocop:disable Metrics/CyclomaticComplexity
      case @mode
      when :farm
        farm_change
      when :orchard
        orchard_change
      when :delivery
        delivery_change
      when :cultivar
        cultivar_change
      when :production_run
        production_run_change
      when :fruit_received_at
        fruit_received_at_change
      else
        unhandled_behaviour!
      end
    end

    private

    def add_behaviours
      behaviours do |behaviour|
        behaviour.dropdown_change :farm_id,
                                  notify: [{ url: '/quality/mrl/mrl_results/ui_change/farm' }]
        behaviour.dropdown_change :orchard_id,
                                  notify: [{ url: '/quality/mrl/mrl_results/ui_change/orchard' }]
        behaviour.dropdown_change :rmt_delivery_id,
                                  notify: [{ url: '/quality/mrl/mrl_results/ui_change/delivery' }]
        behaviour.dropdown_change :cultivar_id,
                                  notify: [{ url: '/quality/mrl/mrl_results/ui_change/cultivar',
                                             param_keys: %i[mrl_result_fruit_received_at] }]
        behaviour.keyup :production_run_id,
                        notify: [{ url: '/quality/mrl/mrl_results/ui_change/production_run',
                                   param_keys: %i[mrl_result_fruit_received_at] }]
        behaviour.input_change :fruit_received_at,
                               notify: [{ url: '/quality/mrl/mrl_results/ui_change/fruit_received_at',
                                          param_keys: %i[mrl_result_cultivar_id mrl_result_production_run_id] }]
      end
    end

    def farm_change
      repo = MasterfilesApp::FarmRepo.new
      if params[:changed_value].blank?
        pucs = []
        orchards = []
      else
        farm_id = params[:changed_value]
        pucs = repo.for_select_pucs(where: { farm_id: farm_id })
        orchards = repo.for_select_orchards(where: { farm_id: farm_id })
      end
      json_actions([OpenStruct.new(type: :replace_select_options,
                                   dom_id: 'mrl_result_puc_id',
                                   options_array: pucs),
                    OpenStruct.new(type: :replace_select_options,
                                   dom_id: 'mrl_result_orchard_id',
                                   options_array: orchards)])
    end

    def orchard_change
      deliveries = if params[:changed_value].blank?
                     []
                   else
                     QualityApp::MrlResultRepo.new.for_select_rmt_deliveries(where: { Sequel[:rmt_deliveries][:orchard_id] => params[:changed_value] })
                   end
      json_actions([OpenStruct.new(type: :replace_select_options,
                                   dom_id: 'mrl_result_rmt_delivery_id',
                                   options_array: deliveries)])
    end

    def delivery_change
      repo = MasterfilesApp::CultivarRepo.new
      cultivars = if params[:changed_value].blank?
                    []
                  else
                    cultivar_id = repo.get(:rmt_deliveries, params[:changed_value], :cultivar_id)
                    repo.for_select_cultivars(where: { id: cultivar_id })
                  end
      json_actions([OpenStruct.new(type: :replace_select_options,
                                   dom_id: 'mrl_result_cultivar_id',
                                   options_array: cultivars)])
    end

    def cultivar_change
      repo = MasterfilesApp::CalendarRepo.new
      fruit_received_at = params[:mrl_result_fruit_received_at]
      seasons = if params[:changed_value].blank? || fruit_received_at.blank?
                  []
                else
                  cultivar_id = params[:changed_value].to_i
                  season_id = repo.get_season_id(cultivar_id, fruit_received_at)
                  repo.for_select_seasons(
                    where: { Sequel[:seasons][:id] => season_id }
                  )
                end
      json_replace_select_options('mrl_result_season_id', seasons)
    end

    def production_run_change # rubocop:disable Metrics/AbcSize
      repo = MasterfilesApp::CalendarRepo.new
      fruit_received_at = params[:mrl_result_fruit_received_at]
      seasons = if params[:changed_value].blank? || fruit_received_at.blank?
                  []
                else
                  cultivar_id = repo.get(:production_runs, params[:changed_value].to_i, :cultivar_id)
                  season_id = cultivar_id.nil? ? nil : repo.get_season_id(cultivar_id, fruit_received_at)
                  repo.for_select_seasons(
                    where: { Sequel[:seasons][:id] => season_id }
                  )
                end
      json_replace_select_options('mrl_result_season_id', seasons)
    end

    def fruit_received_at_change # rubocop:disable Metrics/AbcSize
      repo = MasterfilesApp::CalendarRepo.new
      cultivar_id = params[:mrl_result_cultivar_id]
      production_run_id = params[:mrl_result_production_run_id]
      seasons = if params[:changed_value].blank? || (cultivar_id.blank? && production_run_id.blank?)
                  []
                else
                  fruit_received_at = params[:changed_value]
                  season_cultivar_id = cultivar_id.blank? ? repo.get(:production_runs, production_run_id, :cultivar_id) : cultivar_id
                  season_id = cultivar_id.nil? ? nil : repo.get_season_id(season_cultivar_id, fruit_received_at)
                  repo.for_select_seasons(
                    where: { Sequel[:seasons][:id] => season_id }
                  )
                end
      json_replace_select_options('mrl_result_season_id', seasons)
    end
  end
end
