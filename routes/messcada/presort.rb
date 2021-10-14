# frozen_string_literal: true

class Nspack < Roda
  route 'presort', 'messcada' do |r|
    interactor = RawMaterialsApp::PresortStagingRunInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

    # STAGE BINS
    # view-source:http://192.168.43.148:9296/messcada/presort/staging?bin1=776548&bin2=783875&bin3=771442&unit=PRS1
    # --------------------------------------------------------------------------
    r.on 'staging' do
      res = interactor.stage_bins(params, request.path)
      res.instance
    end

    # STAGE BINS OVERRIDE
    # view-source:http://192.168.43.148:9296/messcada/presort/staging_override_provided?&answer=no&bin1=776548&bin2=783875&bin3=771442&unit=PRS1
    # --------------------------------------------------------------------------
    r.on 'staging_override_provided' do
      res = interactor.staging_override_provided(params, request.path)
      res.instance
    end

    # Bin Tipped
    # view-source:http://192.168.43.148:9296/messcada/presort/bin_tipped?bin=704
    # --------------------------------------------------------------------------
    r.on 'bin_tipped' do
      res = interactor.bin_tipped(params, request.path)
      res.instance
    rescue StandardError => e
      ErrorMailer.send_exception_email(e, subject: "PresortBinTipped - #{e.message}", message: 'PresortBinTipped Service.')
      puts e.message
      "<result><error msg=\"#{e.message}\" /></result>"
    end
  end
end
