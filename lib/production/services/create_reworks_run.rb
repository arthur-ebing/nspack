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
      @pallets_affected = params[:pallets_affected].nil? ? pallets_selected : params[:pallets_affected]
      @affected_pallet_sequences = params[:pallet_sequence_id].nil? ? repo.find_pallet_ids_from_pallet_number(pallets_affected) : params[:pallet_sequence_id]
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

      res
    end

    private

    def build_reworks_run_booleans
      {
        scrap_pallets: scrap_pallets?,
        unscrap_pallets: unscrap_pallets?,
        repack_pallets: repack_pallets?
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

    def update_existing_record?
      case reworks_action
      when AppConst::REWORKS_ACTION_CLONE, AppConst::REWORKS_ACTION_REMOVE then
        false
      else
        true
      end
    end

    def create_reworks_run  # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity
      reworks_run_attrs = resolve_reworks_run_attrs
      repo.create_reworks_run(reworks_run_attrs.to_h)
      repo.reworks_run_clone_pallet(pallets_affected) if reworks_run_booleans[:repack_pallets]
      repo.update_reworks_run_pallets(pallets_affected, pallet_update_attrs, reworks_run_booleans) if reworks_run_booleans[:scrap_pallets] || reworks_run_booleans[:unscrap_pallets]
      repo.update_reworks_run_pallet_sequences(affected_pallet_sequences, changes[:after]) if make_changes && update_existing_record?

      ok_response
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def resolve_reworks_run_attrs  # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity,  Metrics/PerceivedComplexity
      {
        user: user_name,
        reworks_run_type_id: reworks_run_type[:id],
        scrap_reason_id: reworks_run_booleans[:scrap_pallets] ? scrap_reason_id : nil,
        remarks: reworks_run_booleans[:scrap_pallets] ? scrap_remarks : nil,
        pallets_selected: make_changes ? "{ #{pallets_selected.join(',')} }" : nil,
        pallets_affected: "{ #{pallets_affected.join(',')} }",
        changes_made: make_changes ? resolve_changes(pallets_affected) : nil,
        pallets_scrapped: reworks_run_booleans[:scrap_pallets] || reworks_run_booleans[:repack_pallets] ? "{ #{pallets_selected.join(',')} }" : nil,
        pallets_unscrapped: reworks_run_booleans[:unscrap_pallets] ? "{ #{pallets_selected.join(',')} }" : nil
      }
    end

    def resolve_changes(affected_pallets)
      changes = { reworks_action: reworks_action }
      affected_pallets.each  do |pallet_number|
        changes['pallets'] = {
          pallet_number: pallet_number
        }.merge(pallet_sequences_objects(pallet_number))
      end
      changes.to_json
    end

    def pallet_sequences_objects(pallet_number)
      pallet_seqs = Array(repo.where(:pallet_sequences, MesscadaApp::PalletSequence, id: affected_pallet_sequences) || repo.where(:pallet_sequences, MesscadaApp::PalletSequence, pallet_number: pallet_number))
      pallet_seqs_objs = {}
      pallet_seqs.each  do |pallet_sequence|
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
