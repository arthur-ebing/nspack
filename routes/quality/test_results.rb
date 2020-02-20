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

      r.on 'edit' do   # EDIT
        check_auth!('test results', 'edit')
        interactor.assert_permission!(:edit, id)
        show_partial { Quality::TestResults::OrchardTestResult::Edit.call(id) }
      end

      r.is do
        r.get do       # SHOW
          check_auth!('test results', 'read')
          show_partial { Quality::TestResults::OrchardTestResult::Show.call(id) }
        end
        r.patch do     # UPDATE
          res = interactor.update_orchard_test_result(id, params[:orchard_test_result])
          if res.success
            row_keys = %i[
              orchard_test_type_id
              orchard_set_result_id
              orchard_id
              puc_id
              description
              status_description
              passed
              classification_only
              freeze_result
              api_result
              classifications
              cultivar_ids
              applicable_from
              applicable_to
            ]
            update_grid_row(id, changes: select_attributes(res.instance, row_keys), notice: res.message)
          else
            re_show_form(r, res) { Quality::TestResults::OrchardTestResult::Edit.call(id, form_values: params[:orchard_test_result], form_errors: res.errors) }
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
      r.on 'new' do    # NEW
        check_auth!('test results', 'new')
        show_partial_or_page(r) { Quality::TestResults::OrchardTestResult::New.call(remote: fetch?(r)) }
      end
      r.post do        # CREATE
        res = interactor.create_orchard_test_result(params[:orchard_test_result])
        if res.success
          row_keys = %i[
            id
            orchard_test_type_id
            orchard_set_result_id
            orchard_id
            puc_id
            description
            status_description
            passed
            classification_only
            freeze_result
            api_result
            classifications
            cultivar_ids
            applicable_from
            applicable_to
            active
          ]
          add_grid_row(attrs: select_attributes(res.instance, row_keys),
                       notice: res.message)
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
