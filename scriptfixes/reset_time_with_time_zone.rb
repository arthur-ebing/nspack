# frozen_string_literal: true

# What this script does:
# ----------------------
# Takes certain timestamp with time zone columns on certain tables and changes them to be
# two hours earlier.
# Applies to transactional data created before 2020-02-14.
#
# Reason for this script:
# -----------------------
# On 2020-02-13 at about 22:00, all timestamp without time zone were converted
# to timestamp with time zone.
# As a result many times display 2 hours later than they should.
#
class ResetTimeWithTimeZone < BaseScript
  def run # rubocop:disable Metrics/AbcSize
    sql = []

    CHANGES.each do |table, columns|
      puts "Updating #{table} for: #{columns.join(', ')}"
      dis = "ALTER TABLE #{table} DISABLE TRIGGER ALL;"
      en = "ALTER TABLE #{table} ENABLE TRIGGER ALL;"
      script = %(#{dis}\n#{columns.map { |col| "UPDATE #{table} SET #{col} = #{col} - interval '2 hours' WHERE #{col} < '2020-02-14 00:00';" }.join("\n")}\n#{en})
      sql << script
      if debug_mode
        puts script
        puts ''
      else
        DB.transaction do
          DB.run(script)
        end
      end
    end

    infodump = <<~STR
      Script: ResetTimeWithTimeZone

      What this script does:
      ----------------------
      Takes certain timestamp with time zone columns on certain tables and changes them to be
      two hours earlier.
      Applies to transactional data created before 2020-02-14.

      Reason for this script:
      -----------------------
      On 2020-02-13 at about 22:00, all timestamp without time zone were converted
      to timestamp with time zone.
      As a result many times display 2 hours later than they should.

      Results:
      --------
      Ran the following SQL:

      #{sql.join("\n")}
    STR

    log_infodump(:data_fix,
                 :timezones,
                 :correct_where_2_hours_ahead,
                 infodump)

    if debug_mode
      success_response('Dry run complete')
    else
      success_response('Applied the time change')
    end
  end

  # TODO: test if any have the correct date?
  CHANGES = {
    carton_labels: %i[created_at updated_at],
    cartons: %i[created_at updated_at],
    govt_inspection_pallets: %i[inspected_at created_at updated_at],
    govt_inspection_sheets: %i[results_captured_at completed_at created_at updated_at cancelled_at],
    load_containers: %i[verified_gross_weight_date created_at updated_at],
    loads: %i[shipped_at created_at updated_at allocated_at],
    pallet_sequences: %i[scrapped_at verified_at created_at updated_at removed_from_pallet_at],
    pallets: %i[scrapped_at shipped_at govt_first_inspection_at govt_reinspection_at internal_inspection_at internal_reinspection_at stock_created_at intake_created_at first_cold_storage_at gross_weight_measured_at palletized_at partially_palletized_at created_at updated_at allocated_at],
    rmt_bins: %i[created_at updated_at bin_received_date_time bin_tipped_date_time exit_ref_date_time rebin_created_at scrapped_at],
    rmt_deliveries: %i[date_delivered tipping_complete_date_time created_at updated_at]
  }.freeze
end
