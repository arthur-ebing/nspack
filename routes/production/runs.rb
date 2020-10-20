# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength
# rubocop:disable Metrics/BlockLength
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
        res = if AppConst::JASPER_NEW_METHOD
                jasper_params = JasperParams.new('bin_ticket',
                                                 current_user.login_name,
                                                 bin_id: multiselect_grid_choices(params))
                CreateJasperReportNew.call(jasper_params)
              else
                CreateJasperReport.call(report_name: 'bin_ticket',
                                        user: current_user.login_name,
                                        file: 'bin_ticket',
                                        params: { bin_id: "#{multiselect_grid_choices(params).join(',')}|intarray",
                                                  keep_file: false })
              end
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
          ]
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
          ]
          acts = [OpenStruct.new(type: :update_grid_row,  ids: id, changes: select_attributes(res.instance, row_keys))]
          content = render_partial { Production::Runs::ProductionRun::Edit.call(id) }
          acts << OpenStruct.new(type: :replace_dialog,  content: content)
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
            ]
            acts = [OpenStruct.new(type: :update_grid_row,  ids: id, changes: select_attributes(res.instance[:this_run], row_keys))]
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
            ]
            acts = [OpenStruct.new(type: :update_grid_row,  ids: id, changes: select_attributes(res.instance[:this_run], row_keys))]
            acts << OpenStruct.new(type: :update_grid_row,  ids: res.instance[:other_run][:id], changes: select_attributes(res.instance[:other_run], row_keys.reject { |k| k == :re_executed_at })) if res.instance[:other_run]
            json_actions(acts, res.message)
          else
            re_show_form(r, res) { Production::Runs::ProductionRun::CompleteStage.call(id, res) }
          end
        end
      end

      r.on 'packout_report_dispatches' do
        res = if AppConst::JASPER_NEW_METHOD
                jasper_params = JasperParams.new('pack_out',
                                                 current_user.login_name,
                                                 production_run_id: id,
                                                 carton_or_bin: AppConst::DEFAULT_FG_PACKAGING_TYPE.capitalize,
                                                 use_packed_weight: AppConst::CARTON_VERIFICATION_REQUIRED,
                                                 use_derived_weight: false,
                                                 dispatched_only: true)
                CreateJasperReportNew.call(jasper_params)
              else
                CreateJasperReport.call(report_name: 'pack_out',
                                        user: current_user.login_name,
                                        file: 'pack_out',
                                        params: { production_run_id: id,
                                                  carton_or_bin: AppConst::DEFAULT_FG_PACKAGING_TYPE.capitalize,
                                                  use_packed_weight: AppConst::CARTON_VERIFICATION_REQUIRED ? 'true|boolean' : 'false|boolean',
                                                  use_derived_weight: 'false|boolean',
                                                  dispatched_only: 'true|boolean',
                                                  keep_file: false })
              end
        if res.success
          change_window_location_via_json(UtilityFunctions.cache_bust_url(res.instance), request.path)
        else
          show_error(res.message, fetch?(r))
        end
      end

      r.on 'packout_report_derived_dispatches' do
        res = if AppConst::JASPER_NEW_METHOD
                jasper_params = JasperParams.new('pack_out',
                                                 current_user.login_name,
                                                 production_run_id: id,
                                                 carton_or_bin: AppConst::DEFAULT_FG_PACKAGING_TYPE.capitalize,
                                                 use_packed_weight: AppConst::CARTON_VERIFICATION_REQUIRED,
                                                 use_derived_weight: true,
                                                 dispatched_only: true)
                CreateJasperReportNew.call(jasper_params)
              else
                CreateJasperReport.call(report_name: 'pack_out',
                                        user: current_user.login_name,
                                        file: 'pack_out',
                                        params: { production_run_id: id,
                                                  carton_or_bin: AppConst::DEFAULT_FG_PACKAGING_TYPE.capitalize,
                                                  use_packed_weight: AppConst::CARTON_VERIFICATION_REQUIRED ? 'true|boolean' : 'false|boolean',
                                                  use_derived_weight: 'true|boolean',
                                                  dispatched_only: 'true|boolean',
                                                  keep_file: false })
              end
        if res.success
          change_window_location_via_json(UtilityFunctions.cache_bust_url(res.instance), request.path)
        else
          show_error(res.message, fetch?(r))
        end
      end

      r.on 'packout_report' do
        res = if AppConst::JASPER_NEW_METHOD
                jasper_params = JasperParams.new('pack_out',
                                                 current_user.login_name,
                                                 production_run_id: id,
                                                 carton_or_bin: AppConst::DEFAULT_FG_PACKAGING_TYPE.capitalize,
                                                 use_packed_weight: AppConst::CARTON_VERIFICATION_REQUIRED,
                                                 use_derived_weight: false,
                                                 dispatched_only: false)
                CreateJasperReportNew.call(jasper_params)
              else
                CreateJasperReport.call(report_name: 'pack_out',
                                        user: current_user.login_name,
                                        file: 'pack_out',
                                        params: { production_run_id: id,
                                                  carton_or_bin: AppConst::DEFAULT_FG_PACKAGING_TYPE.capitalize,
                                                  use_packed_weight: AppConst::CARTON_VERIFICATION_REQUIRED ? 'true|boolean' : 'false|boolean',
                                                  use_derived_weight: 'false|boolean',
                                                  dispatched_only: 'false|boolean',
                                                  keep_file: false })
              end
        if res.success
          change_window_location_via_json(UtilityFunctions.cache_bust_url(res.instance), request.path)
        else
          show_error(res.message, fetch?(r))
        end
      end

      r.on 'packout_report_derived' do
        res = if AppConst::JASPER_NEW_METHOD
                jasper_params = JasperParams.new('pack_out',
                                                 current_user.login_name,
                                                 production_run_id: id,
                                                 carton_or_bin: AppConst::DEFAULT_FG_PACKAGING_TYPE.capitalize,
                                                 use_packed_weight: AppConst::CARTON_VERIFICATION_REQUIRED,
                                                 use_derived_weight: true,
                                                 dispatched_only: false)
                CreateJasperReportNew.call(jasper_params)
              else
                CreateJasperReport.call(report_name: 'pack_out',
                                        user: current_user.login_name,
                                        file: 'pack_out',
                                        params: { production_run_id: id,
                                                  carton_or_bin: AppConst::DEFAULT_FG_PACKAGING_TYPE.capitalize,
                                                  use_packed_weight: AppConst::CARTON_VERIFICATION_REQUIRED ? 'true|boolean' : 'false|boolean',
                                                  use_derived_weight: 'true|boolean',
                                                  dispatched_only: 'false|boolean',
                                                  keep_file: false })
              end
        if res.success
          change_window_location_via_json(UtilityFunctions.cache_bust_url(res.instance), request.path)
        else
          show_error(res.message, fetch?(r))
        end
      end

      r.on 'carton_packout_report' do
        res = if AppConst::JASPER_NEW_METHOD
                jasper_params = JasperParams.new('carton_packout',
                                                 current_user.login_name,
                                                 production_run_id: id)
                CreateJasperReportNew.call(jasper_params)
              else
                CreateJasperReport.call(report_name: 'carton_packout',
                                        user: current_user.login_name,
                                        file: 'carton_packout',
                                        params: { production_run_id: id })
              end
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

      r.on 'product_setup', Integer do |product_setup_id|
        r.on 'print_label' do
          r.get do
            show_partial { Production::Runs::ProductionRun::PrintCarton.call(id, product_setup_id, request.ip) }
          end
          r.patch do
            res = interactor.print_carton_label(id, product_setup_id, request.ip, params[:product_setup])
            if res.success
              show_json_notice(res.message)
            else
              re_show_form(r, res) do
                Production::Runs::ProductionRun::PrintCarton.call(id,
                                                                  product_setup_id,
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
                                                      remote: fetch?(r))
          end
        end
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
          ]
          update_grid_row(id, changes: select_attributes(res.instance, row_keys), notice: res.message)
        else
          re_show_form(r, res) { Production::Runs::ProductionRun::SelectProductSetup.call(id, form_values: params[:product_resource_allocation], form_errors: res.errors) }
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
  end
end
# rubocop:enable Metrics/ClassLength
# rubocop:enable Metrics/BlockLength
