# frozen_string_literal: true

class Nspack < Roda
  route 'mrl', 'quality' do |r|
    # MRL RESULTS
    # --------------------------------------------------------------------------
    r.on 'mrl_results', Integer do |id|
      interactor = QualityApp::MrlResultInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      # Check for notfound:
      r.on !interactor.exists?(:mrl_results, id) do
        handle_not_found(r)
      end

      r.on 'override_mrl_result' do
        r.get do
          check_auth!('mrl', 'edit')
          interactor.assert_permission!(:edit, id)
          mrl_result_params = retrieve_from_local_store(:mrl_result_params)
          store_locally(:mrl_result_params, mrl_result_params)
          show_partial do
            Quality::Mrl::MrlResult::Override.call(id,
                                                   mrl_result_params,
                                                   button_captions: ['Override Mrl Result', 'Overriding...'])
          end
        end

        r.post do
          res = interactor.update_mrl_result(id, retrieve_from_local_store(:mrl_result_params))
          if res.success
            flash[:notice] = res.message
          else
            flash[:error] = res.message
          end
          redirect_to_last_grid(r)
        end
      end

      r.on 'print_mrl_labels' do
        r.get do
          show_partial { Quality::Mrl::MrlResult::PrintMrlLabel.call(id) }
        end
        r.patch do
          res = interactor.print_mrl_result_label(id, params[:mrl_result])
          if res.success
            show_json_notice(res.message)
          else
            re_show_form(r, res) { Quality::Mrl::MrlResult::PrintMrlLabel.call(id, form_values: params[:mrl_result], form_errors: res.errors) }
          end
        end
      end

      r.on 'edit' do   # EDIT
        check_auth!('mrl', 'edit')
        interactor.assert_permission!(:edit, id)
        show_partial { Quality::Mrl::MrlResult::Edit.call(id) }
      end

      r.is do
        r.get do       # SHOW
          check_auth!('mrl', 'read')
          show_partial { Quality::Mrl::MrlResult::Show.call(id) }
        end
        r.patch do     # UPDATE
          res = interactor.update_mrl_result(id, params[:mrl_result])
          if res.success
            flash[:notice] = res.message
            redirect_to_last_grid(r)
          else
            re_show_form(r, res) { Quality::Mrl::MrlResult::Edit.call(id, form_values: params[:mrl_result], form_errors: res.errors) }
          end
        end
        r.delete do    # DELETE
          check_auth!('mrl', 'delete')
          interactor.assert_permission!(:delete, id)
          res = interactor.delete_mrl_result(id)
          if res.success
            delete_grid_row(id, notice: res.message)
          else
            show_json_error(res.message, status: 200)
          end
        end
      end
    end

    r.on 'mrl_results' do
      interactor = QualityApp::MrlResultInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      r.on 'ui_change', String do |change_type| # Handle UI behaviours
        handle_ui_change(:mrl_result, change_type.to_sym, params)
      end

      r.on 'rmt_delivery', Integer do |rmt_delivery_id|
        check_auth!('mrl', 'new')
        res = interactor.delivery_mrl_result_attrs(rmt_delivery_id)
        if res.success
          show_partial_or_page(r) do
            Quality::Mrl::MrlResult::New.call(true,
                                              false,
                                              form_values: res.instance,
                                              form_errors: res.errors,
                                              remote: fetch?(r))
          end
        end
      end

      r.on 'new' do    # NEW
        check_auth!('mrl', 'new')
        pre_harvest_result = params[:pre_harvest_result] == 'true'
        post_harvest_result = params[:post_harvest_result] == 'true'
        show_partial_or_page(r) do
          Quality::Mrl::MrlResult::New.call(pre_harvest_result,
                                            post_harvest_result,
                                            remote: fetch?(r))
        end
      end
      r.post do        # CREATE
        val_res = interactor.validate_existing_mrl_result(params[:mrl_result])
        if val_res.success
          existing_id = val_res[:instance][:existing_id]
          unless existing_id.nil?
            store_locally(:mrl_result_params, val_res.instance)
            flash[:notice] = val_res.message
            r.redirect("/quality/mrl/mrl_results/#{existing_id}/override_mrl_result")
          end
          res = interactor.create_mrl_result(params[:mrl_result])
          flash[:notice] = res.message
          redirect_to_last_grid(r)
        else
          re_show_form(r, val_res, url: '/quality/mrl/mrl_results/new') do
            Quality::Mrl::MrlResult::New.call(val_res.instance[:pre_harvest_result],
                                              val_res.instance[:post_harvest_result],
                                              form_values: val_res.instance,
                                              form_errors: val_res.errors,
                                              remote: fetch?(r))
          end
        end
      end
    end
  end
end
