# frozen_string_literal: true

module QualityApp
  class PhytCleanApi < BaseRepo
    attr_reader :header

    def auth_token_call
      http = Crossbeams::HTTPCalls.new(AppConst::PHYT_CLEAN_ENVIRONMENT.include?('https'))
      url = "#{AppConst::PHYT_CLEAN_ENVIRONMENT}/api/oauth2/token"
      params = { username: AppConst::PHYT_CLEAN_API_USERNAME, password: AppConst::PHYT_CLEAN_API_PASSWORD, grant_type: 'password' }

      res = http.request_post(url, params)
      return failed_response(res.message) unless res.success

      instance = JSON.parse(res.instance.body)
      @header = { Authorization: "bearer #{instance['access_token']}" }
      success_response(instance['message'], header)
    end

    def request_phyt_clean_seasons
      http = Crossbeams::HTTPCalls.new(AppConst::PHYT_CLEAN_ENVIRONMENT.include?('https'))
      url = "#{AppConst::PHYT_CLEAN_ENVIRONMENT}/api/seasons"

      res = http.request_get(url, header)
      return failed_response(res.message) unless res.success

      instance = JSON.parse(res.instance.body)
      success_response('Received seasons', instance)
    end

    def request_phyt_clean_glossary(season_id)
      http = Crossbeams::HTTPCalls.new(AppConst::PHYT_CLEAN_ENVIRONMENT.include?('https'))
      url = "#{AppConst::PHYT_CLEAN_ENVIRONMENT}/api/glossary?seasonID=#{season_id}"

      res = http.request_get(url, header)
      return failed_response(res.message) unless res.success

      instance = JSON.parse(res.instance.body)
      success_response('Received glossary', instance)
    end

    def request_phyt_clean_standard_phyto_data(season_id, puc_id)
      http = Crossbeams::HTTPCalls.new(AppConst::PHYT_CLEAN_ENVIRONMENT.include?('https'))
      url = "#{AppConst::PHYT_CLEAN_ENVIRONMENT}/api/standardphytodata"

      fbo_xml = "<?xml version=\"1.0\"?><Request><Fbo>
                  <FboCode>#{get(:pucs, puc_id, :puc_code)}</FboCode>
                </Fbo></Request>"
      params = { seasonID: season_id, outputType: 'json', fboXML: fbo_xml }
      res = http.request_post(url, params, header)
      return failed_response(res.message) unless res.success

      instance = JSON.parse(res.instance.body)
      success_response('Received standard phyto data', instance)
    end

    def request_get_citrus_eu_orchard_status
      http = Crossbeams::HTTPCalls.new(AppConst::PHYT_CLEAN_ENVIRONMENT.include?('https'), responder: PhytCleanHttpResponder.new, read_timeout: 60)
      url = "#{AppConst::PHYT_CLEAN_ENVIRONMENT}/api/citruseuorchardstatus"

      res = http.request_get(url, header)
      return failed_response(res.message) unless res.success

      instance = JSON.parse(res.instance.body)
      success_response('Received citrus eu orchard status', instance)
    end

    def filter_phyt_clean_response(array)
      pucs_list = select_values(:pucs, :puc_code)
      filtered_response = []
      array.each do |hash|
        next unless pucs_list.include? hash['puc']

        filtered_response << UtilityFunctions.symbolize_keys(hash)
      end
      filtered_response
    end
  end
end
