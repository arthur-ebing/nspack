# frozen_string_literal: true

# What this script does:
# ----------------------
# Data fix  production_runs where allow_cultivar_mixing was set to true
# Updates production_run, carton_labels and pallet_sequences.
# sets allow_cultivar_mixing to false
# updates commodity_id and cultivar_id
#
# Reason for this script:
# -----------------------
# Some reason
#
# To run:
# -------
# Debug : DEBUG=y RACK_ENV=production ruby scripts/base_script.rb FixRunsWhereAllowCultivarMixingWasIncorrectlySet production_run_id cultivar_name
# Live  : RACK_ENV=production ruby scripts/base_script.rb FixRunsWhereAllowCultivarMixingWasIncorrectlySet production_run_id cultivar_name
# Dev   : ruby scripts/base_script.rb FixRunsWhereAllowCultivarMixingWasIncorrectlySet production_run_id cultivar_name
#
class FixRunsWhereAllowCultivarMixingWasIncorrectlySet < BaseScript
  def run # rubocop:disable Metrics/AbcSize
    parse_args
    status = 'REPLACE_CULTIVAR_FIX'
    @carton_label_ids = nil
    @pallet_sequence_ids = nil

    DB.transaction do
      cl = DB[:carton_labels].where(production_run_id: @production_run_id)
      @carton_label_ids = cl.select_map(:id).uniq
      p "@carton_label_ids: #{@carton_label_ids}"
      cl.update(cultivar_id: @cultivar_id)

      ps = DB[:pallet_sequences].where(production_run_id: @production_run_id)
      @pallet_sequence_ids = ps.select_map(:id).uniq
      p ''
      p "@pallet_sequence_ids: #{@pallet_sequence_ids}"
      pallet_ids = ps.select_map(:pallet_id).uniq
      ps.update(cultivar_id: @cultivar_id)
      log_multiple_statuses(:pallets, pallet_ids, status, user_name: 'System', comment: 'Run was incorrectly setup without cultivar_id')

      DB[:production_runs].where(id: @production_run_id).update(allow_cultivar_mixing: false, cultivar_id: @cultivar_id)
      log_status(:production_runs, @production_run_id, status, user_name: 'System', comment: 'Run was incorrectly setup without cultivar_id')

      raise Crossbeams::InfoError, 'Debug mode' if debug_mode
    end

    log_info

    success_response('Completed script')
  rescue Crossbeams::InfoError => e
    failed_response(e.message)
  end

  def parse_args
    @production_run_id = DB[:production_runs].where(id: args[0]).get(:id)
    raise ArgumentError, 'Production Run not found' if @production_run_id.nil?

    @cultivar_id = DB[:cultivars].where(cultivar_name: args[1]).get(:id)
    raise ArgumentError, 'Cultivar name not found' if @cultivar_id.nil?

    p "@production_run_id: #{@production_run_id}"
    p "@cultivar_id: #{@cultivar_id}"
  end

  def log_info
    infodump = <<~STR
      Script: FixRunsWhereAllowCultivarMixingWasIncorrectlySet

      What this script does:
      ----------------------
      Data fix  production_runs where allow_cultivar_mixing was set to true
      Updates production_run, carton_labels and pallet_sequences.
      sets allow_cultivar_mixing to false
      updates cultivar_id

      Reason for this script:
      -----------------------
      Data fix

      Input:
      ------
      @production_run_id: #{@production_run_id}
      @cultivar_name: #{args[1]}
      @cultivar_id: #{@cultivar_id}


      Results:
      --------
      Updated
      @carton_label_ids: #{@carton_label_ids.join(', ')}

      @pallet_sequence_ids: #{@pallet_sequence_ids.join(', ')}
    STR

    log_infodump(:production_run_fix,
                 :allow_cultivar_mixing,
                 :updated_labels_and_sequences,
                 infodump)
  end
end
