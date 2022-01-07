# frozen_string_literal: true

module UiRules
  class PresortStagingRunRule < Base
    def generate_rules # rubocop:disable Metrics/AbcSize
      @resource_repo = ProductionApp::ResourceRepo.new
      @supplier_repo = MasterfilesApp::SupplierRepo.new
      @cultivar_repo = MasterfilesApp::CultivarRepo.new
      @fruit_repo = MasterfilesApp::FruitRepo.new
      @size_repo = MasterfilesApp::RmtSizeRepo.new
      @calender_repo = MasterfilesApp::CalendarRepo.new

      @rules[:implements_presort_legacy_data_fields] = AppConst::CR_RMT.implements_presort_legacy_data_fields?

      make_form_object

      @rules[:can_edit?] = !@form_object.setup_completed && !@form_object.running && !@form_object.staged && !repo.running_or_staged_children?(@form_object.id)

      apply_form_values
      add_progress_step
      add_controls
      common_values_for_fields common_fields
      add_plant_resource_field

      add_behaviours

      form_name 'presort_staging_run'
    end

    def add_plant_resource_field
      if repo.exists?(:presort_staging_run_children, presort_staging_run_id: @form_object.id)
        supplier_id_label = @supplier_repo.find_supplier(@form_object.supplier_id)&.supplier
        fields[:supplier_id] = { renderer: :label, with_value: supplier_id_label, caption: 'Supplier' }
      else
        fields[:supplier_id] = { renderer: :select, options: @supplier_repo.for_select_suppliers,
                                 disabled_options: @supplier_repo.for_select_inactive_suppliers,
                                 caption: 'Supplier',
                                 prompt: true }
      end
    end

    def common_fields # rubocop:disable Metrics/AbcSize
      season_id_label = repo.get(:seasons, :season_code, @form_object.season_id)
      fields = { id: { renderer: :label, with_value: @form_object.id, caption: 'Run Id' },
                 presort_unit_plant_resource_id: { renderer: :select,
                                                   options: @resource_repo.for_select_plant_resources_of_type(Crossbeams::Config::ResourceDefinitions::PRESORTING_UNIT),
                                                   caption: 'Line Plant Resource',
                                                   required: true,
                                                   prompt: true },
                 cultivar_id: { renderer: :select, options: @cultivar_repo.for_select_cultivars,
                                disabled_options: @cultivar_repo.for_select_inactive_cultivars,
                                caption: 'Cultivar', required: true,
                                prompt: true },
                 rmt_class_id: { renderer: :select, options: @fruit_repo.for_select_rmt_classes,
                                 disabled_options: @fruit_repo.for_select_inactive_rmt_classes,
                                 caption: 'Rmt Class',
                                 required: false,
                                 prompt: true },
                 rmt_size_id: { renderer: :select, options: @size_repo.for_select_rmt_sizes,
                                caption: 'Rmt Size',
                                required: false,
                                prompt: true },
                 season_id: { renderer: :label, with_value: season_id_label, caption: 'Season' } }

      return fields unless rules[:implements_presort_legacy_data_fields]

      fields[:colour_percentage_id] = { renderer: :select,
                                        options: messcada_repo.for_select_run_colour_percentages_for_cultivar(@form_object.cultivar_id),
                                        caption: 'Colour',
                                        prompt: true }
      fields[:actual_cold_treatment_id] = { renderer: :select,
                                            options: messcada_repo.for_select_treatments_by_type(AppConst::COLD_TREATMENT),
                                            prompt: true }
      fields[:actual_ripeness_treatment_id] = { renderer: :select,
                                                options: messcada_repo.for_select_treatments_by_type(AppConst::RIPENESS_TREATMENT),
                                                prompt: true }
      fields[:rmt_code_id] = { renderer: :select,
                               options: messcada_repo.for_select_rmt_codes_by_cultivar(@form_object.cultivar_id),
                               prompt: true }
      fields
    end

    def make_form_object
      if @mode == :new
        make_new_form_object
        return
      end

      @form_object = repo.find_presort_staging_run(@options[:id])
    end

    def make_new_form_object
      @form_object = OpenStruct.new(uncompleted_at: nil,
                                    completed: true,
                                    presort_unit_plant_resource_id: nil,
                                    supplier_id: nil,
                                    completed_at: nil,
                                    canceled: true,
                                    canceled_at: nil,
                                    cultivar_id: nil,
                                    rmt_class_id: nil,
                                    rmt_size_id: nil,
                                    season_id: nil,
                                    editing: true,
                                    staged: true,
                                    legacy_data: nil)
    end

    def handle_behaviour
      changed = {
        cultivar_changed: :cultivar_changed
      }
      changed = changed[@options[:field]]
      return unhandled_behaviour! if changed.nil?

      send(changed)
    end

    private

    def add_progress_step
      steps = ['Editing', 'Setup Completed', 'Running', 'Staged']
      step = 0
      step = 1 if @form_object.setup_completed
      step = 2 if @form_object.running
      step = 3 if @form_object.staged

      @form_object = OpenStruct.new(@form_object.to_h.merge(steps: steps, step: step))
    end

    def add_controls
      id = @form_object.id
      complete_setup = { control_type: :link,
                         style: :action_button,
                         text: 'Complete Setup',
                         url: "/raw_materials/presorting/presort_staging_runs/#{id}/complete_setup",
                         icon: :checkon }

      uncomplete_setup = { control_type: :link,
                           style: :action_button,
                           text: 'Uncomplete Setup',
                           url: "/raw_materials/presorting/presort_staging_runs/#{id}/uncomplete_setup",
                           icon: :back }

      activate = { control_type: :link,
                   style: :action_button,
                   text: 'Activate Run',
                   url: "/raw_materials/presorting/presort_staging_runs/#{id}/activate_run",
                   icon: :checkon }

      complete_staging = { control_type: :link,
                           style: :action_button,
                           text: 'Complete Staging',
                           url: "/raw_materials/presorting/presort_staging_runs/#{id}/complete_staging",
                           icon: :checkon }

      controls = case @form_object.step
                 when 0
                   [complete_setup]
                 when 1
                   [uncomplete_setup, activate]
                 when 2
                   [complete_staging]
                 else
                   []
                 end

      @form_object = OpenStruct.new(@form_object.to_h.merge(controls: controls))
    end

    def repo
      RawMaterialsApp::PresortStagingRunRepo.new
    end

    def messcada_repo
      MesscadaApp::MesscadaRepo.new
    end

    def add_behaviours
      url = "/raw_materials/presorting/presort_staging_runs/ui_change/#{@mode}"
      behaviours do |behaviour|
        behaviour.dropdown_change :cultivar_id, notify: [{ url: "#{url}/cultivar_changed" }]
      end
    end

    def cultivar_changed # rubocop:disable Metrics/AbcSize
      actions = []
      if !params[:changed_value].nil_or_empty?
        season_id = MasterfilesApp::CalendarRepo.new.get_season_id(params[:changed_value], Time.now)
        season_code = repo.get_value(:seasons, :season_code, id: season_id) if season_id

        if AppConst::CR_RMT.implements_presort_legacy_data_fields?
          colour_percentages = messcada_repo.for_select_run_colour_percentages_for_cultivar(params[:changed_value])
          actions << OpenStruct.new(type: :replace_select_options, dom_id: 'presort_staging_run_colour_percentage_id', options_array: colour_percentages)
          rmt_codes = messcada_repo.for_select_rmt_codes_by_cultivar(params[:changed_value])
          actions << OpenStruct.new(type: :replace_select_options, dom_id: 'presort_staging_run_rmt_code_id', options_array: rmt_codes)
        end
      elsif AppConst::CR_RMT.implements_presort_legacy_data_fields?
        actions << OpenStruct.new(type: :replace_select_options, dom_id: 'presort_staging_run_colour_percentage_id', options_array: [])
        actions << OpenStruct.new(type: :replace_select_options, dom_id: 'presort_staging_run_rmt_code_id', options_array: [])
      end

      actions << OpenStruct.new(type: :replace_inner_html, dom_id: 'presort_staging_run_season_id', value: season_code)
      json_actions(actions)
    end
  end
end
