# frozen_string_literal: true

# What this script does:
# ----------------------
# This de-allocates (deletes product_resource_allocations) all records (against any run) where the plant_resource-code is 'CLM-<25,26,27,28>-<not B1>'
#
# So, eg product_resource_allocations with plant_resource_code = CLM-25-B2,CLM-25-B3,CLM-25-B4,CLM-25-B5 and CLM-25-B6 should be deleted, but not CLM-25-B1
# Same for CLM's 26,27 and 28
#
# Reason for this script:
# -----------------------
# For Addo:  (SR2)
#
# Autopackers (CLM-25 to CLM-28) should only have a B1 button. They have been defined with 6 buttons which means that people erroneously allocate to B2 etc. What needs to happen is that all allocation records linked to those button resources need to be deleted and then the buttons themselves must be deleted.
#
# To run:
# -------
# Debug : DEBUG=y RACK_ENV=production ruby scripts/base_script.rb DeallocateProductResourceAllocations
# Live  : RACK_ENV=production ruby scripts/base_script.rb DeallocateProductResourceAllocations
# Dev   : ruby scripts/base_script.rb DeallocateProductResourceAllocations
#
class DeallocateProductResourceAllocations < BaseScript
  def run # rubocop:disable Metrics/AbcSize
    query = <<~SQL
      SELECT DISTINCT plant_resource_id,plant_resource_code
      FROM plant_resources
      JOIN product_resource_allocations ON plant_resources.id = product_resource_allocations.plant_resource_id
      WHERE plant_resource_code LIKE 'CLM-2%'
      ORDER BY plant_resource_code
    SQL
    plant_resources = DB[query].all
    return failed_response('There are no product_resource_allocations to fix') if plant_resources.empty?

    plant_resource_ids = plant_resources.map { |r| r[:id] }

    count = 0
    text_data = []
    plant_resources.each do |plant_resource|
      plant_resource_code = plant_resource[:plant_resource_code]
      arr = plant_resource_code.split('-')
      next unless deallocate_resource_allocations?(arr)

      count += 1
      text_data << "Deleted plant_resource #{plant_resource_code} and its product_resource_allocations"
      if debug_mode
        p "Deleted plant_resource #{plant_resource_code} and its product_resource_allocations"
      else
        DB.transaction do
          p "Deleted plant_resource #{plant_resource_code} and its product_resource_allocations"
          delete_plant_resource(plant_resource[:plant_resource_id])
        end
      end
    end
    p "Plant resource records affected: #{count}"

    infodump = <<~STR
      Script: DeallocateProductResourceAllocations

      What this script does:
      ----------------------
      This de-allocates (deletes product_resource_allocations) all records (against any run) where the plant_resource-code is 'CLM-<25,26,27,28>-<not B1>'

      So, eg product_resource_allocations with plant_resource_code = CLM-25-B2,CLM-25-B3,CLM-25-B4,CLM-25-B5 and CLM-25-B6 should be deleted, but not CLM-25-B1
      Same for CLM's 26,27 and 28

      Reason for this script:
      -----------------------
      For Addo:  (SR2)

      Autopackers (CLM-25 to CLM-28) should only have a B1 button. They have been defined with 6 buttons which means that people erroneously allocate to B2 etc. What needs to happen is that all allocation records linked to those button resources need to be deleted and then the buttons themselves must be deleted.

      Results:
      --------
      Updated something

      data: Deleted plant_resources (#{plant_resource_ids.join(',')})

      text data:
      #{text_data.join("\n\n")}
    STR

    log_infodump(:data_fix,
                 :product_resource_allocations,
                 :DeallocateProductResourceAllocations,
                 infodump)

    if debug_mode
      success_response('Dry run complete')
    else
      success_response('Something was done')
    end
  end

  private

  def deallocate_resource_allocations?(args)
    deallocate = args[1].to_i.between?(25, 28)
    deallocate = false if args[2] == 'B1'
    deallocate
  end

  def delete_plant_resource(id) # rubocop:disable Metrics/AbcSize
    DB[:product_resource_allocations].where(plant_resource_id: id).delete
    DB[:tree_plant_resources].where(ancestor_plant_resource_id: id).or(descendant_plant_resource_id: id).delete
    system_resource_id = DB[:plant_resources].where(id: id).get(:system_resource_id)
    DB[:palletizing_bay_states].where(palletizing_bay_resource_id: id).delete
    DB[:plant_resources].where(id: id).delete
    DB[:system_resources].where(id: system_resource_id).delete if system_resource_id
  end
end
