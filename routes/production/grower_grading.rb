# frozen_string_literal: true

class Nspack < Roda
  route 'grower_grading', 'production' do |r|
    # GROWER GRADING RULES
    # --------------------------------------------------------------------------
    r.on 'grower_grading_rules', Integer do |id|
      interactor = ProductionApp::GrowerGradingRuleInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      # Check for notfound:
      r.on !interactor.exists?(:grower_grading_rules, id) do
        handle_not_found(r)
      end

      r.on 'edit' do   # EDIT
        check_auth!('grower grading', 'edit')
        interactor.assert_permission!(:edit, id)
        show_partial { Production::GrowerGrading::GrowerGradingRule::Edit.call(id) }
      end

      r.on 'manage' do   # EDIT
        check_auth!('grower grading', 'edit')
        interactor.assert_permission!(:edit, id)
        show_partial_or_page(r) { Production::GrowerGrading::GrowerGradingRule::Manage.call(id) }
      end

      r.on 'clone_grower_grading_rule' do
        r.on 'clone' do
          check_auth!('grower grading', 'edit')
          interactor.assert_permission!(:edit, id)
          show_partial_or_page(r) { Production::GrowerGrading::GrowerGradingRule::Clone.call(id) }
        end

        r.post do
          check_auth!('grower grading', 'edit')
          interactor.assert_permission!(:edit, id)
          res = interactor.clone_grower_grading_rule(id, params[:grower_grading_rule])
          if res.success
            flash[:notice] = res.message
            redirect_to_last_grid(r)
          else
            re_show_form(r, res) do
              Production::GrowerGrading::GrowerGradingRule::Clone.call(id,
                                                                       form_values: params[:grower_grading_rule],
                                                                       form_errors: res.errors)
            end
          end
        end
      end

      r.on 'activate' do
        check_auth!('grower grading', 'edit')
        interactor.assert_permission!(:activate, id)
        res = interactor.activate_grower_grading_rule(id)
        if res.success
          flash[:notice] = res.message
        else
          flash[:error] = res.message
        end
        redirect_to_last_grid(r)
      end

      r.on 'deactivate' do
        check_auth!('grower grading', 'edit')
        interactor.assert_permission!(:deactivate, id)
        res = interactor.deactivate_grower_grading_rule(id)
        if res.success
          flash[:notice] = res.message
        else
          flash[:error] = res.message
        end
        redirect_to_last_grid(r)
      end

      r.on 'apply_rule' do
        check_auth!('grower grading', 'edit')
        interactor.assert_permission!(:apply_rule, id)
        res = interactor.apply_rule(id)
        if res.success
          flash[:notice] = res.message
        else
          flash[:error] = res.message
        end
        redirect_to_last_grid(r)
      end

      r.on 'grower_grading_rule_items' do
        interactor = ProductionApp::GrowerGradingRuleItemInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

        r.on 'ui_change', String do |change_type| # Handle UI behaviours
          handle_ui_change(:grower_grading_rule_item, change_type.to_sym, params)
        end

        r.on 'new' do    # NEW
          check_auth!('grower grading', 'new')
          show_partial_or_page(r) { Production::GrowerGrading::GrowerGradingRuleItem::New.call(id, remote: fetch?(r)) }
        end
        r.post do        # CREATE
          res = interactor.create_grower_grading_rule_item(params[:grower_grading_rule_item])
          if res.success
            row_keys = %i[
              id
              rule_item_code
              commodity_code
              marketing_variety_code
              grade_code
              inspection_type_code
              actual_count
              size_count
              size_reference
              rmt_class_code
              rmt_size_code
              legacy_data
              changes
              active
              created_by
              updated_by
            ]
            add_grid_row(attrs: select_attributes(res.instance, row_keys),
                         notice: res.message)
          else
            re_show_form(r, res, url: "/production/grower_grading/grower_grading_rules/#{id}/grower_grading_rule_items/new") do
              Production::GrowerGrading::GrowerGradingRuleItem::New.call(id,
                                                                         form_values: params[:grower_grading_rule_item],
                                                                         form_errors: res.errors,
                                                                         remote: fetch?(r))
            end
          end
        end
      end

      r.is do
        r.get do       # SHOW
          check_auth!('grower grading', 'read')
          show_partial { Production::GrowerGrading::GrowerGradingRule::Show.call(id) }
        end
        r.patch do     # UPDATE
          res = interactor.update_grower_grading_rule(id, params[:grower_grading_rule])
          if res.success
            row_keys = %i[
              rule_name
              description
              file_name
              packhouse_resource_code
              line_resource_code
              season_code
              cultivar_group_code
              cultivar_name
              rebin_rule
              created_by
              updated_by
            ]
            update_grid_row(id, changes: select_attributes(res.instance, row_keys), notice: res.message)
          else
            re_show_form(r, res) { Production::GrowerGrading::GrowerGradingRule::Edit.call(id, form_values: params[:grower_grading_rule], form_errors: res.errors) }
          end
        end
        r.delete do    # DELETE
          check_auth!('grower grading', 'delete')
          interactor.assert_permission!(:delete, id)
          res = interactor.delete_grower_grading_rule(id)
          if res.success
            delete_grid_row(id, notice: res.message)
          else
            show_json_error(res.message, status: 200)
          end
        end
      end
    end

    r.on 'grower_grading_rules' do
      interactor = ProductionApp::GrowerGradingRuleInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      r.on 'ui_change', String do |change_type| # Handle UI behaviours
        handle_ui_change(:grower_grading_rule, change_type.to_sym, params)
      end

      r.on 'new' do    # NEW
        check_auth!('grower grading', 'new')
        show_partial_or_page(r) { Production::GrowerGrading::GrowerGradingRule::New.call(remote: fetch?(r)) }
      end
      r.post do        # CREATE
        res = interactor.create_grower_grading_rule(params[:grower_grading_rule])
        if res.success
          row_keys = %i[
            id
            rule_name
            description
            file_name
            packhouse_resource_code
            line_resource_code
            season_code
            cultivar_group_code
            cultivar_name
            rebin_rule
            active
            created_by
            updated_by
          ]
          add_grid_row(attrs: select_attributes(res.instance, row_keys),
                       notice: res.message)
        else
          re_show_form(r, res, url: '/production/grower_grading/grower_grading_rules/new') do
            Production::GrowerGrading::GrowerGradingRule::New.call(form_values: params[:grower_grading_rule],
                                                                   form_errors: res.errors,
                                                                   remote: fetch?(r))
          end
        end
      end
    end

    # GROWER GRADING RULE ITEMS
    # --------------------------------------------------------------------------
    r.on 'grower_grading_rule_items', Integer do |id|
      interactor = ProductionApp::GrowerGradingRuleItemInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      # Check for notfound:
      r.on !interactor.exists?(:grower_grading_rule_items, id) do
        handle_not_found(r)
      end

      r.on 'edit' do   # EDIT
        check_auth!('grower grading', 'edit')
        interactor.assert_permission!(:edit, id)
        show_partial { Production::GrowerGrading::GrowerGradingRuleItem::Edit.call(id) }
      end

      r.on 'clone_grower_grading_rule_item' do
        r.on 'clone' do
          check_auth!('grower grading', 'edit')
          interactor.assert_permission!(:edit, id)
          show_partial_or_page(r) { Production::GrowerGrading::GrowerGradingRuleItem::Clone.call(id) }
        end

        r.post do        # CREATE CLONE
          res = interactor.clone_grower_grading_rule_item(id, params[:grower_grading_rule_item])
          if res.success
            row_keys = %i[
              id
              rule_item_code
              commodity_code
              marketing_variety_code
              grade_code
              inspection_type_code
              actual_count
              size_count
              size_reference
              rmt_class_code
              rmt_size_code
              legacy_data
              changes
              active
              created_by
              updated_by
            ]
            add_grid_row(attrs: select_attributes(res.instance, row_keys),
                         notice: res.message)
          else
            re_show_form(r, res, url: "/production/grower_grading/grower_grading_rule_items/#{id}/clone_grower_grading_rule_item/clone") do
              Production::GrowerGrading::GrowerGradingRuleItem::Clone.call(id,
                                                                           form_values: params[:grower_grading_rule_item],
                                                                           form_errors: res.errors)
            end
          end
        end
      end

      r.on 'activate' do
        check_auth!('grower grading', 'edit')
        interactor.assert_permission!(:activate, id)
        res = interactor.activate_grower_grading_rule_item(id)
        flash[:notice] = res.message
        r.redirect(back_button_url)
      end

      r.on 'deactivate' do
        check_auth!('grower grading', 'edit')
        interactor.assert_permission!(:deactivate, id)
        res = interactor.deactivate_grower_grading_rule_item(id)
        flash[:notice] = res.message
        r.redirect(back_button_url)
      end

      r.is do
        r.get do       # SHOW
          check_auth!('grower grading', 'read')
          show_partial { Production::GrowerGrading::GrowerGradingRuleItem::Show.call(id) }
        end
        r.patch do     # UPDATE
          res = interactor.update_grower_grading_rule_item(id, params[:grower_grading_rule_item])
          if res.success
            row_keys = %i[
              rule_item_code
              commodity_code
              marketing_variety_code
              grade_code
              inspection_type_code
              rmt_class_code
              actual_count
              size_count
              size_reference
              legacy_data
              changes
              active
              created_by
              updated_by
            ]
            update_grid_row(id, changes: select_attributes(res.instance, row_keys), notice: res.message)
          else
            re_show_form(r, res) { Production::GrowerGrading::GrowerGradingRuleItem::Edit.call(id, form_values: params[:grower_grading_rule_item], form_errors: res.errors) }
          end
        end
        r.delete do    # DELETE
          check_auth!('grower grading', 'delete')
          interactor.assert_permission!(:delete, id)
          res = interactor.delete_grower_grading_rule_item(id)
          if res.success
            delete_grid_row(id, notice: res.message)
          else
            show_json_error(res.message, status: 200)
          end
        end
      end
    end

    # GROWER GRADING POOLS
    # --------------------------------------------------------------------------
    r.on 'grower_grading_pools', Integer do |id|
      interactor = ProductionApp::GrowerGradingPoolInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      # Check for notfound:
      r.on !interactor.exists?(:grower_grading_pools, id) do
        handle_not_found(r)
      end

      r.on 'edit' do   # EDIT
        check_auth!('grower grading', 'edit')
        interactor.assert_permission!(:edit, id)
        show_partial { Production::GrowerGrading::GrowerGradingPool::Edit.call(id) }
      end

      r.on 'manage', String do |object_name|
        check_auth!('grower grading', 'edit')
        interactor.assert_permission!(:edit, id)
        show_partial_or_page(r) { Production::GrowerGrading::GrowerGradingPool::Manage.call(id, object_name) }
      end

      r.on 'complete_objects_grading', String do |object_name|
        check_auth!('grower grading', 'edit')
        interactor.assert_permission!(:edit, id)
        res = interactor.complete_objects_grading(id, object_name)
        if res.success
          flash[:notice] = res.message
        else
          flash[:error] = res.message
        end
        redirect_to_last_grid(r)
      end

      r.on 'reopen_objects_grading', String do |object_name|
        check_auth!('grower grading', 'edit')
        interactor.assert_permission!(:edit, id)
        res = interactor.reopen_objects_grading(id, object_name)
        if res.success
          flash[:notice] = res.message
        else
          flash[:error] = res.message
        end
        redirect_to_last_grid(r)
      end

      r.on 'complete_pool' do
        r.get do
          check_auth!('grower grading', 'edit')
          interactor.assert_permission!(:complete_pool, id)
          show_partial do
            Production::GrowerGrading::GrowerGradingPool::Confirm.call(id,
                                                                       url: "/production/grower_grading/grower_grading_pools/#{id}/complete_pool",
                                                                       notice: 'Press the button to mark grading pool as complete',
                                                                       button_captions: ['Mark as Complete', 'Completing...'])
          end
        end

        r.post do
          interactor.mark_pool_as_complete(id)
          update_grid_row(id, changes: { completed: true }, notice: 'Grading Pool has been marked as complete')
        end
      end

      r.on 'un_complete_pool' do
        r.get do
          check_auth!('grower grading', 'edit')
          interactor.assert_permission!(:complete_pool, id)
          show_partial do
            Production::GrowerGrading::GrowerGradingPool::Confirm.call(id,
                                                                       url: "/production/grower_grading/grower_grading_pools/#{id}/un_complete_pool",
                                                                       notice: 'Press the button to undo complete status of grading pool',
                                                                       button_captions: ['Undo complete', 'Undoing complete...'])
          end
        end

        r.post do
          interactor.mark_pool_as_incomplete(id)
          update_grid_row(id, changes: { completed: false }, notice: 'Grading Pool no longer marked as complete')
        end
      end

      r.is do
        r.get do       # SHOW
          check_auth!('grower grading', 'read')
          show_partial { Production::GrowerGrading::GrowerGradingPool::Show.call(id) }
        end
        r.patch do     # UPDATE
          res = interactor.update_grower_grading_pool(id, params[:grower_grading_pool])
          if res.success
            row_keys = %i[
              pool_name
              description
              production_run_code
              cultivar_group_code
              cultivar_name
              farm_code
              season_code
              commodity_code
              inspection_type_code
              bin_quantity
              gross_weight
              nett_weight
              pro_rata_factor
              legacy_data
              completed
              rule_applied
              created_by
              updated_by
              rule_applied_by
              rule_applied_at
            ]
            update_grid_row(id, changes: select_attributes(res.instance, row_keys), notice: res.message)
          else
            re_show_form(r, res) { Production::GrowerGrading::GrowerGradingPool::Edit.call(id, form_values: params[:grower_grading_pool], form_errors: res.errors) }
          end
        end
        r.delete do    # DELETE
          check_auth!('grower grading', 'delete')
          interactor.assert_permission!(:delete, id)
          res = interactor.delete_grower_grading_pool(id)
          if res.success
            delete_grid_row(id, notice: res.message)
          else
            show_json_error(res.message, status: 200)
          end
        end
      end
    end

    r.on 'grower_grading_pools' do
      interactor = ProductionApp::GrowerGradingPoolInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      r.on 'create_grading_pools' do
        check_auth!('grower grading', 'new')
        r.redirect '/list/grower_grading_production_runs/multi?key=create_grading_pools'
      end

      r.on 'multiselect_production_runs' do
        res = interactor.create_grading_pools(multiselect_grid_choices(params))
        if res.success
          flash[:notice] = res.message
        else
          flash[:error] = res.message
        end
        redirect_to_last_grid(r)
      end

      r.on 'new' do    # NEW
        check_auth!('grower grading', 'new')
        show_partial_or_page(r) { Production::GrowerGrading::GrowerGradingPool::New.call(remote: fetch?(r)) }
      end
      r.post do        # CREATE
        res = interactor.create_grower_grading_pool(params[:grower_grading_pool])
        if res.success
          flash[:notice] = res.message
          redirect_to_last_grid(r)
        else
          re_show_form(r, res, url: '/production/grower_grading/grower_grading_pools/new') do
            Production::GrowerGrading::GrowerGradingPool::New.call(form_values: params[:grower_grading_pool],
                                                                   form_errors: res.errors,
                                                                   remote: fetch?(r))
          end
        end
      end
    end

    # GROWER GRADING CARTONS
    # --------------------------------------------------------------------------
    r.on 'grower_grading_cartons', Integer do |id|
      interactor = ProductionApp::GrowerGradingCartonInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      # Check for notfound:
      r.on !interactor.exists?(:grower_grading_cartons, id) do
        handle_not_found(r)
      end

      r.on 'inline_edit_carton_fields' do
        res = interactor.inline_edit_carton_fields(id, params)
        if res.success
          row_keys = %i[
            graded_size_count
            graded_grade_code
            graded_rmt_class_code
          ]
          update_grid_row(id, changes: select_attributes(res.instance, row_keys), notice: res.message)
        else
          undo_grid_inline_edit(message: res.message, message_type: :error)
        end
      end

      r.is do
        r.get do       # SHOW
          check_auth!('grower grading', 'read')
          show_partial { Production::GrowerGrading::GrowerGradingCarton::Show.call(id) }
        end
      end
    end

    # GROWER GRADING REBINS
    # --------------------------------------------------------------------------
    r.on 'grower_grading_rebins', Integer do |id|
      interactor = ProductionApp::GrowerGradingRebinInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      # Check for notfound:
      r.on !interactor.exists?(:grower_grading_rebins, id) do
        handle_not_found(r)
      end

      r.on 'inline_edit_rebin_fields' do
        res = interactor.inline_edit_rebin_fields(id, params)
        if res.success
          row_keys = %i[
            graded_rmt_class_code
            graded_rmt_size_code
            graded_gross_weight
            graded_nett_weight
          ]
          update_grid_row(id, changes: select_attributes(res.instance, row_keys), notice: res.message)
        else
          undo_grid_inline_edit(message: res.message, message_type: :error)
        end
      end

      r.is do
        r.get do       # SHOW
          check_auth!('grower grading', 'read')
          show_partial { Production::GrowerGrading::GrowerGradingRebin::Show.call(id) }
        end
      end
    end
  end
end
