# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength

class Nspack < Roda # rubocop:disable Metrics/ClassLength
  route 'shifts', 'production' do |r|
    # SHIFTS
    # --------------------------------------------------------------------------
    r.on 'shifts', Integer do |id|
      interactor = ProductionApp::ShiftInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      # Check for notfound:
      r.on !interactor.exists?(:shifts, id) do
        handle_not_found(r)
      end

      r.on 'edit' do   # EDIT
        check_auth!('shifts', 'edit')
        interactor.assert_permission!(:edit, id)
        show_page { Production::Shifts::Shift::Edit.call(id) }
      end

      r.is do
        r.patch do     # UPDATE
          res = interactor.update_shift(id, params[:shift])
          if res.success
            flash[:notice] = res.message
            redirect_via_json "/production/shifts/shifts/#{id}/edit"
          else
            re_show_form(r, res) { Production::Shifts::Shift::Edit.call(id, form_values: params[:shift], form_errors: res.errors, current_user: current_user) }
          end
        end
        r.delete do    # DELETE
          check_auth!('shifts', 'delete')
          interactor.assert_permission!(:delete, id)
          res = interactor.delete_shift(id)
          if res.success
            delete_grid_row(id, notice: res.message)
          else
            show_json_error(res.message, status: 200)
          end
        end
      end
      r.on 'shift_exceptions' do
        interactor = ProductionApp::ShiftExceptionInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})
        r.on 'preselect' do
          check_auth!('shifts', 'new')
          store_last_referer_url(:shift_exceptions)
          show_partial_or_page(r) { Production::Shifts::ShiftException::Preselect.call(id, remote: fetch?(r)) }
        end
        r.on 'new', Integer do |contract_worker_id|
          check_auth!('shifts', 'new')
          show_partial_or_page(r) { Production::Shifts::ShiftException::New.call(id, contract_worker_id, remote: fetch?(r)) }
        end
        r.on 'new' do
          r.post do
            check_auth!('shifts', 'new')
            contract_worker_id = params[:shift_exception][:contract_worker_id]
            if contract_worker_id && !contract_worker_id.empty?
              re_show_form(r, OpenStruct.new(message: nil), url: "/production/shifts/shifts/#{id}/shift_exceptions/new/#{contract_worker_id}") do
                Production::Shifts::ShiftException::New.call(id, Integer(contract_worker_id), remote: fetch?(r))
              end
            else
              show_json_error('No Contract Worker was selected', status: 200)
            end
          end
        end

        r.post do        # CREATE
          res = interactor.create_shift_exception(id, params[:shift_exception])
          if res.success
            row_keys = %i[
              id
              contract_worker_name
              remarks
              running_hours
            ]
            add_grid_row(attrs: select_attributes(res.instance, row_keys),
                         notice: res.message)
          else
            re_show_form(r, res, url: "/production/shifts/shifts/#{id}/shift_exceptions/new") do
              Production::Shifts::ShiftException::New.call(id,
                                                           params[:shift_exception][:contract_worker_id],
                                                           form_values: params[:shift_exception],
                                                           form_errors: res.errors,
                                                           remote: fetch?(r))
            end
          end
        end
      end

      r.on 'incentive_report' do
        res = CreateJasperReport.call(report_name: 'incentive',
                                      user: current_user.login_name,
                                      file: 'incentive',
                                      params: { shift_id: id, OUT_FILE_TYPE: (params[:key] == 'excel' ? 'XLS' : 'PDF') })
        if res.success
          change_window_location_via_json(UtilityFunctions.cache_bust_url(res.instance), request.path, download: params[:key] == 'excel')
        else
          show_error(res.message, fetch?(r))
        end
      end
      r.on 'incentive_count_report' do
        res = CreateJasperReport.call(report_name: 'incentive_count',
                                      user: current_user.login_name,
                                      file: 'incentive_count',
                                      params: { shift_id: id, OUT_FILE_TYPE: (params[:key] == 'excel' ? 'XLS' : 'PDF') })
        if res.success
          change_window_location_via_json(UtilityFunctions.cache_bust_url(res.instance), request.path, download: params[:key] == 'excel')
        else
          show_error(res.message, fetch?(r))
        end
      end
      r.on 'incentive_palletizer_report' do
        res = CreateJasperReport.call(report_name: 'incentive_plt',
                                      user: current_user.login_name,
                                      file: 'incentive_plt',
                                      params: { shift_id: id, OUT_FILE_TYPE: (params[:key] == 'excel' ? 'XLS' : 'PDF') })
        if res.success
          change_window_location_via_json(UtilityFunctions.cache_bust_url(res.instance), request.path, download: params[:key] == 'excel')
        else
          show_error(res.message, fetch?(r))
        end
      end
    end

    r.on 'shifts' do
      interactor = ProductionApp::ShiftInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})
      r.on 'new' do    # NEW
        check_auth!('shifts', 'new')
        show_partial_or_page(r) { Production::Shifts::Shift::New.call(remote: fetch?(r)) }
      end
      r.post do        # CREATE
        res = interactor.create_shift(params[:shift])
        if res.success
          row_keys = %i[
            id
            shift_type_id
            shift_type_code
            employment_type_code
            active
            running_hours
            start_date_time
            end_date_time
          ]
          add_grid_row(attrs: select_attributes(res.instance, row_keys),
                       notice: res.message)
        else
          re_show_form(r, res, url: '/production/shifts/shifts/new') do
            Production::Shifts::Shift::New.call(form_values: params[:shift],
                                                form_errors: res.errors,
                                                remote: fetch?(r))
          end
        end
      end
    end

    # SHIFT EXCEPTIONS
    # --------------------------------------------------------------------------
    r.on 'shift_exceptions', Integer do |id|
      interactor = ProductionApp::ShiftExceptionInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      # Check for notfound:
      r.on !interactor.exists?(:shift_exceptions, id) do
        handle_not_found(r)
      end

      r.on 'edit' do   # EDIT
        check_auth!('shifts', 'edit')
        interactor.assert_permission!(:edit, id)
        show_partial { Production::Shifts::ShiftException::Edit.call(id) }
      end

      r.is do
        r.patch do     # UPDATE
          res = interactor.update_shift_exception(id, params[:shift_exception])
          if res.success
            row_keys = %i[
              shift_id
              contract_worker_id
              remarks
              running_hours
            ]
            update_grid_row(id, changes: select_attributes(res.instance, row_keys), notice: res.message)
          else
            re_show_form(r, res) { Production::Shifts::ShiftException::Edit.call(id, form_values: params[:shift_exception], form_errors: res.errors) }
          end
        end
        r.delete do    # DELETE
          check_auth!('shifts', 'delete')
          interactor.assert_permission!(:delete, id)
          res = interactor.delete_shift_exception(id)
          if res.success
            delete_grid_row(id, notice: res.message)
          else
            show_json_error(res.message, status: 200)
          end
        end
      end
    end

    # CONTRACT WORKERS SUMMARY REPORTS
    # --------------------------------------------------------------------------
    r.on 'summary_reports', String do |employment_type|
      r.on 'select_contract_workers' do
        store_locally(:incentive_summary_params, params[:shift])
        show_page do
          Production::Production::Shift::SummaryReport.call(employment_type,
                                                            params[:shift],
                                                            back_url: back_button_url)
        end
      end

      r.on 'incentive_summary_report' do
        attrs = retrieve_from_local_store(:incentive_summary_params)
        store_locally(:incentive_summary_params, attrs)

        report_name =  case employment_type
                       when 'packers'
                         'packer_summary'
                       when 'palletizer'
                         'palletizer_summary'
                       end
        res = CreateJasperReport.call(report_name: report_name.to_s,
                                      user: current_user.login_name,
                                      file: report_name.to_s,
                                      params: { FromDateTime: "#{attrs[:from_date]} 00:00:00|date",
                                                ToDateTime: "#{attrs[:to_date]} 00:00:00|date",
                                                WorkerIds: "#{multiselect_grid_choices(params).join(',')}|intarray",
                                                OUT_FILE_TYPE: 'CSV',
                                                keep_file: false })
        if res.success
          change_window_location_via_json(UtilityFunctions.cache_bust_url(res.instance), request.path, download: true)
        else
          show_error(res.message, fetch?(r))
        end
      end

      r.get do
        show_page { Production::Production::Shift::Filter.call(employment_type) }
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
