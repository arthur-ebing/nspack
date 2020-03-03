# frozen_string_literal: true

# What this script does:
# ----------------------
# Takes all rmt_bins where the time portion of bin_received_date_time is 22:00
# and adds two hours to them.
#
# Reason for this script:
# -----------------------
# Originally bin_received_date_time contained only a date portion (time was midnight)
# Later this was changed to be an actual date time.
# When the time zone change was made, all timestamps were reduced by 2 hours
# to become proper UTC times.
# However because these values never had real times in them, midnight was converted to
# 22:00 on the previous day (UTC, displays as midnight in SAST).
# Queries would work fine except when converting the time to a date before applying the
# local timezone in the app. In this case the date would show as the previous day.
#
class AdvanceBinReceivedTime < BaseScript
  def run # rubocop:disable Metrics/AbcSize
    query = <<~SQL
      SELECT id, bin_received_date_time,
      bin_received_date_time + INTERVAL '2h' AS newtime
      FROM rmt_bins
      WHERE EXTRACT('hour' FROM bin_received_date_time) = 22
      ORDER BY bin_received_date_time, id
    SQL
    data = DB[query].all
    ids = data.map { |r| r[:id] }

    if debug_mode
      puts 'Updating the following records by advancing that date time by two hours:'
      puts "\n    ID |     current date |         new date"
      puts "\n-------+------------------+------------------"
      data.each do |rec|
        puts "#{rec[:id].to_s.rjust(6)} | #{rec[:bin_received_date_time].strftime('%Y-%m-%d %H:%M')} | #{rec[:newtime].strftime('%Y-%m-%d %H:%M')}"
      end
    else
      DB.transaction do
        upd = <<~SQL
          UPDATE rmt_bins
          SET bin_received_date_time = bin_received_date_time + INTERVAL '2h'
          WHERE EXTRACT('hour' FROM bin_received_date_time) = 22;
        SQL
        puts "Changed the times of #{ids.length} rmt_bins."
        DB.run(upd)
        log_multiple_statuses(:rmt_bins, ids, 'ADVANCED RECEIVE TIME', comment: 'to midnight', user_name: 'System')
      end
    end

    infodump = <<~STR
      Script: AdvanceBinReceivedTime

      What this script does:
      ----------------------
      Takes all rmt_bins where the time portion of bin_received_date_time is 22:00
      and adds two hours to them.

      Reason for this script:
      -----------------------
      Originally bin_received_date_time contained only a date portion (time was midnight)
      Later this was changed to be an actual date time.
      When the time zone change was made, all timestamps were reduced by 2 hours
      to become proper UTC times.
      However because these values never had real times in them, midnight was converted to
      22:00 on the previous day (UTC, displays as midnight in SAST).
      Queries would work fine except when converting the time to a date before applying the
      local timezone in the app. In this case the date would show as the previous day.

      Results:
      --------

      Changed the times of #{ids.length} rmt_bins.

      Updating the following records by advancing that date time by two hours:
          ID |     current date |         new date
      -------+------------------+------------------
      #{data.map do |rec|
        "#{rec[:id].to_s.rjust(6)} | #{rec[:bin_received_date_time].strftime('%Y-%m-%d %H:%M')} | #{rec[:newtime].strftime('%Y-%m-%d %H:%M')}"
      end.join("\n")}

      ids: #{ids.join(', ')}
    STR

    log_infodump(:data_fix,
                 :timezones,
                 :advance_10pm_times_to_midnight,
                 infodump)

    if debug_mode
      success_response('Dry run complete')
    else
      success_response('Times were updated')
    end
  end
end
