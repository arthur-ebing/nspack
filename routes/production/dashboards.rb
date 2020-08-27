# frozen_string_literal: true

class Nspack < Roda
  route 'dashboards', 'production' do |r| # rubocop:disable Metrics/BlockLength
    layout_to_use = if params[:fullpage] && params[:fullpage].downcase == 'y'
                      'layout_dash_content'
                    else
                      'layout'
                    end

    # PALLETIZING BAY STATES
    # --------------------------------------------------------------------------
    r.on 'palletizing_bays' do
      r.is do
        show_page_in_layout(layout_to_use) { Production::Dashboards::Dashboard::PalletizingStates.call }
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
        show_page_in_layout(layout_to_use) { Production::Dashboards::Dashboard::ProductionRuns.call(params) }
      end

      r.on 'detail' do
        content = render_partial { Production::Dashboards::Dashboard::ProductionRunsDetail.call(params) }
        { updateMessage: { content: content, continuePolling: true } }.to_json
      end
    end

    # LOADS
    # --------------------------------------------------------------------------
    r.on 'load_weeks' do
      show_page_in_layout(layout_to_use) { Production::Dashboards::Dashboard::LoadWeeks.call }
    end

    r.on 'load_days' do
      show_page_in_layout(layout_to_use) { Production::Dashboards::Dashboard::LoadDays.call }
    end

    # IN STOCK
    # --------------------------------------------------------------------------
    r.on 'in_stock' do
      show_page_in_layout(layout_to_use) { Production::Dashboards::Dashboard::PalletsInStock.call }
    end

    # DELIVERIES
    # --------------------------------------------------------------------------
    r.on 'delivery_weeks' do
      show_page_in_layout(layout_to_use) { Production::Dashboards::Dashboard::DeliveryWeeks.call }
    end

    r.on 'delivery_days' do
      show_page_in_layout(layout_to_use) { Production::Dashboards::Dashboard::DeliveryDays.call }
    end

    # CARTON-PALLET SUMMARY
    # --------------------------------------------------------------------------
    r.on 'carton_pallet_summary_weeks' do
      show_page_in_layout(layout_to_use) { Production::Dashboards::Dashboard::CartonPalletSummaryWeeks.call }
    end

    r.on 'carton_pallet_summary_days' do
      show_page_in_layout(layout_to_use) { Production::Dashboards::Dashboard::CartonPalletSummaryDays.call }
    end

    # DEVICE ALLOCATIONS
    # --------------------------------------------------------------------------
    r.on 'device_allocation', String do |device|
      r.is do
        show_page_in_layout(layout_to_use) { Production::Dashboards::Dashboard::DeviceAllocation.call(device) }
      end

      r.on 'detail' do
        content = render_partial { Production::Dashboards::Dashboard::DeviceAllocationDetail.call(device) }
        { updateMessage: { content: content, continuePolling: true } }.to_json
      end
    end
  end
end
