# frozen_string_literal: true

class Nspack < Roda
  route 'in_progress', 'production' do |r|
    # PRODUCTION RUNS
    # --------------------------------------------------------------------------
    r.on 'product_setups' do
      interactor = ProductionApp::ProductionRunInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})
      r.on 'select' do
        r.get do
          check_auth!('in progress', 'edit')
          run_id = interactor.active_run_id_for_user(current_user)
          if run_id.nil?
            # select running runs that are labeling by showing their line numbers
            show_partial_or_page(r) { Production::Runs::ProductionRun::SelectLabelLine.call }
          else
            r.redirect "/list/product_setups_on_runs/with_params?key=standard&production_run_id=#{run_id}"
          end
        end

        r.post do
          run_id = params[:production_run][:production_run_id]
          r.redirect "/list/product_setups_on_runs/with_params?key=standard&production_run_id=#{run_id}"
        end
      end
    end
  end
end
