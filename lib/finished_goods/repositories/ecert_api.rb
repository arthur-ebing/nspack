# frozen_string_literal: true

module FinishedGoodsApp
  class ECertApi < BaseRepo
    attr_reader :headers

    def auth_token_call
      http = Crossbeams::HTTPCalls.new(false)
      url = 'http://uas.ecert.co.za/oauth2/token'
      params = { client_id: AppConst::E_CERT_API_CLIENT_ID, client_secret: AppConst::E_CERT_API_CLIENT_SECRET, grant_type: 'client_credentials' }

      res = http.request_post(url, params)
      return failed_response(res.message) unless res.success

      instance = JSON.parse(res.instance.body)
      @headers = { Authorization: "bearer #{instance['access_token']}" }
      success_response(instance['message'])
    end

    def find_tracking_unit(pallet_number)
      http = Crossbeams::HTTPCalls.new(false)
      url = "#{AppConst::E_CERT_ENVIRONMENT}tur.ecert.co.za/api/TrackingUnit/GetTrackingUnit?trackingUnitId=#{pallet_number}"

      res = http.request_get(url, headers)
      return failed_response(res.message) unless res.success

      instance = JSON.parse(res.instance.body)
      success_response('Found Tracking Unit', instance)
    end

    def elot_preverify(url, params)
      http = Crossbeams::HTTPCalls.new(false, open_timeout: 30, read_timeout: 60)

      res = http.json_post(url, params, headers)
      return failed_response(res.message) unless res.success

      instance = JSON.parse(res.instance.body)
      save_to_yaml(url: url, params: params, response: instance)

      success_response('Posted Pre-verification', instance)
    end

    def update_agreements # rubocop:disable Metrics/AbcSize
      http = Crossbeams::HTTPCalls.new(false)
      url = "#{AppConst::E_CERT_ENVIRONMENT}ecert.co.za/api/v1/Agreement/Get"
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
      begin
        YAML.load_file('tmp/eCert_store.yml')
      rescue Errno::ENOENT
        File.open('tmp/eCert_store.yml', 'w') { |file| file.write([].to_yaml) }
      end

      File.open('tmp/eCert_store.yml', 'w') do |file|
        file.write(payload.to_yaml)
      end
    end
  end
end
