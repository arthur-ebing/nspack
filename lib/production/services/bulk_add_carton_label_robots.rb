# frozen_string_literal: true

module ProductionApp
  class BulkAddCartonLabelRobot < BaseService
    attr_reader :id, :repo, :opts, :robot_type_id, :button_type_id, :printer_type_id, :range

    def initialize(id, opts)
      @id = id
      @opts = opts
      @repo = ResourceRepo.new
      @robot_type_id = repo.plant_resource_type_id_from_code(Crossbeams::Config::ResourceDefinitions::CLM_ROBOT)
      @button_type_id = repo.plant_resource_type_id_from_code(Crossbeams::Config::ResourceDefinitions::ROBOT_BUTTON)
      @printer_type_id = repo.plant_resource_type_id_from_code(Crossbeams::Config::ResourceDefinitions::PRINTER)
      starting_no = opts[:starting_no]
      @range = (starting_no..(starting_no + opts[:no_clms] - 1))
    end

    def call
      res = set_up_resource_list
      return res unless res.success

      resources.zip(modules).zip(printers).each do |mods, printer|
        build_resources(mods[0], mods[1], printer)
      end

      success_response("Added #{opts[:no_clms]} carton labeling robots")
    end

    private

    def set_up_resource_list # rubocop:disable Metrics/AbcSize
      in_use_plt = repo.select_values(:plant_resources, :plant_resource_code, plant_resource_code: resources)
      return failed_response("These plant resources already exist: #{in_use_plt.join(', ')}") unless in_use_plt.empty?

      in_use_sys = repo.select_values(:system_resources, :system_resource_code, system_resource_code: modules)
      return failed_response("These plant resources already exist: #{in_use_sys.join(', ')}") unless in_use_sys.empty?

      in_use_prn = repo.select_values(:plant_resources, :plant_resource_code, plant_resource_code: printers)
      return failed_response("These printers already exist: #{in_use_prn.join(', ')}") unless in_use_prn.empty?

      ok_response
    end

    def modules
      @modules ||= range.map { |r| "CLM-#{r.to_s.rjust(2, '0')}" }
    end

    def resources
      @resources ||= range.map { |r| "#{opts[:plant_resource_prefix]} #{r}" }
    end

    def printers
      # Range should be decreased if > 1 robot/printer
      @printers ||= range.map { |r| "PRN-#{r.to_s.rjust(2, '0')} #{r}" }
    end

    def build_resources(pname, sname, printer) # rubocop:disable Metrics/AbcSize
      attrs = {
        plant_resource_type_id: robot_type_id,
        plant_resource_code: pname,
        description: pname
      }
      plant_id = repo.create_child_plant_resource(id, attrs, sys_code: sname)
      opts[:no_buttons].times do |no|
        repo.create_child_plant_resource(plant_id,
                                         plant_resource_type_id: button_type_id,
                                         plant_resource_code: "#{sname}-B#{no + 1}",
                                         description: "#{sname}-B#{no + 1}")
      end
      prt_id = repo.create_child_plant_resource(id,
                                                plant_resource_type_id: printer_type_id,
                                                plant_resource_code: printer,
                                                description: printer)
      prt_sys_id = repo.get_value(:plant_resources, :system_resource_id, id: prt_id)
      repo.link_a_peripheral(plant_id, prt_sys_id)
    end
  end
end
