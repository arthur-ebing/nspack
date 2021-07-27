# frozen_string_literal: true

class Nspack < Roda
  route 'presorting', 'raw_materials' do |r|
    # PRESORT STAGING RUNS
    # --------------------------------------------------------------------------
    r.on 'presort_staging_runs', Integer do |id|
      interactor = RawMaterialsApp::PresortStagingRunInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      # Check for notfound:
      r.on !interactor.exists?(:presort_staging_runs, id) do
        handle_not_found(r)
      end

      r.on 'complete_setup' do
        res = interactor.complete_setup(id)
        flash[res.success ? :notice : :error] = res.message
        r.redirect '/list/presort_staging_runs'
      end

      r.on 'uncomplete_setup' do
        res = interactor.uncomplete_setup(id)
        flash[res.success ? :notice : :error] = res.message
        r.redirect '/list/presort_staging_runs'
      end

      r.on 'activate_run' do
        res = interactor.activate_run(id)
        flash[res.success ? :notice : :error] = res.message
        r.redirect '/list/presort_staging_runs'
      end

      r.on 'complete_staging' do
        res = interactor.complete_staging(id)
        flash[res.success ? :notice : :error] = res.message
        r.redirect '/list/presort_staging_runs'
      end

      r.on 'edit' do   # EDIT
        check_auth!('presorting', 'edit')
        interactor.assert_permission!(:edit, id)
        show_partial_or_page(r) { RawMaterials::Presorting::PresortStagingRun::Edit.call(id) }
      end

      r.on 'staging_run_child' do
        r.get do
          show_partial_or_page(r) { RawMaterials::Presorting::PresortStagingRunChild::New.call(id, remote: fetch?(r)) }
        end

        r.post do
          res = interactor.create_presort_staging_run_child(id, params[:presort_staging_run_child])
          if res.success
            row_keys = %i[
              id
              farm_code
              presort_staging_run_id
              staged_at
              canceled
              farm_id
              editing
              staged
              status
              active
            ]
            add_grid_row(attrs: select_attributes(res.instance, row_keys),
                         notice: res.message)
          else
            re_show_form(r, res, url: "/raw_materials/presorting/presort_staging_runs/#{id}/staging_run_child") do
              RawMaterials::Presorting::PresortStagingRunChild::New.call(id,
                                                                         form_values: params[:presort_staging_run_child],
                                                                         form_errors: res.errors,
                                                                         remote: fetch?(r))
            end
          end
        end
      end

      r.is do
        r.get do       # SHOW
          check_auth!('presorting', 'read')
          show_partial_or_page(r) { RawMaterials::Presorting::PresortStagingRun::Show.call(id) }
        end
        r.patch do     # UPDATE
          res = interactor.update_presort_staging_run(id, params[:presort_staging_run])
          if res.success
            row_keys = %i[
              id
              setup_uncompleted_at
              setup_completed
              presort_unit_plant_resource_id
              supplier_id
              setup_completed_at
              canceled
              canceled_at
              cultivar_id
              rmt_class_id
              rmt_size_id
              season_id
              editing
              staged
              active
              legacy_data
              status
              plant_resource_code
              cultivar_name
              rmt_class_code
              size_code
              season_code
              supplier
            ]
            update_grid_row(id, changes: select_attributes(res.instance, row_keys), notice: res.message)
          else
            re_show_form(r, res) { RawMaterials::Presorting::PresortStagingRun::Edit.call(id, form_values: params[:presort_staging_run], form_errors: res.errors) }
          end
        end
        r.delete do    # DELETE
          check_auth!('presorting', 'delete')
          interactor.assert_permission!(:delete, id)
          res = interactor.delete_presort_staging_run(id)
          if res.success
            delete_grid_row(id, notice: res.message)
          else
            show_json_error(res.message, status: 200)
          end
        end
      end
    end

    r.on 'presort_staging_runs' do
      interactor = RawMaterialsApp::PresortStagingRunInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      r.on 'ui_change', String, String do |change_mode, change_field|
        handle_ui_change(:presort_staging_run, change_mode.to_sym, params, { field: change_field.to_sym })
      end

      r.on 'new' do    # NEW
        check_auth!('presorting', 'new')
        show_partial_or_page(r) { RawMaterials::Presorting::PresortStagingRun::New.call(remote: fetch?(r)) }
      end

      r.post do        # CREATE
        res = interactor.create_presort_staging_run(params[:presort_staging_run])
        if res.success
          row_keys = %i[
            id
            setup_uncompleted_at
            setup_completed
            presort_unit_plant_resource_id
            supplier_id
            setup_completed_at
            canceled
            canceled_at
            cultivar_id
            rmt_class_id
            rmt_size_id
            season_id
            editing
            staged
            active
            legacy_data
            status
            plant_resource_code
            cultivar_name
            rmt_class_code
            size_code
            season_code
            supplier
          ]
          add_grid_row(attrs: select_attributes(res.instance, row_keys),
                       notice: res.message)
        else
          re_show_form(r, res, url: '/raw_materials/presorting/presort_staging_runs/new') do
            RawMaterials::Presorting::PresortStagingRun::New.call(form_values: params[:presort_staging_run],
                                                                  form_errors: res.errors,
                                                                  remote: fetch?(r))
          end
        end
      end
    end

    r.on 'presort_staging_run_children', Integer do |id|
      interactor = RawMaterialsApp::PresortStagingRunInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      r.on 'activate_child_run' do
        res = interactor.activate_child_run(id)
        flash[res.success ? :notice : :error] = res.message
        # show_partial_or_page(r) { RawMaterials::Presorting::PresortStagingRun::Edit.call(res.instance) }
        r.redirect "/raw_materials/presorting/presort_staging_runs/#{res.instance}/edit"
      end

      r.on 'complete_staging' do
        res = interactor.complete_child_staging(id)
        flash[res.success ? :notice : :error] = res.message
        show_partial_or_page(r) { RawMaterials::Presorting::PresortStagingRun::Edit.call(res.instance) }
      end
    end
  end
end
