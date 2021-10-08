module MesscadaApp
  class CreateApportBins < BaseService
    attr_reader :repo, :delivery_repo, :bins, :presort_staging_child_run_id, :http, :plant_resource_code

    def initialize(bins, presort_staging_child_run_id, plant_resource_code)
      @bins = bins
      @presort_staging_child_run_id = presort_staging_child_run_id
      @repo = RawMaterialsApp::PresortStagingRunRepo.new
      @delivery_repo = RawMaterialsApp::RmtDeliveryRepo.new
      @plant_resource_code = plant_resource_code
      @http = Crossbeams::HTTPCalls.new(use_ssl: false, call_logger: call_logger)
    end

    def call # rubocop:disable Metrics/AbcSize
      inserts = []
      bins.each do |bin_id|
        bin = delivery_repo.find_rmt_bin_flat(bin_id)
        response = find_stale_staged_untipped_apport_bin(bin[:bin_asset_number])
        if response.success
          res = response.instance.body.split('resultset>').last.split('</res').first
          results = Marshal.load(Base64.decode64(res)) # rubocop:disable Security/MarshalLoad
          unless results.empty?
            response = delete_stale_staged_untipped_apport_bin(bin[:bin_asset_number])
            unless response.success
              msg = response.message
              err = "Could not delete Apport bin record. Sql error: delete from Apport where NumPalox = '#{bin[:bin_asset_number]}' and LotMAF is null and DateLecture is null and StatusMAF is null. Message: #{msg}."
              raise err
            end
          end
        else
          msg = response.message
          err = "Failed to lookup Apport stale staged and untipped apport_bin: select * from Apport where NumPalox = '#{bin[:bin_asset_number]}' and LotMAF is null and DateLecture is null and StatusMAF is null. Message: #{msg}."
          raise err
        end

        code_apporteur, code_parcelle, nom_parcelle = calc_code_apporteur_and_code_parcelle_and_nom_parcelle(bin)
        inserts << <<~SQL
          INSERT INTO Apport (NumPalox,DateApport,CodeParcelle,CodeVariete,
          CodeApporteur,CodeEmballage,Nombre,Poids,
          NumApport,TypeTraitement,NomParcelle,NomVariete,
          NomApporteur,CodeEspece,NomEspece,
          Partie,Year,Free_int1,Free_int2,Free_string1,
          Free_string2,Free_string3)
          VALUES('#{bin[:bin_asset_number]}',getdate(),'#{code_parcelle}','#{bin[:legacy_data]['track_slms_indicator_1_code']}'
          ,'#{code_apporteur}','#{bin[:container_material_type_code]}','#{bin[:id]}','#{bin[:nett_weight]}'
          ,'#{presort_staging_child_run_id}','#{bin[:legacy_data]['treatment_code']}','#{nom_parcelle}','#{bin[:legacy_data]['track_slms_indicator_1_description']}'
          ,'#{bin[:farm_description]}','#{bin[:commodity_code]}','#{bin[:commodity_description]}'
          ,'#{bin[:production_run_rebin_id]}','#{bin[:season_year]}',NULL,'#{bin[:season_year]}','#{bin[:cultivar_name]}'
          ,'#{bin[:farm_group_id]}',NULL);\n
        SQL
      end
      return if inserts.empty?

      response = create_apport_bin(inserts)
      return if response.success

      msg = response.message
      err = "SQL Integration returned an error running : INSERT INTO Apport. Message: #{msg}."
      raise err
    end

    private

    def mssql_server_uri_for_presort_unit
      return AppConst::PRESORT1_MSSQL_SERVER_INTERFACE if plant_resource_code == 'PST-01'

      AppConst::PRESORT2_MSSQL_SERVER_INTERFACE
    end

    def find_stale_staged_untipped_apport_bin(bin_asset_number)
      sql = "select * from Apport where NumPalox = '#{bin_asset_number}' and LotMAF is null and DateLecture is null and StatusMAF is null"
      parameters = { method: 'select', statement: Base64.encode64(sql) }
      http.request_post("#{mssql_server_uri_for_presort_unit}/select", parameters)
    end

    def delete_stale_staged_untipped_apport_bin(bin_asset_number)
      sql = "delete from Apport where NumPalox = '#{bin_asset_number}' and LotMAF is null and DateLecture is null and StatusMAF is null"
      parameters = { method: 'delete', statement: Base64.encode64(sql) }
      http.request_post("#{mssql_server_uri_for_presort_unit}/exec", parameters)
    end

    def calc_code_apporteur_and_code_parcelle_and_nom_parcelle(bin) # rubocop:disable Metrics/AbcSize
      child_run_farm_code = repo.child_run_farm(presort_staging_child_run_id)
      season_year = repo.get_value(:seasons, :season_year, id: bin[:season_id])
      if child_run_farm_code.upcase == '0P'
        code_apporteur = '0P'
        code_parcelle = "0P_#{bin[:legacy_data]['track_slms_indicator_1_code']}"
        nom_parcelle = "0P_#{bin[:legacy_data]['track_slms_indicator_1_code']}"
      else
        code_apporteur = bin[:farm_code]
        if season_year == 2014
          nom_parcelle = "#{bin[:farm_code]}_#{bin[:legacy_data]['track_slms_indicator_1_code']}"
          code_parcelle = "#{bin[:farm_code]}_#{bin[:legacy_data]['track_slms_indicator_1_code']}"
        else
          nom_parcelle = "#{bin[:orchard_code]}_#{bin[:farm_code]}_#{bin[:legacy_data]['track_slms_indicator_1_code']}"
          code_parcelle = "#{bin[:orchard_code]}_#{bin[:farm_code]}_#{bin[:legacy_data]['track_slms_indicator_1_code']}"
        end
      end
      [code_apporteur, code_parcelle, nom_parcelle]
    end

    def create_apport_bin(inserts)
      insert_ql = "BEGIN TRANSACTION\n #{inserts.join} COMMIT TRANSACTION"
      parameters = { method: 'insert', statement: Base64.encode64(insert_ql) }
      http.request_post("#{mssql_server_uri_for_presort_unit}/exec", parameters)
    end

    def call_logger
      Crossbeams::HTTPTextCallLogger.new('CREATE-APPORT-BIN', log_path: AppConst::BIN_STAGING_LOG_FILE)
    end
  end
end
