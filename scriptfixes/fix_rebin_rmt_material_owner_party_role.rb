# frozen_string_literal: true

# What this script does:
# ----------------------
# Fixes rmt_material_owner_party_role_id value on rebin rmt_bins
# Sets status of affected objects to BIN_MATERIAL_OWNER_PARTY_ROLE_FIX
# Bin asset control triggers will add the records in bin_asset_transactions_queue with event type BIN_MATERIAL_OWNER_CHANGED / REBIN_MATERIAL_OWNER_CHANGED
#
# Reason for this script:
# -----------------------
# Rebin verification was leaving the rmt_material_owner_party_role_id blank
#
# To run:
# -------
# Debug : DEBUG=y RACK_ENV=production ruby scripts/base_script.rb FixRebinRmtMaterialOwnerPartyRole
# Live  : RACK_ENV=production ruby scripts/base_script.rb FixRebinRmtMaterialOwnerPartyRole
# Dev   : ruby scripts/base_script.rb FixRebinRmtMaterialOwnerPartyRole
#
class FixRebinRmtMaterialOwnerPartyRole < BaseScript
  attr_reader :rmt_bin_ids

  def run # rubocop:disable Metrics/AbcSize
    @rmt_bin_ids = DB[:rmt_bins]
                   .where(rmt_material_owner_party_role_id: nil)
                   .exclude(verified_from_carton_label_id: nil)
                   .select_map(%i[id verified_from_carton_label_id])
    return failed_response('There are no rmt bins to fix') if rmt_bin_ids.nil_or_empty?

    p "#{rmt_bin_ids.count} rmt_bins records to update."

    @text_data = []
    DB.transaction do
      rmt_bin_ids.each do |rmt_bin_id, carton_label_id|
        owner_party_role_id = resolve_owner_party_role_for_carton_label(carton_label_id)
        next if owner_party_role_id.nil?

        attrs = { rmt_material_owner_party_role_id: owner_party_role_id }
        str = "updated rmt_bin : #{rmt_bin_id} : #{attrs}"
        if debug_mode
          p str
        else
          @text_data << str
          DB[:rmt_bins].where(id: rmt_bin_id).update(attrs)
          log_status(:rmt_bins, rmt_bin_id, 'BIN_MATERIAL_OWNER_PARTY_ROLE_FIX', user_name: 'System')
        end
      end
    end

    infodump
    success_response('Rmt container material owner party role id updated successfully')
  end

  def resolve_owner_party_role_for_carton_label(carton_label_id)
    standard_pack_code_id = DB[:carton_labels].where(id: carton_label_id).get(:standard_pack_code_id)
    DB[:rmt_container_material_owners]
      .where(id: DB[:standard_pack_codes]
                   .where(id: standard_pack_code_id)
                   .get(:rmt_container_material_owner_id))
      .get(:rmt_material_owner_party_role_id)
  end

  def infodump
    infodump = <<~STR
      Script: FixRebinRmtMaterialOwnerPartyRole

      What this script does:
      ----------------------
      Fixes rmt_material_owner_party_role_id value on rebin rmt_bins
      Sets status of affected objects to BIN_MATERIAL_OWNER_PARTY_ROLE_FIX
      Bin asset control triggers will add the records in bin_asset_transactions_queue with event type BIN_MATERIAL_OWNER_CHANGED / REBIN_MATERIAL_OWNER_CHANGED

      Reason for this script:
      -----------------------
      Rebin verification was leaving the rmt_material_owner_party_role_id blank

      Results:
      --------
      data: Updated bins(#{rmt_bin_ids.join(',')})

      text data:
      #{@text_data.join("\n\n")}

    STR
    log_infodump(:data_fix,
                 :rmt_bins_rmt_material_owner_party_role_fix,
                 :fix_rmt_material_owner_party_role,
                 infodump)
  end
end
