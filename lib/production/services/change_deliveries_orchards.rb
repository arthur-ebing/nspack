# frozen_string_literal: true

module ProductionApp
  class ChangeDeliveriesOrchards < BaseService # rubocop:disable Metrics/ClassLength
    attr_reader :repo, :farm_repo, :cultivar_repo, :change_attrs, :reworks_run_attrs,
                :delivery_ids, :default_changes_to_apply,
                :production_runs, :tipped_bins, :cartons, :carton_labels, :pallet_sequences

    def initialize(change_attrs, reworks_run_attrs)
      @repo = ProductionApp::ReworksRepo.new
      @farm_repo = MasterfilesApp::FarmRepo.new
      @cultivar_repo = MasterfilesApp::CultivarRepo.new
      @change_attrs = change_attrs
      @reworks_run_attrs = reworks_run_attrs
      @delivery_ids = change_attrs[:delivery_ids]
      @default_changes_to_apply = { orchard_id: change_attrs[:to_orchard],
                                    cultivar_id: change_attrs[:to_cultivar] }
    end

    def call
      res = change_deliveries_orchards
      raise Crossbeams::InfoError, unwrap_failed_response(res) unless res.success

      ok_response
    end

    private

    def change_deliveries_orchards  # rubocop:disable Metrics/AbcSize
      res = validate_orchard_change_params(change_attrs)
      return validation_failed_response(res) unless res.messages.empty?

      res = validate_reworks_run_params(reworks_run_attrs)
      return validation_failed_response(res) unless res.messages.empty?

      reworks_run_attrs[:changes_made] = reworks_run_attrs[:changes_made].to_json
      from_attrs = { orchard_id: change_attrs[:from_orchard],
                     cultivar_id: change_attrs[:from_cultivar] }
      @production_runs = repo.deliveries_production_runs(delivery_ids, change_attrs[:ignore_runs_that_allow_mixing])
      @tipped_bins = DB[:rmt_bins].where(production_run_tipped_id: production_runs).where(from_attrs).select_map(:id)
      @carton_labels = DB[:carton_labels].where(production_run_id: production_runs).where(from_attrs).select_map(:id)
      @cartons = DB[:cartons].where(production_run_id: production_runs).where(from_attrs).select_map(:id)
      @pallet_sequences = DB[:pallet_sequences].where(production_run_id: production_runs).where(from_attrs).select_map(:id)

      errors = change_validations
      return failed_response(errors) unless errors.nil?

      res = update_orchard_changes
      return res unless res.success

      ok_response
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def validate_orchard_change_params(params)
      ReworksOrchardChangeSchema.call(params)
    end

    def validate_reworks_run_params(params)
      ReworksRunFlatSchema.call(params)
    end

    def change_validations # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      no_changes = change_attrs[:from_orchard] == change_attrs[:to_orchard] && change_attrs[:from_cultivar] == change_attrs[:to_cultivar]
      return 'Validation Error. Change has been aborted altogether. No Changes were made' if no_changes

      deliveries_farms = repo.deliveries_farms(delivery_ids)
      return 'Farm Error. Deliveries must all have the same farm' unless deliveries_farms.length == 1

      same_cultivar_group = deliveries_cultivar_group(change_attrs[:from_cultivar]) == deliveries_cultivar_group(change_attrs[:to_cultivar])
      return 'Cultivar Error: Cultivars must be within the same cultivar group' unless same_cultivar_group

      run_has_objects = run_object_exists?
      return nil unless run_has_objects

      return 'Production Run Error. Some bins in some of the deliveries are in production_runs that do not allow orchard mixing' unless change_attrs[:ignore_runs_that_allow_mixing] || allow_mixing?

      return 'Marketing Varieties Error. Some cultivar changes invalidates existing marketing_varieties' if run_has_objects && invalidates_marketing_varieties?
    end

    def deliveries_cultivar_group(cultivar_id)
      repo.deliveries_cultivar_group(cultivar_id)
    end

    def run_object_exists?
      if tipped_bins.nil_or_empty? && carton_labels.nil_or_empty? && cartons.nil_or_empty? && pallet_sequences.nil_or_empty?
        false
      else
        true
      end
    end

    def allow_mixing?
      return true if change_attrs[:allow_cultivar_mixing]

      return true if check_bins_production_runs_allow_mixing?

      false
    end

    def check_bins_production_runs_allow_mixing?
      repo.bins_production_runs_allow_mixing?(delivery_ids.join(','))
    end

    def invalidates_marketing_varieties?
      change_attrs[:ignore_runs_that_allow_mixing] && !change_attrs[:allow_cultivar_mixing] && repo.invalidates_marketing_varieties?(production_runs, change_attrs[:to_cultivar])
    end

    def update_orchard_changes  # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      # repo.transaction do
      unless reworks_run_attrs[:changes_made].nil_or_empty?
        send_bus_message("Cascading orchard change - updating #{delivery_ids.count} deliveries records", message_type: :information, target_user: reworks_run_attrs[:user_name])
        repo.update_delivery(delivery_ids, default_changes_to_apply)
        parent_id = create_reworks_run(delivery_ids, 'deliveries')
        repo.log_multiple_statuses(:rmt_deliveries, delivery_ids, AppConst::REWORKS_ACTION_CHANGE_DELIVERIES_ORCHARDS, user_name: reworks_run_attrs[:user_name])

        reworks_run_attrs[:parent_id] = parent_id
      end
      update_objects_changes(production_runs, 'production_runs') unless production_runs.nil_or_empty?
      update_objects_changes(tipped_bins, 'rmt_bins') unless tipped_bins.nil_or_empty?
      update_objects_changes(carton_labels, 'carton_labels') unless carton_labels.nil_or_empty?
      update_objects_changes(cartons, 'cartons') unless cartons.nil_or_empty?
      update_objects_changes(pallet_sequences, 'pallet_sequences') unless pallet_sequences.nil_or_empty?
      # end

      ok_response
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_objects_changes(pallets_selected, table_name)  # rubocop:disable Metrics/AbcSize
      res = calc_changes_made(table_name, pallets_selected)
      return unless res.success

      attrs = table_name == 'production_runs' ? default_changes_to_apply.merge(allow_cultivar_mixing: change_attrs[:allow_cultivar_mixing]) : default_changes_to_apply
      reworks_run_attrs[:changes_made] = res.instance.to_json

      send_bus_message("Cascading orchard change - updating #{pallets_selected.count} #{table_name} records", message_type: :information, target_user: reworks_run_attrs[:user_name])
      repo.update_objects(table_name, pallets_selected, attrs)
      create_reworks_run(pallets_selected, table_name)
      repo.log_multiple_statuses(table_name.to_s.to_sym, pallets_selected, AppConst::REWORKS_ACTION_CHANGE_DELIVERIES_ORCHARDS, user_name: reworks_run_attrs[:user_name])
    end

    def calc_changes_made(table_name, pallets_selected) # rubocop:disable Metrics/AbcSize
      to_orchard = change_attrs[:to_orchard]
      to_cultivar = change_attrs[:to_cultivar]

      orchard = farm_repo.find_farm_orchard_by_orchard_id(to_orchard)
      cultivar = cultivar_repo.find_cultivar(to_cultivar)&.cultivar_name

      changes = []
      repo.changes_made_objects(table_name, pallets_selected.join(',')).group_by { |h| h[:cultivar_name] }.each do |_k, v|
        change = { before: {}, after: {}, change_descriptions: { before: {}, after: {} } }

        if to_orchard != v[0][:orchard_id]
          change[:before].store(:orchard_id, v[0][:orchard_id])
          change[:after].store(:orchard_id, to_orchard)

          change[:change_descriptions][:before].store(:orchard, v[0][:farm_orchard_code])
          change[:change_descriptions][:after].store(:orchard, orchard)
        end

        if to_cultivar != v[0][:cultivar_id]
          change[:before].store(:cultivar_id, v[0][:cultivar_id])
          change[:after].store(:cultivar_id, to_cultivar)

          change[:change_descriptions][:before].store(:cultivar, v[0][:cultivar_name])
          change[:change_descriptions][:after].store(:cultivar, cultivar)
        end

        changes << change
      end

      return failed_response('No Changes were applied. No Changes were made') if changes.length == 1 && changes[0][:before].empty?

      changes_made = { pallets: { pallet_sequences: { changes: changes } } }
      success_response('ok', changes_made)
    end

    def create_reworks_run(pallets_selected, table_name)
      pallets_selected = table_name == 'pallet_sequences' ? repo.selected_pallet_numbers(pallets_selected) : pallets_selected

      reworks_run_attrs[:pallets_affected] = "{ #{pallets_selected.join(',')} }"
      reworks_run_attrs[:pallets_selected] = "{ #{pallets_selected.join(',')} }"
      reworks_run_attrs[:remarks] = table_name

      repo.create_reworks_run(reworks_run_attrs)
    end
  end
end
