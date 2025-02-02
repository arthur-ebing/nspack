# frozen_string_literal: true

module ProductionApp
  class ChangeRunCultivar < BaseService
    attr_reader :repo, :cultivar_repo, :params, :user_name, :before_state, :production_run_id

    def initialize(params, user_name)
      @repo = ProductionApp::ReworksRepo.new
      @cultivar_repo = MasterfilesApp::CultivarRepo.new
      @params = params
      @user_name = user_name
      @production_run_id = params[:production_run_id]
      @before_state = resolve_production_run_before_state
    end

    def call
      res = change_run_cultivar
      raise Crossbeams::InfoError, unwrap_failed_response(res) unless res.success

      ok_response
    end

    private

    def change_run_cultivar # rubocop:disable Metrics/AbcSize
      repo.transaction do
        arr = %i[cultivar_id allow_cultivar_mixing reconfiguring setup_complete]
        repo.update_production_run(production_run_id,
                                   params.to_h.slice(*arr))
        parent_id = repo.create_reworks_run(resolve_reworks_run_attrs)
        repo.log_status(:production_runs, production_run_id, AppConst::REWORKS_ACTION_CHANGE_RUN_CULTIVAR)

        change_attrs = params.to_h.slice(:cultivar_id)
        objects_reworks_run_attrs = resolve_reworks_run_attrs(parent_id)
        update_objects_changes('carton_labels',
                               repo.production_run_object_ids('carton_labels', params),
                               change_attrs,
                               objects_reworks_run_attrs)
        update_objects_changes('pallet_sequences', # scrapped???
                               repo.production_run_object_ids('pallet_sequences', params),
                               change_attrs,
                               objects_reworks_run_attrs)

        ReExecuteRun.call(production_run_id, user_name) if params[:labeling]
      end

      ok_response
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def resolve_production_run_before_state
      run = ProductionApp::ProductionRunRepo.new.find_production_run(production_run_id)
      {
        cultivar_id: run[:cultivar_id],
        allow_cultivar_mixing: run[:allow_cultivar_mixing],
        reconfiguring: run[:reconfiguring],
        setup_complete: run[:setup_complete]
      }
    end

    def resolve_reworks_run_attrs(parent_id = nil) # rubocop:disable Metrics/AbcSize
      arr = %i[allow_cultivar_mixing reconfiguring setup_complete]
      extra_after_state = parent_id.nil? ? params.to_h.slice(*arr) : {}
      extra_before_state = parent_id.nil? ? before_state.to_h.slice(*arr) : {}
      {
        parent_id: parent_id,
        user: user_name,
        pallets_affected: "{ #{Array(production_run_id).join(',')} }",
        pallets_selected: "{ #{Array(production_run_id).join(',')} }",
        reworks_run_type_id: params[:reworks_run_type_id],
        changes_made: resolve_changes_made(before: { cultivar_id: before_state[:cultivar_id] }.merge(extra_before_state).to_h,
                                           after: params.to_h.slice(:cultivar_id).merge(extra_after_state).to_h,
                                           change_descriptions: { before: { cultivar_name: cultivar_repo.find_cultivar(before_state[:cultivar_id])&.cultivar_name }.merge(extra_before_state).to_h,
                                                                  after: { cultivar_name: cultivar_repo.find_cultivar(params[:cultivar_id])&.cultivar_name }.merge(extra_after_state).to_h })
      }
    end

    def resolve_changes_made(changes_made)
      changes = {}
      changes['pallets'] = { pallet_sequences: { changes: changes_made } }
      changes.to_json
    end

    def update_objects_changes(table_name, object_ids, attrs, reworks_run_attrs)
      return if object_ids.nil_or_empty?

      reworks_run_attrs[:pallets_affected] = "{ #{object_ids.join(',')} }"
      reworks_run_attrs[:pallets_selected] = "{ #{object_ids.join(',')} }"
      reworks_run_attrs[:remarks] = table_name
      repo.update_objects(table_name, object_ids, attrs)
      repo.create_reworks_run(reworks_run_attrs)
      repo.log_multiple_statuses(table_name.to_s.to_sym, object_ids, AppConst::REWORKS_ACTION_CHANGE_RUN_CULTIVAR, user_name: user_name)
    end
  end
end
