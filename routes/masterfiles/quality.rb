# frozen_string_literal: true

class Nspack < Roda
  route 'quality', 'masterfiles' do |r|
    # ORCHARD TEST TYPES
    # --------------------------------------------------------------------------
    r.on 'orchard_test_types', Integer do |id|
      interactor = QualityApp::OrchardTestTypeInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      # Check for notfound:
      r.on !interactor.exists?(:orchard_test_types, id) do
        handle_not_found(r)
      end

      r.on 'edit' do   # EDIT
        check_auth!('quality', 'edit')
        interactor.assert_permission!(:edit, id)
        show_partial_or_page(r) { Quality::Config::OrchardTestType::Edit.call(id) }
      end

      r.is do
        r.get do       # SHOW
          check_auth!('quality', 'read')
          show_partial_or_page(r) { Quality::Config::OrchardTestType::Show.call(id) }
        end
        r.patch do     # UPDATE
          res = interactor.update_orchard_test_type(id, params[:orchard_test_type])
          if res.success
            flash[:notice] = res.message
            redirect_via_json '/list/orchard_test_results'
          else
            re_show_form(r, res) { Quality::Config::OrchardTestType::Edit.call(id, form_values: params[:orchard_test_type], form_errors: res.errors) }
          end
        end
        r.delete do    # DELETE
          check_auth!('quality', 'delete')
          interactor.assert_permission!(:delete, id)
          res = interactor.delete_orchard_test_type(id)
          if res.success
            delete_grid_row(id, notice: res.message)
          else
            show_json_error(res.message, status: 200)
          end
        end
      end
    end

    r.on 'orchard_test_types' do
      @repo = QualityApp::OrchardTestRepo.new
      r.on 'api_name_changed' do
        actions = []
        if params[:changed_value] == AppConst::PHYT_CLEAN_STANDARD
          actions << OpenStruct.new(type: :show_element, dom_id: 'orchard_test_type_api_attribute_field_wrapper')
          options_array = @repo.for_select_orchard_test_api_attributes(AppConst::PHYT_CLEAN_STANDARD)
        else
          actions << OpenStruct.new(type: :hide_element, dom_id: 'orchard_test_type_api_attribute_field_wrapper')
          options_array = nil
        end
        actions << OpenStruct.new(type: :replace_select_options, dom_id: 'orchard_test_type_api_attribute', options_array: options_array)
        json_actions(actions)
      end

      r.on 'result_type_changed' do
        actions = []
        if params[:changed_value] == AppConst::CLASSIFICATION
          actions << OpenStruct.new(type: :set_required, dom_id: 'orchard_test_type_api_pass_result', required: false)
          actions << OpenStruct.new(type: :hide_element, dom_id: 'orchard_test_type_api_pass_result_field_wrapper')
        else
          actions << OpenStruct.new(type: :set_required, dom_id: 'orchard_test_type_api_pass_result', required: true)
          actions << OpenStruct.new(type: :show_element, dom_id: 'orchard_test_type_api_pass_result_field_wrapper')
        end
        json_actions(actions)
      end

      r.on 'commodity_group_changed' do
        if params[:changed_value].nil_or_empty?
          blank_json_response
        else
          actions = []
          commodity_ids = @repo.select_values(:commodities, :id, commodity_group_id: Array(params[:changed_value].split(',')))
          cultivar_list = MasterfilesApp::CultivarRepo.new.for_select_cultivar_codes(where: { commodity_id: commodity_ids })
          actions << OpenStruct.new(type: :replace_multi_options, dom_id: 'orchard_test_type_applicable_cultivar_ids', options_array: cultivar_list)
          json_actions(actions)
        end
      end

      r.on 'applies_to_all_markets' do
        if params[:changed_value].nil_or_empty?
          blank_json_response
        else
          actions = []
          actions << OpenStruct.new(type: params[:changed_value] == 'f' ? :show_element : :hide_element, dom_id: 'orchard_test_type_applicable_tm_group_ids_field_wrapper')
          json_actions(actions)
        end
      end

      r.on 'applies_to_all_cultivars' do
        if params[:changed_value].nil_or_empty?
          blank_json_response
        else
          actions = []
          actions << OpenStruct.new(type: params[:changed_value] == 'f' ? :show_element : :hide_element, dom_id: 'orchard_test_type_applicable_commodity_group_ids_field_wrapper')
          actions << OpenStruct.new(type: params[:changed_value] == 'f' ? :show_element : :hide_element, dom_id: 'orchard_test_type_applicable_cultivar_ids_field_wrapper')
          json_actions(actions)
        end
      end

      interactor = QualityApp::OrchardTestTypeInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})
      r.on 'new' do    # NEW
        check_auth!('quality', 'new')
        show_partial_or_page(r) { Quality::Config::OrchardTestType::New.call(remote: fetch?(r)) }
      end
      r.post do        # CREATE
        res = interactor.create_orchard_test_type(params[:orchard_test_type])
        if res.success
          flash[:notice] = res.message
          r.redirect '/list/orchard_test_results'
        else
          re_show_form(r, res, url: '/masterfiles/quality/orchard_test_types/new') do
            Quality::Config::OrchardTestType::New.call(form_values: params[:orchard_test_type],
                                                       form_errors: res.errors,
                                                       remote: fetch?(r))
          end
        end
      end
    end

    # PALLET VERIFICATION FAILURE REASONS
    # --------------------------------------------------------------------------
    r.on 'pallet_verification_failure_reasons', Integer do |id|
      interactor = MasterfilesApp::PalletVerificationFailureReasonInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      # Check for notfound:
      r.on !interactor.exists?(:pallet_verification_failure_reasons, id) do
        handle_not_found(r)
      end

      r.on 'edit' do   # EDIT
        check_auth!('quality', 'edit')
        interactor.assert_permission!(:edit, id)
        show_partial { Masterfiles::Quality::PalletVerificationFailureReason::Edit.call(id) }
      end

      r.is do
        r.get do       # SHOW
          check_auth!('quality', 'read')
          show_partial { Masterfiles::Quality::PalletVerificationFailureReason::Show.call(id) }
        end
        r.patch do     # UPDATE
          res = interactor.update_pallet_verification_failure_reason(id, params[:pallet_verification_failure_reason])
          if res.success
            update_grid_row(id, changes: { reason: res.instance[:reason] },
                                notice: res.message)
          else
            re_show_form(r, res) { Masterfiles::Quality::PalletVerificationFailureReason::Edit.call(id, form_values: params[:pallet_verification_failure_reason], form_errors: res.errors) }
          end
        end
        r.delete do    # DELETE
          check_auth!('quality', 'delete')
          interactor.assert_permission!(:delete, id)
          res = interactor.delete_pallet_verification_failure_reason(id)
          if res.success
            delete_grid_row(id, notice: res.message)
          else
            show_json_error(res.message, status: 200)
          end
        end
      end
    end

    r.on 'pallet_verification_failure_reasons' do
      interactor = MasterfilesApp::PalletVerificationFailureReasonInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})
      r.on 'new' do    # NEW
        check_auth!('quality', 'new')
        show_partial_or_page(r) { Masterfiles::Quality::PalletVerificationFailureReason::New.call(remote: fetch?(r)) }
      end
      r.post do        # CREATE
        res = interactor.create_pallet_verification_failure_reason(params[:pallet_verification_failure_reason])
        if res.success
          row_keys = %i[
            id
            reason
            active
          ]
          add_grid_row(attrs: select_attributes(res.instance, row_keys),
                       notice: res.message)
        else
          re_show_form(r, res, url: '/masterfiles/quality/pallet_verification_failure_reasons/new') do
            Masterfiles::Quality::PalletVerificationFailureReason::New.call(form_values: params[:pallet_verification_failure_reason],
                                                                            form_errors: res.errors,
                                                                            remote: fetch?(r))
          end
        end
      end
    end

    # SCRAP REASONS
    # --------------------------------------------------------------------------
    r.on 'scrap_reasons', Integer do |id|
      interactor = MasterfilesApp::ScrapReasonInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      # Check for notfound:
      r.on !interactor.exists?(:scrap_reasons, id) do
        handle_not_found(r)
      end

      r.on 'edit' do   # EDIT
        check_auth!('quality', 'edit')
        interactor.assert_permission!(:edit, id)
        show_partial { Masterfiles::Quality::ScrapReason::Edit.call(id) }
      end

      r.is do
        r.get do       # SHOW
          check_auth!('quality', 'read')
          show_partial { Masterfiles::Quality::ScrapReason::Show.call(id) }
        end
        r.patch do     # UPDATE
          res = interactor.update_scrap_reason(id, params[:scrap_reason])
          if res.success
            row_keys = %i[
              scrap_reason
              description
              applies_to_pallets
              applies_to_bins
              applies_to_cartons
            ]
            update_grid_row(id, changes: select_attributes(res.instance, row_keys), notice: res.message)
          else
            re_show_form(r, res) { Masterfiles::Quality::ScrapReason::Edit.call(id, form_values: params[:scrap_reason], form_errors: res.errors) }
          end
        end
        r.delete do    # DELETE
          check_auth!('quality', 'delete')
          interactor.assert_permission!(:delete, id)
          res = interactor.delete_scrap_reason(id)
          if res.success
            delete_grid_row(id, notice: res.message)
          else
            show_json_error(res.message, status: 200)
          end
        end
      end
    end

    r.on 'scrap_reasons' do
      interactor = MasterfilesApp::ScrapReasonInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})
      r.on 'new' do    # NEW
        check_auth!('quality', 'new')
        show_partial_or_page(r) { Masterfiles::Quality::ScrapReason::New.call(remote: fetch?(r)) }
      end
      r.post do        # CREATE
        res = interactor.create_scrap_reason(params[:scrap_reason])
        if res.success
          row_keys = %i[
            id
            scrap_reason
            description
            active
            applies_to_pallets
            applies_to_bins
            applies_to_cartons
          ]
          add_grid_row(attrs: select_attributes(res.instance, row_keys),
                       notice: res.message)
        else
          re_show_form(r, res, url: '/masterfiles/quality/scrap_reasons/new') do
            Masterfiles::Quality::ScrapReason::New.call(form_values: params[:scrap_reason],
                                                        form_errors: res.errors,
                                                        remote: fetch?(r))
          end
        end
      end
    end

    # INSPECTORS
    # --------------------------------------------------------------------------
    r.on 'inspectors', Integer do |id|
      interactor = MasterfilesApp::InspectorInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      # Check for notfound:
      r.on !interactor.exists?(:inspectors, id) do
        handle_not_found(r)
      end

      r.on 'edit' do   # EDIT
        check_auth!('quality', 'edit')
        interactor.assert_permission!(:edit, id)
        show_partial { Masterfiles::Quality::Inspector::Edit.call(id) }
      end

      r.is do
        r.get do       # SHOW
          check_auth!('quality', 'read')
          show_partial { Masterfiles::Quality::Inspector::Show.call(id) }
        end
        r.patch do     # UPDATE
          res = interactor.update_inspector(id, params[:inspector])
          if res.success
            row_keys = %i[
              inspector
              inspector_code
              tablet_ip_address
              tablet_port_number
            ]
            update_grid_row(id, changes: select_attributes(res.instance, row_keys), notice: res.message)
          else
            re_show_form(r, res) { Masterfiles::Quality::Inspector::Edit.call(id, form_values: params[:inspector], form_errors: res.errors) }
          end
        end
        r.delete do    # DELETE
          check_auth!('quality', 'delete')
          interactor.assert_permission!(:delete, id)
          res = interactor.delete_inspector(id)
          if res.success
            delete_grid_row(id, notice: res.message)
          else
            show_json_error(res.message, status: 200)
          end
        end
      end
    end

    r.on 'inspectors' do
      interactor = MasterfilesApp::InspectorInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})
      r.on 'new' do    # NEW
        check_auth!('quality', 'new')
        show_partial_or_page(r) { Masterfiles::Quality::Inspector::New.call(remote: fetch?(r)) }
      end

      r.post do        # CREATE
        res = interactor.create_inspector(params[:inspector])
        if res.success
          row_keys = %i[
            id
            inspector
            inspector_code
            tablet_ip_address
            tablet_port_number
            active
          ]
          add_grid_row(attrs: select_attributes(res.instance, row_keys),
                       notice: res.message)
        else
          re_show_form(r, res, url: '/masterfiles/quality/inspectors/new') do
            Masterfiles::Quality::Inspector::New.call(form_values: params[:inspector],
                                                      form_errors: res.errors,
                                                      remote: fetch?(r))
          end
        end
      end
    end

    # INSPECTION FAILURE TYPES
    # --------------------------------------------------------------------------
    r.on 'inspection_failure_types', Integer do |id|
      interactor = MasterfilesApp::InspectionFailureTypeInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      # Check for notfound:
      r.on !interactor.exists?(:inspection_failure_types, id) do
        handle_not_found(r)
      end

      r.on 'edit' do   # EDIT
        check_auth!('quality', 'edit')
        interactor.assert_permission!(:edit, id)
        show_partial { Masterfiles::Quality::InspectionFailureType::Edit.call(id) }
      end

      r.is do
        r.get do       # SHOW
          check_auth!('quality', 'read')
          show_partial { Masterfiles::Quality::InspectionFailureType::Show.call(id) }
        end
        r.patch do     # UPDATE
          res = interactor.update_inspection_failure_type(id, params[:inspection_failure_type])
          if res.success
            update_grid_row(id, changes: { failure_type_code: res.instance[:failure_type_code], description: res.instance[:description] }, notice: res.message)
          else
            re_show_form(r, res) { Masterfiles::Quality::InspectionFailureType::Edit.call(id, form_values: params[:inspection_failure_type], form_errors: res.errors) }
          end
        end
        r.delete do    # DELETE
          check_auth!('quality', 'delete')
          interactor.assert_permission!(:delete, id)
          res = interactor.delete_inspection_failure_type(id)
          if res.success
            delete_grid_row(id, notice: res.message)
          else
            show_json_error(res.message, status: 200)
          end
        end
      end
    end

    r.on 'inspection_failure_types' do
      interactor = MasterfilesApp::InspectionFailureTypeInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})
      r.on 'new' do    # NEW
        check_auth!('quality', 'new')
        show_partial_or_page(r) { Masterfiles::Quality::InspectionFailureType::New.call(remote: fetch?(r)) }
      end
      r.post do        # CREATE
        res = interactor.create_inspection_failure_type(params[:inspection_failure_type])
        if res.success
          row_keys = %i[
            id
            failure_type_code
            description
            active
          ]
          add_grid_row(attrs: select_attributes(res.instance, row_keys),
                       notice: res.message)
        else
          re_show_form(r, res, url: '/masterfiles/quality/inspection_failure_types/new') do
            Masterfiles::Quality::InspectionFailureType::New.call(form_values: params[:inspection_failure_type],
                                                                  form_errors: res.errors,
                                                                  remote: fetch?(r))
          end
        end
      end
    end

    # INSPECTION FAILURE REASONS
    # --------------------------------------------------------------------------
    r.on 'inspection_failure_reasons', Integer do |id|
      interactor = MasterfilesApp::InspectionFailureReasonInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      # Check for notfound:
      r.on !interactor.exists?(:inspection_failure_reasons, id) do
        handle_not_found(r)
      end

      r.on 'edit' do   # EDIT
        check_auth!('quality', 'edit')
        interactor.assert_permission!(:edit, id)
        show_partial { Masterfiles::Quality::InspectionFailureReason::Edit.call(id) }
      end

      r.is do
        r.get do       # SHOW
          check_auth!('quality', 'read')
          show_partial { Masterfiles::Quality::InspectionFailureReason::Show.call(id) }
        end
        r.patch do     # UPDATE
          res = interactor.update_inspection_failure_reason(id, params[:inspection_failure_reason])
          if res.success
            row_keys = %i[
              inspection_failure_type_id
              failure_type_code
              failure_reason
              description
              main_factor
              secondary_factor
              status
              active
            ]
            update_grid_row(id, changes: select_attributes(res.instance, row_keys), notice: res.message)
          else
            re_show_form(r, res) { Masterfiles::Quality::InspectionFailureReason::Edit.call(id, form_values: params[:inspection_failure_reason], form_errors: res.errors) }
          end
        end
        r.delete do    # DELETE
          check_auth!('quality', 'delete')
          interactor.assert_permission!(:delete, id)
          res = interactor.delete_inspection_failure_reason(id)
          if res.success
            delete_grid_row(id, notice: res.message)
          else
            show_json_error(res.message, status: 200)
          end
        end
      end
    end

    r.on 'inspection_failure_reasons' do
      interactor = MasterfilesApp::InspectionFailureReasonInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})
      r.on 'new' do    # NEW
        check_auth!('quality', 'new')
        show_partial_or_page(r) { Masterfiles::Quality::InspectionFailureReason::New.call(remote: fetch?(r)) }
      end
      r.post do        # CREATE
        res = interactor.create_inspection_failure_reason(params[:inspection_failure_reason])
        if res.success
          row_keys = %i[
            id
            inspection_failure_type_id
            failure_type_code
            failure_reason
            description
            main_factor
            secondary_factor
            status
            active
          ]
          add_grid_row(attrs: select_attributes(res.instance, row_keys),
                       notice: res.message)
        else
          re_show_form(r, res, url: '/masterfiles/quality/inspection_failure_reasons/new') do
            Masterfiles::Quality::InspectionFailureReason::New.call(form_values: params[:inspection_failure_reason],
                                                                    form_errors: res.errors,
                                                                    remote: fetch?(r))
          end
        end
      end
    end

    # INSPECTION TYPES
    # --------------------------------------------------------------------------
    r.on 'inspection_types', Integer do |id|
      interactor = MasterfilesApp::InspectionTypeInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      # Check for notfound:
      r.on !interactor.exists?(:inspection_types, id) do
        handle_not_found(r)
      end

      r.on 'edit' do   # EDIT
        check_auth!('quality', 'edit')
        interactor.assert_permission!(:edit, id)
        show_partial { Masterfiles::Quality::InspectionType::Edit.call(id) }
      end

      r.is do
        r.get do       # SHOW
          check_auth!('quality', 'read')
          show_partial { Masterfiles::Quality::InspectionType::Show.call(id) }
        end
        r.patch do     # UPDATE
          res = interactor.update_inspection_type(id, params[:inspection_type])
          if res.success
            row_keys = %i[
              inspection_type_code
              description
              inspection_failure_type_id
              failure_type_code
              passed_default
              applicable_tm_ids
              applicable_tms
              applicable_tm_customer_ids
              applicable_tm_customers
              applicable_grade_ids
              applicable_grades
              applicable_marketing_org_party_role_ids
              applicable_marketing_org_party_roles
              applicable_packed_tm_group_ids
              applicable_packed_tm_groups
            ]
            update_grid_row(id, changes: select_attributes(res.instance, row_keys), notice: res.message)
          else
            re_show_form(r, res) { Masterfiles::Quality::InspectionType::Edit.call(id, form_values: params[:inspection_type], form_errors: res.errors) }
          end
        end
        r.delete do    # DELETE
          check_auth!('quality', 'delete')
          interactor.assert_permission!(:delete, id)
          res = interactor.delete_inspection_type(id)
          if res.success
            delete_grid_row(id, notice: res.message)
          else
            show_json_error(res.message, status: 200)
          end
        end
      end
    end

    r.on 'inspection_types' do
      interactor = MasterfilesApp::InspectionTypeInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      r.on 'change', String, String do |change_mode, change_field|
        handle_ui_change(:inspection_type, change_mode.to_sym, params, { field: change_field.to_sym })
      end

      r.on 'new' do    # NEW
        check_auth!('quality', 'new')
        show_partial_or_page(r) { Masterfiles::Quality::InspectionType::New.call(remote: fetch?(r)) }
      end

      r.post do        # CREATE
        res = interactor.create_inspection_type(params[:inspection_type])
        if res.success
          row_keys = %i[
            id
            inspection_type_code
            description
            inspection_failure_type_id
            failure_type_code
            passed_default
            applicable_tm_ids
            applicable_tms
            applicable_tm_customer_ids
            applicable_tm_customers
            applicable_grade_ids
            applicable_grades
            applicable_marketing_org_party_role_ids
            applicable_marketing_org_party_roles
            applicable_packed_tm_group_ids
            applicable_packed_tm_groups
            active
          ]
          add_grid_row(attrs: select_attributes(res.instance, row_keys),
                       notice: res.message)
        else
          re_show_form(r, res, url: '/masterfiles/quality/inspection_types/new') do
            Masterfiles::Quality::InspectionType::New.call(form_values: params[:inspection_type],
                                                           form_errors: res.errors,
                                                           remote: fetch?(r))
          end
        end
      end
    end

    # QC MEASUREMENT TYPES
    # --------------------------------------------------------------------------
    r.on 'qc_measurement_types', Integer do |id|
      interactor = MasterfilesApp::QcInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      # Check for notfound:
      r.on !interactor.exists?(:qc_measurement_types, id) do
        handle_not_found(r)
      end

      r.on 'edit' do   # EDIT
        check_auth!('quality', 'edit')
        interactor.assert_permission!(:qc_measurement_type, :edit, id)
        show_partial { Masterfiles::Quality::QcMeasurementType::Edit.call(id) }
      end

      r.is do
        r.get do       # SHOW
          check_auth!('quality', 'read')
          show_partial { Masterfiles::Quality::QcMeasurementType::Show.call(id) }
        end
        r.patch do     # UPDATE
          res = interactor.update_qc_measurement_type(id, params[:qc_measurement_type])
          if res.success
            update_grid_row(id, changes: { qc_measurement_type_name: res.instance[:qc_measurement_type_name], description: res.instance[:description] },
                                notice: res.message)
          else
            re_show_form(r, res) { Masterfiles::Quality::QcMeasurementType::Edit.call(id, form_values: params[:qc_measurement_type], form_errors: res.errors) }
          end
        end
        r.delete do    # DELETE
          check_auth!('quality', 'delete')
          interactor.assert_permission!(:qc_measurement_type, :delete, id)
          res = interactor.delete_qc_measurement_type(id)
          if res.success
            delete_grid_row(id, notice: res.message)
          else
            show_json_error(res.message, status: 200)
          end
        end
      end
    end

    r.on 'qc_measurement_types' do
      interactor = MasterfilesApp::QcInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})
      r.on 'new' do    # NEW
        check_auth!('quality', 'new')
        show_partial_or_page(r) { Masterfiles::Quality::QcMeasurementType::New.call(remote: fetch?(r)) }
      end
      r.post do        # CREATE
        res = interactor.create_qc_measurement_type(params[:qc_measurement_type])
        if res.success
          row_keys = %i[
            id
            qc_measurement_type_name
            description
            active
          ]
          add_grid_row(attrs: select_attributes(res.instance, row_keys),
                       notice: res.message)
        else
          re_show_form(r, res, url: '/masterfiles/quality/qc_measurement_types/new') do
            Masterfiles::Quality::QcMeasurementType::New.call(form_values: params[:qc_measurement_type],
                                                              form_errors: res.errors,
                                                              remote: fetch?(r))
          end
        end
      end
    end

    # QC SAMPLE TYPES
    # --------------------------------------------------------------------------
    r.on 'qc_sample_types', Integer do |id|
      interactor = MasterfilesApp::QcInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      # Check for notfound:
      r.on !interactor.exists?(:qc_sample_types, id) do
        handle_not_found(r)
      end

      r.on 'edit' do   # EDIT
        check_auth!('quality', 'edit')
        interactor.assert_permission!(:qc_sample_type, :edit, id)
        show_partial { Masterfiles::Quality::QcSampleType::Edit.call(id) }
      end

      r.is do
        r.get do       # SHOW
          check_auth!('quality', 'read')
          show_partial { Masterfiles::Quality::QcSampleType::Show.call(id) }
        end
        r.patch do     # UPDATE
          res = interactor.update_qc_sample_type(id, params[:qc_sample_type])
          if res.success
            update_grid_row(id, changes: { qc_sample_type_name: res.instance[:qc_sample_type_name],
                                           description: res.instance[:description],
                                           default_sample_size: res.instance[:default_sample_size] },
                                notice: res.message)
          else
            re_show_form(r, res) { Masterfiles::Quality::QcSampleType::Edit.call(id, form_values: params[:qc_sample_type], form_errors: res.errors) }
          end
        end
        r.delete do    # DELETE
          check_auth!('quality', 'delete')
          interactor.assert_permission!(:qc_sample_type, :delete, id)
          res = interactor.delete_qc_sample_type(id)
          if res.success
            delete_grid_row(id, notice: res.message)
          else
            show_json_error(res.message, status: 200)
          end
        end
      end
    end

    r.on 'qc_sample_types' do
      interactor = MasterfilesApp::QcInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})
      r.on 'new' do    # NEW
        check_auth!('quality', 'new')
        show_partial_or_page(r) { Masterfiles::Quality::QcSampleType::New.call(remote: fetch?(r)) }
      end
      r.post do        # CREATE
        res = interactor.create_qc_sample_type(params[:qc_sample_type])
        if res.success
          row_keys = %i[
            id
            qc_sample_type_name
            description
            default_sample_size
            active
          ]
          add_grid_row(attrs: select_attributes(res.instance, row_keys),
                       notice: res.message)
        else
          re_show_form(r, res, url: '/masterfiles/quality/qc_sample_types/new') do
            Masterfiles::Quality::QcSampleType::New.call(form_values: params[:qc_sample_type],
                                                         form_errors: res.errors,
                                                         remote: fetch?(r))
          end
        end
      end
    end

    # QC TEST TYPES
    # --------------------------------------------------------------------------
    r.on 'qc_test_types', Integer do |id|
      interactor = MasterfilesApp::QcInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      # Check for notfound:
      r.on !interactor.exists?(:qc_test_types, id) do
        handle_not_found(r)
      end

      r.on 'edit' do   # EDIT
        check_auth!('quality', 'edit')
        interactor.assert_permission!(:qc_test_type, :edit, id)
        show_partial { Masterfiles::Quality::QcTestType::Edit.call(id) }
      end

      r.is do
        r.get do       # SHOW
          check_auth!('quality', 'read')
          show_partial { Masterfiles::Quality::QcTestType::Show.call(id) }
        end
        r.patch do     # UPDATE
          res = interactor.update_qc_test_type(id, params[:qc_test_type])
          if res.success
            update_grid_row(id, changes: { qc_test_type_name: res.instance[:qc_test_type_name], description: res.instance[:description] },
                                notice: res.message)
          else
            re_show_form(r, res) { Masterfiles::Quality::QcTestType::Edit.call(id, form_values: params[:qc_test_type], form_errors: res.errors) }
          end
        end
        r.delete do    # DELETE
          check_auth!('quality', 'delete')
          interactor.assert_permission!(:qc_test_type, :delete, id)
          res = interactor.delete_qc_test_type(id)
          if res.success
            delete_grid_row(id, notice: res.message)
          else
            show_json_error(res.message, status: 200)
          end
        end
      end
    end

    r.on 'qc_test_types' do
      interactor = MasterfilesApp::QcInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})
      r.on 'new' do    # NEW
        check_auth!('quality', 'new')
        show_partial_or_page(r) { Masterfiles::Quality::QcTestType::New.call(remote: fetch?(r)) }
      end
      r.post do        # CREATE
        res = interactor.create_qc_test_type(params[:qc_test_type])
        if res.success
          row_keys = %i[
            id
            qc_test_type_name
            description
            active
          ]
          add_grid_row(attrs: select_attributes(res.instance, row_keys),
                       notice: res.message)
        else
          re_show_form(r, res, url: '/masterfiles/quality/qc_test_types/new') do
            Masterfiles::Quality::QcTestType::New.call(form_values: params[:qc_test_type],
                                                       form_errors: res.errors,
                                                       remote: fetch?(r))
          end
        end
      end
    end

    # FRUIT DEFECT TYPES
    # --------------------------------------------------------------------------
    r.on 'fruit_defect_types', Integer do |id|
      interactor = MasterfilesApp::QcInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      # Check for notfound:
      r.on !interactor.exists?(:fruit_defect_types, id) do
        handle_not_found(r)
      end

      r.on 'edit' do   # EDIT
        check_auth!('quality', 'edit')
        interactor.assert_permission!(:fruit_defect_type, :edit, id)
        show_partial { Masterfiles::Quality::FruitDefectType::Edit.call(id) }
      end

      r.is do
        r.get do       # SHOW
          check_auth!('quality', 'read')
          show_partial { Masterfiles::Quality::FruitDefectType::Show.call(id) }
        end
        r.patch do     # UPDATE
          res = interactor.update_fruit_defect_type(id, params[:fruit_defect_type])
          if res.success
            update_grid_row(id, changes: { fruit_defect_type_name: res.instance[:fruit_defect_type_name], description: res.instance[:description] },
                                notice: res.message)
          else
            re_show_form(r, res) { Masterfiles::Quality::FruitDefectType::Edit.call(id, form_values: params[:fruit_defect_type], form_errors: res.errors) }
          end
        end
        r.delete do    # DELETE
          check_auth!('quality', 'delete')
          interactor.assert_permission!(:fruit_defect_type, :delete, id)
          res = interactor.delete_fruit_defect_type(id)
          if res.success
            delete_grid_row(id, notice: res.message)
          else
            show_json_error(res.message, status: 200)
          end
        end
      end
    end

    r.on 'fruit_defect_types' do
      interactor = MasterfilesApp::QcInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})
      r.on 'new' do    # NEW
        check_auth!('quality', 'new')
        show_partial_or_page(r) { Masterfiles::Quality::FruitDefectType::New.call(remote: fetch?(r)) }
      end
      r.post do        # CREATE
        res = interactor.create_fruit_defect_type(params[:fruit_defect_type])
        if res.success
          row_keys = %i[
            id
            fruit_defect_type_name
            description
            active
          ]
          add_grid_row(attrs: select_attributes(res.instance, row_keys),
                       notice: res.message)
        else
          re_show_form(r, res, url: '/masterfiles/quality/fruit_defect_types/new') do
            Masterfiles::Quality::FruitDefectType::New.call(form_values: params[:fruit_defect_type],
                                                            form_errors: res.errors,
                                                            remote: fetch?(r))
          end
        end
      end
    end

    # FRUIT DEFECTS
    # --------------------------------------------------------------------------
    r.on 'fruit_defects', Integer do |id|
      interactor = MasterfilesApp::QcInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      # Check for notfound:
      r.on !interactor.exists?(:fruit_defects, id) do
        handle_not_found(r)
      end

      r.on 'edit' do   # EDIT
        check_auth!('quality', 'edit')
        interactor.assert_permission!(:fruit_defect, :edit, id)
        show_partial { Masterfiles::Quality::FruitDefect::Edit.call(id) }
      end

      r.is do
        r.get do       # SHOW
          check_auth!('quality', 'read')
          show_partial { Masterfiles::Quality::FruitDefect::Show.call(id) }
        end
        r.patch do     # UPDATE
          res = interactor.update_fruit_defect(id, params[:fruit_defect])
          if res.success
            row_keys = %i[
              rmt_class_id
              fruit_defect_type_id
              fruit_defect_code
              short_description
              description
              internal
              rmt_class_code
              fruit_defect_type_name
            ]
            update_grid_row(id, changes: select_attributes(res.instance, row_keys), notice: res.message)
          else
            re_show_form(r, res) { Masterfiles::Quality::FruitDefect::Edit.call(id, form_values: params[:fruit_defect], form_errors: res.errors) }
          end
        end
        r.delete do    # DELETE
          check_auth!('quality', 'delete')
          interactor.assert_permission!(:fruit_defect, :delete, id)
          res = interactor.delete_fruit_defect(id)
          if res.success
            delete_grid_row(id, notice: res.message)
          else
            show_json_error(res.message, status: 200)
          end
        end
      end
    end

    r.on 'fruit_defects' do
      interactor = MasterfilesApp::QcInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})
      r.on 'new' do    # NEW
        check_auth!('quality', 'new')
        show_partial_or_page(r) { Masterfiles::Quality::FruitDefect::New.call(remote: fetch?(r)) }
      end
      r.post do        # CREATE
        res = interactor.create_fruit_defect(params[:fruit_defect])
        if res.success
          row_keys = %i[
            id
            rmt_class_id
            fruit_defect_type_id
            fruit_defect_code
            short_description
            description
            internal
            rmt_class_code
            fruit_defect_type_name
          ]
          add_grid_row(attrs: select_attributes(res.instance, row_keys),
                       notice: res.message)
        else
          re_show_form(r, res, url: '/masterfiles/quality/fruit_defects/new') do
            Masterfiles::Quality::FruitDefect::New.call(form_values: params[:fruit_defect],
                                                        form_errors: res.errors,
                                                        remote: fetch?(r))
          end
        end
      end
    end
  end
end
