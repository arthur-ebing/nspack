# frozen_string_literal: true

module QualityApp
  module PhytCleanCalls
    attr_reader :headers

    class PhytCleanHttpResponder
      include Crossbeams::Responses
      def format_response(response, _context)
        p response
        p response&.body
        if response.code == '200'
          success_response(response.code, response)
        else
          failed_response("The response code is #{response.code}", response.code)
        end
      end
    end

    def auth_token_call
      http = Crossbeams::HTTPCalls.new(AppConst::PHYT_CLEAN_ENVIRONMENT.include?('https'), responder: PhytCleanHttpResponder.new)
      url = "#{AppConst::PHYT_CLEAN_ENVIRONMENT}/api/oauth2/token"
      params = { username: AppConst::PHYT_CLEAN_API_USERNAME, password: AppConst::PHYT_CLEAN_API_PASSWORD, grant_type: 'password' }

      res = http.request_post(url, params)
      return failed_response(res.message) unless res.success

      instance = JSON.parse(res.instance.body)
      @headers = { Authorization: "bearer #{instance['access_token']}" }
      success_response(instance['message'])
    end

    def request_citrus_eu_orchard_status
      http = Crossbeams::HTTPCalls.new(AppConst::PHYT_CLEAN_ENVIRONMENT.include?('https'), responder: PhytCleanHttpResponder.new)
      url = "#{AppConst::PHYT_CLEAN_ENVIRONMENT}/api/citruseuorchardstatus"

      res = http.request_get(url, headers)
      return failed_response(res.message) unless res.success

      instance = JSON.parse(res.instance.body)
      success_response('ok', instance)
    end
  end
end
