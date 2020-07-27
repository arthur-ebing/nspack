# frozen_string_literal: true

class Nspack < Roda
  route 'dashboards', 'production' do |r|
    # PALLETIZING BAY STATES
    # --------------------------------------------------------------------------
    r.on 'palletizing_bays' do
      r.is do
        show_page { Production::Dashboards::Dashboard::PalletizingStates.call }
      end

      r.on 'detail' do
        content = render_partial { Production::Dashboards::Dashboard::PalletizingStatesDetail.call }
        { updateMessage: { content: content, continuePolling: true } }.to_json
      end
    end

    # PRODUCTION RUNS
    # --------------------------------------------------------------------------
    r.on 'production_runs' do
      r.is do
        show_page { Production::Dashboards::Dashboard::ProductionRuns.call }
      end

      r.on 'detail' do
        content = render_partial { Production::Dashboards::Dashboard::ProductionRunsDetail.call }
        { updateMessage: { content: content, continuePolling: true } }.to_json
      end
    end
  end
end
