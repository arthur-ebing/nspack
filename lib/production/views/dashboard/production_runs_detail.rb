# frozen_string_literal: true

module Production
  module Dashboards
    module Dashboard
      class ProductionRunsDetail
        def self.call(params)
          layout = Crossbeams::Layout::Page.build({}) do |page|
            page.add_text draw_boxes(params[:line])
          end

          layout
        end

        def self.draw_boxes(line)
          recs = ProductionApp::DashboardRepo.new.production_runs(line)
          <<~HTML
            <div class="flex flex-column">
              #{runs(recs).join("\n")}
            </div>
          HTML
        end

        def self.runs(recs) # rubocop:disable Metrics/AbcSize, Metrics/PerceivedComplexity
          recs.map do |rec|
            target_markets = ProductionApp::DashboardRepo.new.tm_for_run(rec[:id])
            tm_cartons = if target_markets.empty?
                           ['<tr><td collspan="2">None packed</td></tr>']
                         else
                           target_markets.map do |tm|
                             %(<tr><td>#{tm[:packed_tm_group]}</td><td class="tr">#{tm[:no_cartons]}</td></tr>)
                           end
                         end

            re_exec = if rec[:re_executed_at].nil?
                        ''
                      else
                        %(<div class="pa2 mr2 mt2 fw8">Re-exec: #{rec[:re_executed_at].strftime('%H:%M')}</div>)
                      end
            percentage = if rec[:carton_weight].zero? || rec[:bins_tipped_weight].zero?
                           0
                         else
                           rec[:carton_weight] / rec[:bins_tipped_weight] * 100.0
                         end
            <<~HTML
              <div class="flex flex-column mv2 bg-mid-gray pt1 pl2 pb2 outline">
                <div class="flex flex-wrap near-white">
                  <div class="pa2 mr2 mt2 fw8">#{rec[:packhouse_code]} #{rec[:line_code]}</div>
                  <div class="pa2 mr2 mt2 fw8">#{rec[:production_run_code]}</div>
                  <div class="pa2 mr2 mt2 fw8">#{rec[:active_run_stage]}</div>
                  <div class="pa2 mr2 mt2 fw8">Start: #{rec[:started_at].strftime('%H:%M')}</div>
                  #{re_exec}
                </div>

                <div class="flex flex-wrap">
                  <div class="outline pa2 mr2 mt2 bg-washed-blue">
                    <p class="bt bb fw7">Spec</p>
                    <table>
                      <tr><td>PUC:</td><td>#{rec[:puc_code]}</td></tr>
                      <tr><td>Orchard:</td><td>#{rec[:orchard_code]}</td></tr>
                      <tr><td>Cultivar grp:</td><td>#{rec[:cultivar_group_code]}</td></tr>
                    </table>
                  </div>

                  <div class="outline pa2 mr2 mt2 bg-washed-blue">
                    <p class="bt bb fw7">Target Mkts</p>
                    <table style="width:100%">
                      #{tm_cartons.join("\n")}
                    </table>
                  </div>

                  <div class="outline pa2 mr2 mt2 bg-washed-blue tc flex flex-column justify-center" style="background: linear-gradient(0deg, #8ABDEA #{percentage.to_i}%, #e6f4f1 #{percentage.to_i}%);">
                    <p class="fw6 f2 mid-gray dib v-mid">#{UtilityFunctions.delimited_number(percentage)}%</p>
                  </div>
                  <div class="outline pa2 mr2 mt2 bg-washed-blue">
                    <p class="bt bb fw7">Bins</p>
                    <table>
                      <tr><td>Tipped:</td><td class="tr">#{rec[:bins_tipped]}</td></tr>
                      <tr><td>Weight:</td><td class="tr">#{UtilityFunctions.delimited_number(rec[:bins_tipped_weight])}</td></tr>
                      <tr><td>Rebins:</td><td class="tr">#{rec[:rebins_created]}</td></tr>
                      <tr><td>Rebin Weight:</td><td class="tr">#{UtilityFunctions.delimited_number(rec[:rebins_weight])}</td></tr>
                    </table>
                  </div>
                  <div class="outline pa2 mr2 mt2 bg-washed-blue">
                    <p class="bt bb fw7">Cartons</p>
                    <table>
                      <tr><td>Labels:</td><td class="tr">#{rec[:carton_labels_printed]}</td></tr>
                      <tr><td>Verified:</td><td class="tr">#{rec[:cartons_verified]}</td></tr>
                      <tr><td>Weight:</td><td class="tr">#{UtilityFunctions.delimited_number(rec[:cartons_verified_weight])}</td></tr>
                      <tr><td>STD Weight:</td><td class="tr">#{UtilityFunctions.delimited_number(rec[:carton_weight])}</td></tr>
                    </table>
                  </div>
                  <div class="outline pa2 mr2 mt2 bg-washed-blue">
                    <p class="bt bb fw7">Pallets</p>
                    <table>
                      <tr><td>Full:</td><td class="tr">#{rec[:pallets_palletized_full]}</td></tr>
                      <tr><td>Partial:</td><td class="tr">#{rec[:pallets_palletized_partial]}</td></tr>
                      <tr><td>Inspected:</td><td class="tr">#{rec[:inspected_pallets]}</td></tr>
                      <tr><td>Verified:</td><td class="tr">#{rec[:verified_pallets]}</td></tr>
                      <tr><td>Weight:</td><td class="tr">#{UtilityFunctions.delimited_number(rec[:pallet_weight])}</td></tr>
                    </table>
                  </div>
                </div>
              </div>
            HTML
          end
        end
      end
    end
  end
end
