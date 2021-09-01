module MesscadaApp
  class BinIntegration < BaseService
    attr_reader :repo, :bin_number, :run_id

    def initialize(bin_number, run_id)
      @repo = MesscadaRepo.new
      @bin_number = bin_number
      @run_id = run_id
    end

    def call # rubocop:disable Metrics/AbcSize,  Metrics/CyclomaticComplexity
      if AppConst::CR_RMT.check_external_bin_valid_for_integration?
        res = valid_bin_for_kromco_rmt_system?
        return res unless res.success
      end

      bin_attrs_res = bin_attributes
      return bin_attrs_res unless bin_attrs_res.success

      repo.transaction do
        unless bin_attrs_res.instance[:delivery_number].nil_or_empty? || (delivery_id = repo.find_external_bin_delivery(bin_attrs_res.instance[:delivery_number]))
          delivery_attrs_res = delivery_attributes(bin_attrs_res.instance[:delivery_number])
          return delivery_attrs_res unless delivery_attrs_res.success

          delivery_attrs_res.instance.delete_if { |k, _v| [:commodity_id].include?(k) }
          delivery_id = RawMaterialsApp::RmtDeliveryRepo.new.create_rmt_delivery(delivery_attrs_res.instance)
          repo.log_status(:rmt_deliveries, delivery_id, 'DELIVERY CREATED FROM EXTERNAL SYSTEM')
        end

        bin_attrs_res.instance[:bin_attrs][:rmt_delivery_id] = delivery_id
        bin_attrs_res.instance[:bin_attrs].delete_if { |k, _v| [:commodity_id].include?(k) }
        id = RawMaterialsApp::RmtDeliveryRepo.new.create_rmt_bin(bin_attrs_res.instance[:bin_attrs])
        repo.log_status(:rmt_bins, id, 'BIN CREATED FROM EXTERNAL SYSTEM')
      end

      ok_response
    end

    def valid_bin_for_kromco_rmt_system?
      res = repo.can_bin_be_tipped?(bin_number)
      return res unless res.success

      bintip_criteria_passed?
    end

    def bin_attributes # rubocop:disable Metrics/AbcSize
      res = repo.fetch_bin_from_external_system(bin_number)
      return res unless res.success

      bin_attrs = { bin_asset_number: res.instance['bin_number'], nett_weight: res.instance['weight'], bin_fullness: AppConst::BIN_FULL, qty_bins: 1,
                    bin_received_date_time: res.instance['bin_receive_date_time'], rmt_container_type_id: repo.get_value(:rmt_container_types, :id, container_type_code: 'BIN') }

      fields = %i[farm_code orchard_code product_class_code size_code rmt_variety_code season_code location_code commodity_code puc_code]
      hash = Hash[fields.zip(fields.map { |f| res.instance[f.to_s] })]
      hash[:container_material_type_code] = res.instance['pack_material_product_code']
      mf_res = MasterfilesApp::LookupMasterfileValues.call(hash)
      return mf_res unless mf_res.success

      bin_attrs.merge!(mf_res.instance)

      bin_columns = %w[bin_number weight is_half_bin bin_receive_date_time orchard_code farm_code product_class_code rmt_variety_code season_code size_code location_code commodity_id]
      bin_attrs[:legacy_data] = res.instance.delete_if { |k, _v| bin_columns.include?(k) }.to_json
      success_response('ok', { bin_attrs: bin_attrs, delivery_number: res.instance['delivery_number'] })
    end

    private

    def bintip_criteria_passed? # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      run = ProductionApp::ProductionRunRepo.new.find_production_run_flat(run_id)
      return failed_response("Bin Tipping Criteria Not Setup For Run:#{run_id}") unless run.legacy_bintip_criteria
      return failed_response("Bin Tipping Legacy Data Not Setup For Run:#{run_id}") unless run.legacy_data

      res = repo.fetch_bin_from_external_system(bin_number)
      return res unless res.success

      run_legacy_data = run.legacy_data.merge!({ 'farm_code' => run.farm_id, 'commodity_code' => repo.get_value(:cultivar_groups, :commodity_id, id: run.cultivar_group_id),
                                                 'rmt_variety_code' => run.cultivar_id, 'season_code' => run.season_id })

      fields = %i[farm_code orchard_code product_class_code size_code rmt_variety_code season_code location_code commodity_code puc_code]
      hash = Hash[fields.zip(fields.map { |f| res.instance[f.to_s] })]
      bin_mfs_res = MasterfilesApp::LookupMasterfileValues.call(hash)
      return bin_mfs_res unless bin_mfs_res.success

      bin_legacy_data = { 'rmt_size' => res.instance['size_code'], 'treatment_code' => res.instance['rmtp_treatment_code'], 'pc_code' => res.instance['pc_name'],
                          'track_indicator_code' => res.instance['track_slms_indicator_1_code'], 'ripe_point_code' => res.instance['ripe_point_code'], 'rmt_product_type' => res.instance['rmt_product_type_code'],
                          'farm_code' => bin_mfs_res.instance[:farm_id], 'commodity_code' => bin_mfs_res.instance[:commodity_id], 'rmt_variety_code' => bin_mfs_res.instance[:cultivar_id], 'season_code' => bin_mfs_res.instance[:season_id],
                          'product_class_code' => res.instance['product_class_code'], 'cold_store_type' => res.instance['cold_store_type_code'] }

      run.legacy_bintip_criteria.find_all { |_k, v| v == 't' }.each do |c|
        mf_keys = %w[farm_code commodity_code rmt_variety_code season_code]
        unless bin_legacy_data[c[0]] == run_legacy_data[c[0]] # rubocop:disable Style/Next
          run_legacy_data_code = if mf_keys.include?(c[0])
                                   c[0] == 'rmt_variety_code' ? run[:cultivar_name] : run[c[0].to_sym]
                                 else
                                   run_legacy_data[c[0]]
                                 end
          return failed_response("Tipping Criteria Fails. Bin #{c[0]}: '#{mf_keys.include?(c[0]) ? res.instance[c[0]] : bin_legacy_data[c[0]]}'. Run requires #{c[0]}: '#{run_legacy_data_code}'")
        end
      end

      success_response('ok')
    end

    def delivery_attributes(delivery_number) # rubocop:disable Metrics/AbcSize
      delivery_res = repo.fetch_delivery_from_external_system(delivery_number)
      return delivery_res unless delivery_res.success

      delivery_attrs = { date_delivered: delivery_res.instance['date_delivered'], date_picked: delivery_res.instance['date_time_picked'],
                         quantity_bins_with_fruit: delivery_res.instance['quantity_full_bins'], truck_registration_number: delivery_res.instance['truck_registration_number'] }

      fields = %i[farm_code orchard_code rmt_variety_code season_code commodity_code puc_code]
      hash = Hash[fields.zip(fields.map { |f| delivery_res.instance[f.to_s] })]
      hash[:delivery_destination_code] = delivery_res.instance['destination_complex']
      del_mf_res = MasterfilesApp::LookupMasterfileValues.call(hash)
      return del_mf_res unless del_mf_res.success

      delivery_attrs.merge!(del_mf_res.instance)
      delivery_attrs.delete_if { |k, _v| k == :cultivar_group_id }

      del_columns = %w[date_delivered date_time_picked quantity_full_bins truck_registration_number farm_code rmt_variety_code destination_complex orchard_code season_code commodity_code puc_code]
      delivery_attrs[:legacy_data] = delivery_res.instance.delete_if { |k, _v| del_columns.include?(k) }.to_json
      success_response('ok', delivery_attrs)
    end
  end
end
