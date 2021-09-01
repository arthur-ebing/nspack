# frozen_string_literal: true

class Nspack < Roda
  route 'bin_integration', 'raw_materials' do |r|
    # BIN INTEGRATION QUEUE
    # --------------------------------------------------------------------------
    r.on 'bin_integration_queue' do
      interactor = RawMaterialsApp::BinIntegrationQueueInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      r.on 'reprocess' do
        res = interactor.reprocess_queue(multiselect_grid_choices(params))
        flash[res.success ? :notice : :error] = res.message
        r.redirect('/list/bin_integration_queue/multi?key=standard')
      end
    end
  end
end
