# frozen_string_literal: true

class Nspack < Roda
  route 'stock', 'finished_goods' do |r|
    # --------------------------------------------------------------------------
    # SET LOCAL PALLET
    # --------------------------------------------------------------------------
    r.on 'set_local_pallet' do
      interactor = FinishedGoodsApp::PalletMovementsInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})
      res = interactor.set_local_pallet
      flash[res.success ? :notice : :error] = res.message
      redirect_to_last_grid(r)
    end
  end
end
