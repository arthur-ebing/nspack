# frozen_string_literal: true

# What this script does:
# ----------------------
# Update all robot button plant resources
# to have their codes and descriptions rebuilt from the CLM code.
#
# Reason for this script:
# -----------------------
# Sitrusrand renamed their plant resource names for all CLMs
# before the change was put in place that keeps the button names in sync.
#
class SetRobotButtonCodes < BaseScript
  def run # rubocop:disable Metrics/AbcSize
    type_id = DB[:plant_resource_types].where(plant_resource_type_code: 'CLM_ROBOT').get(:id)
    ids = DB[:plant_resources].where(plant_resource_type_id: type_id).select_map(%i[id plant_resource_code])

    @ar_log = []

    if debug_mode
      ids.each do |id, clm|
        @ar_log << "Would update #{clm}"
        update_buttons(id, clm)
      end
      puts @ar_log.join("\n")
      puts 'Done'
    else
      DB.transaction do
        ids.each do |id, clm|
          @ar_log << "Updating #{clm}"
          update_buttons(id, clm)
        end
      end
    end

    infodump = <<~STR
      Script: SetRobotButtonCodes

      What this script does:
      ----------------------
      Update all robot button plant resources
      to have their codes and descriptions rebuilt from the CLM code.

      Reason for this script:
      -----------------------
      Sitrusrand renamed their plant resource names for all CLMs
      before the change was put in place that keeps the button names in sync.

      Results:
      --------
      Updated CLM button names:

      #{@ar_log.join("\n")}
    STR

    log_infodump(:data_fix,
                 :plant_resources,
                 :change_robot_button_codes,
                 infodump)

    if debug_mode
      success_response('Dry run complete')
    else
      success_response('Buttons updated')
    end
  end

  private

  def update_buttons(plant_resource_id, clm_code) # rubocop:disable Metrics/AbcSize
    ids = DB[:tree_plant_resources].where(ancestor_plant_resource_id: plant_resource_id, path_length: 1).select_map(:descendant_plant_resource_id)
    ids.each do |id|
      pr_code = DB[:plant_resources].join(:plant_resource_types, id: :plant_resource_type_id).where(Sequel[:plant_resources][:id] => id).get(:plant_resource_type_code)
      next unless pr_code == 'ROBOT_BUTTON'

      old_code = DB[:plant_resources].where(id: id).get(:plant_resource_code)
      new_code = old_code.sub(/.+(B\d+)$/, "#{clm_code} \\1")
      next if old_code == new_code

      if debug_mode
        @ar_log << "Would change #{old_code} to #{new_code}"
      else
        @ar_log << "Change #{old_code} to #{new_code}"
        DB[:plant_resources].where(id: id).update(plant_resource_code: new_code, description: new_code)
      end
    end
  end
end
