module RawMaterialsApp
  class PresortMafDataImport < BaseService # rubocop:disable Metrics/ClassLength
    attr_reader :repo, :maf_lot_number, :grading_pool_id, :user_name, :pool_farm_id, :maf_data_results

    def initialize(maf_lot_number, grading_pool_id, user_name)
      @repo = RawMaterialsApp::PresortGrowerGradingRepo.new
      @maf_lot_number = maf_lot_number
      @grading_pool_id = grading_pool_id
      @user_name = user_name
    end

    def call # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity
      return failed_response("Maf lot number : #{maf_lot_number} does not exist") unless repo.maf_lot_number_exists?(maf_lot_number)
      return failed_response("Maf lot number : #{maf_lot_number} does not have tipped bins") unless repo.grading_pool_bins_exists?(maf_lot_number)
      return failed_response("Presort Grading Pool for Maf lot number : #{maf_lot_number} does not exists") unless repo.grading_pool_exists?(maf_lot_number)

      resolve_maf_data
      return failed_response("Data for Maf Lot Number :#{maf_lot_number} not found in MAF") if maf_data_results.empty?
      return failed_response("INVALID FARM: Presort farm for Maf Lot Number :#{maf_lot_number} must be the same") unless same_pool_farm?

      import_maf_data
      res = "<maf_lot_numbers><maf_lot_number result_status=\"OK\" msg=\"imported maf data #{maf_lot_number}\" /></maf_lot_numbers>"
      AppConst::PRESORT_GROWER_GRADING_LOG.info(res)

      ok_response
    rescue Crossbeams::InfoError => e
      failed_response('error', error_xml(e.message))
    rescue StandardError => e
      ErrorMailer.send_exception_email(e, subject: "#{self.class.name} - #{e.message}", message: 'PresortMafDataImport Service.')
      puts e.message
      failed_response('error', error_xml(e.message))
    end

    private

    def resolve_maf_data # rubocop:disable Metrics/AbcSize
      maf_query = maf_data_sql
      parameters = { method: 'select', statement: Base64.encode64(maf_query) }
      http = Crossbeams::HTTPCalls.new(use_ssl: false)
      plant = maf_lot_number.to_i <= 100_000 ? 'PST-01' : 'PST-02'
      response = http.request_post("#{AppConst.mssql_production_interface(plant)}/select", parameters)
      unless response.success
        err = if response.instance.is_a?(String) && response.instance&.start_with?('<message>')
                "SQL Integration returned an error running : #{maf_query}. Message: #{response.instance.split('</message>').first.split('<message>').last}."
              else
                "SQL Integration returned an error running : #{maf_query}. Message: #{response.message}."
              end
        raise Crossbeams::InfoError, err
      end

      res = response.instance.body.split('resultset>').last.split('</res').first
      @maf_data_results = Marshal.load(Base64.decode64(res)) # rubocop:disable Security/MarshalLoad
    end

    def maf_data_sql
      <<~SQL
        SELECT Numero_lot AS maf_lot_number, Code_adherent AS maf_farm_code, Code_clone AS maf_rmt_code,
               Nom_article AS maf_article, Nom_calibre AS maf_count, SUM(Poids) AS maf_weight,
               Poids_total_calibre AS maf_lot_weight, Nb_palox AS maf_infeed_bin_qty
        FROM Viewlotapportresultat
        WHERE Numero_lot = '#{maf_lot_number}' AND Nom_article <> 'Recycling'
        GROUP BY Numero_lot, Code_adherent, Code_clone, Nom_article, Nom_calibre, Num_couleur, Poids_total_calibre, Nb_palox, Num_calibre
        ORDER BY Numero_lot, Num_couleur, Num_calibre
      SQL
    end

    def same_pool_farm?
      @pool_farm_id, pool_farm_code = repo.presort_grading_pool_farm_for(grading_pool_id)
      maf_data_results.reject { |r| r['maf_farm_code'] == pool_farm_code }.length.zero?
    end

    def import_maf_data
      rec = maf_data_results.first
      repo.update_presort_grower_grading_pool(grading_pool_id,
                                              { rmt_bin_count: rec['maf_infeed_bin_qty'],
                                                rmt_bin_weight: rec['maf_lot_weight'] })
      repo.log_status(:presort_grower_grading_pools, grading_pool_id, 'MAF_DATA_IMPORTED')

      res = create_presort_grading_bins
      return res unless res.success

      ok_response
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def create_presort_grading_bins # rubocop:disable Metrics/AbcSize
      defaults = { presort_grower_grading_pool_id: grading_pool_id,
                   farm_id: pool_farm_id,
                   created_by: user_name }
      maf_data_results.each do |data|
        res = validate_grading_bin_params(defaults.merge(resolve_maf_presort_bin_attrs(data)))
        return validation_failed_response(res) if res.failure?

        grading_bin_id = repo.look_for_existing_grading_bin_id(res)
        grading_bin_id.nil? ? repo.create_presort_grower_grading_bin(res) : repo.update_presort_grower_grading_bin(grading_bin_id, grading_bin_weight_attrs(grading_bin_id, res[:rmt_bin_weight]))
      end
      repo.log_multiple_statuses(:presort_grower_grading_bins, repo.presort_grower_grading_bin_ids(grading_pool_id), 'CREATED')
      ok_response
    end

    def resolve_maf_presort_bin_attrs(maf_bin) # rubocop:disable Metrics/AbcSize
      attrs = resolve_maf_bin_data(maf_bin['maf_article'], maf_bin['maf_count'])
      attrs.merge({ maf_rmt_code: maf_bin['maf_rmt_code'],
                    maf_weight: maf_bin['maf_weight'].to_f,
                    rmt_bin_weight: maf_bin['maf_weight'].to_f,
                    maf_tipped_quantity: maf_bin['maf_infeed_bin_qty'],
                    maf_total_lot_weight: maf_bin['maf_lot_weight'],
                    rmt_class_id: repo.get_id(:rmt_classes, rmt_class_code: attrs[:maf_class]),
                    treatment_id: repo.get_id(:treatments, treatment_code: attrs[:maf_colour]),
                    rmt_size_id: repo.get_id(:rmt_sizes, size_code: attrs[:maf_count]) })
    end

    def resolve_maf_bin_data(maf_article, maf_count)
      arr = maf_article.split('_')
      if maf_article.upcase.index('PESAGE')
        { maf_article: 'WASTE_ALL_PSG',
          maf_class: 'WASTE',
          maf_colour: 'ALL',
          maf_count: 'PSG',
          maf_article_count: 'PSG' }
      elsif arr[0] == '2L' || arr[0] == '3'
        { maf_article: maf_article,
          maf_class: arr[0],
          maf_colour: arr[1],
          maf_count: maf_count,
          maf_article_count: arr[2] }
      else
        arr.delete_at(2)
        arr.push(maf_count)
        { maf_article: arr.join('_'),
          maf_class: arr[0],
          maf_colour: arr[1],
          maf_count: maf_count,
          maf_article_count: arr[2] }
      end
    end

    def validate_grading_bin_params(params)
      NewPresortGrowerGradingBinSchema.call(params)
    end

    def duplicate_grading_bin?(hash)
      attrs = hash.to_h.reject { |k, _| %i[id active created_by updated_by created_at updated_at].include?(k) }
      repo.exists?(:presort_grower_grading_bins, attrs)
    end

    def grading_bin_weight_attrs(grading_bin_id, rmt_bin_weight)
      grading_bin_weight = (repo.get(:presort_grower_grading_bins, grading_bin_id, :maf_weight) + rmt_bin_weight)
      { maf_weight: grading_bin_weight, rmt_bin_weight: grading_bin_weight }
    end

    def error_xml(message)
      xml = "<result><error msg=\"#{message}\" /></result>"
      AppConst::PRESORT_GROWER_GRADING_LOG.error(xml)
      xml
    end
  end
end
