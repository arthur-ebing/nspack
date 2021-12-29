# frozen_string_literal: true

module RawMaterialsApp
  class  ProcessBinAssetControlEvent < BaseService
    attr_reader :repo, :bin_event_type, :rmt_bin_ids, :changes_made, :set_attrs

    def initialize(params)
      @repo = RawMaterialsApp::BinAssetsRepo.new
      @bin_event_type = params[:bin_event_type]
      @rmt_bin_ids = Array(params[:rmt_bin_ids])
      @changes_made = params[:changes_made].nil_or_empty? ? {} : eval(params[:changes_made]) # rubocop:disable Security/Eval:
    end

    def call
      res = process_bin_asset_control_event
      raise Crossbeams::InfoError, unwrap_failed_response(res) unless res.success

      success_response('Bin Asset control event processed successfully')
    end

    private

    def process_bin_asset_control_event
      res = nil
      repo.bin_event_type_delivery_sets(bin_event_type, rmt_bin_ids).each do |set|
        res = perform_bin_asset_control_operation(set)
        return res unless res.success
      end
      ok_response
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def perform_bin_asset_control_operation(set)
      resolve_delivery_set_attrs(set)
      return reworks_bin_asset_control(set) if bin_event_type == 'BIN_PALLET_MATERIAL_OWNER_CHANGED'

      process_asset_move
    end

    def resolve_delivery_set_attrs(set) # rubocop:disable Metrics/AbcSize
      attrs = find_delivery_attrs(set)
      @set_attrs = {
        farm_location_id: get_farm_location_id(attrs[:farm_id]),
        dest_depot_location_id: get_dest_depot_location_id(set[:dest_depot_id]),
        owner_id: resolve_owner_id(set),
        quantity_bins: set[:quantity_bins].to_i,
        opts: { business_process_id: repo.get_id(:business_processes, process: AppConst::PROCESS_BIN_ASSET_CONTROL),
                parent_transaction_id: nil,
                asset_transaction_type_id: repo.get_id(:asset_transaction_types, transaction_type_code: bin_event_type),
                is_adhoc: false,
                fruit_reception_delivery_id: set[:rmt_delivery_id],
                truck_registration_number: attrs[:truck_registration_number],
                ref_no: attrs[:reference_number],
                quantity_bins: 1,
                changes_made: repo.hash_for_jsonb_col(changes_made),
                affected_rmt_bin_ids: repo.array_for_db_col(rmt_bin_ids) }
      }
    end

    def find_delivery_attrs(set)
      hash = repo.find_rmt_delivery_attrs(set[:rmt_delivery_id])
      return hash unless hash.nil?

      {
        farm_id: repo.get(:production_runs, set[:production_run_rebin_id], :farm_id),
        truck_registration_number: nil,
        reference_number: set[:production_run_rebin_id]
      }
    end

    def get_farm_location_id(farm_id)
      repo.get(:farms, farm_id, :location_id)
    end

    def get_dest_depot_location_id(dest_depot_id)
      repo.get_dest_depot_location_id(dest_depot_id)
    end

    def resolve_owner_id(attrs)
      repo.get_owner_id({ rmt_material_owner_party_role_id: attrs[:rmt_material_owner_party_role_id],
                          rmt_container_material_type_id: attrs[:rmt_container_material_type_id] })
    end

    def reworks_bin_asset_control(set) # rubocop:disable Metrics/AbcSize
      res = DestroyBinAssets.call({ owner_id: changes_made[:before].to_h[:owner_id],
                                    location_id: onsite_full_location_id,
                                    quantity: set_attrs[:quantity_bins] },
                                  set_attrs[:opts].to_h,
                                  true)
      return res unless res.success

      res = CreateBinAssets.call({ total_quantity: set_attrs[:quantity_bins],
                                   to_location_id: set_attrs[:farm_location_id],
                                   ref_no: set_attrs[:opts][:ref_no] },
                                 [set],
                                 set_attrs[:opts])
      return res unless res.success

      ok_response
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def process_asset_move
      res = reverse_previous_asset_move
      return res unless res.success

      res = MoveBinAssets.call({ owner_id: set_attrs[:owner_id],
                                 quantity: set_attrs[:quantity_bins],
                                 from_location_id: resolve_from_location_id,
                                 to_location_id: resolve_to_location_id },
                               set_attrs[:opts].to_h,
                               true)
      return res unless res.success

      ok_response
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def reverse_previous_asset_move # rubocop:disable Metrics/AbcSize
      return ok_response unless %w[FARM_CHANGED MATERIAL_OWNER_CHANGED REBIN_MATERIAL_OWNER_CHANGED].include?(bin_event_type)

      return ok_response if changes_made[:before].nil_or_empty?

      res = MoveBinAssets.call({ owner_id: resolve_previous_owner_id,
                                 quantity: set_attrs[:quantity_bins],
                                 from_location_id: resolve_previous_to_location_id,
                                 to_location_id: resolve_previous_from_location_id },
                               set_attrs[:opts].to_h,
                               true)
      return res unless res.success

      ok_response
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def resolve_previous_owner_id
      bin_event_type == 'FARM_CHANGED' ? set_attrs[:owner_id] : resolve_owner_id(changes_made[:before].to_h)
    end

    def resolve_previous_from_location_id
      case bin_event_type
      when 'FARM_CHANGED'
        get_farm_location_id(changes_made[:before].to_h[:farm_id])
      when 'REBIN_MATERIAL_OWNER_CHANGED'
        onsite_full_location_id
      else
        # MATERIAL_OWNER_CHANGED
        set_attrs[:farm_location_id]
      end
    end

    def resolve_previous_to_location_id
      bin_event_type == 'REBIN_MATERIAL_OWNER_CHANGED' ? onsite_empty_location_id : onsite_full_location_id
    end

    def onsite_empty_location_id
      repo.onsite_bin_asset_location_id_for_location_code(AppConst::ONSITE_EMPTY_BIN_LOCATION)
    end

    def onsite_full_location_id
      repo.onsite_bin_asset_location_id_for_location_code(AppConst::ONSITE_FULL_BIN_LOCATION)
    end

    def resolve_from_location_id
      case bin_event_type
      when 'REBIN_CREATED', 'BIN_UNTIPPED', 'REBIN_UNSCRAPPED'
        onsite_empty_location_id
      when 'BIN_DELETED', 'REBIN_DELETED', 'BIN_TIPPED', 'BIN_SCRAPPED', 'REBIN_SCRAPPED',
           'BIN_DISPATCHED_VIA_RMT', 'BIN_DISPATCHED_VIA_FG', 'REBIN_MATERIAL_OWNER_CHANGED'
        onsite_full_location_id
      when 'BIN_UNSHIPPED', 'BIN_UNSHIPPED_VIA_FG'
        set_attrs[:dest_depot_location_id]
      else
        # 'DELIVERY_RECEIVED', 'FARM_CHANGED', 'MATERIAL_OWNER_CHANGED', 'BIN_UNSCRAPPED'
        set_attrs[:farm_location_id]
      end
    end

    def resolve_to_location_id
      case bin_event_type
      when 'REBIN_DELETED', 'BIN_TIPPED', 'REBIN_SCRAPPED'
        onsite_empty_location_id
      when 'BIN_DELETED', 'BIN_SCRAPPED'
        set_attrs[:farm_location_id]
      when 'BIN_DISPATCHED_VIA_RMT', 'BIN_DISPATCHED_VIA_FG'
        set_attrs[:dest_depot_location_id]
      else
        # 'DELIVERY_RECEIVED', 'REBIN_CREATED', 'BIN_UNSHIPPED', 'BIN_UNTIPPED', 'FARM_CHANGED'
        # 'MATERIAL_OWNER_CHANGED', 'BIN_UNSCRAPPED', 'BIN_UNSHIPPED_VIA_FG', 'REBIN_UNSCRAPPED', 'REBIN_MATERIAL_OWNER_CHANGED'
        onsite_full_location_id
      end
    end
  end
end
