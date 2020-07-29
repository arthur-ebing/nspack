# frozen_string_literal: true

class Nspack < Roda
  route 'dashboards', 'production' do |r| # rubocop:disable Metrics/BlockLength
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

    # LOADS
    # --------------------------------------------------------------------------
    r.on 'load_weeks' do
      show_page { Production::Dashboards::Dashboard::LoadWeeks.call }
    end

    r.on 'load_days' do
      show_page { Production::Dashboards::Dashboard::LoadDays.call }
    end

    # IN STOCK
    # --------------------------------------------------------------------------
    r.on 'in_stock' do
      show_page { Production::Dashboards::Dashboard::PalletsInStock.call }
    end

    # DELIVERIES
    # --------------------------------------------------------------------------
    r.on 'delivery_weeks' do
      show_page { Production::Dashboards::Dashboard::DeliveryWeeks.call }
    end

    r.on 'delivery_days' do
      show_page { Production::Dashboards::Dashboard::DeliveryDays.call }
    end
  end
end
