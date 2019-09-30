# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength
# rubocop:disable Metrics/BlockLength
class Nspack < Roda
  route 'runs', 'production' do |r|
    # PRODUCTION RUNS
    # --------------------------------------------------------------------------
    r.on 'production_runs', Integer do |id|
      interactor = ProductionApp::ProductionRunInteractor.new(current_user, {}, { route_url: request.path }, {})

      # Check for notfound:
      r.on !interactor.exists?(:production_runs, id) do
        handle_not_found(r)
      end

      r.on 'edit' do   # EDIT
        check_auth!('runs', 'edit')
        interactor.assert_permission!(:edit, id)
        show_partial { Production::Runs::ProductionRun::Edit.call(id) }
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
      interactor = ProductionApp::ProductionRunInteractor.new(current_user, {}, { route_url: request.path }, {})
      r.on 'new' do    # NEW
        check_auth!('runs', 'new')
        set_last_grid_url('/list/production_runs', r)
        show_partial_or_page(r) { Production::Runs::ProductionRun::New.call(remote: fetch?(r)) }
      end

      r.on 'choose_setup', Integer do |product_resource_allocation_id|
        res = interactor.allocate_product_setup(product_resource_allocation_id, params)
        if res.success
          json_actions([OpenStruct.new(type: :update_grid_row,
                                       ids: product_resource_allocation_id,
                                       changes: { product_setup_id: res.instance[:product_setup_id] })],
                       "Allocated #{params[:column_value]}.")
        else
          undo_grid_inline_edit(message: res.message, message_type: :warn)
        end
      end

      r.on 'selected_template', Integer do |id|
        show_json_notice("GOT #{id}")
        res = interactor.selected_template(id)
        if res.success
          json_actions(
            [
              OpenStruct.new(type: :replace_input_value,
                             dom_id: 'production_run_product_setup_template_id',
                             value: res.instance[:id]),
              OpenStruct.new(type: :replace_input_value,
                             dom_id: 'production_run_pst',
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
        send("production_run_changed_#{key}".to_sym, interactor)
      end

      r.post do        # CREATE
        res = interactor.create_production_run(params[:production_run])
        if res.success
          if fetch?(r)
            row_keys = %i[
              id
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
            add_grid_row(attrs: select_attributes(res.instance, row_keys),
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
  end

  # DROPDOWN CHANGES
  # ----------------
  def production_run_changed_packhouse(interactor)
    res = interactor.lines_for_packhouse(params)
    if res.success
      json_replace_select_options('production_run_production_line_id', res.instance)
    else
      show_json_error(res.message)
    end
  end

  def production_run_changed_farm(interactor) # rubocop:disable Metrics/AbcSize
    res = interactor.change_for_farm(params)
    if res.success
      json_actions(
        [
          OpenStruct.new(type: :replace_select_options,
                         dom_id: 'production_run_puc_id',
                         options_array: res.instance[:pucs]),
          OpenStruct.new(type: :replace_select_options,
                         dom_id: 'production_run_orchard_id',
                         options_array: res.instance[:orchards]),
          OpenStruct.new(type: :replace_select_options,
                         dom_id: 'production_run_cultivar_group_id',
                         options_array: res.instance[:cultivar_groups]),
          OpenStruct.new(type: :replace_select_options,
                         dom_id: 'production_run_cultivar_id',
                         options_array: res.instance[:cultivars]),
          OpenStruct.new(type: :replace_select_options,
                         dom_id: 'production_run_season_id',
                         options_array: res.instance[:seasons])
        ]
      )
    else
      show_json_error(res.message)
    end
  end

  def production_run_changed_puc(interactor) # rubocop:disable Metrics/AbcSize
    res = interactor.change_for_puc(params)
    if res.success
      json_actions(
        [
          OpenStruct.new(type: :replace_select_options,
                         dom_id: 'production_run_orchard_id',
                         options_array: res.instance[:orchards]),
          OpenStruct.new(type: :replace_select_options,
                         dom_id: 'production_run_cultivar_group_id',
                         options_array: res.instance[:cultivar_groups]),
          OpenStruct.new(type: :replace_select_options,
                         dom_id: 'production_run_cultivar_id',
                         options_array: res.instance[:cultivars]),
          OpenStruct.new(type: :replace_select_options,
                         dom_id: 'production_run_season_id',
                         options_array: res.instance[:seasons])
        ]
      )
    else
      show_json_error(res.message)
    end
  end

  def production_run_changed_orchard(interactor)
    res = interactor.change_for_orchard(params)
    if res.success
      json_actions(
        [
          OpenStruct.new(type: :replace_select_options,
                         dom_id: 'production_run_cultivar_group_id',
                         options_array: res.instance[:cultivar_groups]),
          OpenStruct.new(type: :replace_select_options,
                         dom_id: 'production_run_cultivar_id',
                         options_array: res.instance[:cultivars])
        ]
      )
    else
      show_json_error(res.message)
    end
  end

  def production_run_changed_cultivar_group(interactor)
    res = interactor.change_for_cultivar_group(params)
    if res.success
      json_actions(
        [
          OpenStruct.new(type: :replace_select_options,
                         dom_id: 'production_run_cultivar_id',
                         options_array: res.instance[:cultivars]),
          OpenStruct.new(type: :replace_select_options,
                         dom_id: 'production_run_season_id',
                         options_array: res.instance[:seasons])
        ]
      )
    else
      show_json_error(res.message)
    end
  end
end
# rubocop:enable Metrics/ClassLength
# rubocop:enable Metrics/BlockLength
