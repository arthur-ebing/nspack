# frozen_string_literal: true

# What this script does:
# ----------------------
# Extracts Delivery Jasper reports.
# Selects deliveries created within a recent period.
# Generates delivery reports for each and places them in the provided dir.
# Parameters: time (in minutes) and output_dir (a full path).
#
# Reason for this script:
# -----------------------
# To regularly place all dispatch reports in a central place.
#
# To run: (using 60 minutes as the time period and /home/user/place as the output dir)
# -------
# Debug : DEBUG=y RACK_ENV=production ruby scripts/base_script.rb ExtractDeliveryReports 60 /home/user/place
# Live  : RACK_ENV=production ruby scripts/base_script.rb ExtractDeliveryReports 60 /home/user/place
# Dev   : ruby scripts/base_script.rb ExtractDeliveryReports 60 /home/user/place
#
class ExtractDeliveryReports < BaseScript
  def run # rubocop:disable Metrics/AbcSize
    raise ArgumentError, 'Requires 2 input parameters - the time in minutes and the output dir' unless args.length == 2

    time_period = args.first.to_i
    out_dir = args.last
    ids = find_relevant_deliveries(time_period)

    if debug_mode
      puts "Found #{ids.length} deliveries: #{ids.inspect}"
    else
      ids.each { |id| RawMaterialsApp::Job::GenerateDeliveryReport.enqueue(id, out_dir) }
    end

    if debug_mode
      success_response('Dry run complete')
    else
      success_response("#{ids.length} delivery reports enqueued")
    end
  end

  private

  def find_relevant_deliveries(time_period)
    start_time = Time.now - time_period * 60
    query = <<~SQL
      SELECT id FROM rmt_deliveries
      WHERE created_at > ?
    SQL
    DB[query, start_time].select_map
  end
end
