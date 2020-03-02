# frozen_string_literal: true

module QualityApp
  class PhytCleanRequests< BaseService
    include PhytCleanCalls
    attr_accessor :payload

    def initialize(id)
      @id = id
    end

    def call
      res = auth_token_call
      return failed_response(res.message) unless res.success

      res = request_citrus_eu_orchard_status
      return failed_response(res.message) unless res.success

      message = 'Data cannot be retrieved as it is out of the valid querying period'
      if res.instance.first['notificationMessage'] == message
        return failed_response(message)
      end

      ok_response
    end

    private

    def repo
      @repo ||= OrchardTestRepo.new
    end
  end
end
