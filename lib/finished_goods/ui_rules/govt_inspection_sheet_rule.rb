# frozen_string_literal: true

module UiRules
  class GovtInspectionSheetRule < Base # rubocop:disable Metrics/ClassLength
    def generate_rules
      @repo = FinishedGoodsApp::GovtInspectionRepo.new
      @party_repo = MasterfilesApp::PartyRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields common_fields

      set_show_fields if %i[show].include? @mode
      add_behaviours if %i[new edit].include? @mode

      add_progress_step
      add_controls
      add_rules

      form_name 'govt_inspection_sheet'
    end

    def set_show_fields # rubocop:disable Metrics/AbcSize
      fields[:inspector] = { renderer: :label }
      fields[:inspection_billing] = { renderer: :label }
      fields[:exporter] = { renderer: :label }
      fields[:booking_reference] = { renderer: :label }
      fields[:results_captured] = { renderer: :label, as_boolean: true }
      fields[:results_captured_at] = { renderer: :label }
      fields[:api_results_received] = { renderer: :label,  as_boolean: true }
      fields[:use_inspection_destination_for_load_out] = { renderer: :label,
                                                           caption: 'Use Destination Region For Load Out EDI',
                                                           as_boolean: true }
      fields[:completed] = { renderer: :label,  as_boolean: true }
      fields[:completed_at] = { renderer: :label }
      fields[:inspected] = { renderer: :label,  as_boolean: true }
      fields[:inspection_point] = { renderer: :label }
      fields[:awaiting_inspection_results] = { renderer: :label, as_boolean: true }
      fields[:packed_tm_group_id] = { renderer: :label,
                                      caption: 'Packed TM Group' }
      fields[:destination_region] = { renderer: :label }
      fields[:destination_country] = { renderer: :label }
      fields[:active] = { renderer: :label,  as_boolean: true }
      fields[:upn] = { renderer: :label, caption: 'UPN' }
      fields[:reinspection] = { renderer: :label,
                                hide_on_load: !@form_object.reinspection,
                                as_boolean: true }
      fields[:created_by] = { renderer: :label }
      fields[:consignment_note_number] = { renderer: :label }
      fields[:status] = { renderer: :label }
    end

    def common_fields # rubocop:disable Metrics/AbcSize
      valid_tm_group_ids = @repo.select_values(:destination_regions_tm_groups, :target_market_group_id)
      valid_destination_region_ids = @repo.select_values(:destination_regions_tm_groups, :destination_region_id)
      {
        inspector_id: { renderer: :select,
                        options: MasterfilesApp::InspectorRepo.new.for_select_inspectors,
                        disabled_options: MasterfilesApp::InspectorRepo.new.for_select_inactive_inspectors,
                        caption: 'Inspector',
                        required: true },
        inspection_billing_party_role_id: { renderer: :select,
                                            options: @party_repo.for_select_party_roles(AppConst::ROLE_INSPECTION_BILLING),
                                            disabled_options: @party_repo.for_select_inactive_party_roles(AppConst::ROLE_INSPECTION_BILLING),
                                            caption: 'Inspection Billing',
                                            required: true },
        exporter_party_role_id: { renderer: :select,
                                  options: @party_repo.for_select_party_roles(AppConst::ROLE_EXPORTER),
                                  disabled_options: @party_repo.for_select_inactive_party_roles(AppConst::ROLE_EXPORTER),
                                  caption: 'Exporter',
                                  required: true },
        booking_reference: { required: true },
        results_captured: { renderer: :checkbox },
        results_captured_at: { renderer: :date },
        api_results_received: { renderer: :checkbox },
        use_inspection_destination_for_load_out: { renderer: :checkbox,
                                                   caption: 'Use Destination Region For Load Out EDI' },
        completed: { renderer: :checkbox,
                     disabled: true },
        completed_at: { renderer: :date },
        inspected: { renderer: :checkbox,
                     disabled: true },
        inspection_point: {},
        awaiting_inspection_results: { renderer: :checkbox },
        packed_tm_group_id: { renderer: :select,
                              options: MasterfilesApp::TargetMarketRepo.new.for_select_packed_tm_groups(
                                where: { id: valid_tm_group_ids }
                              ),
                              disabled_options: MasterfilesApp::TargetMarketRepo.new.for_select_inactive_tm_groups,
                              caption: 'Packed TM Group',
                              required: true },
        destination_region_id: { renderer: :select,
                                 options: MasterfilesApp::DestinationRepo.new.for_select_destination_regions(
                                   where: { id: valid_destination_region_ids }
                                 ),
                                 disabled_options: MasterfilesApp::DestinationRepo.new.for_select_inactive_destination_regions,
                                 caption: 'Destination Region',
                                 required: true },
        destination_country_id: { renderer: :select,
                                  options: MasterfilesApp::DestinationRepo.new.for_select_destination_countries(
                                    where: { destination_region_id: valid_destination_region_ids }
                                  ),
                                  disabled_options: MasterfilesApp::DestinationRepo.new.for_select_inactive_destination_countries,
                                  caption: 'Destination Country',
                                  prompt: true,
                                  required: false },
        upn: { renderer: :label, caption: 'UPN' },
        scanned_number: { renderer: :input,
                          caption: 'Pallet Number',
                          subtype: :numeric,
                          hide_on_load: @form_object.completed },
        reinspection: { renderer: :checkbox,
                        hide_on_load: !@form_object.reinspection,
                        disable: @mode != :reinspection },
        created_by: { disabled: true },
        consignment_note_number: { disabled: true },
        status: { disabled: true }
      }
    end

    def make_form_object
      make_new_form_object && return if %i[new reinspection].include? @mode

      @form_object = OpenStruct.new(@repo.find_govt_inspection_sheet(@options[:id]).to_h)
      @form_object[:scanned_number] = nil
    end

    def make_new_form_object
      @form_object = OpenStruct.new(inspector_id: nil,
                                    inspection_billing_party_role_id: @party_repo.find_party_role_from_party_name_for_role(AppConst::DEFAULT_INSPECTION_BILLING, AppConst::ROLE_BILLING_CLIENT),
                                    exporter_party_role_id: @party_repo.find_party_role_from_party_name_for_role(AppConst::DEFAULT_EXPORTER, AppConst::ROLE_EXPORTER),
                                    booking_reference: @repo.get_last(:govt_inspection_sheets, :booking_reference),
                                    results_captured: nil,
                                    results_captured_at: nil,
                                    api_results_received: nil,
                                    use_inspection_destination_for_load_out: AppConst::CR_FG.use_inspection_destination_for_load_out?,
                                    completed: nil,
                                    completed_at: nil,
                                    inspected: nil,
                                    inspection_point: @repo.get_last(:govt_inspection_sheets, :inspection_point),
                                    awaiting_inspection_results: nil,
                                    packed_tm_group_id: @repo.get_last(:govt_inspection_sheets, :packed_tm_group_id),
                                    destination_region_id: @repo.get_last(:govt_inspection_sheets, :destination_region_id),
                                    destination_country_id: @repo.get_last(:govt_inspection_sheets, :destination_country_id),
                                    reinspection: @mode == :reinspection,
                                    scanned_number: nil)
    end

    private

    def add_progress_step
      steps = ['Add Pallets', 'Capture Results', 'Finished']
      step = 0
      step = 1 if @form_object.completed
      step = 2 if @form_object.inspected

      @form_object[:steps] = steps
      @form_object[:step] = step
    end

    def add_controls # rubocop:disable Metrics/AbcSize
      id = @options[:id]
      edit = { control_type: :link,
               style: :action_button,
               text: 'Edit',
               url: "/finished_goods/inspection/govt_inspection_sheets/#{id}/edit",
               prompt: 'Are you sure, you want to edit this inspection?',
               icon: :edit }
      delete = { control_type: :link,
                 style: :action_button,
                 text: 'Delete',
                 url: "/finished_goods/inspection/govt_inspection_sheets/#{id}/delete",
                 prompt: 'Are you sure, you want to delete this inspection?',
                 visible: !@form_object.allocated,
                 icon: :checkoff }
      complete = { control_type: :link,
                   style: :action_button,
                   text: 'Complete adding pallets',
                   url: "/finished_goods/inspection/govt_inspection_sheets/#{id}/complete",
                   prompt: 'Are you sure, you want to complete this inspection?',
                   icon: :checkon }
      uncomplete = { control_type: :link,
                     style: :action_button,
                     text: 'Uncomplete',
                     url: "/finished_goods/inspection/govt_inspection_sheets/#{id}/uncomplete",
                     prompt: 'Are you sure you want to uncomplete this inspection?',
                     icon: :back }
      preverify = { control_type: :link,
                    style: :action_button,
                    text: 'eCert Preverify',
                    url: "/finished_goods/inspection/govt_inspection_sheets/#{id}/preverify",
                    icon: :checkon }
      titan_inspection = { control_type: :link,
                           style: :action_button,
                           text: 'Titan Inspection',
                           url: "/finished_goods/inspection/govt_inspection_sheets/#{id}/titan_inspection",
                           visible: @form_object.allow_titan_inspection & AppConst::CR_FG.do_titan_inspections?,
                           icon: :edit }
      finish = { control_type: :link,
                 style: :action_button,
                 text: 'Finish Inspection',
                 url: "/finished_goods/inspection/govt_inspection_sheets/#{id}/finish",
                 icon: :checkon }
      reopen = { control_type: :link,
                 style: :action_button,
                 text: 'Reopen',
                 url: "/finished_goods/inspection/govt_inspection_sheets/#{id}/reopen",
                 prompt: 'Are you sure you want to reopen this inspection?',
                 icon: :back }
      toggle = @form_object.use_inspection_destination_for_load_out
      toggle_use_inspection_destination = { control_type: :link,
                                            style: :action_button,
                                            text: "#{toggle ? "Don't use" : 'Use'} Destination Region for Load Out",
                                            url: "/finished_goods/inspection/govt_inspection_sheets/#{id}/toggle_use_inspection_destination",
                                            prompt: "Are you sure you#{toggle ? ' do not' : ''} want to use destination region for load out?",
                                            icon: :edit }

      case @form_object.step
      when 0
        instance_controls = [edit, delete]
        progress_controls = [complete]
      when 1
        instance_controls = [edit]
        progress_controls = [uncomplete, preverify, titan_inspection, finish]
      when 2
        instance_controls = []
        progress_controls = [reopen, titan_inspection, toggle_use_inspection_destination]
      else
        instance_controls = []
        progress_controls = []
      end
      @form_object[:progress_controls] = progress_controls
      @form_object[:instance_controls] = instance_controls
    end

    def add_behaviours
      behaviours do |behaviour|
        behaviour.dropdown_change(:packed_tm_group_id, notify: [{ url: '/finished_goods/inspection/govt_inspection_sheets/packed_tm_group_changed' }])
        behaviour.dropdown_change(:destination_region_id, notify: [{ url: '/finished_goods/inspection/govt_inspection_sheets/destination_region_changed' }])
      end
    end

    def add_rules # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      rules[:inspected] = @form_object.inspected
      rules[:create_intake_tripsheet] = @form_object.inspected && !@form_object.tripsheet_created && !AppConst::HIDE_INTAKE_TRIP_SHEET_ON_GOVT_INSPECTION_SHEET
      rules[:load_vehicle] = @form_object.tripsheet_created && !@form_object.tripsheet_loaded
      rules[:vehicle_loaded] = @form_object.tripsheet_loaded
      rules[:cancel_tripsheet] = (@form_object.tripsheet_created || @form_object.tripsheet_loaded) && !@form_object.tripsheet_offloaded
      rules[:refresh_tripsheet] = (@form_object.tripsheet_created || @form_object.tripsheet_loaded) && !@form_object.tripsheet_offloaded && @repo.refresh_tripsheet?(@form_object.id)
      rules[:print_tripsheet] = (@form_object.tripsheet_created || @form_object.tripsheet_loaded) && !@form_object.tripsheet_offloaded
      rules[:tripsheet_complete] = @repo.refresh_to_complete_offload?(@form_object.id)
    end
  end
end
