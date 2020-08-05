# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
class Nspack < Roda # rubocop:disable Metrics/ClassLength
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
        if res.success
          flash[:notice] = res.message
        else
          flash[:error] = "#{res.message} #{res.errors}"
        end
        r.redirect '/list/orchard_test_results'
      end

      r.on 'edit' do   # EDIT
        check_auth!('test results', 'edit')
        interactor.assert_permission!(:edit, id)
        show_partial_or_page(r) { Quality::TestResults::OrchardTestResult::Edit.call(id) }
      end

      r.on 'bulk_edit' do
        r.get do       # EDIT
          check_auth!('test results', 'edit')
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
          check_auth!('test results', 'read')
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
          check_auth!('test results', 'delete')
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

      r.on 'pallet_diff' do
        show_partial_or_page(r) { Quality::TestResults::OrchardTestResult::DiffTool.call(:pallet_sequences) }
      end

      r.on 'orchard_diff' do
        show_partial_or_page(r) { Quality::TestResults::OrchardTestResult::DiffTool.call(:orchards) }
      end

      r.on 'phyt_clean_request' do
        res = interactor.phyt_clean_request
        if res.success
          flash[:notice] = res.message
        else
          flash[:error] = "#{res.message} #{res.errors}"
        end
        r.redirect '/list/orchard_test_results'
      end

      r.on 'bulk_edit_all' do
        if params[:changed_value] == 't'
          json_hide_element('orchard_test_result_group_ids_field_wrapper')
        else
          json_show_element('orchard_test_result_group_ids_field_wrapper')
        end
      end

      r.on 'multi_delete' do
        check_auth!('test results', 'delete')
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
        check_auth!('test results', 'new')
        res = interactor.create_orchard_test_results
        if res.success
          flash[:notice] = res.message
        else
          flash[:error] = "#{res.message} #{res.errors}"
        end
        r.redirect '/list/orchard_test_results'
      end

      r.on 'new' do    # NEW
        check_auth!('test results', 'new')
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
# rubocop:enable Metrics/BlockLength
