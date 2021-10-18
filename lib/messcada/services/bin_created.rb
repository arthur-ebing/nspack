module MesscadaApp
  class PresortBinCreated < BaseService
    attr_reader :repo, :bin, :presorted_bin, :logger, :plant_resource_code

    def initialize(bin, plant_resource_code)
      @repo = RawMaterialsApp::PresortStagingRunRepo.new
      @bin = bin
      @plant_resource_code = plant_resource_code
      @logger = AppConst::PRESORT_BIN_CREATED_LOG
    end

    def call
      repo.transaction do
        validations
        representative_bin = get_main_bin_farm
        raise "multiple farms for bin[#{bin}] with no matching Code_adherent_max. #{presorted_bin.map { |bin| "record#{presorted_bin.index(bin) + 1}=(#{bin['Code_adherent']},#{bin['Code_adherent_max']})" }.join(',')}" unless representative_bin
        raise "Bin #{bin} creation ignored" if representative_bin['Nom_article'].to_s == 'Article 128' && (representative_bin['Palox_poids'].nil_or_empty? || representative_bin['Palox_poids'].to_i.zero?)

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

    def get_main_bin_farm
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

    def presorted_bin_exists
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
