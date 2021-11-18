# frozen_string_literal: true

# What this script does:
# ----------------------
# Accepts an old rmt_container_material_type_id and a new mt_container_material_type_id and changes the value on rmt_bins to new mt_container_material_type_id
# Sets status of affected objects to BIN_MATERIAL_MF_FIX_FROM: <old code> TO: <new code>
# Bin asset control triggers will add the records in bin_asset_transactions_queue with event type BIN_MATERIAL_OWNER_CHANGED / REBIN_MATERIAL_OWNER_CHANGED
#
# Reason for this script:
# -----------------------
# Quick way to change rmt_container_material_type_id on rmt_bins from A to B
#
# To run:
# -------
# Debug : DEBUG=y RACK_ENV=production ruby scripts/base_script.rb ChangeRmtContainerMaterialType from_material_type_id to_material_type_id
# Live  : RACK_ENV=production ruby scripts/base_script.rb ChangeRmtContainerMaterialType from_material_type_id to_material_type_id
# Dev   : ruby scripts/base_script.rb ChangeRmtContainerMaterialType from_material_type_id to_material_type_id
#
class ChangeRmtContainerMaterialType < BaseScript
  attr_reader :from_material_type_id, :to_material_type_id, :rmt_bin_ids

  def run # rubocop:disable Metrics/AbcSize
    resolve_args

    @rmt_bin_ids = DB[:rmt_bins]
                   .where(rmt_container_material_type_id: from_material_type_id)
                   .select_map(:id).uniq
    p "#{rmt_bin_ids.count} rmt_bins records to update."

    str = "updated rmt_bins : #{rmt_bin_ids.join(',')} : #{{ rmt_container_material_type_id: to_material_type_id }}"
    if debug_mode
      p str
    else
      DB.transaction do
        DB[:rmt_bins].where(id: rmt_bin_ids).update({ rmt_container_material_type_id: to_material_type_id }) unless rmt_bin_ids.nil_or_empty?
        log_multiple_statuses(:rmt_bins, rmt_bin_ids, "BIN_MATERIAL_MF_FIX_FROM: #{from_material_type_id} TO: #{to_material_type_id}", user_name: 'System')
      end
    end

    infodump(str)
    success_response('Rmt container material type updated successfully')
  end

  def resolve_args # rubocop:disable Metrics/AbcSize
    @from_material_type_id = DB[:rmt_container_material_types].where(id: args[0]).get(:id)
    raise ArgumentError, "Rmt container material type with id: #{args[0]} does not exist" if from_material_type_id.nil?

    @to_material_type_id = DB[:rmt_container_material_types].where(id: args[1]).get(:id)
    raise ArgumentError, "Rmt container material type with id: #{args[1]} does not exist" if to_material_type_id.nil?

    p "from_material_type_id: #{from_material_type_id}"
    p "to_material_type_id: #{to_material_type_id}"

    raise ArgumentError, 'From and To container material type cannot be the same' if from_material_type_id == to_material_type_id
  end

  def infodump(str)
    infodump = <<~STR
      Script: ChangeRmtContainerMaterialType

      What this script does:
      ----------------------
      Accepts an old rmt_container_material_type_id and a new mt_container_material_type_id and changes the value on rmt_bins to new mt_container_material_type_id
      Sets status of affected objects to BIN_MATERIAL_MF_FIX_FROM: <old code> TO: <new code>
      Bin asset control triggers will add the records in bin_asset_transactions_queue with event type BIN_MATERIAL_OWNER_CHANGED / REBIN_MATERIAL_OWNER_CHANGED

      Reason for this script:
      -----------------------
      Quick way to change rmt_container_material_type_id on rmt_bins from A to B

      Results:
      --------
      Updated

      #{str}

    STR
    log_infodump(:data_fix,
                 :rmt_bins_rmt_container_material_type_change,
                 :change_rmt_container_material_type,
                 infodump)
  end
end
