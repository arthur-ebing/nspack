# frozen_string_literal: true

module MesscadaApp
  module BinTipSupport
    def active_run_for_device
      line = ProductionApp::ResourceRepo.new.plant_resource_parent_of_system_resource(Crossbeams::Config::ResourceDefinitions::LINE, @device)
      return line unless line.success

      res = ProductionApp::ProductionRunRepo.new.find_production_runs_for_line_in_state(line.instance, running: true, tipping: true)
      return res unless res.success

      return failed_response('Line has > 1 tipping run') unless res.instance.length == 1

      success_response('run found', res.instance.first)
    end
  end
end
