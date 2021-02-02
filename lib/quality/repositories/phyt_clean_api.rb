# frozen_string_literal: true

module QualityApp
  class PhytCleanApi < BaseRepo
    attr_reader :http, :header

    def auth_token_call # rubocop:disable Metrics/AbcSize
      @http = Crossbeams::HTTPCalls.new(AppConst::PHYT_CLEAN_ENVIRONMENT.include?('https'), read_timeout: 30)
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

    def request_phyt_clean_glossary(season_id)
      auth_token_call if header.nil?

      url = "#{AppConst::PHYT_CLEAN_ENVIRONMENT}/api/glossary?seasonID=#{season_id}"
      res = http.request_get(url, header)
      return failed_response(res.message) unless res.success

      instance = JSON.parse(res.instance.body)
      success_response('Received glossary', instance)
    end

    def request_phyt_clean_standard_data(season_id, puc_ids) # rubocop:disable Metrics/AbcSize
      auth_token_call if header.nil?

      season = find(:seasons, Seasons, season_id)
      raise Crossbeams::InfoError, "Season #{season[:season_code]}, ended: #{season[:end_date]}, unable to fetch standard phytodata" if  Date.today > season[:end_date]

      url = "#{AppConst::PHYT_CLEAN_ENVIRONMENT}/api/standardphytodata"
      fbo_xml = "<?xml version=\"1.0\"?><Request><Fbo><FboCode>#{select_values(:pucs, :puc_code, id: puc_ids).join('</FboCode></Fbo><Fbo><FboCode>')}</FboCode></Fbo></Request>"
      params = { seasonID: season_id, outputType: 'json', fboXML: fbo_xml }
      res = http.request_post(url, params, header)
      return failed_response(res.message) unless res.success

      instance = JSON.parse(res.instance.body)
      success_response('Received standard phyto data', instance)
    end
  end
end
