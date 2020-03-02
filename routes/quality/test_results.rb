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

      r.on 'phyt_clean_request' do
        res = interactor.phyt_clean_request(id)
        if res.success
          flash[:notice] = res.message
        else
          flash[:error] = "#{res.message} #{res.errors}"
        end
        r.redirect '/list/orchard_test_results'
        res
      end

      r.on 'edit' do   # EDIT
        check_auth!('test results', 'edit')
        interactor.assert_permission!(:edit, id)
        show_partial_or_page(r) { Quality::TestResults::OrchardTestResult::Edit.call(id) }
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
            redirect_to_last_grid(r)
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
      @cultivar_repo = MasterfilesApp::CultivarRepo.new
      @farm_repo = MasterfilesApp::FarmRepo.new

      r.on 'puc_changed' do
        if params[:changed_value].nil_or_empty?
          blank_json_response
        else
          actions = []
          orchard_list = @repo.for_select_orchards(puc_id: params[:changed_value])
          actions << OpenStruct.new(type: :replace_select_options, dom_id: 'orchard_test_result_orchard_id', options_array: orchard_list)
          json_actions(actions)
        end
      end

      r.on 'orchard_changed' do
        if params[:changed_value].nil_or_empty?
          blank_json_response
        else
          actions = []
          orchard = @farm_repo.find_orchard(params[:changed_value])
          cultivar_list = @cultivar_repo.for_select_cultivars(where: { id: Array(orchard&.cultivar_ids) })
          actions << OpenStruct.new(type: :replace_select_options, dom_id: 'orchard_test_result_cultivar_id', options_array: cultivar_list)
          json_actions(actions)
        end
      end

      r.on 'cultivar_changed' do
        if params[:changed_value].nil_or_empty?
          blank_json_response
        else
          actions = []
          season = @cultivar_repo.find_cultivar_season(params[:changed_value])
          actions << OpenStruct.new(type: :replace_input_value, dom_id: 'orchard_test_result_applicable_from', value: season&.start_date)
          actions << OpenStruct.new(type: :replace_input_value, dom_id: 'orchard_test_result_applicable_to', value: season&.end_date)
          json_actions(actions)
        end
      end

      r.on 'new' do    # NEW
        check_auth!('test results', 'new')
        show_partial_or_page(r) { Quality::TestResults::OrchardTestResult::New.call(remote: fetch?(r)) }
      end
      r.post do        # CREATE
        res = interactor.create_orchard_test_result(params[:orchard_test_result])
        if res.success
          flash[:notice] = res.message
          r.redirect("/quality/test_results/orchard_test_results/#{res.instance.id}/edit")
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
