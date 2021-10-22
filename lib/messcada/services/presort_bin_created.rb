module MesscadaApp
  class PresortBinCreated < BaseService # rubocop:disable Metrics/ClassLength
    attr_reader :repo, :bin_asset_number, :presorted_bin, :logger, :plant_resource_code, :delivery_repo, :messcada_repo

    def initialize(bin_asset_number, plant_resource_code)
      @repo = RawMaterialsApp::PresortStagingRunRepo.new
      @delivery_repo = RawMaterialsApp::RmtDeliveryRepo.new
      @messcada_repo = MesscadaApp::MesscadaRepo.new
      @bin_asset_number = bin_asset_number
      @plant_resource_code = plant_resource_code
      @logger = AppConst::PRESORT_BIN_CREATED_LOG
    end

    def call # rubocop:disable Metrics/AbcSize,  Metrics/CyclomaticComplexity
      repo.transaction do
        validations
        representative_bin = main_bin_farm
        raise Crossbeams::InfoError, "multiple farms for bin[#{bin_asset_number}] with no matching Code_adherent_max. #{presorted_bin.map { |bin| "record#{presorted_bin.index(bin) + 1}=(#{bin['Code_adherent']},#{bin['Code_adherent_max']})" }.join(',')}" unless representative_bin
        raise Crossbeams::InfoError, "Bin:#{bin_asset_number} creation ignored. Bin is in progress" if representative_bin['Nom_article'].to_s == 'Article 128' && (representative_bin['Palox_poids'].nil_or_empty? || representative_bin['Palox_poids'].to_i.zero?)

        presorted_bin_staging_run = presorted_bin_staging_run(representative_bin['Numero_bon_apport'])
        raise Crossbeams::InfoError, "Presort Staging Run for child:#{representative_bin['Numero_bon_apport']} could not be found" unless presorted_bin_staging_run

        presorted_bin_has_different_nom_articles = !presorted_bin.map { |b| b['Nom_article'] }.uniq.one?
        presorted_bin_rmt_product_code = presorted_bin_rmt_product_code(representative_bin['Nom_article'], presorted_bin_staging_run, presorted_bin_has_different_nom_articles)

        bin_attributes = bin_attributes(representative_bin, presorted_bin_staging_run, presorted_bin_rmt_product_code)
        create_bin(bin_attributes)

        res = "<bins><bin result_status=\"OK\" msg=\"created bin #{bin_asset_number}\" /></bins>"
        logger.info(res)
        success_response('bin tipped result', res)
      end
    rescue Crossbeams::InfoError => e
      failed_response('error', error_xml(e.message))
    rescue StandardError => e
      ErrorMailer.send_exception_email(e, subject: "#{self.class.name} - #{e.message}", message: 'PresortBinCreated Service.')
      puts e.message
      failed_response('error', error_xml(e.message))
    end

    private

    def error_xml(message)
      xml = "<result><error msg=\"#{message}\" /></result>"
      logger.error(xml)
      xml
    end

    def create_bin(bin_attributes) # rubocop:disable Metrics/AbcSize
      bin_id = delivery_repo.create_rmt_bin(bin_attributes)
      repo.log_status(:rmt_bins, bin_id, "CREATED_IN_PRESORT_#{plant_resource_code}")
      return if presorted_bin.size == 1

      presorted_bin.each do |b|
        puc_code = repo.puc_code_for_farm(b['Code_adherent_max'])
        farm_mf = { farm_code: b['Code_adherent_max'] }
        farm_mf_res = MasterfilesApp::LookupMasterfileValues.call(farm_mf)
        raise Crossbeams::InfoError, farm_mf_res.message unless farm_mf_res.success

        orchard_mf = { farm_code: b['Code_adherent_max'],
                       puc_code: puc_code,
                       orchard_code: b['Code_parcelle'].split('_')[0] }
        orchard_mf_res = MasterfilesApp::LookupMasterfileValues.call(orchard_mf)
        orchard_id = orchard_mf_res.instance[:orchard_id] if orchard_mf_res.success

        id = repo.create_bin_sequence(rmt_bin_id: bin_id,
                                      nett_weight: b['Poids'],
                                      presort_run_lot_number: b['Numero_lot_max'],
                                      farm_id: farm_mf_res.instance[:farm_id],
                                      orchard_id: orchard_id)
        repo.log_status(:bin_sequences, id, 'CREATED')
      end
    end

    def bin_attributes(representative_bin, presorted_bin_staging_run, presorted_bin_rmt_product_code) # rubocop:disable Metrics/AbcSize
      rmt_container_material_type_id = repo.get_value(:rmt_container_material_types, :id, container_material_type_code: representative_bin['Code_article_caracteristique'])
      rmt_material_owner_party_role_id = repo.find_container_material_owner_by_container_material_type_and_org_code(rmt_container_material_type_id, AppConst::CR_RMT.default_container_material_owner)
      cultivar_group_id = repo.get_value(:cultivars, :cultivar_group_id, id: presorted_bin_staging_run[:cultivar_id])
      tare_weight = repo.get_value(:rmt_container_material_types, :tare_weight, id: rmt_container_material_type_id)
      location_id = repo.get_value(:plant_resources, :location_id, id: presorted_bin_staging_run[:presort_unit_plant_resource_id])
      bin_attrs = { season_id: presorted_bin_staging_run[:season_id],
                    presorted: true,
                    cultivar_id: presorted_bin_staging_run[:cultivar_id],
                    rmt_container_material_type_id: rmt_container_material_type_id,
                    rmt_material_owner_party_role_id: rmt_material_owner_party_role_id,
                    cultivar_group_id: cultivar_group_id,
                    bin_fullness: 'Full',
                    qty_bins: 1,
                    location_id: location_id,
                    bin_asset_number: bin_asset_number,
                    nett_weight: representative_bin['Palox_poids'],
                    gross_weight: tare_weight + representative_bin['Palox_poids'],
                    is_rebin: false,
                    main_presort_run_lot_number: representative_bin['Numero_lot_max'],
                    rmt_container_type_id: repo.get_value(:rmt_container_types, :id, container_type_code: AppConst::CR_RMT.default_rmt_container_type) }
      bin_attrs[:legacy_data] = { 'cold_store_type' => representative_bin['Code_frigo'],
                                  'numero_lot_max' => representative_bin['Numero_lot_max'],
                                  'treatment_code' => presorted_bin_rmt_product_code.split('_')[2],
                                  'track_slms_indicator1_code' => presorted_bin_staging_run[:legacy_data]['track_indicator_code'],
                                  'code_cumul' => representative_bin['Code_cumul'],
                                  'ripe_point_code' => presorted_bin_rmt_product_code.split('_')[4] }

      puc_code = repo.puc_code_for_farm(representative_bin['Code_adherent_max'])
      mfs = { farm_code: representative_bin['Code_adherent_max'],
              puc_code: puc_code,
              product_class_code: presorted_bin_rmt_product_code.split('_')[3],
              size_code: presorted_bin_rmt_product_code.split('_')[5],
              orchard_code: representative_bin['Code_parcelle'].split('_')[0] }
      mf_res = MasterfilesApp::LookupMasterfileValues.call(mfs)
      raise Crossbeams::InfoError, mf_res.message unless mf_res.success

      bin_attrs.merge!(mf_res.instance)
      bin_attrs
    end

    def presorted_bin_rmt_product_code(rep_nom_article, presorted_bin_staging_run, presorted_bin_has_different_nom_articles)
      commodity_code = repo.cultivar_commodity(presorted_bin_staging_run[:cultivar_id])
      cultivar_code = repo.get_value(:cultivars, :cultivar_code, id: presorted_bin_staging_run[:cultivar_id])
      ripe_point_code = presorted_bin_staging_run[:legacy_data]['ripe_point_code']
      return "#{commodity_code}_#{cultivar_code}_STD_PS_#{ripe_point_code}_MIX" if presorted_bin_has_different_nom_articles
      return "#{commodity_code}_#{cultivar_code}_ALL_ALL_#{ripe_point_code}_128" if rep_nom_article == 'Article 128'

      nom_article_components = rep_nom_article.split('_')
      "#{commodity_code}_#{cultivar_code}_#{nom_article_components[1]}_#{nom_article_components[0]}_#{ripe_point_code}_#{nom_article_components[2]}"
    end

    def presorted_bin_staging_run(numero_bon_apport)
      raise Crossbeams::InfoError, "Error:Presorted Bin:#{bin_asset_number}: ViewpaloxKromco.Numero_bon_apport does not have a value" unless numero_bon_apport

      repo.child_run_parent(numero_bon_apport)
    end

    def main_bin_farm
      no_weight_bin_farms = presorted_bin.find_all { |b| b['Poids'].nil_or_empty? }
      raise Crossbeams::InfoError, "Bin[#{no_weight_bin_farms.map { |f| f['Numero_palox'] }.uniq.join(',')}] does not have a value for weight. presort_lot_no[#{no_weight_bin_farms.map { |f| f['Numero_lot_max'] }.uniq.join(',')}]" unless no_weight_bin_farms.empty?

      presorted_bin.first
    end

    def validations
      bin_exists?
      presorted_bin_exists
    end

    def bin_exists?
      raise Crossbeams::InfoError, "Bin:#{bin_asset_number} already exists in Nspack"  if repo.exists?(:rmt_bins, bin_asset_number: bin_asset_number)
    end

    def presorted_bin_exists # rubocop:disable Metrics/AbcSize
      response = find_created_apport_bin(bin_asset_number)
      unless response.success
        err = if response.instance&.start_with?('<message>')
                "SQL Integration returned an error running : select * from ViewpaloxKromco where ViewpaloxKromco.Numero_palox=#{bin_asset_number}. Message: #{response.instance.split('</message>').first.split('<message>').last}."
              else
                "SQL Integration returned an error running : select * from ViewpaloxKromco where ViewpaloxKromco.Numero_palox=#{bin_asset_number}. Message: #{response.message}."
              end
        raise Crossbeams::InfoError, err
      end

      res = response.instance.body.split('resultset>').last.split('</res').first
      @presorted_bin = Marshal.load(Base64.decode64(res)) # rubocop:disable Security/MarshalLoad
      raise Crossbeams::InfoError, "Presorted Bin:#{bin_asset_number} not found in MAF" if @presorted_bin.empty?
    end

    def find_created_apport_bin(bin_asset_number)
      sql = "SELECT * FROM ViewpaloxKromco WHERE  ViewpaloxKromco.Numero_palox=#{bin_asset_number} ORDER BY Poids DESC"
      parameters = { method: 'select', statement: Base64.encode64(sql) }
      call_logger = Crossbeams::HTTPTextCallLogger.new('FIND-CREATED-APPORT-BIN', log_path: AppConst::PRESORT_BIN_CREATED_LOG_FILE)
      http = Crossbeams::HTTPCalls.new(call_logger: call_logger)
      http.request_post("#{AppConst.mssql_production_interface(plant_resource_code)}/select", parameters)
    end
  end
end
