# frozen_string_literal: true

class Nspack < Roda
  route 'quality', 'masterfiles' do |r|
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
  end
end
