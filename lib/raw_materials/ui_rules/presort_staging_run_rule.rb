# frozen_string_literal: true

module UiRules
  class PresortStagingRunRule < Base # rubocop:disable Metrics/ClassLength
    def generate_rules # rubocop:disable Metrics/AbcSize
      @resource_repo = ProductionApp::ResourceRepo.new
      @supplier_repo = MasterfilesApp::SupplierRepo.new
      @cultivar_repo = MasterfilesApp::CultivarRepo.new
      @fruit_repo = MasterfilesApp::FruitRepo.new
      @size_repo = MasterfilesApp::RmtSizeRepo.new
      @calender_repo = MasterfilesApp::CalendarRepo.new

      kr?
      make_form_object
      apply_form_values
      add_progress_step
      add_controls

      @rules[:can_edit?] = !@form_object[:setup_completed] && !@form_object[:active] && !@form_object[:staged] && !repo.active_or_staged_children?(@form_object[:id])

      common_values_for_fields common_fields
      add_plant_resource_field

      set_show_fields unless @rules[:can_edit?] || @mode == :new

      add_behaviours

      form_name 'presort_staging_run'
    end

    def kr?
      @rules[:is_kr] = (AppConst::CLIENT_CODE == 'kr')
    end

    def add_plant_resource_field
      if repo.exists?(:presort_staging_run_children, presort_staging_run_id: @form_object[:id])
        supplier_id_label = @supplier_repo.find_supplier(@form_object[:supplier_id])&.supplier
        fields[:supplier_id] = { renderer: :label, with_value: supplier_id_label, caption: 'Supplier' }
      else
        fields[:supplier_id] = { renderer: :select, options: @supplier_repo.for_select_suppliers,
                                 disabled_options: @supplier_repo.for_select_inactive_suppliers,
                                 caption: 'Supplier',
                                 required: true,
                                 prompt: true }
      end
    end

    def set_show_fields # rubocop:disable Metrics/AbcSize
      supplier_id_label = @supplier_repo.find_supplier(@form_object[:supplier_id])&.supplier
      cultivar_id_label = repo.get(:cultivars, @form_object[:cultivar_id], :cultivar_name)
      presort_unit_plant_resource_id_label = repo.get(:plant_resources, @form_object[:presort_unit_plant_resource_id], :plant_resource_code)
      rmt_class_id_label = repo.get(:rmt_classes, @form_object[:rmt_class_id], :rmt_class_code)
      rmt_size_id_label = repo.get(:rmt_sizes, @form_object[:rmt_size_id], :size_code)
      season_id_label = repo.get(:seasons, @form_object[:season_id], :season_code)
      fields[:setup_uncompleted_at] = { renderer: :label, format: :without_timezone_or_seconds }
      fields[:setup_completed] = { renderer: :label, as_boolean: true }
      fields[:presort_unit_plant_resource_id] = { renderer: :label, with_value: presort_unit_plant_resource_id_label, caption: 'Line Plant Resource' }
      fields[:supplier_id] = { renderer: :label, with_value: supplier_id_label, caption: 'Supplier' }
      fields[:setup_completed_at] = { renderer: :label, format: :without_timezone_or_seconds }
      fields[:canceled] = { renderer: :label, as_boolean: true }
      fields[:canceled_at] = { renderer: :label, format: :without_timezone_or_seconds }
      fields[:cultivar_id] = { renderer: :label, with_value: cultivar_id_label, caption: 'Cultivar' }
      fields[:rmt_class_id] = { renderer: :label, with_value: rmt_class_id_label, caption: 'Rmt Class' }
      fields[:rmt_size_id] = { renderer: :label, with_value: rmt_size_id_label, caption: 'Rmt Size' }
      fields[:season_id] = { renderer: :label, with_value: season_id_label, caption: 'Season' }
      fields[:editing] = { renderer: :label, as_boolean: true }
      fields[:staged] = { renderer: :label, as_boolean: true }
      fields[:active] = { renderer: :label, as_boolean: true }
      return fields unless kr?

      fields[:ripe_point_code] = { renderer: :label, with_value: @form_object[:legacy_data].to_h['ripe_point_code'] }
      fields[:track_indicator_code] = { renderer: :label, with_value: @form_object[:legacy_data].to_h['track_indicator_code'] }
    end

    def common_fields
      season_id_label = repo.get(:seasons, @form_object[:season_id], :season_code)
      fields = { presort_unit_plant_resource_id: { renderer: :select,
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
                                 required: true,
                                 prompt: true },
                 rmt_size_id: { renderer: :select, options: @size_repo.for_select_rmt_sizes,
                                caption: 'Rmt Size',
                                required: true,
                                prompt: true },
                 season_id: { renderer: :label, with_value: season_id_label, caption: 'Season' } }

      return fields unless @rules[:is_kr]

      fields[:ripe_point_code] = { renderer: :select, options: messcada_repo.ripe_point_codes.map { |s| s[0] }.uniq, required: true, prompt: true }
      fields[:track_indicator_code] = { renderer: :select, options: [], required: true, prompt: true }
      fields
    end

    def make_form_object
      if @mode == :new
        make_new_form_object
        return
      end

      @form_object = repo.find_presort_staging_run(@options[:id])
      @form_object = repo.find_presort_staging_run(@options[:id]).to_h.merge(ripe_point_code: @form_object.legacy_data.to_h['ripe_point_code'], track_indicator_code: @form_object.legacy_data.to_h['track_indicator_code']) if kr?
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
      steps = ['Editing', 'Setup Completed', 'Activated', 'Staged']
      step = 0
      step = 1 if @form_object.setup_completed
      step = 2 if @form_object.active
      step = 3 if @form_object.staged

      @form_object = OpenStruct.new(@form_object.to_h.merge(steps: steps, step: step))
    end

    def add_controls
      id = @form_object[:id]
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
      unless params[:changed_value].nil_or_empty?
        season_id = MasterfilesApp::CalendarRepo.new.get_season_id(params[:changed_value], Time.now)
        season_code = repo.get_value(:seasons, :season_code, id: season_id) if season_id

        if kr?
          cultivar_name = repo.get(:cultivars, params[:changed_value], :cultivar_name)
          track_indicator_codes = messcada_repo.track_indicator_codes(cultivar_name).uniq if cultivar_name
          actions << OpenStruct.new(type: :replace_select_options, dom_id: 'presort_staging_run_track_indicator_code', options_array: track_indicator_codes.to_a)
        end
      end

      actions << OpenStruct.new(type: :replace_inner_html, dom_id: 'presort_staging_run_season_id', value: season_code)
      json_actions(actions)
    end
  end
end
