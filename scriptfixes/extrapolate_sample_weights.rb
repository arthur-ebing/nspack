# frozen_string_literal: true

# What this script does:
# ----------------------
# This service takes a list of all rmt_delivery_ids that are not tipped
# For each delivery:
#     Check if all sample bins on the delivery has been weighed (has a nett_weight)
#         If so:
#             get the average weight of all sample bins
#             Update all non sample bins with the average weight
#             Flag the delivery's sample_bins_weighed  (new column)
#             Set sample_weights_extrapolated_at to now()  (new column)
#             Set status on delivery SAMPLE_WEIGHTS_APPLIED
#
# Reason for this script:
# -----------------------
# extrapolate bin weights
#
# To run:
# -------
# Debug : DEBUG=y RACK_ENV=production ruby scripts/base_script.rb ExtrapolateSampleWeights
# Live  : RACK_ENV=production ruby scripts/base_script.rb ExtrapolateSampleWeights
# Dev   : ruby scripts/base_script.rb ExtrapolateSampleWeights
#
class ExtrapolateSampleWeights < BaseScript
  def run # rubocop:disable Metrics/AbcSize
    rmt_delivery_ids = DB[:rmt_deliveries]
                       .join(:cultivars, id: :cultivar_id)
                       .join(:cultivar_groups, id: :cultivar_group_id)
                       .join(:commodities, id: :commodity_id)
                       .where(allocate_sample_rmt_bins: true, derive_rmt_nett_weight: false)
                       .exclude(delivery_tipped: true)
                       .distinct
                       .select_map(Sequel[:rmt_deliveries][:id])
    return failed_response('There are no deliveries to fix') if rmt_delivery_ids.nil_or_empty?

    p "#{rmt_delivery_ids.count} deliveries records to fix."
    @text_data = []

    DB.transaction do
      rmt_delivery_ids.each do |rmt_delivery_id|
        str = "updated rmt_bins nett weight where rmt_delivery_id is #{rmt_delivery_id}\n"
        if debug_mode
          p str
        else
          @text_data << str
          res = RawMaterialsApp::ExtrapolateSampleWeightsForDelivery.call(rmt_delivery_id)
          raise Crossbeams::InfoError, res.message unless res.success
        end
      end

      infodump
      success_response('ok')
    end
  rescue StandardError => e
    ErrorMailer.send_exception_email(e, subject: 'ExtrapolateSampleWeights queue failure')
    failed_response(e.message)
  end

  private

  def infodump
    infodump = <<~STR
      Script: ExtrapolateSampleWeights

      What this script does:
      ----------------------
      This service takes a list of all rmt_delivery_ids that are not tipped
      For each delivery:
          Check if all sample bins on the delivery has been weighed (has a nett_weight)
              If so:
                  get the average weight of all sample bins
                  Update all non sample bins with the average weight
                  Flag the delivery's sample_bins_weighed  (new column)
                  Set sample_weights_extrapolated_at to now()  (new column)
                  Set status on delivery SAMPLE_WEIGHTS_APPLIED

      Reason for this script:
      -----------------------
      extrapolate bin weights

      Results:
      --------
      #{@text_data.join("\n\n")}
    STR
    log_infodump(:data_fix,
                 :extrapolate_bin_weights,
                 :update_bin_nett_weight_for_deliveries,
                 infodump)
  end
end
