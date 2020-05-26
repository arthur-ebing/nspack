# frozen_string_literal: true

# require 'logger'
class LoadUnshipLocationRevert < BaseScript
  def run # rubocop:disable Metrics/AbcSize
    query = <<~SQL
      SELECT
        logged_actions.row_data_id AS pallet_id,
        row_data -> 'pallet_number' AS pallet_number,
        row_data -> 'location_id'   AS location_id
      FROM audit.logged_actions
      LEFT JOIN audit.status_logs ON status_logs.transaction_id = logged_actions.transaction_id
        AND logged_actions.row_data_id = status_logs.row_data_id
        AND status_logs.table_name = 'pallets'
      JOIN pallets ON pallets.id = logged_actions.row_data_id
      WHERE logged_actions.table_name = 'pallets'
        AND logged_actions.transaction_id = 5032061
        AND pallets.location_id = 5
    SQL
    pallets = DB[query].select_map(%i[pallet_id pallet_number location_id])

    p "Records affected: #{pallets.count}"
    pallets.each do |pallet_id, pallet_number, location_id|
      attrs = { location_id: location_id }
      if debug_mode
        p "Updated row #{pallet_id} #{pallet_number}: #{attrs}"
      else
        DB.transaction do
          p "Updated row #{pallet_id} #{pallet_number}: #{attrs}"
          DB[:pallets].where(id: pallet_id).update(attrs)
          log_status(:pallets, pallet_id, 'UNSHIP LOCATION REVERT', comment: 'reverted_transaction_id_5032061')
        end
      end
    end

    log_infodump(:data_fix,
                 :pallets,
                 :reverted_transaction_id_5032061,
                 "Reverted transaction_id 5032061 for pallet locations:#{pallets}")

    if debug_mode
      success_response('Dry run complete')
    else
      success_response('Data Updated')
    end
  end
end
