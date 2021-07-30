# frozen_string_literal: true

module FinishedGoodsApp
  class TitanAddendum < BaseService
    attr_reader :load_id, :repo, :task, :user, :payload, :api_request, :header, :http

    def initialize(load_id, task, user)
      @repo = TitanRepo.new
      @load_id = load_id
      @task = task.to_sym
      @user = user
      @api_request = repo.find_titan_addendum(load_id)
    end

    MODES = {
      request: :request_addendum_call,
      cancel: :cancel_addendum_call,
      status: :addendum_status_call
    }.freeze

    def call
      mode = MODES[task]
      raise ArgumentError, "Mode \"#{task}\" is unknown for #{self.class}" if mode.nil?
      return failed_response('Addendum transaction not found') unless api_request || task == :request

      auth_token_call

      send(mode)
    end

    private

    def log_titan_request(request_type, res)
      result_doc = res.instance
      result_doc = { message: res.message } if result_doc.empty?

      attrs = { request_type: request_type,
                load_id: load_id,
                request_doc: payload.to_json,
                result_doc: result_doc.to_json,
                success: res.success,
                request_id: res.instance['requestId'],
                transaction_id: res.instance['transactionId'] }
      repo.create_titan_request(attrs)
      res
    end

    # --------------------------------------------------------------------------
    # CALLS
    # --------------------------------------------------------------------------
    def request_addendum_call
      url = "#{AppConst::TITAN_API_HOST}/ec/ExportCertification/Addendum"

      @payload = repo.compile_addendum(load_id)
      res = http.json_post(url, payload, header)
      log_titan_request('Request Addendum', res)
    end

    def cancel_addendum_call
      url = "#{AppConst::TITAN_API_HOST}/ec/ExportCertification/Addendum/CancelAddendum"

      @payload = { transactionId: api_request.transaction_id, requestId: api_request.request_id.to_s }
      res = http.json_post(url, payload, header)
      log_titan_request('Cancel Addendum', res)
    end

    def addendum_status_call
      url = "#{AppConst::TITAN_API_HOST}/ec/ExportCertification/Addendum/AddendumStatus?transactionId=#{api_request.transaction_id}"
      @payload = { url: url }
      res = http.request_get(url, header)
      log_titan_request('Addendum Status', res)
    end

    def auth_token_call
      @http = Crossbeams::HTTPCalls.new(call_logger: call_logger, responder: TitanHttpResponder.new)
      raise Crossbeams::InfoError, 'Service Unavailable: Failed to connect to remote server.' unless http.can_ping?('ppecb.com')

      url = "#{AppConst::TITAN_API_HOST}/oauth/ApiAuth"
      params = { API_UserId: AppConst::TITAN_ADDENDUM_API_USER_ID, API_Secret: AppConst::TITAN_ADDENDUM_API_SECRET }

      res = http.json_post(url, params)
      raise Crossbeams::InfoError, res.message unless res.success

      @header = { 'Authorization' => "Bearer #{res.instance['token']}" }
    end

    def call_logger
      Crossbeams::HTTPTextCallLogger.new('TITAN-ADDENDUM-API', log_path: 'log/titan_addendum_api_http_calls.log')
    end

    class TitanHttpResponder
      include Crossbeams::Responses
      def format_response(response, _context)
        instance = if response.body.empty?
                     ''
                   else
                     JSON.parse(response.body)
                   end
        case response.code
        when '200'
          success_response(instance['message'], instance)
        when '400'
          failed_response('Response code: 400 Bad Request', instance)
        when '500'
          failed_response('Response code: 500 An unexpected error occurred while processing the request.', instance)
        else
          failed_response("Response code: #{response.code}", instance)
        end
      end
    end
  end
end
