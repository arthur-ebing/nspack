# frozen_string_literal: true

class Nspack < Roda
  route 'dashboards', 'production' do |r|
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

    # ROBOT STATES
    # --------------------------------------------------------------------------
    r.on 'robot_states' do
      show_page_in_layout(layout_to_use) { Production::Dashboards::Dashboard::RobotStates.call }
    end
    r.on 'run_robot_state_checks' do
      ProductionApp::Job::PingRobots.enqueue(current_user.user_name)
      { updateMessage: { content: '', continuePolling: false } }.to_json
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
    r.on 'in_stock_per_size' do
      show_page_in_layout(layout_to_use) { Production::Dashboards::Dashboard::PalletsInStockSize.call }
    end

    # DELIVERIES
    # --------------------------------------------------------------------------
    r.on 'delivery_weeks' do
      show_page_in_layout(layout_to_use) { Production::Dashboards::Dashboard::DeliveryWeeks.call }
    end

    r.on 'delivery_days' do
      show_page_in_layout(layout_to_use) { Production::Dashboards::Dashboard::DeliveryDays.call }
    end

    # BIN STATE
    # --------------------------------------------------------------------------
    r.on 'bin_state' do
      show_page_in_layout(layout_to_use) { Production::Dashboards::Dashboard::BinState.call }
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

    # GOSSAMER DATA
    # --------------------------------------------------------------------------
    r.on 'gossamer_data' do
      r.is do
        show_page_in_layout(layout_to_use) { Production::Dashboards::Dashboard::GossamerData.call }
      end

      r.on 'detail' do
        content = render_partial { Production::Dashboards::Dashboard::GossamerDataDetail.call }
        { updateMessage: { content: content, continuePolling: true } }.to_json
        # { updateMessage: { content: content, continuePolling: false } }.to_json
      end
    end
  end
end
