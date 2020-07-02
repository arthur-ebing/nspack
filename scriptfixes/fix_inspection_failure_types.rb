# frozen_string_literal: true

# What this script does:
# ----------------------
# Fixes inspection_failure_types failure_type_code should be unique
#
# Reason for this script:
# -----------------------
# inspection_failure_types.failure_type_code should be unique
#
class FixInspectionFailureTypes < BaseScript
  def run  # rubocop:disable Metrics/AbcSize
    failure_type_codes = DB[:inspection_failure_types]
                         .order(:failure_type_code)
                         .distinct(:failure_type_code)
                         .select_map(:failure_type_code)

    failure_type_codes.each do |failure_type_code|
      recs = DB[:inspection_failure_types]
             .where(failure_type_code: failure_type_code)
             .order(:id)
             .select_map(:id)

      next if recs.count == 1

      inspection_failure_type_id = recs.first

      ids = DB[:inspection_failure_types]
            .join(:inspection_failure_reasons, inspection_failure_type_id: :id)
            .where(failure_type_code: failure_type_code)
            .exclude(inspection_failure_type_id: inspection_failure_type_id)
            .distinct(Sequel[:inspection_failure_types][:id])
            .select_map(:inspection_failure_type_id)

      if debug_mode
        p "Deleted inspection_failure_types #{ids.join(',')}"
      else
        DB.transaction do
          p "Deleted inspection_failure_types #{ids.join(',')}"
          query = <<~SQL
            UPDATE inspection_failure_reasons SET inspection_failure_type_id = #{inspection_failure_type_id}
            WHERE inspection_failure_type_id IN (#{ids.join(',')});
          SQL
          DB.execute(query) unless ids.nil_or_empty?
          DB[:inspection_failure_types].where(failure_type_code: failure_type_code).exclude(id: inspection_failure_type_id).delete
        end
      end
    end

    infodump = <<~STR
      Script: FixInspectionFailureTypes

      What this script does:
      ----------------------
      Fixes inspection_failure_types failure_type_code should be unique

      Reason for this script:
      -----------------------
      inspection_failure_types.failure_type_code should be unique

    STR

    log_infodump(:data_fix,
                 :data_fix,
                 :fix_failure_type_code,
                 infodump)

    if debug_mode
      success_response('Dry run complete')
    else
      success_response('inspection_failure_types updated')
    end
  end
end
