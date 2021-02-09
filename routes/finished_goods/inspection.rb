# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
# rubocop:disable Metrics/ClassLength
class Nspack < Roda
  route 'inspection', 'finished_goods' do |r|
    # GOVT INSPECTION SHEETS
    # --------------------------------------------------------------------------
    r.on 'govt_inspection_sheets', Integer do |id|
      interactor = FinishedGoodsApp::GovtInspectionSheetInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})
      r.on !interactor.exists?(:govt_inspection_sheets, id) do
        handle_not_found(r)
      end

      r.on 'create_intake_tripsheet' do
        r.get do
          show_partial_or_page(r) { FinishedGoods::Inspection::GovtInspectionSheet::NewIntakeTripsheet.call(id) }
        end

        r.post do
          res = interactor.create_intake_tripsheet(id, planned_location_to_id: params[:intake_tripsheet][:location_to_id], business_process_id: MesscadaApp::MesscadaRepo.new.find_business_process('FIRST_INTAKE')[:id],
                                                       stock_type_id: MesscadaApp::MesscadaRepo.new.find_stock_type('PALLET')[:id], govt_inspection_sheet_id: id)
          if res.success
            flash[:notice] = res.message
          else
            flash[:error] = res.message
          end
          r.redirect "/finished_goods/inspection/govt_inspection_sheets/#{id}"
        end
      end

      r.on 'load_vehicle' do
        r.get do
          res = interactor.load_vehicle(id)
          flash[res.success ? :notice : :error] = res.message
          r.redirect "/finished_goods/inspection/govt_inspection_sheets/#{id}"
        end
      end

      r.on 'vehicle_loaded_cancel_confirm' do
        show_partial do
          FinishedGoods::Tripsheet::Confirm.call(id,
                                                 url: "/finished_goods/inspection/govt_inspection_sheets/#{id}/vehicle_offloading_cancel_confirm",
                                                 notice: 'Vehicle has already been loaded. Are you sure want to cancel tripsheet?',
                                                 button_captions: %w[Ok Canceling])
        end
      end

      r.on 'vehicle_offloading_cancel_confirm' do
        res = interactor.offloading_started?(id)
        if res.instance[:offloaded_pallets].zero?
          redirect_via_json("/finished_goods/inspection/govt_inspection_sheets/#{id}/cancel_tripsheet")
        else
          show_partial do
            FinishedGoods::Tripsheet::Confirm.call(id,
                                                   url: "/finished_goods/inspection/govt_inspection_sheets/#{id}/cancel_tripsheet",
                                                   notice: "#{res.instance[:offloaded_pallets]} pallet#{res.instance[:offloaded_pallets] > 1 ? 's' : nil} have already been offloaded. Are you sure want to cancel tripsheet?",
                                                   button_captions: %w[Ok Canceling])
          end
        end
      end

      r.on 'cancel_tripsheet' do
        res = interactor.cancel_tripsheet(id)
        flash[res.success ? :notice : :error] = res.message

        r.get do
          r.redirect "/finished_goods/inspection/govt_inspection_sheets/#{id}"
        end

        r.post do
          redirect_via_json("/finished_goods/inspection/govt_inspection_sheets/#{id}")
        end
      end

      r.on 'refresh_tripsheet' do
        show_partial do
          FinishedGoods::Tripsheet::RefreshTripsheetConfirm.call(id,
                                                                 notice: 'A refresh will leave only offloaded pallets remaining in the tripsheet. Do you want to:')
        end
      end

      r.on 'refresh_tripsheet_cancelled' do
        flash[:error] = 'refresh_tripsheet cancelled'
        r.redirect "/finished_goods/inspection/govt_inspection_sheets/#{id}"
      end

      r.on 'refresh_tripsheet_confirmed' do
        r.get do
          res = interactor.refresh_tripsheet(id)
          flash[res.success ? :notice : :error] = res.message
          r.redirect "/finished_goods/inspection/govt_inspection_sheets/#{id}"
        end
      end

      r.on 'edit' do # EDIT
        check_auth!('inspection', 'edit')
        interactor.assert_permission!(:edit, id)
        show_partial_or_page(r) { FinishedGoods::Inspection::GovtInspectionSheet::Edit.call(id) }
      end

      r.on 'add_pallet' do # ADD_PALLETS
        interactor.assert_permission!(:add_pallet, id)
        r.post do
          res = interactor.add_pallet_govt_inspection_sheet(id, params[:govt_inspection_sheet])
          if res.success
            flash[:notice] = res.message
            r.redirect "/finished_goods/inspection/govt_inspection_sheets/#{id}"
          else
            re_show_form(r, res, url: "/finished_goods/inspection/govt_inspection_sheets/#{id}") do
              FinishedGoods::Inspection::GovtInspectionSheet::Show.call(id, form_values: params[:govt_inspection_sheet], form_errors: res.errors)
            end
          end
        end
      end

      r.on 'add_inspected_pallet' do # ADD_PALLETS
        interactor.assert_permission!(:add_pallet, id)
        r.post do
          res = interactor.validate_add_pallet_govt_inspection_params(id, params[:govt_inspection_sheet])
          if res.success
            json_launch_dialog(render_partial { FinishedGoods::Inspection::GovtInspectionPallet::New.call(form_values: res.instance) })
          else
            flash[:error] = res.message
            redirect_via_json "/finished_goods/inspection/govt_inspection_sheets/#{id}"
          end
        end
      end

      r.on 'complete' do
        check_auth!('inspection', 'edit')
        res = interactor.complete_govt_inspection_sheet(id)
        flash[res.success ? :notice : :error] = res.message
        r.redirect "/finished_goods/inspection/govt_inspection_sheets/#{id}"
      end

      r.on 'uncomplete' do
        check_auth!('inspection', 'edit')
        res = interactor.uncomplete_govt_inspection_sheet(id)
        flash[res.success ? :notice : :error] = res.message
        r.redirect "/finished_goods/inspection/govt_inspection_sheets/#{id}"
      end

      r.on 'finish' do
        check_auth!('inspection', 'edit')
        res = interactor.finish_govt_inspection_sheet(id)
        flash[res.success ? :notice : :error] = res.message
        r.redirect "/finished_goods/inspection/govt_inspection_sheets/#{id}"
      end

      r.on 'reopen' do
        check_auth!('inspection', 'edit')
        res = interactor.reopen_govt_inspection_sheet(id)
        flash[res.success ? :notice : :error] = res.message
        r.redirect "/finished_goods/inspection/govt_inspection_sheets/#{id}"
      end

      r.on 'toggle_use_inspection_destination' do
        check_auth!('inspection', 'edit')
        res = interactor.toggle_use_inspection_destination(id)
        flash[res.success ? :notice : :error] = res.message
        r.redirect "/finished_goods/inspection/govt_inspection_sheets/#{id}"
      end

      r.on 'cancel' do
        check_auth!('inspection', 'edit')
        res = interactor.cancel_govt_inspection_sheet(id)
        flash[res.success ? :notice : :error] = res.message
        r.redirect '/list/govt_inspection_sheets'
      end

      r.on 'delete' do    # DELETE
        check_auth!('inspection', 'delete')
        interactor.assert_permission!(:delete, id)
        res = interactor.delete_govt_inspection_sheet(id)
        if res.success
          flash[:notice] = res.message
          r.redirect '/list/govt_inspection_sheets'
        else
          flash[:error] = res.message
          r.redirect "/finished_goods/inspection/govt_inspection_sheets/#{id}"
        end
      end

      r.on 'preverify' do
        check_auth!('inspection', 'edit')
        show_partial_or_page(r) { FinishedGoods::Ecert::EcertTrackingUnit::New.call(govt_inspection_sheet_id: id, remote: fetch?(r)) }
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
            redirect_via_json "/finished_goods/inspection/govt_inspection_sheets/#{id}"
          else
            re_show_form(r, res) { FinishedGoods::Inspection::GovtInspectionSheet::Edit.call(id, form_values: params[:govt_inspection_sheet], form_errors: res.errors) }
          end
        end
      end
    end

    r.on 'govt_inspection_sheets' do
      r.on 'packed_tm_group_changed' do
        actions = []
        region_list = if params[:changed_value].nil_or_empty?
                        []
                      else
                        MasterfilesApp::DestinationRepo.new.for_select_destination_regions(where: { target_market_group_id: params[:changed_value] })
                      end
        actions << OpenStruct.new(type: :replace_select_options, dom_id: 'govt_inspection_sheet_destination_region_id', options_array: region_list)
        actions << OpenStruct.new(type: :change_select_value, dom_id: 'govt_inspection_sheet_destination_region_id', value: region_list.first.last) if region_list.length == 1
        json_actions(actions)
      end

      r.on 'destination_region_changed' do
        actions = []
        country_list = if params[:changed_value].nil_or_empty?
                         []
                       else
                         MasterfilesApp::DestinationRepo.new.for_select_destination_countries(where: { destination_region_id: params[:changed_value] })
                       end
        actions << OpenStruct.new(type: :replace_select_options, dom_id: 'govt_inspection_sheet_destination_country_id', options_array: country_list)
        actions << OpenStruct.new(type: :change_select_value, dom_id: 'govt_inspection_sheet_destination_country_id', value: country_list.first.last) if country_list.length == 1
        json_actions(actions)
      end

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
          redirect_via_json "/finished_goods/inspection/govt_inspection_sheets/#{res.instance.id}"
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
            row_keys = %i[pallet_number
                          pallet_id
                          govt_inspection_sheet_id
                          completed
                          passed
                          inspected
                          inspected_at
                          failure_reason_id
                          failure_reason
                          description
                          main_factor
                          secondary_factor
                          failure_remarks
                          sheet_inspected
                          gross_weight
                          carton_quantity
                          marketing_varieties
                          packed_tm_groups
                          pallet_base
                          active
                          colour_rule]
            update_grid_row(id,
                            changes: select_attributes(res.instance, row_keys),
                            grid_id: 'govt_inspection_pallets',
                            notice: res.message)
          else
            re_show_form(r, res) { FinishedGoods::Inspection::GovtInspectionPallet::Edit.call(id, form_values: params[:govt_inspection_pallet], form_errors: res.errors) }
          end
        end

        r.delete do    # DELETE
          check_auth!('inspection', 'delete')
          interactor.assert_permission!(:delete, id)
          res = interactor.delete_govt_inspection_pallet(id)
          if res.success
            flash[:notice] = res.message
            redirect_via_json "/finished_goods/inspection/govt_inspection_sheets/#{res.instance.govt_inspection_sheet_id}"
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
                        pallet_number
                        pallet_id
                        govt_inspection_sheet_id
                        completed
                        passed
                        inspected
                        inspected_at
                        failure_reason_id
                        failure_reason
                        description
                        main_factor
                        secondary_factor
                        failure_remarks
                        sheet_inspected
                        gross_weight
                        carton_quantity
                        marketing_varieties
                        packed_tm_groups
                        pallet_base
                        active
                        colour_rule]
          add_grid_row(attrs: select_attributes(res.instance, row_keys),
                       grid_id: 'govt_inspection_pallets',
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

    # INSPECTIONS
    # --------------------------------------------------------------------------
    r.on 'inspections', Integer do |id|
      interactor = FinishedGoodsApp::InspectionInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      # Check for notfound:
      r.on !interactor.exists?(:inspections, id) do
        handle_not_found(r)
      end

      r.on 'edit' do   # EDIT
        check_auth!('inspection', 'edit')
        interactor.assert_permission!(:edit, id)
        show_partial { FinishedGoods::Inspection::Inspection::Edit.call(id) }
      end

      r.is do
        r.get do       # SHOW
          check_auth!('inspection', 'read')
          show_partial { FinishedGoods::Inspection::Inspection::Show.call(id) }
        end
        r.patch do     # UPDATE
          res = interactor.update_inspection(id, params[:inspection])
          if res.success
            row_keys = %i[
              inspection_type_id
              inspection_type_code
              pallet_id
              pallet_number
              inspector_id
              inspector
              inspected
              inspection_failure_reason_ids
              failure_reasons
              passed
              remarks
            ]
            update_grid_row(id, changes: select_attributes(res.instance, row_keys), notice: res.message)
          else
            re_show_form(r, res) { FinishedGoods::Inspection::Inspection::Edit.call(id, form_values: params[:inspection], form_errors: res.errors) }
          end
        end
        r.delete do    # DELETE
          check_auth!('inspection', 'delete')
          interactor.assert_permission!(:delete, id)
          res = interactor.delete_inspection(id)
          if res.success
            delete_grid_row(id, notice: res.message)
          else
            show_json_error(res.message, status: 200)
          end
        end
      end
    end

    r.on 'inspections' do
      interactor = FinishedGoodsApp::InspectionInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})
      r.on 'new' do    # NEW
        check_auth!('inspection', 'new')
        show_partial_or_page(r) { FinishedGoods::Inspection::Inspection::New.call(remote: fetch?(r)) }
      end
      r.post do        # CREATE
        res = interactor.create_inspection(params[:inspection])
        if res.success
          flash[:notice] = res.message
          redirect_via_json "/list/inspections/with_params?key=standard&pallet_id=#{res.instance}"
        else
          re_show_form(r, res, url: '/finished_goods/inspection/inspections/new') do
            FinishedGoods::Inspection::Inspection::New.call(form_values: params[:inspection],
                                                            form_errors: res.errors,
                                                            remote: fetch?(r))
          end
        end
      end
    end

    # REJECT TO REPACK PALLETS
    # --------------------------------------------------------------------------
    r.on 'reject_to_repack', Integer do |id|
      r.on 'print_barcode' do
        pallet = BaseRepo.new.find_hash(:pallets, id)

        jasper_params = JasperParams.new('single_pallet_barcode',
                                         current_user.login_name,
                                         repack_date: pallet[:repacked_at].strftime('%Y-%m-%d'),
                                         pallet_number: pallet[:pallet_number])
        res = CreateJasperReport.call(jasper_params)

        if res.success
          change_window_location_via_json(UtilityFunctions.cache_bust_url(res.instance), request.path)
        else
          show_error(res.message, fetch?(r))
        end
      end
    end

    r.on 'reject_to_repack' do
      interactor = FinishedGoodsApp::GovtInspectionPalletInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      r.on 'new' do
        check_auth!('inspection', 'new')
        r.redirect '/list/stock_pallets/multi?key=reject_to_repack'
      end

      r.on 'multiselect_reject_to_repack' do
        res = interactor.reject_to_repack(multiselect_grid_choices(params))

        if res.success
          flash[:notice] = res.message
        else
          flash[:error] = res.message
        end
        redirect_to_last_grid(r)
      end
    end
  end

  route 'interwarehouse_transfers', 'finished_goods' do |r|
    # VEHICLE JOBS
    # --------------------------------------------------------------------------
    r.on 'vehicle_jobs', Integer do |id|
      r.is do
        r.get do       # SHOW
          # check_auth!('interwarehouse transfers', 'read')
          show_partial { FinishedGoods::InterwarehouseTransfers::VehicleJob::Show.call(id) }
        end
      end
    end

    r.on 'cancel_pallet_tripsheet', Integer do |id|
      interactor = FinishedGoodsApp::GovtInspectionSheetInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      res = interactor.cancel_manual_tripsheet(id)
      if res.success
        flash[:notice] = res.message
      else
        flash[:error] = res.message
      end
      r.redirect('/list/vehicle_jobs')
    end

    r.on 'open_pallet_tripsheet', Integer do |id|
      interactor = FinishedGoodsApp::GovtInspectionSheetInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      res = interactor.open_manual_tripsheet(id)
      if res.success
        flash[:notice] = res.message
      else
        flash[:error] = res.message
      end
      r.redirect('/list/vehicle_jobs')
    end
  end

  route 'buildups', 'finished_goods' do |r|
    # VEHICLE JOBS
    # --------------------------------------------------------------------------
    r.on 'completed' do
      r.redirect('/list/pallet_buildups/with_params?key=standard&completed=true')
    end

    r.on 'uncompleted' do
      r.redirect('/list/pallet_buildups/with_params?key=standard&completed=false')
    end

    r.on 'buildup_cancel', Integer do |id|    # DELETE
      interactor = FinishedGoodsApp::BuildupsInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})
      res = interactor.delete_pallet_buildup(id)
      if res.success
        delete_grid_row(id, notice: res.message)
      else
        show_json_error(res.message, status: 200)
      end
    end

    r.on 'pallet_buildups', Integer do |id|
      r.is do
        r.get do       # SHOW
          show_partial { FinishedGoods::PalletBuildup::Show.call(id) }
        end
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
# rubocop:enable Metrics/ClassLength
