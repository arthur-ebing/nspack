module MesscadaApp
  class PresortBinTipped < BaseService
    attr_reader :repo, :bin, :tipped_apport_bin, :bin_id, :plant_resource_code

    def initialize(bin, plant_resource_code)
      @repo = RawMaterialsApp::PresortStagingRunRepo.new
      @bin = bin
      @plant_resource_code = plant_resource_code
    end

    def call # rubocop:disable Metrics/AbcSize
      repo.transaction do
        validations
        tip_bin
        res = "<bins><bin result_status=\"OK\" msg=\"tipped bin #{bin}\" /></bins>"
        AppConst::PRESORT_BIN_TIPPED_LOG.info(res)
        success_response('bin tipped result', res)
      end
    rescue Crossbeams::InfoError => e
      failed_response('error', error_xml(e.message))
    rescue StandardError => e
      ErrorMailer.send_exception_email(e, subject: "#{self.class.name} - #{e.message}", message: 'PresortBinTipped Service.')
      puts e.message
      failed_response('error', error_xml(e.message))
    end

    private

    def error_xml(message)
      xml = "<result><error msg=\"#{message}\" /></result>"
      AppConst::PRESORT_BIN_TIPPED_LOG.error(xml)
      xml
    end

    def tip_bin
      updates = { tipped_asset_number: bin, bin_asset_number: nil, bin_tipped_date_time: Time.now, exit_ref: 'TIPPED_IN_PRESORT', bin_tipped: true,
                  presort_tip_lot_number: @tipped_apport_bin['LotMAF'], tipped_in_presort_at: Time.now, exit_ref_date_time: Time.now }
      RawMaterialsApp::RmtDeliveryRepo.new.update_rmt_bin(bin_id, updates)
      repo.log_status(:rmt_bins, bin_id, 'TIPPED_IN_PRESORT')
    end

    def validations
      bin_exists?
      apport_bin_exists?
    end

    def bin_exists?
      @bin_id = repo.validate_bin_exists(bin)
    end

    def apport_bin_exists? # rubocop:disable Metrics/AbcSize
      response = repo.find_tipped_apport_bin(bin, plant_resource_code)
      unless response.success
        err = if response.instance.is_a?(String) && response.instance&.start_with?('<message>')
                "SQL Integration returned an error running: select Apport.* from Apport where Apport.NumPalox='#{bin}'. Message: #{response.instance.split('</message>').first.split('<message>').last}."
              else
                "SQL Integration returned an error running: select Apport.* from Apport where Apport.NumPalox='#{bin}'. Message: #{response.message}."
              end
        raise Crossbeams::InfoError, err
      end

      res = response.instance.body.split('resultset>').last.split('</res').first
      results = Marshal.load(Base64.decode64(res)) # rubocop:disable Security/MarshalLoad
      raise Crossbeams::InfoError, "Tipped Presorted Bin:#{bin} not found in Apport db" if results.empty?

      @tipped_apport_bin = results[0]
    end
  end
end
