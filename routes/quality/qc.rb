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

      # r.on 'complete' do
      #   r.get do
      #     check_auth!('qc', 'edit')
      #     interactor.assert_permission!(:complete, id)
      #     show_partial { Quality::Qc::QcSample::Complete.call(id) }
      #   end

      #   r.post do
      #     res = interactor.complete_a_qc_sample(id, params[:qc_sample])
      #     if res.success
      #       flash[:notice] = res.message
      #       redirect_to_last_grid(r)
      #     else
      #       re_show_form(r, res) { Quality::Qc::QcSample::Complete.call(id, params[:qc_sample], res.errors) }
      #     end
      #   end
      # end

      # r.on 'reopen' do
      #   r.get do
      #     check_auth!('qc', 'edit')
      #     interactor.assert_permission!(:reopen, id)
      #     show_partial { Quality::Qc::QcSample::Reopen.call(id) }
      #   end

      #   r.post do
      #     res = interactor.reopen_a_qc_sample(id, params[:qc_sample])
      #     if res.success
      #       flash[:notice] = res.message
      #       redirect_to_last_grid(r)
      #     else
      #       re_show_form(r, res) { Quality::Qc::QcSample::Reopen.call(id, params[:qc_sample], res.errors) }
      #     end
      #   end
      # end

      r.is do
        r.get do       # SHOW
          check_auth!('qc', 'read')
          show_partial { Quality::Qc::QcSample::Show.call(id) }
        end
        r.patch do     # UPDATE
          res = interactor.update_qc_sample(id, params[:qc_sample])
          if res.success
            row_keys = %i[
              qc_sample_type_id
              rmt_delivery_id
              coldroom_location_id
              production_run_id
              orchard_id
              presort_run_lot_number
              ref_number
              short_description
              sample_size
              editing
              completed
              completed_at
              rmt_bin_ids
            ]
            update_grid_row(id, changes: select_attributes(res.instance, row_keys), notice: res.message)
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
      # r.on 'ui_change', String do |change_type| # Handle UI behaviours
      #   handle_ui_change(:qc_sample, change_type.to_sym, params)
      # end
      r.on 'select', String do |test_type|
        r.get do
          check_auth!('qc', 'new')
          set_last_grid_url('/list/qc_samples', r)
          show_partial_or_page(r) { Quality::Qc::QcSample::Select.call(test_type: test_type, remote: fetch?(r)) }
        end

        r.post do
          res = interactor.find_test_for_sample(params[:qc_sample][:id], test_type)
          # Check param etc
          # see if test exists for sample & redirect there, else create before redirect...
          # show_partial_or_page(r) { Quality::Qc::QcSample::SelectTest.call(params[:qc_sample][:id], remote: fetch?(r)) }
          # res = interactor.create_test_for_sample(id, params[:qc_sample])
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

      r.on 'new_delivery_sample', Integer do |rmt_delivery_id|
        check_auth!('qc', 'new')
        set_last_grid_url('/list/qc_samples', r)
        show_partial_or_page(r) { Quality::Qc::QcSample::New.call(context: :rmt_delivery_id, id: rmt_delivery_id, remote: fetch?(r)) }
      end

      # r.on 'new' do    # NEW
      #   check_auth!('qc', 'new')
      #   set_last_grid_url('/list/qc_samples', r)
      #   show_partial_or_page(r) { Quality::Qc::QcSample::New.call(remote: fetch?(r)) }
      # end
      r.post do        # CREATE
        res = interactor.create_qc_sample(params[:qc_sample])
        if res.success
          # if fetch?(r)
          #   row_keys = %i[
          #     id
          #     qc_sample_type_id
          #     rmt_delivery_id
          #     coldroom_location_id
          #     production_run_id
          #     orchard_id
          #     presort_run_lot_number
          #     ref_number
          #     short_description
          #     sample_size
          #     editing
          #     completed
          #     completed_at
          #     rmt_bin_ids
          #   ]
          #   add_grid_row(attrs: select_attributes(res.instance, row_keys),
          #                notice: res.message)
          # else
          flash[:notice] = res.message
          redirect_to_last_grid(r)
          # end
        else
          context = params[:qc_sample][:context]
          context_key = params[:qc_sample][:context_key]
          re_show_form(r, res, url: "/quality/qc/qc_samples/new_#{context}_sample") do
            Quality::Qc::QcSample::New.call(context: context,
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

      # Check for notfound:
      r.on !interactor.exists?(:qc_tests, id) do
        handle_not_found(r)
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
            redirect_to_last_grid(r)
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
