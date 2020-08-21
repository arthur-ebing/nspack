# frozen_string_literal: true

module Production
  module Dashboards
    module Dashboard
      class CartonPalletSummaryDays
        def self.call
          layout = Crossbeams::Layout::Page.build({}) do |page|
            page.add_text 'Carton/Pallet Summary per day', wrapper: :h2
            page.add_text draw_boxes
          end

          layout
        end

        def self.draw_boxes # rubocop:disable Metrics/AbcSize
          last_day_for_summary = ProductionApp::DashboardRepo.new.last_day_for_summary
          ctn_recs = ProductionApp::DashboardRepo.new.carton_summary
          plt_recs = ProductionApp::DashboardRepo.new.pallet_summary
          recs = calculate_summary(last_day_for_summary, ctn_recs, plt_recs)
          return 'There are no cartons or pallets' if recs.empty?

          ar = []
          ar << <<~HTML
            <div class="flex flex-column mv2 bg-mid-gray pt1 pl2 pb2 outline">
              <div class="flex flex-wrap near-white">
                <div class="pa2 mr2 mt2 fw8"> #{last_day_for_summary.strftime('%A, %d %b %Y')}</div>
              </div>

              <div class="flex flex-wrap">
                #{recs.join("\n")}
              </div>
            </div>
          HTML

          prev_recs = calculate_summary(last_day_for_summary - 1, ctn_recs, plt_recs)
          unless prev_recs.empty?
            ar << <<~HTML
              <div class="flex flex-column mv3 bg-mid-gray pt1 pl2 pb2 outline">
                <div class="flex flex-wrap near-white">
                  <div class="pa2 mr2 mt2 fw8"> #{(last_day_for_summary - 1).strftime('%A, %d %b %Y')}</div>
                </div>

                <div class="flex flex-wrap">
                  #{prev_recs.join("\n")}
                </div>
              </div>
            HTML
          end
          ar.join
        end

        def self.calculate_summary(last_day_for_summary, ctn, plt) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity
          # Do for last 2 days
          ctn_recs = ctn.select { |r| r[:date] == last_day_for_summary } # Date.today } # 2020-07-20
          plt_recs = plt.select { |r| r[:date] == last_day_for_summary } # Date.today }
          key_set = Set.new
          ctn_recs.each { |c| key_set << { ph: c[:packhouse_code], cv: c[:cultivar_code], pack: c[:standard_pack_code] } }
          plt_recs.each { |p| key_set << { ph: p[:packhouse_code], cv: p[:cultivar_code], pack: p[:standard_pack_code] } }
          ar = []
          key_set.each do |key|
            hs = { ph: key[:ph], cv: key[:cv], pack: key[:pack], ctn_tot: 0, ctn_tot_scrap: 0, ctn_qty: 0, plt_qty: 0, ship_c_qty: 0, ship_p_qty: 0,
                   alloc_c_qty: 0, alloc_p_qty: 0, ver_c_qty: 0, ver_p_qty: 0, unver_c_qty: 0, unver_p_qty: 0, load_s_qty: 0, load_a_qty: 0 }
            ctn_recs.select { |r| r[:packhouse_code] == key[:ph] && r[:cultivar_code] == key[:cv] && r[:standard_pack_code] == key[:pack] }.each do |rec|
              hs[:ctn_tot] += rec[:total_verified_carton_qty] unless rec[:scrapped]
              hs[:ctn_tot_scrap] += rec[:total_verified_carton_qty] if rec[:scrapped]
            end
            plt_recs.select { |r| r[:packhouse_code] == key[:ph] && r[:cultivar_code] == key[:cv] && r[:standard_pack_code] == key[:pack] }.each do |rec|
              hs[:ctn_qty] += rec[:total_carton_qty]
              hs[:plt_qty] += rec[:total_pallet_qty]
              hs[:ship_c_qty] += rec[:shipped_carton_qty]
              hs[:ship_p_qty] += rec[:shipped_pallet_qty]
              hs[:alloc_c_qty] += rec[:allocated_carton_qty]
              hs[:alloc_p_qty] += rec[:allocated_pallet_qty]
              hs[:ver_c_qty] += rec[:verified_carton_qty]
              hs[:ver_p_qty] += rec[:verified_pallet_qty]
              hs[:unver_c_qty] += rec[:unverified_carton_qty]
              hs[:unver_p_qty] += rec[:unverified_pallet_qty]
              hs[:load_s_qty] += rec[:shipped_load_qty]
              hs[:load_a_qty] += rec[:allocated_load_qty]
            end
            ar << hs
          end
          ar.map { |a| summary_block(a) }
        end

        def self.summary_block(item) # rubocop:disable Metrics/AbcSize
          <<~HTML
            <div class="outline pa2 mr3 mt2 tc" style="min-width:230px;background:#e6f4f1;">
              <p class="fw6 f4 mt0 pb1 bb">#{item[:ph]} #{item[:cv]} #{item[:pack]}</p>
              <p class="fw7 f4 tc pa2 mt0 mb2" style="background-color:#8ABDEA">
                Cartons &mdash; VERIFIED: <span class="f3">#{item[:ctn_tot]}</span>, SCRAPPED: <span class="f3">#{item[:ctn_tot_scrap]}</span>
              </p>
              <table class="thinbordertable" style="width:100%">
                <tr><th></th><th></th><th></th><th>Cartons</th><th>Pallets</th></tr>
                <tr><th colspan="2"></th><td rowspan="2" class="tc f3 b">TOTAL</td><td colspan="2" class="bg-white">Pallets</td></tr>
                <tr><th>Cartons</th><th>Pallets</th><td class="tr f2">#{item[:ctn_qty]}</td><td class="tr f2">#{item[:plt_qty]}</td></tr>
                <tr><td colspan="2" class="bg-white">Shiped (#{item[:load_s_qty]})</td><td rowspan="2" class="tc f3 b">LOAD</td><td colspan="2" class="bg-white">Allocated (#{item[:load_a_qty]})</td></tr>
                <tr><td class="tr f2">#{item[:ship_c_qty]}</td><td class="tr f2">#{item[:ship_p_qty]}</td><td class="tr f2">#{item[:alloc_c_qty]}</td><td class="tr f2">#{item[:alloc_p_qty]}</td></tr>
                <tr><td colspan="2" class="bg-white">Verified</td><td rowspan="2" class="tc f3 b">VERIFY</td><td colspan="2" class="bg-white">Unverified</td></tr>
                <tr><td class="tr f2">#{item[:ver_c_qty]}</td><td class="tr f2">#{item[:ver_p_qty]}</td><td class="tr f2">#{item[:unver_c_qty]}</td><td class="tr f2">#{item[:unver_p_qty]}</td></tr>
              </table>
            </div>
          HTML
        end
      end
    end
  end
end
