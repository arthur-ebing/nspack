# frozen_string_literal: true

class Nspack < Roda
  route 'stock', 'finished_goods' do |r| # rubocop:disable Metrics/BlockLength
    # --------------------------------------------------------------------------
    # SET LOCAL PALLET
    # --------------------------------------------------------------------------
    r.on 'set_local_pallet' do
      interactor = FinishedGoodsApp::PalletMovementsInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})
      res = interactor.set_local_pallet
      flash[res.success ? :notice : :error] = res.message
      redirect_to_last_grid(r)
    end

    # ALLOCATE TARGET CUSTOMER
    # --------------------------------------------------------------------------
    r.on 'allocate_target_customer' do
      interactor = FinishedGoodsApp::PalletMovementsInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})
      r.on 'new' do
        r.get do
          check_auth!('stock', 'new')
          show_partial_or_page(r) { FinishedGoods::Stock::TargetCustomer::AllocateTargetCustomer.call }
        end

        r.post do
          target_customer_id = params[:target_customer][:target_customer_party_role_id]
          store_locally(:target_customer_id, target_customer_id)
          r.redirect "/list/stock_pallets/multi?key=target_customer_pallets&id=#{target_customer_id}"
        end
      end

      r.on 'multiselect_target_customer_pallets' do
        res = interactor.set_pallets_target_customer(retrieve_from_local_store(:target_customer_id), multiselect_grid_choices(params))

        if res.success
          flash[:notice] = res.message
        else
          flash[:error] = res.message
        end
        redirect_via_json('/finished_goods/stock/allocate_target_customer/new')
      end
    end
  end
end
