module MesscadaApp
  class StageBins < BaseService
    attr_reader :repo, :delivery_repo, :bins, :plant_resource_code

    def initialize(bins, plant_resource_code)
      @repo = RawMaterialsApp::PresortStagingRunRepo.new
      @delivery_repo = RawMaterialsApp::RmtDeliveryRepo.new
      @bins = bins.compact
      @plant_resource_code = plant_resource_code
    end

    def call # rubocop:disable Metrics/AbcSize
      active_presort_staging_run_child_id = repo.running_child_run_for_plant_resource(plant_resource_code)
      bin_ids = repo.select_values(:rmt_bins, :id, bin_asset_number: bins)
      location_to_id = repo.get_value(:plant_resources, :location_id, plant_resource_code: plant_resource_code)
      delivery_repo.update_rmt_bin(bin_ids, presort_staging_run_child_id: active_presort_staging_run_child_id, staged_for_presorting_at: Time.now, staged_for_presorting: true)

      bin_ids.each do |b|
        res = FinishedGoodsApp::MoveStock.call(AppConst::BIN_STOCK_TYPE, b, location_to_id, AppConst::PRESORT_STAGING_BUSINESS_PROCESS, nil)
        raise unwrap_failed_response(res) unless res.success
      end

      CreateApportBins.call(bin_ids, active_presort_staging_run_child_id, plant_resource_code)
    end

    def self.result(bin_results)
      xml = '<result>'
      xml += "\n\t<bins>"
      bin_results.each do |results|
        attrs = get_bin_attributes(results).map { |key, value| key.to_s + '="' + value.to_s + '" ' }.join
        xml += "\n\t\t<bin#{results[:bin_item]} #{attrs}/>"
      end
      xml += "\n\t</bins>\n"
      xml += '</result>'
      AppConst::BIN_STAGING_LOG.info(xml)
      xml
    end

    def self.get_bin_attributes(results)
      attrs = {}
      if results[:status] == 'FAILED'
        attrs[:result_status] = 'ERR'
        attrs[:msg] = results[:errs].join("\n")
      else
        attrs[:result_status] = results[:status]
        attrs[:msg] = results[:msg] if results[:msg]
      end
      attrs
    end

    def self.error_xml(message)
      xml = "<result><error msg=\"#{message}\" /></result>"
      AppConst::BIN_STAGING_LOG.error(xml)
      xml
    end
  end
end
