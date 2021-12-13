# frozen_string_literal: true

class Nspack < Roda
  route 'test_results', 'quality' do |r|
    # ORCHARD TEST RESULTS
    # --------------------------------------------------------------------------
    r.on 'orchard_test_results', Integer do |id|
      interactor = QualityApp::OrchardTestResultInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      # Check for notfound:
      r.on !interactor.exists?(:orchard_test_results, id) do
        handle_not_found(r)
      end

      r.on 'phyt_clean_request', Integer do |puc_id|
        res = interactor.phyt_clean_request(puc_id)
        flash[res.success ? :notice : :error] = res.message
        r.redirect '/list/orchard_test_results'
      end

      r.on 'edit' do   # EDIT
        check_auth!('otmc', 'edit')
        interactor.assert_permission!(:edit, id)
        show_partial_or_page(r) { Quality::TestResults::OrchardTestResult::Edit.call(id) }
      end

      r.on 'bulk_edit' do
        r.get do       # EDIT
          check_auth!('otmc', 'edit')
          interactor.assert_permission!(:edit, id)
          show_partial_or_page(r) { Quality::TestResults::OrchardTestResult::BulkEdit.call(id) }
        end
        r.patch do     # UPDATE
          res = interactor.update_orchard_test_result(id, params[:orchard_test_result])
          if res.success
            flash[:notice] = res.message
            r.redirect '/list/orchard_test_results'
          else
            re_show_form(r, res, url: "/quality/test_results/orchard_test_results/#{id}/bulk_edit") do
              Quality::TestResults::OrchardTestResult::BulkEdit.call(id,
                                                                     form_values: params[:orchard_test_result],
                                                                     form_errors: res.errors)
            end
          end
        end
      end

      r.is do
        r.get do       # SHOW
          check_auth!('otmc', 'read')
          show_partial_or_page(r) { Quality::TestResults::OrchardTestResult::Show.call(id) }
        end
        r.patch do     # UPDATE
          res = interactor.update_orchard_test_result(id, params[:orchard_test_result])
          if res.success
            flash[:notice] = res.message
            r.redirect '/list/orchard_test_results'
          else
            re_show_form(r, res, url: "/quality/test_results/orchard_test_results/#{id}/edit") do
              Quality::TestResults::OrchardTestResult::Edit.call(id,
                                                                 form_values: params[:orchard_test_result],
                                                                 form_errors: res.errors)
            end
          end
        end

        r.delete do    # DELETE
          check_auth!('otmc', 'delete')
          interactor.assert_permission!(:delete, id)
          res = interactor.delete_orchard_test_result(id)
          if res.success
            delete_grid_row(id, notice: res.message)
          else
            show_json_error(res.message, status: 200)
          end
        end
      end
    end

    r.on 'orchard_test_results' do
      interactor = QualityApp::OrchardTestResultInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})
      @repo = QualityApp::OrchardTestRepo.new
      @farm_repo = MasterfilesApp::FarmRepo.new

      r.on 'phyt_clean_callback' do
        show_partial_or_page(r) { Quality::TestResults::OrchardTestResult::Callback.call(r.remaining_path) }
      end

      r.on 'diff', String do |mode|
        res = interactor.phyt_clean_diff(mode.to_sym)
        if res.success
          flash[:notice] = res.message
          store_locally(:phyto_res, res.instance)
          redirect_via_json "/quality/test_results/orchard_test_results/show_diff/#{mode}"
        else
          flash[:error] = res.message
          redirect_via_json '/list/orchard_test_results'
        end
      end

      r.on 'show_diff', String do |mode|
        show_page { Quality::TestResults::OrchardTestResult::DiffTool.call(mode.to_sym, retrieve_from_local_store(:phyto_res)) }
      end

      r.on 'phyt_clean_request' do
        res = interactor.phyt_clean_request
        flash[res.success ? :notice : :error] = res.message
        redirect_via_json '/list/orchard_test_results'
      end

      r.on 'bulk_edit_all' do
        if params[:changed_value] == 't'
          json_hide_element('orchard_test_result_group_ids_field_wrapper')
        else
          json_show_element('orchard_test_result_group_ids_field_wrapper')
        end
      end

      r.on 'multi_delete' do
        check_auth!('otmc', 'delete')
        res = nil
        multiselect_grid_choices(params).each do |id|
          interactor.assert_permission!(:delete, id)
          res = interactor.delete_orchard_test_result(id)
          unless res.success
            flash[:error] = res.message
            r.redirect request.referer
          end
        end
        flash[:notice] = res.message
        r.redirect request.referer
      end

      r.on 'create' do    # REFRESH
        check_auth!('otmc', 'new')
        res = interactor.create_orchard_test_results
        flash[res.success ? :notice : :error] = res.message
        r.redirect '/list/orchard_test_results'
      end

      r.on 'new' do    # NEW
        check_auth!('otmc', 'new')
        show_partial_or_page(r) { Quality::TestResults::OrchardTestResult::New.call(remote: fetch?(r)) }
      end
      r.post do        # CREATE
        res = interactor.create_orchard_test_result(params[:orchard_test_result])
        if res.success
          flash[:notice] = res.message
          r.redirect '/list/orchard_test_results'
        else
          re_show_form(r, res, url: '/quality/test_results/orchard_test_results/new') do
            Quality::TestResults::OrchardTestResult::New.call(form_values: params[:orchard_test_result],
                                                              form_errors: res.errors,
                                                              remote: fetch?(r))
          end
        end
      end
    end
  end
end
