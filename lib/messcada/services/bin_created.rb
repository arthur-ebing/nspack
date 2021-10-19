module MesscadaApp
  class PresortBinCreated < BaseService # rubocop:disable Metrics/ClassLength
    attr_reader :repo, :bin, :presorted_bin, :logger, :plant_resource_code, :delivery_repo

    def initialize(bin, plant_resource_code)
      @repo = RawMaterialsApp::PresortStagingRunRepo.new
      @delivery_repo = RawMaterialsApp::RmtDeliveryRepo.new
      @bin = bin
      @plant_resource_code = plant_resource_code
      @logger = AppConst::PRESORT_BIN_CREATED_LOG
    end

    def call # rubocop:disable Metrics/AbcSize,  Metrics/CyclomaticComplexity
      repo.transaction do
        validations
        representative_bin = main_bin_farm
        raise "multiple farms for bin[#{bin}] with no matching Code_adherent_max. #{presorted_bin.map { |bin| "record#{presorted_bin.index(bin) + 1}=(#{bin['Code_adherent']},#{bin['Code_adherent_max']})" }.join(',')}" unless representative_bin
        raise "Bin:#{bin} creation ignored" if representative_bin['Nom_article'].to_s == 'Article 128' && (representative_bin['Palox_poids'].nil_or_empty? || representative_bin['Palox_poids'].to_i.zero?)

        presorted_bin_staging_run = presorted_bin_staging_run(representative_bin['Numero_bon_apport'])
        raise "Presort Staging Run for child:#{representative_bin['Numero_bon_apport']} could not be found" unless presorted_bin_staging_run

        presorted_bin_has_different_nom_articles = !presorted_bin.map { |b| b['Nom_article'] }.uniq.one?
        presorted_bin_rmt_product_code = presorted_bin_rmt_product_code(representative_bin['Nom_article'], presorted_bin_staging_run, presorted_bin_has_different_nom_articles)
        rmt_container_material_type_id = repo.get_value(:rmt_container_material_types, :id, container_material_type_code: representative_bin['Code_article_caracteristique'])
        rmt_material_owner_party_role_id = repo.find_container_material_owner_by_container_material_type_and_org_code(rmt_container_material_type_id, AppConst::CR_RMT.default_container_material_owner)

        bin_attributes = bin_attributes(representative_bin, presorted_bin_staging_run, presorted_bin_rmt_product_code, rmt_container_material_type_id)
        bin_attributes.merge!(rmt_material_owner_party_role_id: rmt_material_owner_party_role_id)

        id = delivery_repo.create_rmt_bin(bin_attributes)
        repo.log_status(:rmt_bins, id, "CREATED_IN_PRESORT_#{plant_resource_code}")

        res = "<bins><bin result_status=\"OK\" msg=\"created bin #{bin}\" /></bins>"
        logger.info(res)
        success_response('bin tipped result', res)
      end
    rescue StandardError => e
      failed_response('error', error_xml(e.message))
    end

    private

    def error_xml(message)
      xml = "<result><error msg=\"#{message}\" /></result>"
      logger.error(xml)
      xml
    end

    def bin_attributes(representative_bin, presorted_bin_staging_run, presorted_bin_rmt_product_code, rmt_container_material_type_id) # rubocop:disable Metrics/AbcSize
      orchard_id = representative_bin['Code_parcelle'].split('_')[0]
      raise "Missing MF. Orchard Id: #{orchard_id}" unless repo.exists?(:orchards, id: orchard_id)

      cultivar_group_id = repo.get_value(:cultivars, :cultivar_group_id, id: presorted_bin_staging_run[:cultivar_id])
      tare_weight = repo.get_value(:rmt_container_material_types, :tare_weight, id: rmt_container_material_type_id)
      location_id = repo.get_value(:plant_resources, :location_id, id: presorted_bin_staging_run[:presort_unit_plant_resource_id])
      bin_attrs = { season_id: presorted_bin_staging_run[:season_id],
                    cultivar_id: presorted_bin_staging_run[:cultivar_id],
                    rmt_container_material_type_id: rmt_container_material_type_id,
                    cultivar_group_id: cultivar_group_id,
                    bin_fullness: 'Full',
                    qty_bins: 1,
                    location_id: location_id,
                    bin_asset_number: bin,
                    nett_weight: representative_bin['Palox_poids'],
                    gross_weight: tare_weight + representative_bin['Palox_poids'],
                    is_rebin: false,
                    main_presort_run_lot_number: representative_bin['Numero_lot_max'],
                    orchard_id: orchard_id }
      bin_attrs[:legacy_data] = { 'cold_store_type' => representative_bin['Code_frigo'],
                                  'numero_lot_max' => representative_bin['Numero_lot_max'],
                                  'treatment_code' => presorted_bin_rmt_product_code.split('_')[2],
                                  'track_slms_indicator1_code' => presorted_bin_staging_run[:legacy_data]['track_indicator_code'],
                                  'code_cumul' => representative_bin['Code_cumul'],
                                  'ripe_point_code' => presorted_bin_rmt_product_code.split('_')[4] }

      mfs = { farm_code: representative_bin['Code_adherent_max'],
              product_class_code: presorted_bin_rmt_product_code.split('_')[3],
              size_code: presorted_bin_rmt_product_code.split('_')[5] }
      mf_res = MasterfilesApp::LookupMasterfileValues.call(mfs)
      raise mf_res.message unless mf_res.success

      bin_attrs.merge!(mf_res.instance)
      bin_attrs
    end

    def presorted_bin_rmt_product_code(rep_nom_article, presorted_bin_staging_run, presorted_bin_has_different_nom_articles)
      commodity_code = repo.cultivar_commodity(presorted_bin_staging_run[:cultivar_id])
      rmt_variety_code = repo.get_value(:cultivars, :cultivar_code, id: presorted_bin_staging_run[:cultivar_id])
      ripe_point_code = presorted_bin_staging_run[:legacy_data]['ripe_point_code']
      return "#{commodity_code}_#{rmt_variety_code}_STD_PS_#{ripe_point_code}_MIX" if presorted_bin_has_different_nom_articles
      return "#{commodity_code}_#{rmt_variety_code}_ALL_ALL_#{ripe_point_code}_128" if rep_nom_article == 'Article 128'

      nom_article_components = rep_nom_article.split('_')
      "#{commodity_code}_#{rmt_variety_code}_#{nom_article_components[1]}_#{nom_article_components[0]}_#{ripe_point_code}_#{nom_article_components[2]}"
    end

    def presorted_bin_staging_run(numero_bon_apport)
      raise "Error:Presorted Bin:#{bin}: ViewpaloxKromco.Numero_bon_apport does not have a value" unless numero_bon_apport

      repo.child_run_parent(numero_bon_apport)
    end

    def main_bin_farm # rubocop:disable Metrics/AbcSize
      no_weight_bin_farms = presorted_bin.find_all { |b| b['Poids'].nil_or_empty? }
      raise "Bin[#{no_weight_bin_farms.map { |f| f['Numero_palox'] }.uniq.join(',')}] does not have a value for weight. presort_lot_no[#{no_weight_bin_farms.map { |f| f['Numero_lot_max'] }.uniq.join(',')}]" unless no_weight_bin_farms.empty?

      presorted_bin.min { |x, y| y['Poids'] <=> x['Poids'] }
    end

    def validations
      bin_exists?
      presorted_bin_exists
    end

    def bin_exists?
      raise "Bin:#{bin} already exists in Nspack"  if repo.exists?(:rmt_bins, bin_asset_number: bin)
    end

    def presorted_bin_exists # rubocop:disable Metrics/AbcSize
      response = find_created_apport_bin(bin)
      unless response.success
        msg = response.message
        err = "SQL Integration returned an error running : select * from ViewpaloxKromco where ViewpaloxKromco.Numero_palox=#{bin}. The http code is #{response.code}. Message: #{msg}."
        raise err
      end

      res = response.instance.body.split('resultset>').last.split('</res').first
      @presorted_bin = Marshal.load(Base64.decode64(res)) # rubocop:disable Security/MarshalLoad
      raise Crossbeams::InfoError, "Presorted Bin:#{bin} not found in MAF" if @presorted_bin.empty?
    end

    def find_created_apport_bin(bin_asset_number)
      sql = "select * from ViewpaloxKromco where  ViewpaloxKromco.Numero_palox=#{bin_asset_number}"
      parameters = { method: 'select', statement: Base64.encode64(sql) }
      call_logger = Crossbeams::HTTPTextCallLogger.new('FIND-CREATED-APPORT-BIN', log_path: AppConst::PRESORT_BIN_CREATED_LOG_FILE)
      http = Crossbeams::HTTPCalls.new(use_ssl: false, call_logger: call_logger)
      http.request_post("#{AppConst.mssql_server_interface(plant_resource_code)}/select", parameters)
    end
  end
end
