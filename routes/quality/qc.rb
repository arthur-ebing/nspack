# frozen_string_literal: true

class Nspack < Roda
  route 'qc', 'quality' do |r|
    # QC SAMPLES
    # --------------------------------------------------------------------------
    r.on 'qc_samples', Integer do |id|
      interactor = QualityApp::QcSampleInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      # Check for notfound:
      r.on !interactor.exists?(:qc_samples, id) do
        handle_not_found(r)
      end

      r.on 'print_barcode' do
        r.get do
          show_partial_or_page(r) { Quality::Qc::QcSample::PrintBarcode.call(id) }
        end
        r.patch do
          res = interactor.print_sample_barcode(id, params[:qc_sample])
          if res.success
            show_json_notice(res.message)
          else
            re_show_form(r, res) { Quality::Qc::QcSample::PrintBarcode.call(id, form_values: params[:qc_sample], form_errors: res.errors) }
          end
        end
      end

      r.on 'select_test' do
        res = interactor.create_test_for_sample(id, params[:qc_sample])
        if res.success
          flash[:notice] = res.message
          r.redirect "/quality/qc/qc_tests/#{res.instance[:test_id]}/#{res.instance[:test_type]}"
        else
          # TODO: FIXTHIS...
          flash[:error] = res.message
          redirect_to_last_grid(r)
        end
        # create test and redirect to edit.
      end

      r.on 'qc_test', String do |qc_test_type|
        # Create if not exists and redirect to edit.
        test_interactor = QualityApp::QcTestInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})
        qc_test_id = test_interactor.find_or_create_test(id, qc_test_type)
        r.redirect "/quality/qc/qc_tests/#{qc_test_id}/#{qc_test_type}"
      end

      r.on 'edit' do   # EDIT
        check_auth!('qc', 'edit')
        interactor.assert_permission!(:edit, id)
        show_partial { Quality::Qc::QcSample::Edit.call(id) }
      end

      r.on 'manage' do
        show_page { Quality::Qc::QcSample::Manage.call(id) }
      end

      r.is do
        r.get do       # SHOW
          check_auth!('qc', 'read')
          show_partial { Quality::Qc::QcSample::Show.call(id) }
        end
        r.patch do     # UPDATE
          res = interactor.update_qc_sample(id, params[:qc_sample])
          if res.success
            if request.referer.end_with?('manage')
              redirect_via_json(request.referer)
            else
              show_json_notice(res.message)
            end
          else
            re_show_form(r, res) { Quality::Qc::QcSample::Edit.call(id, form_values: params[:qc_sample], form_errors: res.errors) }
          end
        end
        r.delete do    # DELETE
          check_auth!('qc', 'delete')
          interactor.assert_permission!(:delete, id)
          res = interactor.delete_qc_sample(id)
          if res.success
            delete_grid_row(id, notice: res.message)
          else
            show_json_error(res.message, status: 200)
          end
        end
      end
    end

    r.on 'qc_samples' do
      interactor = QualityApp::QcSampleInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})
      r.on 'select', String do |test_type|
        r.get do
          check_auth!('qc', 'new')
          set_last_grid_url('/list/qc_samples', r)
          show_partial_or_page(r) { Quality::Qc::QcSample::Select.call(test_type: test_type, remote: fetch?(r)) }
        end

        r.post do
          res = interactor.find_test_for_sample(params[:qc_sample][:id], test_type)
          if res.success
            r.redirect "/quality/qc/qc_tests/#{res.instance[:test_id]}/#{res.instance[:test_type]}"
          else
            re_show_form(r, res, url: '/quality/qc/qc_samples/new') do
              Quality::Qc::QcSample::Select.call(test_type: test_type,
                                                 form_values: params[:qc_sample],
                                                 form_errors: res.errors,
                                                 remote: fetch?(r))
            end
          end
        end
      end

      r.on 'select' do
        r.get do
          check_auth!('qc', 'new')
          set_last_grid_url('/list/qc_samples', r)
          show_partial_or_page(r) { Quality::Qc::QcSample::Select.call(remote: fetch?(r)) }
        end

        r.post do
          show_partial_or_page(r) { Quality::Qc::QcSample::SelectTest.call(params[:qc_sample][:id], remote: fetch?(r)) }
        end
      end

      r.on 'new_rmt_delivery_id_sample', Integer, Integer do |qc_sample_type_id, rmt_delivery_id|
        check_auth!('qc', 'new')
        set_last_grid_url('/list/qc_samples', r)
        show_partial_or_page(r) { Quality::Qc::QcSample::New.call(qc_sample_type_id, context: :rmt_delivery_id, id: rmt_delivery_id, remote: fetch?(r)) }
      end

      r.on 'production_run_sample', Integer, String do |production_run_id, sample_type|
        check_auth!('qc', 'new')
        res = interactor.find_qc_sample_or_type(:production_run_id, production_run_id, sample_type: sample_type)
        if res.success
          redirect_via_json("/quality/qc/qc_samples/#{res.instance}/manage")
        else
          show_partial_or_page(r) { Quality::Qc::QcSample::New.call(res.instance, context: :production_run_id, id: production_run_id, remote: fetch?(r)) }
        end
      end

      r.post do        # CREATE
        res = interactor.create_qc_sample(params[:qc_sample])
        if res.success
          flash[:notice] = res.message
          if fetch?(r)
            redirect_via_json(res.instance)
          else
            r.redirect res.instance
          end
        else
          sample_type = params[:qc_sample][:qc_sample_type_id]
          context = params[:qc_sample][:context]
          context_key = params[:qc_sample][:context_key]
          re_show_form(r, res, url: "/quality/qc/qc_samples/new_#{context}_sample/#{sample_type}/#{context_key}") do
            Quality::Qc::QcSample::New.call(sample_type,
                                            context: context,
                                            id: context_key,
                                            form_values: params[:qc_sample],
                                            form_errors: res.errors,
                                            remote: fetch?(r))
          end
        end
      end
    end

    # QC TESTS
    # --------------------------------------------------------------------------
    r.on 'qc_tests', Integer do |id|
      interactor = QualityApp::QcTestInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})
      sample_interactor = QualityApp::QcSampleInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      # Check for notfound:
      r.on !interactor.exists?(:qc_tests, id) do
        handle_not_found(r)
      end

      r.on 'defects' do
        r.get do
          redirect_url = sample_interactor.redirect_url_for_test(id)
          show_partial_or_page(r) { Quality::Qc::QcTest::Defects.call(id, redirect_url: redirect_url) }
        end

        r.patch do
          res = interactor.update_qc_test_sample_size(id, params[:qc_test])
          if res.success
            show_json_notice(res.message)
          else
            show_json_warning(res.message)
          end
        end
      end

      r.on 'defects_grid' do
        interactor.defects_grid(id)
      rescue StandardError => e
        show_json_exception(e)
      end

      r.on 'inline_defect', Integer do |fruit_defect_id|
        res = interactor.save_defect_measure(id, fruit_defect_id, params)
        if res.success
          blank_json_response
        else
          undo_grid_inline_edit(message: unwrap_failed_response(res))
        end
      end

      r.on 'starch' do
        r.get do
          check_auth!('qc', 'edit')
          interactor.assert_permission!(:edit, id)
          show_partial_or_page(r) { Quality::Qc::QcTest::Starch.call(id, remote: fetch?(r)) }
        end

        r.patch do
          res = interactor.save_starch_test(id, params[:qc_test])
          if res.success
            show_json_notice(res.message)
          else
            re_show_form(r, res, url: "/quality/qc/qc_tests/#{id}/starch") do
              Quality::Qc::QcTest::Starch.call(id, form_values: params[:qc_test],
                                                   form_errors: res.errors,
                                                   remote: fetch?(r))
            end
          end
        end
      end
    end
  end
end
