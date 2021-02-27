# frozen_string_literal: true

module QualityApp
  class PhytCleanApi < BaseRepo
    attr_reader :http, :header

    def auth_token_call
      @http = Crossbeams::HTTPCalls.new(read_timeout: 30)
      url = "#{AppConst::PHYT_CLEAN_ENVIRONMENT}/api/oauth2/token"
      raise Crossbeams::InfoError, 'Service Unavailable: Failed to connect to remote server.' unless http.can_ping?(url)

      params = { username: AppConst::PHYT_CLEAN_API_USERNAME, password: AppConst::PHYT_CLEAN_API_PASSWORD, grant_type: 'password' }
      res = http.request_post(url, params)
      raise Crossbeams::InfoError, res.message unless res.success

      instance = JSON.parse(res.instance.body)
      @header = { Authorization: "bearer #{instance['access_token']}" }
    end

    def request_phyt_clean_seasons
      auth_token_call if header.nil?

      url = "#{AppConst::PHYT_CLEAN_ENVIRONMENT}/api/seasons"
      res = http.request_get(url, header)
      return failed_response(res.message) unless res.success

      instance = JSON.parse(res.instance.body)
      success_response('Received seasons', instance)
    end

    def request_phyt_clean_glossary(phyt_clean_season_id)
      auth_token_call if header.nil?

      url = "#{AppConst::PHYT_CLEAN_ENVIRONMENT}/api/glossary?seasonID=#{phyt_clean_season_id}"
      res = http.request_get(url, header)
      return failed_response(res.message) unless res.success

      instance = JSON.parse(res.instance.body)
      success_response('Received glossary', instance)
    end

    def request_phyt_clean_standard_data(phyt_clean_season_id, puc_ids) # rubocop:disable Metrics/AbcSize
      auth_token_call if header.nil?

      url = "#{AppConst::PHYT_CLEAN_ENVIRONMENT}/api/standardphytodata"
      fbo_xml = "<?xml version=\"1.0\"?><Request><Fbo><FboCode>#{select_values(:pucs, :puc_code, id: puc_ids).join('</FboCode></Fbo><Fbo><FboCode>')}</FboCode></Fbo></Request>"
      params = { seasonID: phyt_clean_season_id, outputType: 'json', fboXML: fbo_xml }
      res = http.request_post(url, params, header)
      return failed_response(res.message) unless res.success

      instance = JSON.parse(res.instance.body)
      success_response('Received standard phyto data', instance)
    end
  end
end
