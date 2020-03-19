# frozen_string_literal: true

# require 'logger'
class GovtInspectionSheetsUpdateCreatedBy < BaseScript
  def run # rubocop:disable Metrics/AbcSize
    sheet_ids = DB[:govt_inspection_sheets].order(:id).select_map(:id)
    p "Records affected: #{sheet_ids.count}"

    sheet_ids.each do |sheet_id|
      user_name = DB[Sequel[:audit][:status_logs]].where(table_name: 'govt_inspection_sheets', row_data_id: sheet_id).order(:id).get(:user_name)
      created_by = DB[:users].where(user_name: user_name).get(:id)

      attrs = { created_by: user_name }
      if debug_mode
        p "Updated sheet #{sheet_id}: #{attrs}"
      else
        DB.transaction do
          p "Updated sheet #{sheet_id}: #{attrs}"
          DB[:govt_inspection_sheets].where(id: sheet_id).update(created_by: created_by)
        end
      end
    end

    log_infodump(:data_fix,
                 :govt_inspection_sheets,
                 :set_created_by,
                 "Updated  govt_inspection_sheets created_by for sheet_ids:#{sheet_ids}")

    if debug_mode
      success_response('Dry run complete')
    else
      success_response('Data Updated')
    end
  end
end
