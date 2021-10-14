module MesscadaApp
  class BinCreated < BaseService
    attr_reader :repo, :bin, :logger

    def initialize(bin)
      @repo = RawMaterialsApp::PresortStagingRunRepo.new
      @bin = bin
      @logger = AppConst::BIN_CREATED_LOG
    end

    def call
      repo.transaction do
        validations

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

    def validations
      bin_exists?
      presorted_bin_exists?
    end

    def bin_exists?
      raise "Bin:#{bin} already exists in Nspack"  if repo.exists?(:rmt_bins, bin_asset_number: bin)
    end

    def presorted_bin_exists?
      response = find_created_apport_bin(bin)
      unless response.success
        msg = response.message
        err = "SQL Integration returned an error running : select * from ViewpaloxKromco where ViewpaloxKromco.Numero_palox=#{bin}. The http code is #{response.code}. Message: #{msg}."
        raise err
      end
    end

    def find_created_apport_bin(bin_asset_number)
      sql = "select * from ViewpaloxKromco where  ViewpaloxKromco.Numero_palox=#{bin_asset_number}"
      parameters = { method: 'select', statement: Base64.encode64(sql) }
      call_logger = Crossbeams::HTTPTextCallLogger.new('FIND-CREATED-APPORT-BIN', log_path: AppConst::BIN_CREATED_LOG_FILE)
      http = Crossbeams::HTTPCalls.new(use_ssl: false, call_logger: call_logger)
      http.request_post("#{AppConst::BIN_CREATED_MSSQL_SERVER_INTERFACE}/select", parameters)
    end
  end
end
