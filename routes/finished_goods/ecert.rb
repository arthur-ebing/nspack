# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
class Nspack < Roda
  route 'ecert', 'finished_goods' do |r|
    # ECERT AGREEMENTS
    # --------------------------------------------------------------------------
    r.on 'ecert_agreements', Integer do |id|
      interactor = FinishedGoodsApp::EcertAgreementInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      # Check for notfound:
      r.on !interactor.exists?(:ecert_agreements, id) do
        handle_not_found(r)
      end

      r.is do
        r.get do       # SHOW
          check_auth!('ecert', 'read')
          show_partial { FinishedGoods::Ecert::EcertAgreement::Show.call(id) }
        end
        r.delete do    # DELETE
          check_auth!('ecert', 'delete')
          interactor.assert_permission!(:delete, id)
          res = interactor.delete_ecert_agreement(id)
          if res.success
            delete_grid_row(id, notice: res.message)
          else
            show_json_error(res.message, status: 200)
          end
        end
      end
    end

    r.on 'ecert_agreements' do
      interactor = FinishedGoodsApp::EcertAgreementInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      r.on 'update_agreements' do
        res = interactor.update_agreements
        if res.success
          flash[:notice] = res.message
        else
          flash[:error] = "#{res.message} #{res.errors}"
        end
        r.redirect '/list/ecert_agreements'
      end
    end

    # ECERT TRACKING UNITS
    # --------------------------------------------------------------------------
    r.on 'ecert_tracking_units', Integer do |id|
      interactor = FinishedGoodsApp::EcertTrackingUnitInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      # Check for notfound:
      r.on !interactor.exists?(:ecert_tracking_units, id) do
        handle_not_found(r)
      end

      r.is do
        r.delete do    # DELETE
          check_auth!('ecert', 'delete')
          interactor.assert_permission!(:delete, id)
          res = interactor.delete_ecert_tracking_unit(id)
          if res.success
            delete_grid_row(id, notice: res.message)
          else
            show_json_error(res.message, status: 200)
          end
        end
      end
    end

    r.on 'ecert_tracking_units' do
      interactor = FinishedGoodsApp::EcertTrackingUnitInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      r.on 'status' do
        r.get do
          show_partial_or_page(r) { FinishedGoods::Ecert::EcertTrackingUnit::Status.call(remote: fetch?(r)) }
        end
        r.post do # FIND
          res = interactor.ecert_tracking_unit_status(params[:ecert_tracking_unit_status][:pallet_number])
          if res.success
            form_values = params[:ecert_tracking_unit_status]
            show_partial_or_page(r) { FinishedGoods::Ecert::EcertTrackingUnit::Status.call(res: res.instance.first, form_values: form_values, remote: fetch?(r)) }
          else
            re_show_form(r, res, url: '/finished_goods/ecert/ecert_tracking_units/status') do
              FinishedGoods::Ecert::EcertTrackingUnit::Status.call(form_values: params[:ecert_tracking_unit],
                                                                   form_errors: res.errors,
                                                                   remote: fetch?(r))
            end
          end
        end
      end

      r.on 'new' do    # NEW
        check_auth!('ecert', 'new')
        show_partial_or_page(r) { FinishedGoods::Ecert::EcertTrackingUnit::New.call(remote: fetch?(r)) }
      end
      r.post do        # CREATE
        res = interactor.elot_preverify(params[:ecert_tracking_unit])
        if res.success
          flash[:notice] = res.message
        else
          flash[:error] = res.message
          re_show_form(r, res, url: '/finished_goods/ecert/ecert_tracking_units/new') do
            FinishedGoods::Ecert::EcertTrackingUnit::New.call(form_values: params[:ecert_tracking_unit],
                                                              form_errors: res.errors,
                                                              remote: fetch?(r))
          end
        end
        redirect_to_last_grid(r)
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
