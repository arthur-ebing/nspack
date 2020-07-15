# frozen_string_literal: true

# What this script does:
# ----------------------
# Gets a list of robot modules and their ip addresses per packhouse.
# Calls MesServer on each ip address to get the version number.
# Prints the output or error for each module within a packhouse.
#
# Reason for this script:
# -----------------------
# To get a quick way to see the status of all robots at a site.
# As well as to check the running MesScada versions.
#
class RobotVersions < BaseScript
  def run # rubocop:disable Metrics/AbcSize
    # Do some work here...
    # get list of modules grouped per ph

    if debug_mode
      # Print list of modules
      puts 'List of modules and ip addresses per packhouse'
      robot_list.each do |ph, recs|
        puts "\n#{ph}"
        puts '-' * ph.length
        recs.each do |rec|
          puts "#{rec[:system_resource_code]}\t#{rec[:ip_address]}"
        end
      end
    else
      # Check MesServer versions & print
      puts 'MesServer status of each robot per packhouse'
      robot_list.each do |ph, recs|
        puts "\n#{ph}"
        puts '-' * ph.length
        recs.each do |rec|
          res = `curl -sS http://#{rec[:ip_address]}:2080/?Type=SoftwareRevision`
          puts "#{rec[:system_resource_code]}\t#{rec[:ip_address]}\t#{res}"
        end
      end
    end

    if debug_mode
      success_response('Dry run complete')
    else
      success_response('Listing done')
    end
  end

  private

  def robot_list
    query = <<~SQL
      SELECT (SELECT "c"."plant_resource_code"
      FROM "plant_resources" c
      JOIN "tree_plant_resources" t1 ON "t1"."ancestor_plant_resource_id" = "c"."id"
      WHERE "t1"."descendant_plant_resource_id" = "plant_resources"."id"
        AND c.plant_resource_type_id = (SELECT id FROM plant_resource_types WHERE plant_resource_type_code = 'PACKHOUSE')
      ) AS packhouse,
      system_resource_code,
      ip_address
      FROM system_resources
      JOIN plant_resources ON plant_resources.system_resource_id = system_resources.id
      WHERE system_resource_type_id = (SELECT id FROM system_resource_types WHERE system_resource_type_code = 'MODULE')
      ORDER BY 1, 2, inet(ip_address);
    SQL
    DB[query].all.group_by { |rec| rec[:packhouse] }
  end
end
