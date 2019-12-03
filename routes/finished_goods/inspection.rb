# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
class Nspack < Roda # rubocop:disable Metrics/ClassLength
  route 'inspection', 'finished_goods' do |r|
    # GOVT INSPECTION SHEETS
    # --------------------------------------------------------------------------
    r.on 'govt_inspection_sheets', Integer do |id|
      interactor = FinishedGoodsApp::GovtInspectionSheetInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})
      pallet_interactor = FinishedGoodsApp::GovtInspectionPalletInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})
      # Check for notfound:
      r.on !interactor.exists?(:govt_inspection_sheets, id) do
        handle_not_found(r)
      end

      r.on 'add_pallet' do   # ADD_PALLETS
        r.get do
          check_auth!('inspection', 'edit')
          interactor.assert_permission!(:edit, id)
          show_partial_or_page(r) { FinishedGoods::Inspection::GovtInspectionSheet::AddPallet.call(id) }
        end

        r.post do
          res = pallet_interactor.add_pallets_govt_inspection_pallet(govt_inspection_sheet_id: id, pallet_number: params[:govt_inspection_sheet][:pallet_number])
          if res.success
            flash[:notice] = res.message
            r.redirect "/finished_goods/inspection/govt_inspection_sheets/#{id}/add_pallet"
          else
            re_show_form(r, res, url: "/finished_goods/inspection/govt_inspection_sheets/#{id}/add_pallet") do
              FinishedGoods::Inspection::GovtInspectionSheet::AddPallet.call(id)
            end
          end
        end
      end

      r.on 'edit' do   # EDIT
        check_auth!('inspection', 'edit')
        interactor.assert_permission!(:edit, id)
        show_partial_or_page(r) { FinishedGoods::Inspection::GovtInspectionSheet::Edit.call(id) }
      end

      r.on 'complete' do
        check_auth!('inspection', 'edit')
        interactor.assert_permission!(:complete, id)
        res = interactor.complete_govt_inspection_sheet(id)
        flash[:notice] = res.message
        r.redirect '/list/govt_inspection_sheets'
      end

      r.on 'uncomplete' do
        check_auth!('inspection', 'edit')
        interactor.assert_permission!(:uncomplete, id)
        res = interactor.uncomplete_govt_inspection_sheet(id)
        flash[:notice] = res.message
        r.redirect '/list/govt_inspection_sheets'
      end

      r.on 'capture_results_multiselect' do
        check_auth!('inspection', 'edit')
        interactor.assert_permission!(:edit, id)
        res = pallet_interactor.pass_govt_inspection_pallet_multiselect(multiselect_grid_choices(params))
        flash[:notice] = res.message
        r.redirect request.referer
      end

      r.on 'complete_inspection' do   # COMPLETE
        r.get do
          check_auth!('inspection', 'edit')
          interactor.assert_permission!(:complete_inspection, id)
          show_partial_or_page(r) { FinishedGoods::Inspection::GovtInspectionSheet::CompleteInspection.call(id) }
        end

        r.post do
          res = interactor.complete_inspection_govt_inspection_sheet(id)
          if res.success
            flash[:notice] = res.message
            redirect_to_last_grid(r)
          else
            re_show_form(r, res, url: "/finished_goods/inspection/govt_inspection_sheets/#{id}/complete_inspection") do
              FinishedGoods::Inspection::GovtInspectionSheet::CompleteInspection.call(id)
            end
          end
        end
      end

      r.is do
        r.get do       # SHOW
          check_auth!('inspection', 'read')
          show_partial_or_page(r) { FinishedGoods::Inspection::GovtInspectionSheet::Show.call(id) }
        end
        r.patch do     # UPDATE
          res = interactor.update_govt_inspection_sheet(id, params[:govt_inspection_sheet])
          if res.success
            flash[:notice] = res.message
            redirect_to_last_grid(r)
          else
            re_show_form(r, res) { FinishedGoods::Inspection::GovtInspectionSheet::Edit.call(id, form_values: params[:govt_inspection_sheet], form_errors: res.errors) }
          end
        end
        r.delete do    # DELETE
          check_auth!('inspection', 'delete')
          interactor.assert_permission!(:delete, id)
          res = interactor.delete_govt_inspection_sheet(id)
          if res.success
            delete_grid_row(id, notice: res.message)
          else
            show_json_error(res.message, status: 200)
          end
        end
      end
    end

    r.on 'govt_inspection_sheets' do
      interactor = FinishedGoodsApp::GovtInspectionSheetInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})
      r.on 'new' do    # NEW
        check_auth!('inspection', 'new')
        show_partial_or_page(r) { FinishedGoods::Inspection::GovtInspectionSheet::New.call }
      end
      r.post do        # CREATE
        res = interactor.create_govt_inspection_sheet(params[:govt_inspection_sheet])
        if res.success
          flash[:notice] = res.message
          r.redirect "/finished_goods/inspection/govt_inspection_sheets/#{res.instance.id}/add_pallet"
        else
          re_show_form(r, res, url: '/finished_goods/inspection/govt_inspection_sheets/new') do
            FinishedGoods::Inspection::GovtInspectionSheet::New.call(form_values: params[:govt_inspection_sheet], form_errors: res.errors)
          end
        end
      end
    end

    # GOVT INSPECTION PALLETS
    # --------------------------------------------------------------------------
    r.on 'govt_inspection_pallets', Integer do |id|
      interactor = FinishedGoodsApp::GovtInspectionPalletInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      # Check for notfound:
      r.on !interactor.exists?(:govt_inspection_pallets, id) do
        handle_not_found(r)
      end

      r.on 'capture_result' do   # EDIT
        r.get do
          check_auth!('inspection', 'edit')
          interactor.assert_permission!(:edit, id)
          show_partial { FinishedGoods::Inspection::GovtInspectionPallet::CaptureResult.call(id) }
        end

        r.patch do
          res = interactor.fail_govt_inspection_pallet(id, params[:govt_inspection_pallet])
          if res.success
            flash[:notice] = res.message
            row_keys = %i[pallet_id
                          govt_inspection_sheet_id
                          passed
                          inspected
                          inspected_at
                          failure_reason_id
                          failure_reason
                          failure_remarks
                          status]
            update_grid_row(id, changes: select_attributes(res.instance, row_keys), notice: res.message)
          else
            re_show_form(r, res, url: "/finished_goods/inspection/govt_inspection_pallets/#{id}/inspect") do
              FinishedGoods::Inspection::GovtInspectionPallet::CaptureResult.call(id, form_values: params[:govt_inspection_pallet], form_errors: res.errors)
            end
          end
        end
      end

      r.on 'edit' do   # EDIT
        check_auth!('inspection', 'edit')
        interactor.assert_permission!(:edit, id)
        show_partial { FinishedGoods::Inspection::GovtInspectionPallet::Edit.call(id) }
      end

      r.is do
        r.get do       # SHOW
          check_auth!('inspection', 'read')
          show_partial { FinishedGoods::Inspection::GovtInspectionPallet::Show.call(id) }
        end
        r.patch do     # UPDATE
          res = interactor.update_govt_inspection_pallet(id, params[:govt_inspection_pallet])
          if res.success
            row_keys = %i[pallet_id
                          govt_inspection_sheet_id
                          passed
                          inspected
                          inspected_at
                          failure_reason_id
                          failure_remarks]
            update_grid_row(id, changes: select_attributes(res.instance, row_keys), notice: res.message)
          else
            re_show_form(r, res) { FinishedGoods::Inspection::GovtInspectionPallet::Edit.call(id, form_values: params[:govt_inspection_pallet], form_errors: res.errors) }
          end
        end
        r.delete do    # DELETE
          check_auth!('inspection', 'delete')
          interactor.assert_permission!(:delete, id)
          res = interactor.delete_govt_inspection_pallet(id)
          if res.success
            delete_grid_row(id, notice: res.message)
          else
            show_json_error(res.message, status: 200)
          end
        end
      end
    end

    r.on 'govt_inspection_pallets' do
      interactor = FinishedGoodsApp::GovtInspectionPalletInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})
      r.on 'new' do    # NEW
        check_auth!('inspection', 'new')
        show_partial_or_page(r) { FinishedGoods::Inspection::GovtInspectionPallet::New.call(remote: fetch?(r)) }
      end
      r.post do        # CREATE
        res = interactor.create_govt_inspection_pallet(params[:govt_inspection_pallet])
        if res.success
          row_keys = %i[id
                        pallet_id
                        govt_inspection_sheet_id
                        passed
                        inspected
                        inspected_at
                        failure_reason_id
                        failure_remarks
                        active]
          add_grid_row(attrs: select_attributes(res.instance, row_keys),
                       notice: res.message)
        else
          re_show_form(r, res, url: '/finished_goods/inspection/govt_inspection_pallets/new') do
            FinishedGoods::Inspection::GovtInspectionPallet::New.call(form_values: params[:govt_inspection_pallet],
                                                                      form_errors: res.errors,
                                                                      remote: fetch?(r))
          end
        end
      end
    end

    # GOVT INSPECTION API RESULTS
    # --------------------------------------------------------------------------
    r.on 'govt_inspection_api_results', Integer do |id|
      interactor = FinishedGoodsApp::GovtInspectionApiResultInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      # Check for notfound:
      r.on !interactor.exists?(:govt_inspection_api_results, id) do
        handle_not_found(r)
      end

      r.on 'edit' do   # EDIT
        check_auth!('inspection', 'edit')
        interactor.assert_permission!(:edit, id)
        show_partial { FinishedGoods::Inspection::GovtInspectionApiResult::Edit.call(id) }
      end

      r.is do
        r.get do       # SHOW
          check_auth!('inspection', 'read')
          show_partial { FinishedGoods::Inspection::GovtInspectionApiResult::Show.call(id) }
        end
        r.patch do     # UPDATE
          res = interactor.update_govt_inspection_api_result(id, params[:govt_inspection_api_result])
          if res.success
            row_keys = %i[govt_inspection_sheet_id
                          govt_inspection_request_doc
                          govt_inspection_result_doc
                          results_requested
                          results_requested_at
                          results_received
                          results_received_at
                          upn_number]
            update_grid_row(id, changes: select_attributes(res.instance, row_keys), notice: res.message)
          else
            re_show_form(r, res) { FinishedGoods::Inspection::GovtInspectionApiResult::Edit.call(id, form_values: params[:govt_inspection_api_result], form_errors: res.errors) }
          end
        end
        r.delete do    # DELETE
          check_auth!('inspection', 'delete')
          interactor.assert_permission!(:delete, id)
          res = interactor.delete_govt_inspection_api_result(id)
          if res.success
            delete_grid_row(id, notice: res.message)
          else
            show_json_error(res.message, status: 200)
          end
        end
      end
    end

    r.on 'govt_inspection_api_results' do
      interactor = FinishedGoodsApp::GovtInspectionApiResultInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})
      r.on 'new' do    # NEW
        check_auth!('inspection', 'new')
        show_partial_or_page(r) { FinishedGoods::Inspection::GovtInspectionApiResult::New.call(remote: fetch?(r)) }
      end
      r.post do        # CREATE
        res = interactor.create_govt_inspection_api_result(params[:govt_inspection_api_result])
        if res.success
          row_keys = %i[
            id
            govt_inspection_sheet_id
            govt_inspection_request_doc
            govt_inspection_result_doc
            results_requested
            results_requested_at
            results_received
            results_received_at
            upn_number
            active
          ]
          add_grid_row(attrs: select_attributes(res.instance, row_keys),
                       notice: res.message)
        else
          re_show_form(r, res, url: '/finished_goods/inspection/govt_inspection_api_results/new') do
            FinishedGoods::Inspection::GovtInspectionApiResult::New.call(form_values: params[:govt_inspection_api_result],
                                                                         form_errors: res.errors,
                                                                         remote: fetch?(r))
          end
        end
      end
    end

    # GOVT INSPECTION PALLET API RESULTS
    # --------------------------------------------------------------------------
    r.on 'govt_inspection_pallet_api_results', Integer do |id|
      interactor = FinishedGoodsApp::GovtInspectionPalletApiResultInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      # Check for notfound:
      r.on !interactor.exists?(:govt_inspection_pallet_api_results, id) do
        handle_not_found(r)
      end

      r.on 'edit' do   # EDIT
        check_auth!('inspection', 'edit')
        interactor.assert_permission!(:edit, id)
        show_partial { FinishedGoods::Inspection::GovtInspectionPalletApiResult::Edit.call(id) }
      end

      r.is do
        r.get do       # SHOW
          check_auth!('inspection', 'read')
          show_partial { FinishedGoods::Inspection::GovtInspectionPalletApiResult::Show.call(id) }
        end
        r.patch do     # UPDATE
          res = interactor.update_govt_inspection_pallet_api_result(id, params[:govt_inspection_pallet_api_result])
          if res.success
            row_keys = %i[
              passed
              failure_reasons
              govt_inspection_pallet_id
              govt_inspection_api_result_id
            ]
            update_grid_row(id, changes: select_attributes(res.instance, row_keys), notice: res.message)
          else
            re_show_form(r, res) { FinishedGoods::Inspection::GovtInspectionPalletApiResult::Edit.call(id, form_values: params[:govt_inspection_pallet_api_result], form_errors: res.errors) }
          end
        end
        r.delete do    # DELETE
          check_auth!('inspection', 'delete')
          interactor.assert_permission!(:delete, id)
          res = interactor.delete_govt_inspection_pallet_api_result(id)
          if res.success
            delete_grid_row(id, notice: res.message)
          else
            show_json_error(res.message, status: 200)
          end
        end
      end
    end

    r.on 'govt_inspection_pallet_api_results' do
      interactor = FinishedGoodsApp::GovtInspectionPalletApiResultInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})
      r.on 'new' do    # NEW
        check_auth!('inspection', 'new')
        show_partial_or_page(r) { FinishedGoods::Inspection::GovtInspectionPalletApiResult::New.call(remote: fetch?(r)) }
      end
      r.post do        # CREATE
        res = interactor.create_govt_inspection_pallet_api_result(params[:govt_inspection_pallet_api_result])
        if res.success
          row_keys = %i[id
                        passed
                        failure_reasons
                        govt_inspection_pallet_id
                        govt_inspection_api_result_id
                        active]
          add_grid_row(attrs: select_attributes(res.instance, row_keys),
                       notice: res.message)
        else
          re_show_form(r, res, url: '/finished_goods/inspection/govt_inspection_pallet_api_results/new') do
            FinishedGoods::Inspection::GovtInspectionPalletApiResult::New.call(form_values: params[:govt_inspection_pallet_api_result],
                                                                               form_errors: res.errors,
                                                                               remote: fetch?(r))
          end
        end
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
