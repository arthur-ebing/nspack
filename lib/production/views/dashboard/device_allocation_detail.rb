# frozen_string_literal: true

module Production
  module Dashboards
    module Dashboard
      class DeviceAllocationDetail
        def self.call(device)
          layout = Crossbeams::Layout::Page.build({}) do |page|
            page.add_text draw_boxes(device)
          end

          layout
        end

        def self.draw_boxes(device)
          resource_repo = ProductionApp::ResourceRepo.new
          plant_resource_id = resource_repo.plant_resource_id_for_system_code(device)
          res = resource_repo.plant_resource_parent_of_system_resource(Crossbeams::Config::ResourceDefinitions::LINE, device)
          line_no = res.instance
          production_run_id = ProductionApp::ProductionRunRepo.new.labeling_run_for_line(line_no)
          recs = ProductionApp::DashboardRepo.new.device_allocation(production_run_id, plant_resource_id)
          allocation(recs.first)
        end

        def self.allocation(rec) # rubocop:disable Metrics/AbcSize
          return 'Nothing allocated' if rec.nil?

          size = if rec[:size_ref] && rec[:actual_count]
                   "#{rec[:size_ref]}/#{rec[:actual_count]}"
                 elsif rec[:size_ref]
                   rec[:size_ref]
                 else
                   rec[:actual_count]
                 end
          <<~HTML
            <div class="flex flex-column mv2 bg-mid-gray pt1 pl2 pb2 outline">
              <div class="outline pa2 ma3 bg-washed-blue" style="max-width:20em">
                <table style="border-collapse:collapse;width:100%">
                  <tr style="background-color:#8ABDEA"><td class="f3 pa3">PUC:</td><td class="pa3 f2">#{rec[:puc_code]}</td></tr>
                  <tr style="background-color:#8ABDEA"><td class="f3 pa3">Orchard:</td><td class="pa3 f2">#{rec[:orchard_code]}</td></tr>
                  <tr style="background-color:#8ABDEA"><td class="f3 pa3">Cultivar:</td><td class="pa3 f2">#{rec[:cultivar_code]}</td></tr>
                  <tr><td class="f4 pa3">Variety:</td><td class="pa3 f3">#{rec[:marketing_variety_code]}</td></tr>
                  <tr><td class="f4 pa3">Pack:</td><td class="pa3 f3">#{rec[:standard_pack_code]}</td></tr>
                  <tr><td class="f4 pa3">Grade:</td><td class="pa3 f3">#{rec[:grade_code]}</td></tr>
                  <tr><td class="f4 pa3">Size:</td><td class="pa3 f3">#{size}</td></tr>
                  <tr><td class="f4 pa3">Packed TM:</td><td class="pa3 f3">#{rec[:packed_tm_group]}</td></tr>
                </table>
              </div>
            </div>
          HTML
        end
      end
    end
  end
end
