# frozen_string_literal: true

module ProductionApp
  class BulkAddPalletizerRobot < BaseService
    attr_reader :id, :repo, :opts, :robot_type_id, :bay_type_id, :range
    attr_accessor :curr_bay_code

    def initialize(id, opts)
      @id = id
      @opts = opts
      @repo = ResourceRepo.new
      @robot_type_id = repo.plant_resource_type_id_from_code(Crossbeams::Config::ResourceDefinitions::PALLETIZING_ROBOT)
      @bay_type_id = repo.plant_resource_type_id_from_code(Crossbeams::Config::ResourceDefinitions::PALLETIZING_BAY)
      starting_no = opts[:starting_no]
      @range = (starting_no..(starting_no + opts[:no_robots] - 1))
    end

    def call
      res = set_up_resource_list
      return res unless res.success

      initial_bay_code

      resources.zip(modules).each do |pname, sname|
        build_resources(pname, sname)
      end

      success_response("Added #{opts[:no_robots]} palletizing robots")
    end

    private

    def set_up_resource_list
      in_use_plt = repo.select_values(:plant_resources, :plant_resource_code, plant_resource_code: resources)
      return failed_response("These plant resources already exist: #{in_use_plt.join(', ')}") unless in_use_plt.empty?

      in_use_sys = repo.select_values(:system_resources, :system_resource_code, system_resource_code: modules)
      return failed_response("These plant resources already exist: #{in_use_sys.join(', ')}") unless in_use_sys.empty?

      ok_response
    end

    def modules
      @modules ||= range.map { |r| "PTM-#{r.to_s.rjust(2, '0')}" }
    end

    def resources
      @resources ||= range.map { |r| "#{opts[:plant_resource_prefix]} #{r}" }
    end

    def initial_bay_code
      @curr_bay_code = repo.max_plant_resource_code_for_type(bay_type_id)
      @curr_bay_code = 'PBAY-00' if @curr_bay_code.nil?
    end

    def build_resources(pname, sname) # rubocop:disable Metrics/AbcSize
      attrs = {
        plant_resource_type_id: robot_type_id,
        plant_resource_code: pname,
        description: pname
      }
      plant_id = repo.create_child_plant_resource(id, attrs, sys_code: sname)

      bay_attrs = {
        plant_resource_type_id: bay_type_id,
        plant_resource_code: curr_bay_code,
        description: curr_bay_code
      }

      opts[:bays_per_robot].times do |no|
        @curr_bay_code = @curr_bay_code.succ
        bay_attrs[:plant_resource_code] = curr_bay_code
        bay_attrs[:description] = "#{curr_bay_code} (#{no.zero? ? 'Left' : 'Right'})"
        bay_id = repo.create_child_plant_resource(plant_id, bay_attrs)

        # Also add the palletizing bay state:
        repo.create(:palletizing_bay_states,
                    palletizing_robot_code: sname,
                    scanner_code: no + 1,
                    palletizing_bay_resource_id: bay_id,
                    current_state: 'empty')
      end
    end
  end
end
