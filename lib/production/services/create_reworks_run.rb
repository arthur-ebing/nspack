# frozen_string_literal: true

module ProductionApp
  class CreateReworksRun < BaseService # rubocop:disable ClassLength
    attr_reader :repo, :user_name, :reworks_run_type, :pallets_selected, :pallets_affected,
                :scrap_reason_id, :scrap_remarks, :make_changes,  :reworks_run_booleans, :reworks_action, :changes,
                :affected_pallet_sequences

    def initialize(params, reworks_action, changes)  # rubocop:disable Metrics/AbcSize
      @repo = ProductionApp::ReworksRepo.new
      @user_name = params[:user]
      @reworks_run_type = @repo.where_hash(:reworks_run_types, id: params[:reworks_run_type_id])
      @pallets_selected = params[:pallets_selected]
      @pallets_affected = params[:pallets_affected].nil_or_empty? ? pallets_selected : params[:pallets_affected]
      @affected_pallet_sequences = params[:pallet_sequence_id].nil_or_empty? ? repo.find_sequence_ids_from_pallet_number(pallets_affected) : params[:pallet_sequence_id]
      @make_changes = params[:make_changes]
      @reworks_action = reworks_action
      @changes = changes
      @reworks_run_booleans = build_reworks_run_booleans
      return unless reworks_run_booleans[:scrap_pallets]

      @scrap_reason_id = params[:scrap_reason_id]
      @scrap_remarks = params[:remarks]
    end

    def call
      res = create_reworks_run
      raise Crossbeams::InfoError, unwrap_failed_response(res) unless res.success

      success_response('ok', reworks_run_id: res.instance[:reworks_run_id])
    end

    private

    def build_reworks_run_booleans
      {
        scrap_pallets: scrap_pallets?,
        unscrap_pallets: unscrap_pallets?,
        repack_pallets: repack_pallets?,
        single_edit: single_edit?,
        batch_edit: batch_edit?,
        rmt_bin_change: rmt_bin_change?,
        recalc_nett_weight: recalc_nett_weight?
      }
    end

    def scrap_pallets?
      AppConst::RUN_TYPE_SCRAP_PALLET == reworks_run_type[:run_type]
    end

    def unscrap_pallets?
      AppConst::RUN_TYPE_UNSCRAP_PALLET == reworks_run_type[:run_type]
    end

    def repack_pallets?
      AppConst::RUN_TYPE_REPACK == reworks_run_type[:run_type]
    end

    def single_edit?
      AppConst::REWORKS_ACTION_SINGLE_EDIT == reworks_action
    end

    def batch_edit?
      AppConst::REWORKS_ACTION_BATCH_EDIT == reworks_action
    end

    def rmt_bin_change?
      AppConst::RUN_TYPE_TIP_BINS == reworks_run_type[:run_type] || AppConst::RUN_TYPE_WEIGH_RMT_BINS == reworks_run_type[:run_type]
    end

    def recalc_nett_weight?
      AppConst::RUN_TYPE_RECALC_NETT_WEIGHT == reworks_run_type[:run_type]
    end

    def create_reworks_run  # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity,  Metrics/PerceivedComplexity
      reworks_run_attrs = resolve_reworks_run_attrs
      id = repo.create_reworks_run(reworks_run_attrs.to_h)
      attrs = pallet_update_attrs
      repo.repacking_reworks_run(pallets_affected, attrs) if reworks_run_booleans[:repack_pallets]
      repo.scrapping_reworks_run(pallets_affected, attrs, reworks_run_booleans) if reworks_run_booleans[:scrap_pallets] || reworks_run_booleans[:unscrap_pallets]
      repo.update_pallets_pallet_format(pallets_affected.first) if make_changes && reworks_run_booleans[:single_edit]
      repo.existing_records_batch_update(pallets_affected, affected_pallet_sequences, changes[:after]) if make_changes && reworks_run_booleans[:batch_edit]
      repo.update_pallets_recalc_nett_weight(pallets_affected, user_name) if reworks_run_booleans[:recalc_nett_weight]

      success_response('ok', reworks_run_id: id)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def resolve_reworks_run_attrs  # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity
      {
        user: user_name,
        reworks_run_type_id: reworks_run_type[:id],
        scrap_reason_id: reworks_run_booleans[:scrap_pallets] ? scrap_reason_id : nil,
        remarks: reworks_run_booleans[:scrap_pallets] ? scrap_remarks : nil,
        pallets_selected: resolve_pallets_selected,
        pallets_affected: "{ #{pallets_affected.join(',')} }",
        changes_made: reworks_run_booleans[:rmt_bin_change] ? resolve_bin_changes : resolve_pallet_changes,
        pallets_scrapped: reworks_run_booleans[:scrap_pallets] || reworks_run_booleans[:repack_pallets] ? "{ #{pallets_selected.join(',')} }" : nil,
        pallets_unscrapped: reworks_run_booleans[:unscrap_pallets] ? "{ #{pallets_selected.join(',')} }" : nil
      }
    end

    def resolve_pallets_selected
      return nil if reworks_run_booleans[:scrap_pallets] || reworks_run_booleans[:unscrap_pallets] || reworks_run_booleans[:repack_pallets]

      "{ #{pallets_selected.join(',')} }"
    end

    def resolve_bin_changes
      bin_changes = {}
      bin_changes['pallets'] = { pallet_sequences: { changes: changes } }
      bin_changes.to_json
    end

    def resolve_pallet_changes
      return nil unless make_changes

      sequence_changes = { reworks_action: reworks_action }
      pallets_affected.each  do |pallet_number|
        sequence_changes['pallets'] = {
          pallet_number: pallet_number
        }.merge(pallet_sequences_objects(pallet_number))
      end
      sequence_changes.to_json
    end

    def pallet_sequences_objects(_pallet_number)
      pallet_seqs_objs = {}
      Array(affected_pallet_sequences).each  do |pallet_sequence_id|
        pallet_sequence = repo.where(:pallet_sequences, MesscadaApp::PalletSequence, id: pallet_sequence_id)
        pallet_seqs_objs['pallet_sequences'] = {
          pallet_id: pallet_sequence[:pallet_id],
          pallet_number: pallet_sequence[:pallet_number],
          pallet_sequence_number: pallet_sequence[:pallet_sequence_number],
          changes: changes
        }
      end
      pallet_seqs_objs
    end

    def pallet_update_attrs
      attrs = {}
      attrs = attrs.merge(scrapped: true, scrapped_at: Time.now, exit_ref: AppConst::PALLET_EXIT_REF_SCRAPPED)  if reworks_run_booleans[:scrap_pallets] || reworks_run_booleans[:repack_pallets]
      attrs = attrs.merge(scrapped: false, scrapped_at: nil, exit_ref: nil) if reworks_run_booleans[:unscrap_pallets]
      attrs
    end

    def reworks_run(id)
      repo.find_reworks_run(id)
    end
  end
end
