# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
class Nspack < Roda # rubocop:disable Metrics/ClassLength
  route 'inspection', 'finished_goods' do |r|
    # GOVT INSPECTION SHEETS
    # --------------------------------------------------------------------------
    r.on 'govt_inspection_sheets', Integer do |id|
      interactor = FinishedGoodsApp::GovtInspectionSheetInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

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
          pallet_number = MesscadaApp::ScannedPalletNumber.new(scanned_pallet_number: params[:govt_inspection_sheet][:pallet_number]).pallet_number
          res = interactor.update_govt_inspection_add_pallets(govt_inspection_sheet_id: id, pallet_number: pallet_number)
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
        if res.success
          flash[:notice] = res.message
          r.redirect '/list/govt_inspection_sheets'
        else
          flash[:error] = res.message
          r.redirect "/finished_goods/inspection/govt_inspection_sheets/#{id}/add_pallet"
        end
      end

      r.on 'reopen' do
        check_auth!('inspection', 'edit')
        interactor.assert_permission!(:reopen, id)
        res = interactor.reopen_govt_inspection_sheet(id)
        flash[res.success ? :notice : :error] = res.message
        r.redirect '/list/govt_inspection_sheets'
      end

      r.on 'cancel' do
        check_auth!('inspection', 'edit')
        interactor.assert_permission!(:cancel, id)
        res = interactor.cancel_govt_inspection_sheet(id)
        flash[res.success ? :notice : :error] = res.message
        r.redirect '/list/govt_inspection_sheets'
      end

      r.on 'capture' do   # COMPLETE
        r.get do
          check_auth!('inspection', 'edit')
          interactor.assert_permission!(:capture, id)
          show_partial_or_page(r) { FinishedGoods::Inspection::GovtInspectionSheet::Capture.call(id, request.referer) }
        end

        r.post do
          res = interactor.finish_govt_inspection_sheet(id)
          if res.success
            flash[:notice] = res.message
            redirect_to_last_grid(r)
          else
            re_show_form(r, res, url: "/finished_goods/inspection/govt_inspection_sheets/#{id}/capture") do
              FinishedGoods::Inspection::GovtInspectionSheet::Capture.call(id, request.referer)
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
        r.on 'reinspection' do    # NEW Reinspection
          show_partial_or_page(r) { FinishedGoods::Inspection::GovtInspectionSheet::New.call(mode: :reinspection) }
        end
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

      r.on 'pass' do # EDIT
        check_auth!('inspection', 'edit')
        interactor.assert_permission!(:edit, id)
        res = interactor.pass_govt_inspection_pallet(id)
        flash[:notice] = res.message
        r.redirect request.referer
      end

      r.on 'fail' do # EDIT
        r.get do
          check_auth!('inspection', 'edit')
          interactor.assert_permission!(:edit, id)
          show_partial_or_page(r) { FinishedGoods::Inspection::GovtInspectionPallet::Capture.call(id) }
        end

        r.patch do
          res = interactor.fail_govt_inspection_pallet(id, params[:govt_inspection_pallet])
          if res.success
            flash[:notice] = res.message
            redirect_via_json(request.referer)
          else
            re_show_form(r, res, url: "/finished_goods/inspection/govt_inspection_pallets/#{id}/capture") do
              FinishedGoods::Inspection::GovtInspectionPallet::Capture.call(id, form_values: params[:govt_inspection_pallet], form_errors: res.errors)
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

      r.on 'capture' do
        res = interactor.pass_govt_inspection_pallet(multiselect_grid_choices(params))
        flash[res.success ? :notice : :error] = res.message
        r.redirect request.referer
      end

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
  end
end
# rubocop:enable Metrics/BlockLength
