# frozen_string_literal: true

module FinishedGoodsApp
  class TitanInspection < BaseService # rubocop:disable Metrics/ClassLength
    attr_reader :govt_inspection_sheet_id, :task, :user, :repo,
                :govt_inspection_sheet, :inspection_message_id, :consignment_number,
                :header, :http, :payload

    def initialize(govt_inspection_sheet_id, task, user)
      @repo = GovtInspectionRepo.new
      @task = task.to_sym
      @user = user

      @govt_inspection_sheet_id = govt_inspection_sheet_id
      @consignment_number = DB.get(Sequel.function(:fn_consignment_note_number, govt_inspection_sheet_id))
    end

    MODES = {
      request_inspection: :request_inspection_task,
      request_reinspection: :request_reinspection_task,
      validate: :validation_call,
      update_inspection: :update_inspection_task,
      update_reinspection: :update_reinspection_task,
      results: :request_results_task,
      delete: :delete_inspection_call
    }.freeze

    def call # rubocop:disable Metrics/AbcSize
      mode = MODES[task]
      raise ArgumentError, "Mode \"#{task}\" is unknown for #{self.class}" if mode.nil?

      @govt_inspection_sheet = repo.find_govt_inspection_sheet(govt_inspection_sheet_id)
      return failed_response 'Govt Inspection Record not found' unless govt_inspection_sheet

      @inspection_message_id = repo.get_last(:titan_requests, :inspection_message_id, govt_inspection_sheet_id: govt_inspection_sheet_id)
      return failed_response 'Cant find inspection message id' unless inspection_message_id || %i[request_inspection request_reinspection].include?(task)

      send(mode)
    end

    private

    def request_inspection_task
      res = inspection_call
      return res unless res.success

      validation_call
    end

    def request_reinspection_task
      res = reinspection_call
      return res unless res.success

      validation_call
    end

    def update_inspection_task
      res = update_inspection_call
      return res unless res.success

      validation_call
    end

    def update_reinspection_task
      res = update_reinspection_call
      return res unless res.success

      validation_call
    end

    def request_results_task
      res = request_results_call
      return res unless res.success

      update_govt_inspection
    end

    def update_govt_inspection
      results = FinishedGoodsApp::TitanRepo.new.find_titan_inspection(govt_inspection_sheet_id)

      repo.update_govt_inspection_sheet(govt_inspection_sheet_id, upn: results.upn)
      repo.log_status(:govt_inspection_sheets, govt_inspection_sheet_id, 'TITAN_RESULTS_RECEIVED', user_name: @user.user_name)

      update_govt_inspection_pallets(results)

      ok_response
    end

    def update_govt_inspection_pallets(results) # rubocop:disable Metrics/AbcSize
      failure_type_id = repo.get_id_or_create(:inspection_failure_types,
                                              failure_type_code: 'TITAN Inspections')
      pallets = results.pallets
      pallets.each do |pallet|
        govt_inspection_pallet_id = repo.get_id(:govt_inspection_pallets,
                                                pallet_id: pallet[:pallet_id],
                                                govt_inspection_sheet_id: govt_inspection_sheet_id)

        rejection_reasons = pallet[:rejection_reasons].first
        if rejection_reasons
          failure_reason_id = repo.get_id_or_create(:inspection_failure_reasons,
                                                    failure_reason: rejection_reasons['reasonCode'],
                                                    description: rejection_reasons['reason'],
                                                    inspection_failure_type_id: failure_type_id)
          FailGovtInspectionPallet.call(govt_inspection_pallet_id, failure_reason_id: failure_reason_id, failure_remarks: 'TITAN Inspection')
        else
          PassGovtInspectionPallet.call(govt_inspection_pallet_id)
        end
      end
    end

    def log_titan_request(request_type, res)
      result_doc = res.instance
      result_doc = { message: res.message } if result_doc.empty?

      attrs = { request_type: request_type,
                govt_inspection_sheet_id: govt_inspection_sheet_id,
                request_doc: payload.to_json,
                result_doc: result_doc.to_json,
                success: res.success,
                request_id: res['requestId'],
                transaction_id: res['transactionId'],
                inspection_message_id: res.instance['inspectionMessageId'] }
      TitanRepo.new.create_titan_request(attrs)
      res
    end

    # --------------------------------------------------------------------------
    # CALLS
    # --------------------------------------------------------------------------
    def inspection_call
      auth_token_call if header.nil?
      url = "#{AppConst::TITAN_ENVIRONMENT}/pi/ProductInspection/consignment"
      @payload = TitanRepo.new.compile_inspection(govt_inspection_sheet_id)
      @payload[:transactionType] = '202'
      @header['api-version'] = '2.0'

      res = http.json_post(url, payload, header)
      log_titan_request('Request Inspection', res)
    end

    def reinspection_call
      auth_token_call if header.nil?
      url = "#{AppConst::TITAN_ENVIRONMENT}/pi/ProductReInspection/consignment"
      @payload = TitanRepo.new.compile_inspection(govt_inspection_sheet_id)
      @payload[:transactionType] = '203'

      res = http.json_post(url, payload, header)
      log_titan_request('Request Reinspection', res)
    end

    def validation_call
      auth_token_call if header.nil?
      url = "#{AppConst::TITAN_ENVIRONMENT}/pi/ProductInspection/InspectionMessages/ValidationResult?inspectionMessageId=#{inspection_message_id}"
      @header.delete('api-version')

      res = http.request_get(url, header)
      log_titan_request('Validation', res)
    end

    def update_inspection_call
      auth_token_call if header.nil?
      url = "#{AppConst::TITAN_ENVIRONMENT}/pi/ProductInspection/consignment"
      @payload = TitanRepo.new.compile_inspection(govt_inspection_sheet_id)
      @payload[:inspectionMessageId] = inspection_message_id
      @payload[:transactionType] = '202'
      @header['api-version'] = '2.0'

      res = http.json_put(url, payload, header)
      log_titan_request('Update Inspection', res)
    end

    def update_reinspection_call
      auth_token_call if header.nil?
      url = "#{AppConst::TITAN_ENVIRONMENT}/pi/ProductInspection/consignment"
      @payload = TitanRepo.new.compile_inspection(govt_inspection_sheet_id)
      @payload[:inspectionMessageId] = inspection_message_id
      @payload[:transactionType] = '203'

      res = http.json_put(url, payload, header)
      log_titan_request('Update Reinspection', res)
    end

    def delete_inspection_call
      auth_token_call if header.nil?
      url = "#{AppConst::TITAN_ENVIRONMENT}/pi/ProductInspection/consignment"
      @payload = { inspectionMessageId: inspection_message_id }

      res = http.json_delete(url, payload, header)
      log_titan_request('Delete', res)
    end

    def request_results_call
      auth_token_call if header.nil?
      url = "#{AppConst::TITAN_ENVIRONMENT}/pi/ProductInspection/InspectionResult?consignmentNumber=#{consignment_number}"

      res = http.request_get(url, header)
      log_titan_request('Results', res)
    end

    def auth_token_call
      @http = Crossbeams::HTTPCalls.new(AppConst::TITAN_ENVIRONMENT.include?('https'), responder: TitanHttpResponder.new)
      raise Crossbeams::InfoError, 'Service Unavailable: Failed to connect to remote server.' unless http.can_ping?('ppecb.com')

      url = "#{AppConst::TITAN_ENVIRONMENT}/oauth/ApiAuth"
      params = { API_UserId: AppConst::TITAN_INSPECTION_API_USER_ID, API_Secret: AppConst::TITAN_INSPECTION_API_SECRET }

      res = http.json_post(url, params)
      raise Crossbeams::InfoError, res.message unless res.success

      @header = { 'Authorization' => "Bearer #{res.instance['token']}" }
    end

    class TitanHttpResponder
      include Crossbeams::Responses
      def format_response(response, _context)
        instance = JSON.parse(response.body)
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
