# frozen_string_literal: true

class Nspack < Roda
  route 'stock', 'finished_goods' do |r|
    # --------------------------------------------------------------------------
    # SET LOCAL PALLET TO IN STOCK
    # --------------------------------------------------------------------------
    r.on 'local_pallets_to_in_stock' do
      interactor = FinishedGoodsApp::PalletMovementsInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})
      res = interactor.local_pallets_to_in_stock
      flash[res.success ? :notice : :error] = res.message
      redirect_to_last_grid(r)
    end

    # --------------------------------------------------------------------------
    # SET EXPORT PALLET TO IN STOCK
    # --------------------------------------------------------------------------
    r.on 'export_pallets_to_in_stock' do
      interactor = FinishedGoodsApp::PalletMovementsInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})
      res = interactor.export_pallets_to_in_stock(multiselect_grid_choices(params))
      flash[res.success ? :notice : :error] = res.message
      redirect_via_json request.referer
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
        flash[res.success ? :notice : :error] = res.message
        redirect_via_json('/finished_goods/stock/allocate_target_customer/new')
      end
    end
  end
end
