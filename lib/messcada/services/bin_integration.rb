module MesscadaApp
  class BinIntegration < BaseService # rubocop:disable Metrics/ClassLength
    attr_reader :repo, :bin_number, :run_id

    def initialize(bin_number, run_id)
      @repo = MesscadaRepo.new
      @bin_number = bin_number
      @run_id = run_id
    end

    def call # rubocop:disable Metrics/AbcSize,  Metrics/CyclomaticComplexity
      if AppConst::CLIENT_CODE == 'kr'
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

      bin_attrs = { bin_asset_number: res.instance['bin_number'], nett_weight: res.instance['weight'], bin_fullness: 'Full', qty_bins: 1,
                    bin_received_date_time: res.instance['bin_receive_date_time'], rmt_container_type_id: repo.get_value(:rmt_container_types, :id, container_type_code: 'BIN') }

      mf_res = lookup_masterfiles({ farm_code: res.instance['farm_code'], orchard_code: res.instance['orchard_code'], product_class_code: res.instance['product_class_code'],
                                    size_code: res.instance['size_code'], rmt_variety_code: res.instance['rmt_variety_code'], season_code: res.instance['season_code'],
                                    location_code: res.instance['location_code'], commodity_code: res.instance['commodity_code'], puc_code: res.instance['puc_code'] })
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

      run_legacy_data = run.legacy_data.merge!({ 'farm_code' => run.farm_id, 'commodity_code' => repo.get_value(:cultivars, :commodity_id, id: run.cultivar_id),
                                                 'rmt_variety_code' => run.cultivar_id, 'season_code' => run.season_id })

      bin_mfs_res = lookup_masterfiles({ farm_code: res.instance['farm_code'], orchard_code: res.instance['orchard_code'], product_class_code: res.instance['product_class_code'],
                                         size_code: res.instance['size_code'], rmt_variety_code: res.instance['rmt_variety_code'], season_code: res.instance['season_code'],
                                         location_code: res.instance['location_code'], commodity_code: res.instance['commodity_code'], puc_code: res.instance['puc_code'] })
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

      del_mf_res = lookup_masterfiles({ farm_code: delivery_res.instance['farm_code'], orchard_code: delivery_res.instance['orchard_code'], commodity_code: delivery_res.instance['commodity_code'],
                                        rmt_variety_code: delivery_res.instance['rmt_variety_code'], season_code: delivery_res.instance['season_code'], puc_code: delivery_res.instance['puc_code'],
                                        destination_complex: delivery_res.instance['destination_complex'], delivery_destination_code: delivery_res.instance['destination_complex'] })
      return del_mf_res unless del_mf_res.success

      delivery_attrs.merge!(del_mf_res.instance)
      delivery_attrs.delete_if { |k, _v| k == :cultivar_group_id }

      del_columns = %w[date_delivered date_time_picked quantity_full_bins truck_registration_number farm_code rmt_variety_code destination_complex orchard_code season_code commodity_code puc_code]
      delivery_attrs[:legacy_data] = delivery_res.instance.delete_if { |k, _v| del_columns.include?(k) }.to_json
      success_response('ok', delivery_attrs)
    end

    def lookup_masterfiles(record) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity,  Metrics/PerceivedComplexity
      edi_repo = EdiApp::EdiInRepo.new
      return failed_response("Missing MF. Farm: #{record[:farm_code]}") unless !record.keys.include?(:farm_code) || ((farm_id = repo.get_value(:farms, :id, farm_code: record[:farm_code])) || (farm_id = edi_repo.get_variant_id(:farms, record[:farm_code])))
      return failed_response("Missing MF. PUC: #{record[:puc_code]} Farm: #{record[:farm_code]}") unless !record.keys.include?(:puc_code) || ((puc_id = MasterfilesApp::FarmRepo.new.find_puc_by_puc_code_and_farm(record[:puc_code], farm_id)) || (puc_id = MasterfilesApp::FarmRepo.new.find_puc_by_variant_and_farm(record[:puc_code], farm_id)))
      return failed_response("Missing MF. Orchard: #{record[:orchard_code]} PUC: #{record[:puc_code]} Farm: #{record[:farm_code]}") unless !record.keys.include?(:orchard_code) || ((orchard_id = repo.get_value(:orchards, :id, orchard_code: record[:orchard_code], farm_id: farm_id, puc_id: puc_id)) || (orchard_id = repo.find_orchard_by_variant_and_puc_and_farm(record[:orchard_code], puc_id, farm_id)))
      return failed_response("Missing MF. RmtClass: #{record[:product_class_code]}") unless !record.keys.include?(:product_class_code) || ((rmt_class_id = repo.get_value(:rmt_classes, :id, rmt_class_code: record[:product_class_code])) || (rmt_class_id = edi_repo.get_variant_id(:rmt_classes, record[:product_class_code])))

      return failed_response("Missing MF. Commodity: #{record[:commodity_code]}") unless !record.keys.include?(:commodity_code) || ((commodity_id = repo.get_value(:commodities, :id, code: record[:commodity_code])) || (commodity_id = edi_repo.get_variant_id(:commodities, record[:commodity_code])))

      return failed_response("Missing MF. Cultivar: #{record[:rmt_variety_code]} Commodity: #{record[:commodity_code]} Farm: #{record[:farm_code]} Orchard: #{record[:orchard_code]}") unless !record.keys.include?(:rmt_variety_code) || ((cultivar_id = MasterfilesApp::CultivarRepo.new.find_cultivar_by_cultivar_name_and_commodity_and_orchard(record[:rmt_variety_code], record[:commodity_code], orchard_id)) || (cultivar_id = MasterfilesApp::CultivarRepo.new.find_cultivar_by_variant_and_commodity_and_orchard(record[:rmt_variety_code], record[:commodity_code], orchard_id)))
      return failed_response("Missing MF. Season: #{record[:season_code]} Commodity: #{record[:commodity_code]}") unless !record.keys.include?(:season_code) || ((season_id = MasterfilesApp::CalendarRepo.new.find_cultivar_by_season_code_and_commodity_code(record[:season_code], record[:commodity_code])) || (season_id = MasterfilesApp::CalendarRepo.new.find_season_by_variant(record[:season_code], record[:commodity_code])))
      return failed_response("Missing MF. Size: #{record[:size_code]}") unless !record.keys.include?(:size_code) || ((size_id = repo.get_value(:rmt_sizes, :id, size_code: record[:size_code])) || (size_id = edi_repo.get_variant_id(:rmt_sizes, record[:size_code])))
      return failed_response("Missing MF. Location: #{record[:location_code]}") unless !record.keys.include?(:location_code) || ((location_id = repo.get_value(:locations, :id, location_short_code: record[:location_code])) || (location_id = edi_repo.get_variant_id(:locations, record[:location_code])))
      return failed_response("Missing MF. Delivery Destination: #{record[:delivery_destination_code]}") unless !record.keys.include?(:delivery_destination_code) || !AppConst::DELIVERY_USE_DELIVERY_DESTINATION || ((rmt_delivery_destination_id = repo.get_value(:rmt_delivery_destinations, :id, delivery_destination_code: record[:delivery_destination_code])) || (rmt_delivery_destination_id = edi_repo.get_variant_id(:rmt_delivery_destinations, record[:delivery_destination_code])))

      cultivar_group_id = repo.get_value(:cultivars, :cultivar_group_id, id: cultivar_id)
      mf = {}
      farm_id ? (mf[:farm_id] = farm_id) : nil
      orchard_id ? (mf[:orchard_id] = orchard_id) : nil
      rmt_class_id ? (mf[:rmt_class_id] = rmt_class_id) : nil
      commodity_id ? (mf[:commodity_id] = commodity_id) : nil
      cultivar_id ? (mf[:cultivar_id] = cultivar_id) : nil
      cultivar_group_id ? (mf[:cultivar_group_id] = cultivar_group_id) : nil
      season_id ? (mf[:season_id] = season_id) : nil
      size_id ? (mf[:rmt_size_id] = size_id) : nil
      location_id ? (mf[:location_id] = location_id) : nil
      puc_id ? (mf[:puc_id] = puc_id) : nil
      rmt_delivery_destination_id ? (mf[:rmt_delivery_destination_id] = rmt_delivery_destination_id) : nil
      success_response('ok', mf)
    end
  end
end
