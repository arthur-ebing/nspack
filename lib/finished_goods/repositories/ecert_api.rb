# frozen_string_literal: true

module FinishedGoodsApp
  class ECertApi < BaseRepo
    attr_reader :header

    def auth_token_call
      http = Crossbeams::HTTPCalls.new(false)
      url = 'http://uas.ecert.co.za/oauth2/token'
      raise Crossbeams::InfoError, 'Service Unavailable: Failed to connect to remote server.' unless http.can_ping?('ecert.co.za')

      params = { client_id: AppConst::E_CERT_API_CLIENT_ID, client_secret: AppConst::E_CERT_API_CLIENT_SECRET, grant_type: 'client_credentials' }
      res = http.request_post(url, params)
      raise Crossbeams::InfoError, res.message unless res.success

      instance = JSON.parse(res.instance.body)
      @header = { Authorization: "Bearer #{instance['access_token']}" }
    end

    def tracking_unit_status(pallet_number)
      auth_token_call if header.nil?

      url = "#{AppConst::E_CERT_ENVIRONMENT}tur.ecert.co.za/api/TrackingUnit/GetTrackingUnitStatus?trackingUnitId=#{pallet_number}"
      http = Crossbeams::HTTPCalls.new(url.include?('https'), open_timeout: 15, read_timeout: 30)

      res = http.request_get(url, header)
      return failed_response(res.message) unless res.success

      instance = JSON.parse(res.instance.body)
      success_response('Found Tracking Unit', instance)
    end

    def elot(params, body) # rubocop:disable Metrics/AbcSize
      auth_token_call if header.nil?

      url = "#{AppConst::E_CERT_ENVIRONMENT}tur.ecert.co.za/api/TrackingUnit/eLot?#{params}"
      http = Crossbeams::HTTPCalls.new(url.include?('https'), open_timeout: 30, read_timeout: 60)
      res = http.json_post(url, body, header)
      return failed_response(res.message) unless res.success

      instance = JSON.parse(res.instance.body)
      save_to_yaml(url: url, body: body, response: instance)

      success_response('Posted Pre-verification', instance)
    end

    def update_agreements # rubocop:disable Metrics/AbcSize
      url = 'https://app.ecert.co.za/api/v1/Agreement/Get'
      http = Crossbeams::HTTPCalls.new(url.include?('https'))
      return failed_response('Service Unavailable: Failed to connect to remote server.') unless http.can_ping?('ecert.co.za')

      res = http.request_get(url)
      return failed_response(res.message) unless res.success

      instance = JSON.parse(res.instance.body)
      instance['Data'].each do |agreement|
        params = UtilityFunctions.symbolize_keys(agreement)
        id = get_id(:ecert_agreements, code: params[:AgreementCode])
        attrs = { code: params[:AgreementCode], name: params[:Name], description: params[:Description], start_date: params[:StartDate] }
        id.nil? ? create(:ecert_agreements, attrs) : update(:ecert_agreements, id, attrs)
      end

      success_response('Received Agreements', instance)
    end

    def save_to_yaml(payload)
      File.open(File.join(ENV['ROOT'], 'tmp', 'eCert_store.yml'), 'w') { |f| f << payload.to_yaml }
    end
  end
end
