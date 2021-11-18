# frozen_string_literal: true

module ProductionApp
  class LookupExtendedFgCodeId < BaseService
    attr_reader :extended_fg_code

    def initialize(extended_fg_code)
      @extended_fg_code = extended_fg_code
    end

    def call
      url = "#{AppConst::RMT_INTEGRATION_SERVER_URI}/services/integration/get_extended_fg?extended_fg_code=#{extended_fg_code}"
      http = Crossbeams::HTTPCalls.new
      res = http.request_get(url)
      return failed_response(res.message) unless res.success

      instance = res.instance.body
      return failed_response('Nothing returned from MES') if instance.nil_or_empty?

      success_response('ok', JSON.parse(instance))
    end
  end
end
