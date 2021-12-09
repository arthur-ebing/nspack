# frozen_string_literal: true

class Nspack < Roda
  route 'presort_grower_grading', 'raw_materials' do |r|
    # PRESORT GROWER GRADING POOLS
    # --------------------------------------------------------------------------
    r.on 'presort_grower_grading_pools', Integer do |id|
      interactor = RawMaterialsApp::PresortGrowerGradingPoolInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      # Check for notfound:
      r.on !interactor.exists?(:presort_grower_grading_pools, id) do
        handle_not_found(r)
      end

      # PRESORT GROWER GRADING BINS
      # --------------------------------------------------------------------------
      r.on 'presort_grower_grading_bins' do
        interactor = RawMaterialsApp::PresortGrowerGradingBinInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

        r.on 'new' do    # NEW
          check_auth!('presort grower grading', 'new')
          show_partial_or_page(r) { RawMaterials::PresortGrowerGrading::PresortGrowerGradingBin::New.call(id, remote: fetch?(r)) }
        end
        r.post do        # CREATE
          res = interactor.create_presort_grower_grading_bin(params[:presort_grower_grading_bin])
          if res.success
            row_keys = %i[
              id
              presort_grower_grading_pool_id
              maf_lot_number
              farm_code
              rmt_class_code
              rmt_size_code
              maf_rmt_code
              maf_article
              maf_class
              maf_colour
              maf_count
              maf_article_count
              maf_weight
              maf_tipped_quantity
              maf_total_lot_weight
              created_by
              updated_by
            ]
            add_grid_row(attrs: select_attributes(res.instance, row_keys),
                         notice: res.message)
          else
            re_show_form(r, res, url: "/raw_materials/presort_grower_grading/presort_grower_grading_pools/#{id}/presort_grower_grading_bins/new") do
              RawMaterials::PresortGrowerGrading::PresortGrowerGradingBin::New.call(id,
                                                                                    form_values: params[:presort_grower_grading_bin],
                                                                                    form_errors: res.errors,
                                                                                    remote: fetch?(r))
            end
          end
        end
      end

      r.on 'manage' do
        check_auth!('presort grower grading', 'edit')
        interactor.assert_permission!(:edit, id)
        show_partial_or_page(r) { RawMaterials::PresortGrowerGrading::PresortGrowerGradingPool::Manage.call(id) }
      end

      r.on 'complete_pool' do
        r.get do
          check_auth!('presort grower grading', 'edit')
          interactor.assert_permission!(:complete_pool, id)
          show_partial do
            RawMaterials::PresortGrowerGrading::PresortGrowerGradingPool::Confirm.call(id,
                                                                                       url: "/raw_materials/presort_grower_grading/presort_grower_grading_pools/#{id}/complete_pool",
                                                                                       notice: 'Press the button to mark presort grading pool as complete',
                                                                                       button_captions: ['Mark as Complete', 'Completing...'])
          end
        end

        r.post do
          interactor.mark_pool_as_complete(id)
          update_grid_row(id, changes: { completed: true }, notice: 'Presort Grading Pool has been marked as complete')
        end
      end

      r.on 'un_complete_pool' do
        r.get do
          check_auth!('presort grower grading', 'edit')
          interactor.assert_permission!(:un_complete_pool, id)
          show_partial do
            RawMaterials::PresortGrowerGrading::PresortGrowerGradingPool::Confirm.call(id,
                                                                                       url: "/raw_materials/presort_grower_grading/presort_grower_grading_pools/#{id}/un_complete_pool",
                                                                                       notice: 'Press the button to undo complete status of presort grading pool',
                                                                                       button_captions: ['Undo complete', 'Undoing complete...'])
          end
        end

        r.post do
          interactor.mark_pool_as_incomplete(id)
          update_grid_row(id, changes: { completed: false }, notice: 'Presort Grading Pool no longer marked as complete')
        end
      end

      r.on 'import_maf_data' do
        r.get do
          check_auth!('presort grower grading', 'edit')
          interactor.assert_permission!(:import_maf_data, id)
          show_partial do
            RawMaterials::PresortGrowerGrading::PresortGrowerGradingPool::Confirm.call(id,
                                                                                       url: "/raw_materials/presort_grower_grading/presort_grower_grading_pools/#{id}/import_maf_data",
                                                                                       notice: 'Press the button to import maf data',
                                                                                       button_captions: ['Import MAF Data', 'Importing...'])
          end
        end

        r.post do
          res = interactor.import_maf_data(id)
          if res.success
            flash[:notice] = res.message
          else
            flash[:error] = res.message
          end
          redirect_to_last_grid(r)
        end
      end

      r.on 'refresh_presort_grading' do
        r.get do
          check_auth!('presort grower grading', 'edit')
          interactor.assert_permission!(:refresh_pool, id)
          show_partial do
            RawMaterials::PresortGrowerGrading::PresortGrowerGradingPool::Confirm.call(id,
                                                                                       url: "/raw_materials/presort_grower_grading/presort_grower_grading_pools/#{id}/refresh_presort_grading",
                                                                                       notice: 'Press the button refresh presort grading poof',
                                                                                       button_captions: ['Refresh Presort Pool', 'Refreshing...'])
          end
        end

        r.post do
          res = interactor.refresh_presort_grading(id)
          if res.success
            flash[:notice] = res.message
          else
            flash[:error] = res.message
          end
          redirect_to_last_grid(r)
        end
      end

      r.on 'preview_presort_grading_report' do
        jasper_params = JasperParams.new('ps_grower_grading',
                                         current_user.login_name,
                                         presort_grading_pool_id: id)
        res = CreateJasperReport.call(jasper_params)

        if res.success
          change_window_location_via_json(UtilityFunctions.cache_bust_url(res.instance), request.path)
        else
          show_error(res.message, fetch?(r))
        end
      end

      r.on 'edit' do   # EDIT
        check_auth!('presort grower grading', 'edit')
        interactor.assert_permission!(:edit, id)
        show_partial { RawMaterials::PresortGrowerGrading::PresortGrowerGradingPool::Edit.call(id) }
      end

      r.is do
        r.get do       # SHOW
          check_auth!('presort grower grading', 'read')
          show_partial { RawMaterials::PresortGrowerGrading::PresortGrowerGradingPool::Show.call(id) }
        end
        r.patch do     # UPDATE
          res = interactor.update_presort_grower_grading_pool(id, params[:presort_grower_grading_pool])
          if res.success
            row_keys = %i[
              maf_lot_number
              description
              track_slms_indicator_code
              season_code
              commodity_code
              farm_code
              rmt_bin_count
              rmt_bin_weight
              pro_rata_factor
              completed
              created_by
              updated_by
            ]
            update_grid_row(id, changes: select_attributes(res.instance, row_keys), notice: res.message)
          else
            re_show_form(r, res) { RawMaterials::PresortGrowerGrading::PresortGrowerGradingPool::Edit.call(id, form_values: params[:presort_grower_grading_pool], form_errors: res.errors) }
          end
        end
        r.delete do    # DELETE
          check_auth!('presort grower grading', 'delete')
          interactor.assert_permission!(:delete, id)
          res = interactor.delete_presort_grower_grading_pool(id)
          if res.success
            delete_grid_row(id, notice: res.message)
          else
            show_json_error(res.message, status: 200)
          end
        end
      end
    end

    r.on 'presort_grower_grading_pools' do
      interactor = RawMaterialsApp::PresortGrowerGradingPoolInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      r.on 'create_presort_grading_pools' do
        check_auth!('presort grower grading', 'new')
        r.redirect '/list/presort_grower_grading_maf_lot_numbers/multi?key=create_presort_grading_pools'
      end

      r.on 'multiselect_maf_lot_numbers' do
        res = interactor.create_presort_grading_pools(multiselect_grid_choices(params, treat_as_integers: false))
        if res.success
          flash[:notice] = res.message
        else
          flash[:error] = res.message
        end
        redirect_to_last_grid(r)
      end

      r.on 'new' do    # NEW
        check_auth!('presort grower grading', 'new')
        show_partial_or_page(r) { RawMaterials::PresortGrowerGrading::PresortGrowerGradingPool::New.call(remote: fetch?(r)) }
      end
      r.post do        # CREATE
        res = interactor.create_presort_grower_grading_pool(params[:presort_grower_grading_pool])
        if res.success
          row_keys = %i[
            id
            maf_lot_number
            description
            track_slms_indicator_code
            season_code
            commodity_code
            farm_code
            rmt_bin_count
            rmt_bin_weight
            pro_rata_factor
            completed
            active
            created_by
            updated_by
          ]
          add_grid_row(attrs: select_attributes(res.instance, row_keys),
                       notice: res.message)
        else
          re_show_form(r, res, url: '/raw_materials/presort_grower_grading/presort_grower_grading_pools/new') do
            RawMaterials::PresortGrowerGrading::PresortGrowerGradingPool::New.call(form_values: params[:presort_grower_grading_pool],
                                                                                   form_errors: res.errors,
                                                                                   remote: fetch?(r))
          end
        end
      end
    end

    # PRESORT GROWER GRADING BINS
    # --------------------------------------------------------------------------
    r.on 'presort_grower_grading_bins', Integer do |id|
      interactor = RawMaterialsApp::PresortGrowerGradingBinInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      # Check for notfound:
      r.on !interactor.exists?(:presort_grower_grading_bins, id) do
        handle_not_found(r)
      end

      r.on 'inline_edit_bin_fields' do
        res = interactor.inline_edit_bin_fields(id, params)
        if res.success
          row_keys = %i[
            rmt_class_code
            rmt_size_code
          ]
          update_grid_row(id, changes: select_attributes(res.instance, row_keys), notice: res.message)
        else
          undo_grid_inline_edit(message: res.message, message_type: :error)
        end
      end

      r.on 'edit' do   # EDIT
        check_auth!('presort grower grading', 'edit')
        interactor.assert_permission!(:edit, id)
        show_partial { RawMaterials::PresortGrowerGrading::PresortGrowerGradingBin::Edit.call(id) }
      end

      r.is do
        r.get do       # SHOW
          check_auth!('presort grower grading', 'read')
          show_partial { RawMaterials::PresortGrowerGrading::PresortGrowerGradingBin::Show.call(id) }
        end
        r.patch do     # UPDATE
          res = interactor.update_presort_grower_grading_bin(id, params[:presort_grower_grading_bin])
          if res.success
            row_keys = %i[
              presort_grower_grading_pool_id
              maf_lot_number
              farm_code
              rmt_class_code
              rmt_size_code
              maf_rmt_code
              maf_article
              maf_class
              maf_colour
              maf_count
              maf_article_count
              maf_weight
              maf_tipped_quantity
              maf_total_lot_weight
              created_by
              updated_by
            ]
            update_grid_row(id, changes: select_attributes(res.instance, row_keys), notice: res.message)
          else
            re_show_form(r, res) { RawMaterials::PresortGrowerGrading::PresortGrowerGradingBin::Edit.call(id, form_values: params[:presort_grower_grading_bin], form_errors: res.errors) }
          end
        end
        r.delete do    # DELETE
          check_auth!('presort grower grading', 'delete')
          interactor.assert_permission!(:delete, id)
          res = interactor.delete_presort_grower_grading_bin(id)
          if res.success
            delete_grid_row(id, notice: res.message)
          else
            show_json_error(res.message, status: 200)
          end
        end
      end
    end
  end
end
