# frozen_string_literal: true

module Production
  module Dashboards
    module Dashboard
      class ProductionRuns
        def self.call
          layout = Crossbeams::Layout::Page.build({}) do |page|
            page.add_text 'Production runs', wrapper: :h2
            page.add_text draw_boxes
          end

          layout
        end

        def self.draw_boxes
          recs = ProductionApp::DashboardRepo.new.production_runs
          <<~HTML
            <div class="flex flex-column">
              #{runs(recs).join("\n")}
            </div>
          HTML
        end

        def self.runs(recs) # rubocop:disable Metrics/AbcSize, Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
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
            percentage = if (rec[:carton_weight] || 0).zero? || (rec[:bins_tipped_weight] || 0).zero?
                           0
                         else
                           rec[:carton_weight] / rec[:bins_tipped_weight] * 100.0
                         end
            <<~HTML
              <div class="flex flex-column mv2 bg-washed-green pt1 pl2 pb2 outline">
                <div class="flex flex-wrap">
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
            # code = rec[:plant_resource_code] || "#{rec[:palletizing_robot_code]} - #{rec[:scanner_code]}"
            # if rec[:current_state] == 'empty'
            #   <<~HTML
            #     <div class="outline pa2 mr2 mt2" style="min-width:230px">
            #       <p class="fw6 f4 mt0 pb1 bb">#{code}</p>
            #       <div class="fw6 tc pa2 mid-gray " style="background-color:#e6f4f1"><span class="f2">EMPTY</span><br>&nbsp;</div>
            #       <p class="mt5">Last used: <span class="fw7">#{rec[:updated_at].strftime('%d %b %H:%M')}</span></p>
            #     </div>
            #   HTML
            # elsif rec[:current_state] == 'return_to_bay'
            #   <<~HTML
            #     <div class="outline pa2 mr2 mt2" style="min-width:230px">
            #       <p class="fw6 f4 mt0 pb1 bb">#{code}</p>
            #       <div class="fw6 tc pa2 mid-gray " style="background-color:#e6f4f1"><span class="f2">RTB</span><br>&nbsp;</div>
            #       <p class="mt5">Last used: <span class="fw7">#{rec[:updated_at].strftime('%d %b %H:%M')}</span></p>
            #     </div>
            #   HTML
            # else
            #   <<~HTML
            #     <div class="outline pa2 mr2 mt2" style="min-width:230px">
            #       <p class="fw6 f4 mt0 pb1 bb">#{code}</p>
            #       <div class="tc pa2" style="background: linear-gradient(90deg, #8ABDEA #{rec[:percentage].to_i}%, #e6f4f1 #{rec[:percentage].to_i}%);">
            #         <span class="fw6 f2 mid-gray ">#{rec[:percentage].to_i}%</span><br>
            #       <table style="width:100%"><tr><td>#{rec[:pallet_qty] || 0} cartons</td><td>#{rec[:cartons_per_pallet] || 0} cpp</td></tr></table></div>
            #       <p class="fw7 tc">#{rec[:pallet_number]}</p>
            #       <p><table class="thinbordertable" style="width:100%"><tr><td>#{rec[:commodity]}</td><td>#{rec[:variety]}</td><td>#{rec[:size]}</td></tr></table></p>
            #       <p>#{rec[:palletizer]}</p>
            #     </div>
            #   HTML
            # end
          end
        end
      end
    end
  end
end
