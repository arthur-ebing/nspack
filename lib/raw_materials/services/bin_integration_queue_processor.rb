module RawMaterialsApp
  class BinIntegrationQueueProcessor < BaseService
    attr_reader :repo, :job_no

    def initialize(job_no)
      @repo = RmtDeliveryRepo.new
      @job_no = job_no
    end

    def call # rubocop:disable Metrics/AbcSize, Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
      repo.bin_integration_queue_snapshot(job_no).each do |b|
        repo.transaction do
          delivery_id = nil
          unless b[:delivery_data].nil_or_empty?
            del_attrs_res = delivery_attributes(b[:delivery_data])
            if del_attrs_res.success
              delivery_id = create_update_delivery(del_attrs_res.instance)
            else
              repo.log_bin_integration_queue_error(b[:id], del_attrs_res.message, true, false)
            end
          end

          if del_attrs_res&.success || b[:delivery_data].nil_or_empty?
            bin_attrs_res = bin_attributes(b[:bin_data])
            if bin_attrs_res.success
              create_update_bin(bin_attrs_res.instance[:bin_attrs], delivery_id)
              repo.delete_bin_integration_queue_item(b[:id])
            else
              repo.log_bin_integration_queue_error(b[:id], bin_attrs_res.message, false, true)
            end
          end
        end
      rescue StandardError => e
        repo.log_bin_integration_queue_error(b[:id], e.message, nil, nil, e.backtrace.join("\n"))
      end

      repo.send_email_if_bin_errors(job_no)
    end

    private

    def create_update_delivery(del_attrs)
      delivery_number = JSON.parse(del_attrs[:legacy_data])['delivery_number']
      delivery_id = MesscadaApp::MesscadaRepo.new.find_external_bin_delivery(delivery_number)
      if delivery_id.nil?
        delivery_id = RawMaterialsApp::RmtDeliveryRepo.new.create_rmt_delivery(del_attrs)
        repo.log_status(:rmt_deliveries, delivery_id, 'DELIVERY CREATED FROM EXTERNAL SYSTEM')
      else
        repo.update_rmt_delivery(delivery_id, del_attrs)
      end
      delivery_id
    end

    def create_update_bin(bin_attrs, delivery_id)
      existing_rmt_bin = repo.find_bin_by_asset_number(bin_attrs[:bin_asset_number])
      if existing_rmt_bin.nil?
        bin_attrs[:rmt_delivery_id] = delivery_id
        id = repo.create_rmt_bin(bin_attrs)
        repo.log_status(:rmt_bins, id, 'BIN CREATED FROM EXTERNAL SYSTEM')
      else
        repo.update_rmt_bin(existing_rmt_bin[:id], bin_attrs) unless existing_rmt_bin[:bin_tipped] || existing_rmt_bin[:staged_for_presorting]
      end
    end

    def bin_attributes(legacy_bin_data) # rubocop:disable Metrics/AbcSize
      bin_attrs = { bin_asset_number: legacy_bin_data['bin_number'], nett_weight: legacy_bin_data['weight'],
                    bin_fullness: AppConst::BIN_FULL, qty_bins: 1, bin_received_date_time: legacy_bin_data['bin_receive_date_time'],
                    rmt_container_type_id: repo.get_value(:rmt_container_types, :id, container_type_code: 'BIN') }

      fields = %i[farm_code orchard_code product_class_code size_code rmt_variety_code season_code location_code commodity_code puc_code]
      hash = Hash[fields.zip(fields.map { |f| legacy_bin_data[f.to_s] })]
      hash[:container_material_type_code] = legacy_bin_data['pack_material_product_code']
      mf_res = MasterfilesApp::LookupMasterfileValues.call(hash)
      return mf_res unless mf_res.success

      bin_attrs.merge!(mf_res.instance)
      bin_attrs[:rmt_material_owner_party_role_id] = repo.find_rmt_container_material_owner_by_container_material_type(bin_attrs[:rmt_container_material_type_id])
      bin_attrs.delete_if { |k, _v| [:commodity_id].include?(k) }

      bin_columns = %w[bin_number weight is_half_bin bin_receive_date_time orchard_code farm_code product_class_code rmt_variety_code season_code size_code location_code commodity_id]
      bin_attrs[:legacy_data] = legacy_bin_data.delete_if { |k, _v| bin_columns.include?(k) }.to_json
      success_response('ok', { bin_attrs: bin_attrs, delivery_number: legacy_bin_data['delivery_number'] })
    end

    def delivery_attributes(legacy_delivery_data) # rubocop:disable Metrics/AbcSize
      delivery_attrs = { date_delivered: legacy_delivery_data['date_delivered'], date_picked: legacy_delivery_data['date_time_picked'],
                         quantity_bins_with_fruit: legacy_delivery_data['quantity_full_bins'], truck_registration_number: legacy_delivery_data['truck_registration_number'] }

      fields = %i[farm_code orchard_code rmt_variety_code season_code commodity_code puc_code]
      hash = Hash[fields.zip(fields.map { |f| legacy_delivery_data[f.to_s] })]
      hash[:delivery_destination_code] = legacy_delivery_data['destination_complex']
      del_mf_res = MasterfilesApp::LookupMasterfileValues.call(hash)
      return del_mf_res unless del_mf_res.success

      delivery_attrs.merge!(del_mf_res.instance)
      delivery_attrs.delete_if { |k, _v| %i[commodity_id cultivar_group_id].include?(k) }

      del_columns = %w[date_delivered date_time_picked quantity_full_bins truck_registration_number farm_code rmt_variety_code destination_complex orchard_code season_code commodity_code puc_code]
      delivery_attrs[:legacy_data] = legacy_delivery_data.delete_if { |k, _v| del_columns.include?(k) }.to_json
      success_response('ok', delivery_attrs)
    end
  end
end
