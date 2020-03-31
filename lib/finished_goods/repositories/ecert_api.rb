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

    def elot_preverify(url, body)
      http = Crossbeams::HTTPCalls.new(false)

      res = http.json_post(url, body, headers)
      return failed_response(res.message) unless res.success

      instance = JSON.parse(res.instance.body)
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
  end
end
