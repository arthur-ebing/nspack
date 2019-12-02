# frozen_string_literal: true

module UiRules
  class GovtInspectionSheetRule < Base # rubocop:disable Metrics/ClassLength
    def generate_rules
      @repo = FinishedGoodsApp::GovtInspectionSheetRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields common_fields

      set_show_fields if %i[show reopen add_pallet capture_results].include? @mode

      add_behaviours

      form_name 'govt_inspection_sheet'
    end

    def set_show_fields # rubocop:disable Metrics/AbcSize
      inspector_id_label = MasterfilesApp::InspectorRepo.new.find_inspector_flat(@form_object.inspector_id)&.inspector
      inspection_billing_party_role_id_label = MasterfilesApp::PartyRepo.new.find_party_role(@form_object.inspection_billing_party_role_id)&.party_name
      exporter_party_role_id_label = MasterfilesApp::PartyRepo.new.find_party_role(@form_object.exporter_party_role_id)&.party_name
      destination_country_id_label = MasterfilesApp::DestinationRepo.new.find_country(@form_object.destination_country_id)&.country_name
      govt_inspection_api_result_id_label = FinishedGoodsApp::GovtInspectionApiResultRepo.new.find_govt_inspection_api_result(@form_object.govt_inspection_api_result_id)&.upn_number
      fields[:inspector_id] = { renderer: :label,
                                with_value: inspector_id_label,
                                caption: 'Inspector' }
      fields[:inspection_billing_party_role_id] = { renderer: :label,
                                                    with_value: inspection_billing_party_role_id_label,
                                                    caption: 'Inspection Billing' }
      fields[:exporter_party_role_id] = { renderer: :label,
                                          with_value: exporter_party_role_id_label,
                                          caption: 'Exporter' }
      fields[:booking_reference] = { renderer: :label }
      fields[:results_captured] = { renderer: :label,
                                    as_boolean: true }
      fields[:results_captured_at] = { renderer: :label }
      fields[:api_results_received] = { renderer: :label,
                                        as_boolean: true }
      fields[:completed] = { renderer: :label,
                             as_boolean: true }
      fields[:completed_at] = { renderer: :label }
      fields[:inspected] = { renderer: :label,
                             as_boolean: true }
      fields[:inspection_point] = { renderer: :label }
      fields[:awaiting_inspection_results] = { renderer: :label,
                                               as_boolean: true }
      fields[:destination_country_id] = { renderer: :label,
                                          with_value: destination_country_id_label,
                                          caption: 'Destination Country' }
      fields[:active] = { renderer: :label,
                          as_boolean: true }
      fields[:govt_inspection_api_result_id] = { renderer: :label,
                                                 with_value: govt_inspection_api_result_id_label,
                                                 caption: 'Govt Inspection Api Result' }
    end

    def common_fields # rubocop:disable Metrics/AbcSize
      {
        inspector_id: { renderer: :select,
                        options: MasterfilesApp::InspectorRepo.new.for_select_inspectors,
                        disabled_options: MasterfilesApp::InspectorRepo.new.for_select_inactive_inspectors,
                        caption: 'Inspector',
                        required: true },
        inspection_billing_party_role_id: { renderer: :select,
                                            options: MasterfilesApp::PartyRepo.new.for_select_party_roles(AppConst::ROLE_INSPECTION_BILLING),
                                            disabled_options: MasterfilesApp::PartyRepo.new.for_select_inactive_party_roles(AppConst::ROLE_INSPECTION_BILLING),
                                            caption: 'Inspection Billing',
                                            required: true },
        exporter_party_role_id: { renderer: :select,
                                  options: MasterfilesApp::PartyRepo.new.for_select_party_roles(AppConst::ROLE_EXPORTER),
                                  disabled_options: MasterfilesApp::PartyRepo.new.for_select_inactive_party_roles(AppConst::ROLE_EXPORTER),
                                  caption: 'Exporter',
                                  required: true },
        booking_reference: { required: true },
        results_captured: { renderer: :checkbox },
        results_captured_at: { renderer: :date },
        api_results_received: { renderer: :checkbox },
        completed: { renderer: :checkbox,
                     disabled: true },
        completed_at: { renderer: :date },
        inspected: { renderer: :checkbox,
                     disabled: true },
        inspection_point: {},
        awaiting_inspection_results: { renderer: :checkbox },
        destination_country_id: { renderer: :select,
                                  options: MasterfilesApp::DestinationRepo.new.for_select_destination_countries,
                                  disabled_options: MasterfilesApp::DestinationRepo.new.for_select_inactive_destination_countries,
                                  caption: 'Destination Country',
                                  required: true },
        govt_inspection_api_result_id: { renderer: :select,
                                         options: FinishedGoodsApp::GovtInspectionApiResultRepo.new.for_select_govt_inspection_api_results,
                                         disabled_options: FinishedGoodsApp::GovtInspectionApiResultRepo.new.for_select_inactive_govt_inspection_api_results,
                                         caption: 'Govt Inspection Api Result' },
        pallet_number: { renderer: :input,
                         subtype: :numeric }
      }
    end

    def make_form_object
      make_new_form_object && return if @mode == :new

      @form_object = @repo.find_govt_inspection_sheet(@options[:id])
      @form_object = OpenStruct.new(@form_object.to_h.merge!(pallet_number: nil))
    end

    def make_new_form_object
      @form_object = OpenStruct.new(inspector_id: nil,
                                    inspection_billing_party_role_id: MasterfilesApp::PartyRepo.new.find_party_role_from_party_role_name(AppConst::DEFAULT_INSPECTION_BILLING),
                                    exporter_party_role_id: MasterfilesApp::PartyRepo.new.find_party_role_from_party_role_name(AppConst::DEFAULT_EXPORTER),
                                    booking_reference: @repo.last_record(:booking_reference),
                                    results_captured: nil,
                                    results_captured_at: nil,
                                    api_results_received: nil,
                                    completed: nil,
                                    completed_at: nil,
                                    inspected: nil,
                                    inspection_point: @repo.last_record(:inspection_point),
                                    awaiting_inspection_results: nil,
                                    destination_country_id: @repo.last_record(:destination_country_id),
                                    govt_inspection_api_result_id: nil,
                                    pallet_number: nil)
    end

    private

    def add_behaviours
      behaviours do |behaviour|
        behaviour.input_change(:completed, notify: [{ url: "/finished_goods/inspection/govt_inspection_sheets/#{@options[:id]}/add_pallets" }]) if @mode == :add_pallets
      end
    end
  end
end
