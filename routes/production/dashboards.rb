# frozen_string_literal: true

class Nspack < Roda
  route 'dashboards', 'production' do |r|
    # PALLETIZING BAY STATES
    # --------------------------------------------------------------------------
    r.on 'palletizing_bays' do
      show_page { Production::Dashboards::Dashboard::PalletizingStates.call }
    end

    # PRODUCTION RUNS
    # --------------------------------------------------------------------------
    r.on 'production_runs' do
      show_page { Production::Dashboards::Dashboard::ProductionRuns.call }
    end
  end
end
