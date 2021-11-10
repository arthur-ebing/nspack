# frozen_string_literal: true

module ProductionApp
  class LookupExtendedFgCodeId < BaseService
    attr_reader :extended_fg_code

    def initialize(extended_fg_code)
      @extended_fg_code = extended_fg_code
    end

    def call
      id = request_extended_fg_id

      if id
        success_response('ok', id)
      else
        failed_response('Not found')
      end
    end

    private

    def request_extended_fg_id
      url = "#{AppConst::RMT_INTEGRATION_SERVER_URI}/services/integration/get_extended_fg?extended_fg_code=#{extended_fg_code}"
      http = Crossbeams::HTTPCalls.new
      res = http.request_get(url)
      return res.message unless res.success

      instance = res.instance.body
      return 'Nothing returned from MES' if instance.nil_or_empty?

      JSON.parse(instance)
    end
  end
end
