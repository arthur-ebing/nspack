# frozen_string_literal: true

class Nspack < Roda
  route 'runs', 'production' do |r|
    # PRODUCTION RUNS
    # --------------------------------------------------------------------------
    r.on 'production_runs', Integer do |id|
      interactor = ProductionApp::ProductionRunInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      # Check for notfound:
      r.on !interactor.exists?(:production_runs, id) do
        handle_not_found(r)
      end

      r.on 'edit' do   # EDIT
        check_auth!('runs', 'edit')
        interactor.assert_permission!(:edit, id)
        show_partial { Production::Runs::ProductionRun::Edit.call(id) }
      end

      r.on 'set_bin_tipping_control_data' do
        r.get do
          run = interactor.production_run(id)
          show_partial_or_page(r) { Production::Runs::ProductionRun::BinTippingControlData.call(id, form_values: run.legacy_data, remote: fetch?(r)) }
        end

        r.post do
          res = interactor.create_run_bin_tipping_control_data(id, params[:bin_tipping_control_data])
          if res.success
            flash[:notice] = res.message
            r.redirect("/production/runs/production_runs/#{id}/edit")
          else
            re_show_form(r, res, url: "/production/runs/production_runs/#{id}/set_bin_tipping_control_data") do
              Production::Runs::ProductionRun::BinTippingControlData.call(id, form_values: params[:bin_tipping_control_data],
                                                                              form_errors: res.errors.empty? ? nil : res.errors,
                                                                              remote: fetch?(r))
            end
          end
        end
      end

      r.on 'set_bin_tipping_criteria' do
        r.get do
          show_partial_or_page(r) { Production::Runs::ProductionRun::BinTippingCriteria.call(id, remote: fetch?(r)) }
        end

        r.post do
          res = interactor.create_run_bin_tipping_criteria(id, params[:bin_tipping_criteria])
          if res.success
            flash[:notice] = res.message
            r.redirect("/production/runs/production_runs/#{id}/edit")
          else
            re_show_form(r, res, url: "/production/runs/production_runs/#{id}/set_bin_tipping_criteria") do
              Production::Runs::ProductionRun::BinTippingControlData.call(id, form_values: params[:bin_tipping_criteria],
                                                                              form_errors: res.errors.empty? ? nil : res.errors,
                                                                              remote: fetch?(r))
            end
          end
        end
      end

      r.on 'rebins' do
        interactor = RawMaterialsApp::RmtBinInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

        r.get do
          # check_auth!('deliveries', 'new')
          show_partial_or_page(r) { Production::Runs::Rebins::CreateRebins.call(id, remote: fetch?(r)) }
        end

        r.post do
          res = interactor.create_rebin_groups(id, params[:rebin])
          if res.success
            flash[:notice] = res.message
            redirect_via_json(request.referer)
          else
            re_show_form(r, res, url: "/production/runs/production_runs/#{id}/rebins") do
              Production::Runs::Rebins::CreateRebins.call(id, form_values: params[:rebin],
                                                              form_errors: res.errors.empty? ? nil : res.errors,
                                                              remote: fetch?(r))
            end
          end
        end
      end

      r.on 'print_barcodes' do
        jasper_params = JasperParams.new('bin_ticket',
                                         current_user.login_name,
                                         bin_id: multiselect_grid_choices(params))
        res = CreateJasperReport.call(jasper_params)

        if res.success
          change_window_location_via_json(UtilityFunctions.cache_bust_url(res.instance), request.path)
        else
          show_error(res.message, fetch?(r))
        end
      end

      r.on 'clone' do
        r.get do
          check_auth!('runs', 'edit')
          interactor.assert_permission!(:complete_setup, id)
          show_partial do
            Production::Runs::ProductionRun::Confirm.call(id,
                                                          url: "/production/runs/production_runs/#{id}/clone",
                                                          notice: 'Clone this run?',
                                                          button_captions: %w[Clone Cloning])
          end
        end

        r.post do
          res = interactor.clone_production_run(id)
          if res.success
            row_keys = %i[
              id
              production_run_code
              cultivar_group_code
              cultivar_name
              farm_code
              orchard_code
              packhouse_code
              line_code
              status
              puc_code
              season_code
              farm_id
              puc_id
              packhouse_resource_id
              production_line_id
              season_id
              orchard_id
              cultivar_group_id
              cultivar_id
              product_setup_template_id
              cloned_from_run_id
              active_run_stage
              started_at
              closed_at
              re_executed_at
              completed_at
              allow_cultivar_mixing
              allow_orchard_mixing
              reconfiguring
              closed
              running
              setup_complete
              completed
              allocation_required
              template_name
              cloned_from_run_code
              active
              tipping
              labeling
              colour_rule
            ]
            add_grid_row(attrs: select_attributes(res.instance.to_h.merge(status: "CLONED from run id #{id}"), row_keys),
                         notice: res.message)
          else
            dialog_error(content: res.message)
          end
        end
      end

      r.on 'complete_setup' do
        r.get do
          check_auth!('runs', 'edit')
          interactor.assert_permission!(:complete_setup, id)
          show_partial do
            Production::Runs::ProductionRun::Confirm.call(id,
                                                          url: "/production/runs/production_runs/#{id}/complete_setup",
                                                          notice: 'Press the button to mark setups as complete',
                                                          button_captions: ['Mark as Complete', 'Completing...'])
          end
        end

        r.post do
          interactor.mark_setup_as_complete(id)
          update_grid_row(id, changes: { setup_complete: true, reconfiguring: false, status: 'SETUP_COMPLETED' }, notice: 'Production run setups have been marked as complete')
        end
      end

      r.on 'un_complete_setup' do
        r.get do
          check_auth!('runs', 'edit')
          interactor.assert_permission!(:complete_setup, id)
          show_partial do
            Production::Runs::ProductionRun::Confirm.call(id,
                                                          url: "/production/runs/production_runs/#{id}/un_complete_setup",
                                                          notice: 'Press the button to undo complete status of setups',
                                                          button_captions: ['Undo complete', 'Undoing complete...'])
          end
        end

        r.post do
          interactor.mark_setup_as_incomplete(id)
          update_grid_row(id, changes: { setup_complete: false, status: 'SETUP_UN-COMPLETED' }, notice: 'Production run setups are no longer marked as complete')
        end
      end

      r.on 'close' do
        r.get do
          check_auth!('runs', 'edit')
          interactor.assert_permission!(:close, id)
          show_partial do
            Production::Runs::ProductionRun::Confirm.call(id,
                                                          url: "/production/runs/production_runs/#{id}/close",
                                                          notice: 'Press the button to close the run',
                                                          button_captions: ['Close', 'Closing...'])
          end
        end

        r.post do
          res = interactor.close_run(id)
          if res.success
            flash[:notice] = res.message
          else
            flash[:error] = res.message
          end
          redirect_to_last_grid(r)
        end
      end

      r.on 'execute_run' do
        r.get do
          check_auth!('runs', 'edit')
          interactor.assert_permission!(:execute_run, id)
          show_partial do
            Production::Runs::ProductionRun::Confirm.call(id,
                                                          url: "/production/runs/production_runs/#{id}/execute_run",
                                                          notice: 'Press the button to start tipping the run',
                                                          button_captions: ['Execute', 'Executing...'])
          end
        end

        r.post do
          res = interactor.execute_run(id)
          row_keys = %i[
            running
            tipping
            labeling
            reconfiguring
            setup_complete
            active_run_stage
            started_at
            status
            colour_rule
          ]
          # MessageBus to activerun page to refresh
          acts = [OpenStruct.new(type: :update_grid_row,  ids: id, changes: select_attributes(res.instance[:this_run], row_keys))]
          acts << OpenStruct.new(type: :update_grid_row,  ids: res.instance[:other_run][:id], changes: select_attributes(res.instance[:other_run], row_keys.reject { |k| k == :re_executed_at })) if res.instance[:other_run]
          json_actions(acts, res.message)
        end
      end

      r.on 're_execute_run' do
        r.get do
          check_auth!('runs', 'edit')
          interactor.assert_permission!(:re_execute_run, id)
          show_partial do
            Production::Runs::ProductionRun::Confirm.call(id,
                                                          url: "/production/runs/production_runs/#{id}/re_execute_run",
                                                          notice: 'Press the button to continue executing the run',
                                                          button_captions: ['Re-execute', 'Executing...'])
          end
        end

        r.post do
          res = interactor.re_execute_run(id)
          row_keys = %i[
            running
            tipping
            labeling
            reconfiguring
            setup_complete
            active_run_stage
            status
            re_executed_at
            colour_rule
          ]
          update_grid_row(id, changes: select_attributes(res.instance, row_keys), notice: res.message)
        end
      end

      r.on 're_configure' do
        check_auth!('runs', 'execute')
        res = interactor.re_configure_run(id)
        if res.success
          row_keys = %i[
            running
            tipping
            labeling
            reconfiguring
            setup_complete
            active_run_stage
            status
            colour_rule
          ]
          acts = [OpenStruct.new(type: :update_grid_row,  ids: id, changes: select_attributes(res.instance, row_keys))]
          content = render_partial { Production::Runs::ProductionRun::Edit.call(id) }
          acts << OpenStruct.new(type: :replace_dialog,  content: content, title: 'Re-configure')
          json_actions(acts, res.message)
        else
          dialog_error(res.message, error: "Run cannot be re-configured - #{res.message}")
        end
      end

      r.on 'complete_run' do
        r.get do
          check_auth!('runs', 'execute')
          res = interactor.prepare_to_complete_run(id)
          show_partial { Production::Runs::ProductionRun::CompleteStage.call(id, res, complete_run: true) }
        end

        r.post do
          check_auth!('runs', 'execute')
          res = interactor.complete_run(id)
          if res.success
            row_keys = %i[
              running
              tipping
              labeling
              active_run_stage
              reconfiguring
              re_executed_at
              setup_complete
              completed
              completed_at
              status
              colour_rule
            ]
            acts = [OpenStruct.new(type: :update_grid_row,  ids: id, changes: select_attributes(res.instance[:this_run].to_h.merge(colour_rule: nil), row_keys))]
            acts << OpenStruct.new(type: :update_grid_row,  ids: res.instance[:other_run][:id], changes: select_attributes(res.instance[:other_run], row_keys.reject { |k| k == :re_executed_at })) if res.instance[:other_run]
            json_actions(acts, res.message)
          else
            re_show_form(r, res) { Production::Runs::ProductionRun::CompleteStage.call(id, res) }
          end
        end
      end

      r.on 'complete_stage' do
        r.get do
          check_auth!('runs', 'execute')
          res = interactor.prepare_to_complete_stage(id)
          show_partial { Production::Runs::ProductionRun::CompleteStage.call(id, res) }
        end

        r.post do
          check_auth!('runs', 'execute')
          res = interactor.complete_stage(id)
          if res.success
            row_keys = %i[
              running
              tipping
              labeling
              active_run_stage
              reconfiguring
              re_executed_at
              setup_complete
              completed
              completed_at
              status
              colour_rule
            ]
            acts = [OpenStruct.new(type: :update_grid_row,  ids: id, changes: select_attributes(res.instance[:this_run], row_keys))]
            acts << OpenStruct.new(type: :update_grid_row,  ids: res.instance[:other_run][:id], changes: select_attributes(res.instance[:other_run], row_keys.reject { |k| k == :re_executed_at })) if res.instance[:other_run]
            json_actions(acts, res.message)
          else
            re_show_form(r, res) { Production::Runs::ProductionRun::CompleteStage.call(id, res) }
          end
        end
      end

      r.on 'packout_report_dispatched' do
        jasper_params = JasperParams.new('packout_runs',
                                         current_user.login_name,
                                         production_run_id: [id],
                                         carton_or_bin: AppConst::DEFAULT_FG_PACKAGING_TYPE.capitalize,
                                         use_packed_weight: true,
                                         use_derived_weight: false,
                                         dispatched_only: true,
                                         client_code: AppConst::CLIENT_CODE)
        res = CreateJasperReport.call(jasper_params)

        if res.success
          change_window_location_via_json(UtilityFunctions.cache_bust_url(res.instance), request.path)
        else
          show_error(res.message, fetch?(r))
        end
      end

      r.on 'packout_report_derived_dispatched' do
        jasper_params = JasperParams.new('packout_runs',
                                         current_user.login_name,
                                         production_run_id: [id],
                                         carton_or_bin: AppConst::DEFAULT_FG_PACKAGING_TYPE.capitalize,
                                         use_packed_weight: false,
                                         use_derived_weight: true,
                                         dispatched_only: true,
                                         client_code: AppConst::CLIENT_CODE)
        res = CreateJasperReport.call(jasper_params)

        if res.success
          change_window_location_via_json(UtilityFunctions.cache_bust_url(res.instance), request.path)
        else
          show_error(res.message, fetch?(r))
        end
      end

      r.on 'packout_report' do
        jasper_params = JasperParams.new('packout_runs',
                                         current_user.login_name,
                                         production_run_id: [id],
                                         carton_or_bin: AppConst::DEFAULT_FG_PACKAGING_TYPE.capitalize,
                                         use_packed_weight: true,
                                         use_derived_weight: false,
                                         dispatched_only: false,
                                         client_code: AppConst::CLIENT_CODE)
        res = CreateJasperReport.call(jasper_params)

        if res.success
          change_window_location_via_json(UtilityFunctions.cache_bust_url(res.instance), request.path)
        else
          show_error(res.message, fetch?(r))
        end
      end

      r.on 'packout_report_derived' do
        jasper_params = JasperParams.new('packout_runs',
                                         current_user.login_name,
                                         production_run_id: [id],
                                         carton_or_bin: AppConst::DEFAULT_FG_PACKAGING_TYPE.capitalize,
                                         use_packed_weight: false,
                                         use_derived_weight: true,
                                         dispatched_only: false,
                                         client_code: AppConst::CLIENT_CODE)
        res = CreateJasperReport.call(jasper_params)

        if res.success
          change_window_location_via_json(UtilityFunctions.cache_bust_url(res.instance), request.path)
        else
          show_error(res.message, fetch?(r))
        end
      end

      r.on 'carton_packout_report' do
        jasper_params = JasperParams.new('carton_packout',
                                         current_user.login_name,
                                         production_run_id: id)
        res = CreateJasperReport.call(jasper_params)

        if res.success
          change_window_location_via_json(UtilityFunctions.cache_bust_url(res.instance), request.path)
        else
          show_error(res.message, fetch?(r))
        end
      end

      r.on 'show_stats' do
        check_auth!('runs', 'read')
        show_partial { Production::Runs::ProductionRun::ShowStats.call(id) }
      end

      r.on 'select_template' do
        r.get do
          check_auth!('runs', 'edit')
          interactor.assert_permission!(:edit, id)
          show_partial { Production::Runs::ProductionRun::SelectTemplate.call(id) }
        end
        r.post do
          res = interactor.update_template(id, params[:production_run])
          if res.success
            row_keys = %i[
              product_setup_template_id
              template_name
            ]
            update_grid_row(id, changes: select_attributes(res.instance, row_keys), notice: res.message)
          else
            re_show_form(r, res) { Production::Runs::ProductionRun::SelectTemplate.call(id, form_values: params[:production_run], form_errors: res.errors) }
          end
        end
      end

      r.on 'allocate_setups' do
        check_auth!('runs', 'edit')
        res = interactor.prepare_run_allocation_targets(id)
        if res.success
          show_page { Production::Runs::ProductionRun::AllocateSetups.call(id) }
        else
          flash[:error] = res.message
          redirect_to_last_grid(r)
        end
      end

      r.on 'allocate_target_customer' do
        check_auth!('runs', 'edit')
        show_page { Production::Runs::ProductionRun::AllocateTargetCustomers.call(id) }
      end

      r.on 'view_setups' do
        check_auth!('runs', 'edit')
        if AppConst::CR_PROD.use_packing_specifications?
          r.redirect("/list/packing_specification_items_on_runs/with_params?key=standard&production_run_id=#{id}")
        else
          r.redirect("/list/product_setups_on_runs/with_params?key=standard&production_run_id=#{id}")
        end
      end

      r.on 'product_setup', Integer do |product_setup_id|
        r.on 'print_label' do
          r.get do
            show_partial do
              Production::Runs::ProductionRun::PrintCarton.call({ id: id, product_setup_id: product_setup_id },
                                                                request.ip)
            end
          end
          r.patch do
            res = interactor.print_carton_label({ id: id, product_setup_id: product_setup_id },
                                                request.ip,
                                                params[:product_setup])
            if res.success
              show_json_notice(res.message)
            else
              re_show_form(r, res) do
                Production::Runs::ProductionRun::PrintCarton.call({ id: id, product_setup_id: product_setup_id },
                                                                  request.ip,
                                                                  form_values: params[:product_setup],
                                                                  form_errors: res.errors)
              end
            end
          end
        end
      end

      r.on 'packing_specification_item', Integer do |packing_specification_item_id|
        r.on 'print_label' do
          r.get do
            show_partial do
              Production::Runs::ProductionRun::PrintCarton.call({ id: id, packing_specification_item_id: packing_specification_item_id },
                                                                request.ip)
            end
          end
          r.patch do
            res = interactor.print_carton_label({ id: id, packing_specification_item_id: packing_specification_item_id },
                                                request.ip,
                                                params[:product_setup])
            if res.success
              show_json_notice(res.message)
            else
              re_show_form(r, res) do
                Production::Runs::ProductionRun::PrintCarton.call({ id: id, packing_specification_item_id: packing_specification_item_id },
                                                                  request.ip,
                                                                  form_values: params[:product_setup],
                                                                  form_errors: res.errors)
              end
            end
          end
        end
      end

      r.on 'refresh_pallet_data' do
        res = interactor.refresh_pallet_data(id)
        if res.success
          flash[:notice] = res.message
        else
          flash[:error] = res.message
        end
        redirect_to_last_grid(r)
      end
      r.on 'view_bin_tipping_criteria' do
        show_partial { Production::Runs::ProductionRun::ShowBinTippingCriteria.call(id) }
      end

      r.is do
        r.get do       # SHOW
          check_auth!('runs', 'read')
          show_partial { Production::Runs::ProductionRun::Show.call(id) }
        end
        r.patch do     # UPDATE
          res = interactor.update_production_run(id, params[:production_run])
          if res.success
            row_keys = %i[
              farm_id
              puc_id
              packhouse_resource_id
              production_line_id
              season_id
              orchard_id
              cultivar_group_id
              cultivar_id
              product_setup_template_id
              cloned_from_run_id
              active_run_stage
              started_at
              closed_at
              re_executed_at
              completed_at
              allow_cultivar_mixing
              allow_orchard_mixing
              reconfiguring
              closed
              running
              setup_complete
              completed
            ]
            update_grid_row(id, changes: select_attributes(res.instance, row_keys), notice: res.message)
          else
            re_show_form(r, res) { Production::Runs::ProductionRun::Edit.call(id, form_values: params[:production_run], form_errors: res.errors) }
          end
        end
        r.delete do    # DELETE
          check_auth!('runs', 'delete')
          interactor.assert_permission!(:delete, id)
          res = interactor.delete_production_run(id)
          if res.success
            delete_grid_row(id, notice: res.message)
          else
            show_json_error(res.message, status: 200)
          end
        end
      end
    end

    r.on 'production_runs' do
      interactor = ProductionApp::ProductionRunInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})
      r.on 'new' do    # NEW
        check_auth!('runs', 'new')
        set_last_grid_url('/list/production_runs', r)
        show_partial_or_page(r) { Production::Runs::ProductionRun::New.call(remote: fetch?(r)) }
      end

      r.on 'new_first_submit' do
        res = interactor.validate_new_first(params[:production_run])
        if res.success
          show_partial_or_page(r) { Production::Runs::ProductionRun::New.call(form_values: params[:production_run], remote: fetch?(r), is_second_form: true) }
        else
          re_show_form(r, res, url: '/production/runs/production_runs/new_first_submit') do
            Production::Runs::ProductionRun::New.call(form_values: params[:production_run],
                                                      form_errors: res.errors,
                                                      remote: fetch?(r))
          end
        end
      end

      r.on 'farm_combo_changed' do
        if !params[:changed_value].nil_or_empty?
          farm_repo = MasterfilesApp::FarmRepo.new
          pucs = farm_repo.selected_farm_pucs(where: { farm_id: params[:changed_value] })
          orchards = if !params[:cultivar_id].nil_or_empty?
                       farm_repo.find_orchards_by_farm_and_cultivar(params[:changed_value], params[:cultivar_id])
                     else
                       farm_repo.find_orchards_by_farm_and_cultivar_group(params[:changed_value], params[:cultivar_group_id])
                     end
          json_actions([OpenStruct.new(type: :replace_select_options,
                                       dom_id: 'production_run_puc_id',
                                       options_array: pucs),
                        OpenStruct.new(type: :replace_select_options,
                                       dom_id: 'production_run_orchard_id',
                                       options_array: orchards)])
        else
          json_actions([OpenStruct.new(type: :replace_select_options,
                                       dom_id: 'production_run_puc_id',
                                       options_array: []),
                        OpenStruct.new(type: :replace_select_options,
                                       dom_id: 'production_run_orchard_id',
                                       options_array: [])])
        end
      end

      r.on 'cultivar_group_combo_changed' do
        if !params[:changed_value].nil_or_empty?
          cultivars = MasterfilesApp::CultivarRepo.new.for_select_cultivars(where: { cultivar_group_id: params[:changed_value] })
          seasons = MasterfilesApp::CalendarRepo.new.for_select_seasons_for_cultivar_group(params[:changed_value])
          json_actions([OpenStruct.new(type: :replace_select_options,
                                       dom_id: 'production_run_cultivar_id',
                                       options_array: cultivars),
                        OpenStruct.new(type: :replace_select_options,
                                       dom_id: 'production_run_season_id',
                                       options_array: seasons)])
        else
          json_actions([OpenStruct.new(type: :replace_select_options,
                                       dom_id: 'production_run_cultivar_id',
                                       options_array: []),
                        OpenStruct.new(type: :replace_select_options,
                                       dom_id: 'production_run_season_id',
                                       options_array: [])])
        end
      end

      r.on 'cultivar_combo_changed' do
        seasons = if !params[:changed_value].nil_or_empty?
                    MasterfilesApp::CalendarRepo.new.for_select_seasons_for_cultivar(params[:changed_value])
                  else
                    MasterfilesApp::CalendarRepo.new.for_select_seasons_for_cultivar_group(params[:cultivar_group_id])
                  end
        json_replace_select_options('production_run_season_id', seasons)
      end

      r.on 'ripe_point_code_combo_changed' do
        pc_codes = []
        pc_codes = MesscadaApp::MesscadaRepo.new.ripe_point_codes(ripe_point_code: params[:changed_value]).map { |s| s[1] }.uniq unless params[:changed_value].to_s.empty?
        json_replace_select_options('bin_tipping_control_data_pc_code', pc_codes)
      end

      r.on 'inline_edit_alloc', Integer do |product_resource_allocation_id|
        res = interactor.inline_edit_alloc(product_resource_allocation_id, params)
        if res.success
          json_actions([OpenStruct.new(type: :update_grid_row,
                                       ids: product_resource_allocation_id,
                                       changes: res.instance[:changes])],
                       res.message)
        else
          undo_grid_inline_edit(message: res.message, message_type: :warning)
        end
      end

      r.on 'selected_template', Integer do |id|
        res = interactor.selected_template(id)
        if res.success
          json_actions(
            [
              OpenStruct.new(type: :replace_input_value,
                             dom_id: 'production_run_product_setup_template_id',
                             value: res.instance[:id]),
              OpenStruct.new(type: :replace_input_value,
                             dom_id: 'production_run_template_name',
                             value: res.instance[:template_name])
            ]
          )
        else
          show_json_error(res.message)
        end
      end

      r.on 'selected_packing_specification', Integer do |id|
        res = interactor.selected_packing_specification(id)
        if res.success
          json_actions(
            [
              OpenStruct.new(type: :replace_input_value,
                             dom_id: 'production_run_product_setup_template_id',
                             value: res.instance[:product_setup_template_id])
            ]
          )
        else
          show_json_error(res.message)
        end
      end

      r.on 'search' do
        r.get do
          show_page { Production::Reports::Packout::SearchProductionRuns.call(mode: :list) }
        end

        r.post do
          interactor = ProductionApp::ProductionRunInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

          params[:packout_runs_report].delete_if { |_k, v| v.nil_or_empty? }
          res = interactor.find_packout_runs(params[:packout_runs_report])
          if res.success
            r.redirect("/list/production_runs?key=standard&ids=#{res.instance}")
          else
            flash[:error] = res.message
            r.redirect('/production/runs/production_runs/search')
          end
        end
      end

      # BEHAVIOURS
      # -------------------------------
      r.on 'changed', String do |key|
        UiRules::ChangeRenderer.render_json(:production_run, self, "changed_#{key}".to_sym, interactor: interactor, params: params)
      end

      r.post do        # CREATE
        res = interactor.create_production_run(params[:production_run])
        if res.success
          if fetch?(r)
            row_keys = %i[
              id
              production_run_code
              cultivar_group_code
              cultivar_name
              farm_code
              orchard_code
              packhouse_code
              line_code
              status
              puc_code
              season_code
              farm_id
              puc_id
              packhouse_resource_id
              production_line_id
              season_id
              orchard_id
              cultivar_group_id
              cultivar_id
              product_setup_template_id
              cloned_from_run_id
              active_run_stage
              started_at
              closed_at
              re_executed_at
              completed_at
              allow_cultivar_mixing
              allow_orchard_mixing
              reconfiguring
              closed
              running
              setup_complete
              completed
              allocation_required
            ]
            add_grid_row(attrs: select_attributes(res.instance.to_h.merge(status: 'CREATED'), row_keys),
                         notice: res.message)
          else
            flash[:notice] = res.message
            redirect_to_last_grid(r)
          end
        else
          re_show_form(r, res, url: '/production/runs/production_runs/new') do
            Production::Runs::ProductionRun::New.call(form_values: params[:production_run],
                                                      form_errors: res.errors,
                                                      remote: fetch?(r),
                                                      is_second_form: true)
          end
        end
      end
    end

    r.on 'packout_runs_search' do
      r.on 'farm_combo_changed' do
        handle_ui_change(:packout_runs_report, :farm, params)
      end

      r.on 'puc_combo_changed' do
        handle_ui_change(:packout_runs_report, :puc, params)
      end

      r.on 'orchard_combo_changed' do
        handle_ui_change(:packout_runs_report, :orchard, params)
      end

      r.on 'cultivar_group_combo_changed' do
        handle_ui_change(:packout_runs_report, :cultivar_group, params)
      end

      r.on 'packhouse_resource_changed' do
        handle_ui_change(:packout_runs_report, :packhouse, params)
      end
    end

    r.on 'pallet_mix_rules', Integer do |id|
      interactor = ProductionApp::ProductionRunInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      r.on 'edit' do   # EDIT
        show_partial { Production::Runs::PalletMixRule::Edit.call(id) }
      end

      r.patch do
        res = interactor.update_pallet_mix_rule(id, params[:pallet_mix_rule])
        if res.success
          row_keys = %i[
            scope
            production_run_id
            pallet_id
            allow_tm_mix
            allow_grade_mix
            allow_size_ref_mix
            allow_pack_mix
            allow_std_count_mix
            allow_mark_mix
            allow_inventory_code_mix
            allow_cultivar_mix
            allow_cultivar_group_mix
            allow_puc_mix
            allow_orchard_mix
            packhouse_code
          ]
          update_grid_row(id, changes: select_attributes(res.instance, row_keys), notice: res.message)
        else
          re_show_form(r, res) { Production::Runs::PalletMixRule::Edit.call(id, form_values: params[:pallet_mix_rule], form_errors: res.errors) }
        end
      end

      r.is do
        r.get do       # SHOW
          show_partial { Production::Runs::PalletMixRule::Show.call(id) }
        end
      end
    end

    r.on 'pallet_mix_rules' do
      interactor = ProductionApp::ProductionRunInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      r.on 'new' do    # NEW
        res = interactor.create_pallet_mix_rules
        flash[:notice] = res.message
        r.redirect('/list/pallet_mix_rules')
      end
    end

    r.on 'toggle_bin_tipping_criteria' do
      toggle = params[:changed_value] != 'f'
      json_actions([
                     OpenStruct.new(type: :set_checked, dom_id: 'bin_tipping_criteria_farm_code', checked: toggle),
                     OpenStruct.new(type: :set_checked, dom_id: 'bin_tipping_criteria_commodity_code', checked: toggle),
                     OpenStruct.new(type: :set_checked, dom_id: 'bin_tipping_criteria_rmt_variety_code', checked: toggle),
                     OpenStruct.new(type: :set_checked, dom_id: 'bin_tipping_criteria_treatment_code', checked: toggle),
                     OpenStruct.new(type: :set_checked, dom_id: 'bin_tipping_criteria_rmt_size', checked: toggle),
                     OpenStruct.new(type: :set_checked, dom_id: 'bin_tipping_criteria_product_class_code', checked: toggle),
                     OpenStruct.new(type: :set_checked, dom_id: 'bin_tipping_criteria_rmt_product_type', checked: toggle),
                     OpenStruct.new(type: :set_checked, dom_id: 'bin_tipping_criteria_pc_code', checked: toggle),
                     OpenStruct.new(type: :set_checked, dom_id: 'bin_tipping_criteria_cold_store_type', checked: toggle),
                     OpenStruct.new(type: :set_checked, dom_id: 'bin_tipping_criteria_season_code', checked: toggle),
                     OpenStruct.new(type: :set_checked, dom_id: 'bin_tipping_criteria_track_indicator_code', checked: toggle),
                     OpenStruct.new(type: :set_checked, dom_id: 'bin_tipping_criteria_ripe_point_code', checked: toggle)
                   ])
    end

    r.on 'toggle' do
      toggle = params[:changed_value] != 'f'
      json_actions([
                     OpenStruct.new(type: :set_checked, dom_id: 'pallet_mix_rule_allow_tm_mix', checked: toggle),
                     OpenStruct.new(type: :set_checked, dom_id: 'pallet_mix_rule_allow_grade_mix', checked: toggle),
                     OpenStruct.new(type: :set_checked, dom_id: 'pallet_mix_rule_allow_size_ref_mix', checked: toggle),
                     OpenStruct.new(type: :set_checked, dom_id: 'pallet_mix_rule_allow_pack_mix', checked: toggle),
                     OpenStruct.new(type: :set_checked, dom_id: 'pallet_mix_rule_allow_std_count_mix', checked: toggle),
                     OpenStruct.new(type: :set_checked, dom_id: 'pallet_mix_rule_allow_mark_mix', checked: toggle),
                     OpenStruct.new(type: :set_checked, dom_id: 'pallet_mix_rule_allow_inventory_code_mix', checked: toggle),
                     OpenStruct.new(type: :set_checked, dom_id: 'pallet_mix_rule_allow_cultivar_mix', checked: toggle),
                     OpenStruct.new(type: :set_checked, dom_id: 'pallet_mix_rule_allow_cultivar_group_mix', checked: toggle),
                     OpenStruct.new(type: :set_checked, dom_id: 'pallet_mix_rule_allow_puc_mix', checked: toggle),
                     OpenStruct.new(type: :set_checked, dom_id: 'pallet_mix_rule_allow_orchard_mix', checked: toggle)
                   ])
    end

    r.on 'product_resource_allocations', Integer do |id|
      interactor = ProductionApp::ProductionRunInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      # Check for notfound:
      r.on !interactor.exists?(:product_resource_allocations, id) do
        handle_not_found(r)
      end

      r.on 'copy' do
        r.post do
          res = interactor.copy_run_allocation(id, multiselect_grid_choices(params))
          if res.success
            flash[:notice] = res.message
          else
            flash[:error] = res.message
          end
          redirect_via_json("/production/runs/production_runs/#{res.instance}/allocate_setups")
        end
      end

      r.on 'edit' do
        check_auth!('runs', 'edit')
        show_partial { Production::Runs::ProductResourceAllocation::Edit.call(id) }
      end

      r.patch do # UPDATE
        res = interactor.update_product_resource_allocation(id, params[:product_resource_allocation])
        if res.success
          row_keys = %i[
            product_setup_id
            label_template_id
            packing_method_id
            product_setup_code
            label_template_name
            packing_method_code
            packing_specification_item_code
          ]
          update_grid_row(id, changes: select_attributes(res.instance, row_keys), notice: res.message)
        else
          re_show_form(r, res) { Production::Runs::ProductResourceAllocation::Edit.call(id, form_values: params[:product_resource_allocation], form_errors: res.errors) }
        end
      end

      r.on 'preview_label' do
        res = interactor.preview_allocation_carton_label(id)
        if res.success
          filepath = Tempfile.open([res.instance.fname, '.png'], 'public/tempfiles') do |f|
            f.write(res.instance.body)
            f.path
          end
          File.chmod(0o644, filepath) # Ensure web app can read the image.
          update_dialog_content(content: "<div style='border:2px solid orange'><img src='/#{File.join('tempfiles', File.basename(filepath))}'></div>")
        else
          { flash: { error: res.message } }.to_json
        end
      end
    end

    r.on 'container_material_type_combo_changed' do
      if !params[:changed_value].nil_or_empty?
        container_material_owners = RawMaterialsApp::RmtDeliveryRepo.new.find_container_material_owners_by_container_material_type(params[:changed_value])
        json_replace_select_options('rebin_rmt_material_owner_party_role_id', container_material_owners)
      else
        json_replace_select_options('rebin_rmt_material_owner_party_role_id', [])
      end
    end

    r.on 'bin_filler_roles' do
      interactor = ProductionApp::ProductionRunInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      r.on 'view_robots' do
        check_auth!('runs', 'edit')
        res = interactor.resolve_bin_filler_resource_params(Crossbeams::Config::ResourceDefinitions::BIN_FILLER_ROBOT)
        r.redirect("/list/bin_filler_roles/with_params?key=standard&plant_resource_type_id=#{res.instance[:plant_resource_type_id]}")
      end

      r.on 'edit_bin_filler_roles', Integer do |plant_resource_id|
        r.on 'view_robot_buttons' do
          check_auth!('runs', 'edit')
          res = interactor.resolve_bin_filler_resource_params(Crossbeams::Config::ResourceDefinitions::ROBOT_BUTTON,
                                                              plant_resource_id: plant_resource_id)
          plant_resource_ids = res.instance[:plant_resource_ids].nil_or_empty? ? 'null' : res.instance[:plant_resource_ids]
          r.redirect("/list/bin_filler_roles/with_params?key=robot_buttons&plant_resource_ids=#{plant_resource_ids}")
        end

        r.on 'inline_edit_label_to_print' do
          res = interactor.inline_edit_label_to_print(plant_resource_id, params)
          if res.success
            json_actions([OpenStruct.new(type: :update_grid_row,
                                         ids: plant_resource_id,
                                         changes: res.instance[:changes])],
                         res.message)
          else
            undo_grid_inline_edit(message: res.message, message_type: :warning)
          end
        end
      end
    end
  end
end
