# frozen_string_literal: true

module ProductionApp
  class CreateReworksRun < BaseService # rubocop:disable Metrics/ClassLength
    attr_reader :repo, :user_name, :reworks_run_type, :pallets_selected, :pallets_affected,
                :scrap_reason_id, :scrap_remarks, :make_changes,  :reworks_run_booleans, :reworks_action, :changes,
                :affected_pallet_sequences, :allow_cultivar_group_mixing

    def initialize(params, reworks_action, changes)  # rubocop:disable Metrics/AbcSize
      @repo = ProductionApp::ReworksRepo.new
      @user_name = params[:user]
      @reworks_run_type = @repo.where_hash(:reworks_run_types, id: params[:reworks_run_type_id])
      @pallets_selected = params[:pallets_selected]
      @pallets_affected = params[:pallets_affected].nil_or_empty? ? pallets_selected : params[:pallets_affected]
      @affected_pallet_sequences = if params[:affected_sequences].nil_or_empty?
                                     params[:pallet_sequence_id].nil_or_empty? ? repo.find_sequence_ids_from_pallet_number(pallets_affected) : params[:pallet_sequence_id]
                                   else
                                     params[:affected_sequences]
                                   end
      @allow_cultivar_group_mixing = params[:allow_cultivar_group_mixing].nil? ? false : params[:allow_cultivar_group_mixing]
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

      if reworks_run_booleans[:scrap_pallets] || reworks_run_booleans[:unscrap_pallets]
        res = move_stock_pallet
        return res unless res.success
      end
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
      AppConst::RUN_TYPE_TIP_BINS == reworks_run_type[:run_type] || AppConst::RUN_TYPE_UNTIP_BINS == reworks_run_type[:run_type] || AppConst::RUN_TYPE_WEIGH_RMT_BINS == reworks_run_type[:run_type] || AppConst::RUN_TYPE_BULK_WEIGH_BINS == reworks_run_type[:run_type]
    end

    def recalc_nett_weight?
      AppConst::RUN_TYPE_RECALC_NETT_WEIGHT == reworks_run_type[:run_type]
    end

    def create_reworks_run  # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity,  Metrics/PerceivedComplexity
      reworks_run_attrs = resolve_reworks_run_attrs
      id = repo.create_reworks_run(reworks_run_attrs.to_h)
      attrs = pallet_update_attrs
      repo.repacking_reworks_run(pallets_affected, user_name, attrs) if reworks_run_booleans[:repack_pallets]
      repo.scrapping_reworks_run(pallets_affected, attrs, reworks_run_booleans, user_name) if reworks_run_booleans[:scrap_pallets] || reworks_run_booleans[:unscrap_pallets]
      repo.update_pallets_pallet_format(pallets_affected.first) if make_changes && reworks_run_booleans[:single_edit]
      # repo.existing_records_batch_update(pallets_affected, affected_pallet_sequences, changes[:after]) if make_changes && reworks_run_booleans[:batch_edit]
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
        pallets_unscrapped: reworks_run_booleans[:unscrap_pallets] ? "{ #{pallets_selected.join(',')} }" : nil,
        allow_cultivar_group_mixing: allow_cultivar_group_mixing
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
          pallet_number: pallet_number,
          pallet_sequence_ids: "{ #{Array(affected_pallet_sequences).join(',')} }"
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

    def move_stock_pallet  # rubocop:disable Metrics/AbcSize
      location_long_code = if reworks_run_booleans[:scrap_pallets]
                             AppConst::SCRAP_LOCATION
                           elsif reworks_run_booleans[:unscrap_pallets]
                             AppConst::UNSCRAP_LOCATION
                           end
      location_to_id = MasterfilesApp::LocationRepo.new.find_location_by_location_long_code(location_long_code)&.id
      return failed_response('Location does not exist') if location_to_id.nil_or_empty?

      pallet_ids = repo.find_pallet_ids_from_pallet_number(pallets_affected)
      pallet_ids.each  do |pallet_id|
        res = FinishedGoodsApp::MoveStockService.call(AppConst::PALLET_STOCK_TYPE, pallet_id, location_to_id, AppConst::REWORKS_MOVE_PALLET_BUSINESS_PROCESS, nil)
        return res unless res.success
      end

      ok_response
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end
  end
end
