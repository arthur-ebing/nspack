module RawMaterialsApp
  class BinIntegrationQueueProcessor < BaseService
    attr_reader :repo, :job_no

    def initialize(job_no)
      @repo = RmtDeliveryRepo.new
      @job_no = job_no
    end

    def call # rubocop:disable Metrics/AbcSize, Metrics/PerceivedComplexity
      repo.bin_integration_queue_snapshot(job_no).each do |b|
        repo.transaction do
          bin_attrs_res = bin_attributes(b[:bin_data])
          if bin_attrs_res.success
            existing_rmt_bin = repo.find_bin_by_asset_number(bin_attrs_res.instance[:bin_attrs][:bin_asset_number])
            if existing_rmt_bin.nil?
              id = repo.create_rmt_bin(bin_attrs_res.instance[:bin_attrs])
              repo.log_status(:rmt_bins, id, 'BIN CREATED FROM EXTERNAL SYSTEM')
            else
              repo.update_rmt_bin(existing_rmt_bin[:id], bin_attrs_res.instance[:bin_attrs]) unless existing_rmt_bin[:bin_tipped] || existing_rmt_bin[:staged_for_presorting]
            end
            repo.delete_bin_integration_queue_item(b[:id])
          else
            repo.log_bin_integration_queue_error(b[:id], bin_attrs_res.message)
          end
        end
      rescue StandardError => e
        repo.log_bin_integration_queue_error(b[:id], e.message, e.backtrace.join("\n"))
      end

      send_email_if_bin_errors(job_no)
    end

    private

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
      bin_attrs.delete_if { |k, _v| [:commodity_id].include?(k) }

      bin_columns = %w[bin_number weight is_half_bin bin_receive_date_time orchard_code farm_code product_class_code rmt_variety_code season_code size_code location_code commodity_id]
      bin_attrs[:legacy_data] = legacy_bin_data.delete_if { |k, _v| bin_columns.include?(k) }.to_json
      success_response('ok', { bin_attrs: bin_attrs, delivery_number: legacy_bin_data['delivery_number'] })
    end
  end
end
