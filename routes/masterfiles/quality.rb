# frozen_string_literal: true

class Nspack < Roda # rubocop:disable ClassLength
  route 'quality', 'masterfiles' do |r| # rubocop:disable Metrics/BlockLength
    # PALLET VERIFICATION FAILURE REASONS
    # --------------------------------------------------------------------------
    r.on 'pallet_verification_failure_reasons', Integer do |id| # rubocop:disable Metrics/BlockLength
      interactor = MasterfilesApp::PalletVerificationFailureReasonInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      # Check for notfound:
      r.on !interactor.exists?(:pallet_verification_failure_reasons, id) do
        handle_not_found(r)
      end

      r.on 'edit' do   # EDIT
        check_auth!('quality', 'edit')
        interactor.assert_permission!(:edit, id)
        show_partial { Masterfiles::Quality::PalletVerificationFailureReason::Edit.call(id) }
      end

      r.is do
        r.get do       # SHOW
          check_auth!('quality', 'read')
          show_partial { Masterfiles::Quality::PalletVerificationFailureReason::Show.call(id) }
        end
        r.patch do     # UPDATE
          res = interactor.update_pallet_verification_failure_reason(id, params[:pallet_verification_failure_reason])
          if res.success
            update_grid_row(id, changes: { reason: res.instance[:reason] },
                                notice: res.message)
          else
            re_show_form(r, res) { Masterfiles::Quality::PalletVerificationFailureReason::Edit.call(id, form_values: params[:pallet_verification_failure_reason], form_errors: res.errors) }
          end
        end
        r.delete do    # DELETE
          check_auth!('quality', 'delete')
          interactor.assert_permission!(:delete, id)
          res = interactor.delete_pallet_verification_failure_reason(id)
          if res.success
            delete_grid_row(id, notice: res.message)
          else
            show_json_error(res.message, status: 200)
          end
        end
      end
    end

    r.on 'pallet_verification_failure_reasons' do
      interactor = MasterfilesApp::PalletVerificationFailureReasonInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})
      r.on 'new' do    # NEW
        check_auth!('quality', 'new')
        show_partial_or_page(r) { Masterfiles::Quality::PalletVerificationFailureReason::New.call(remote: fetch?(r)) }
      end
      r.post do        # CREATE
        res = interactor.create_pallet_verification_failure_reason(params[:pallet_verification_failure_reason])
        if res.success
          row_keys = %i[
            id
            reason
            active
          ]
          add_grid_row(attrs: select_attributes(res.instance, row_keys),
                       notice: res.message)
        else
          re_show_form(r, res, url: '/masterfiles/quality/pallet_verification_failure_reasons/new') do
            Masterfiles::Quality::PalletVerificationFailureReason::New.call(form_values: params[:pallet_verification_failure_reason],
                                                                            form_errors: res.errors,
                                                                            remote: fetch?(r))
          end
        end
      end
    end

    # SCRAP REASONS
    # --------------------------------------------------------------------------
    r.on 'scrap_reasons', Integer do |id| # rubocop:disable Metrics/BlockLength
      interactor = MasterfilesApp::ScrapReasonInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      # Check for notfound:
      r.on !interactor.exists?(:scrap_reasons, id) do
        handle_not_found(r)
      end

      r.on 'edit' do   # EDIT
        check_auth!('quality', 'edit')
        interactor.assert_permission!(:edit, id)
        show_partial { Masterfiles::Quality::ScrapReason::Edit.call(id) }
      end

      r.is do
        r.get do       # SHOW
          check_auth!('quality', 'read')
          show_partial { Masterfiles::Quality::ScrapReason::Show.call(id) }
        end
        r.patch do     # UPDATE
          res = interactor.update_scrap_reason(id, params[:scrap_reason])
          if res.success
            update_grid_row(id, changes: { scrap_reason: res.instance[:scrap_reason], description: res.instance[:description], applies_to_pallets: res.instance[:applies_to_pallets] },
                                notice: res.message)
          else
            re_show_form(r, res) { Masterfiles::Quality::ScrapReason::Edit.call(id, form_values: params[:scrap_reason], form_errors: res.errors) }
          end
        end
        r.delete do    # DELETE
          check_auth!('quality', 'delete')
          interactor.assert_permission!(:delete, id)
          res = interactor.delete_scrap_reason(id)
          if res.success
            delete_grid_row(id, notice: res.message)
          else
            show_json_error(res.message, status: 200)
          end
        end
      end
    end

    r.on 'scrap_reasons' do
      interactor = MasterfilesApp::ScrapReasonInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})
      r.on 'new' do    # NEW
        check_auth!('quality', 'new')
        show_partial_or_page(r) { Masterfiles::Quality::ScrapReason::New.call(remote: fetch?(r)) }
      end
      r.post do        # CREATE
        res = interactor.create_scrap_reason(params[:scrap_reason])
        if res.success
          row_keys = %i[
            id
            scrap_reason
            description
            active
            applies_to_pallets
          ]
          add_grid_row(attrs: select_attributes(res.instance, row_keys),
                       notice: res.message)
        else
          re_show_form(r, res, url: '/masterfiles/quality/scrap_reasons/new') do
            Masterfiles::Quality::ScrapReason::New.call(form_values: params[:scrap_reason],
                                                        form_errors: res.errors,
                                                        remote: fetch?(r))
          end
        end
      end
    end
  end
end
