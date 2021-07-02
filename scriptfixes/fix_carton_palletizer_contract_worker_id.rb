# frozen_string_literal: true

# What this script does:
# ----------------------
# Updates the cartons.palletizer_contract_worker_id
#
# Reason for this script:
# -----------------------
# added palletizer_contract_worker_id to cartons table
#
# To run:
# -------
# Debug : DEBUG=y RACK_ENV=production ruby scripts/base_script.rb FixCartonPalletizerContractWorkerId
# Live  : RACK_ENV=production ruby scripts/base_script.rb FixCartonPalletizerContractWorkerId
# Dev   : ruby scripts/base_script.rb FixCartonPalletizerContractWorkerId
#
class FixCartonPalletizerContractWorkerId < BaseScript
  def run # rubocop:disable Metrics/AbcSize
    query = <<~SQL
      SELECT DISTINCT palletizer_identifier_id
      FROM cartons
      WHERE palletizer_contract_worker_id IS NULL;
    SQL
    cartons = DB[query].all
    return failed_response('There are no cartons to fix') if cartons.empty?

    count = 0
    cartons.each do |carton|
      palletizer_identifier_id = carton[:palletizer_identifier_id]
      palletizer_carton_count = DB[:cartons].where(palletizer_identifier_id: palletizer_identifier_id).count
      palletizer_contract_worker_id = DB[:contract_workers].where(personnel_identifier_id: palletizer_identifier_id).get(:id)
      next if palletizer_contract_worker_id.nil_or_empty?

      count += palletizer_carton_count
      attrs = { palletizer_contract_worker_id: palletizer_contract_worker_id }
      if debug_mode
        p "Updated #{palletizer_carton_count} cartons: #{attrs}"
      else
        DB.transaction do
          p "Updated #{palletizer_carton_count} cartons: #{attrs}"
          DB[:cartons].where(palletizer_identifier_id: palletizer_identifier_id).update(attrs)
        end
      end
    end

    infodump = <<~STR
      Script: FixCartonPalletizerContractWorkerId

      What this script does:
      ----------------------
      Updates the cartons.palletizer_contract_worker_id

      Reason for this script:
      -----------------------
      added palletizer_contract_worker_id to cartons table

      Results:
      --------
      Updated palletizer_contract_worker_id for #{count} cartons.
    STR

    log_infodump(:data_fix,
                 :cartons,
                 :set_cartons_palletizer_contract_worker_id,
                 infodump)

    if debug_mode
      success_response('Dry run complete')
    else
      success_response('Cartons palletizer_contract_worker_id set successfully')
    end
  end
end
