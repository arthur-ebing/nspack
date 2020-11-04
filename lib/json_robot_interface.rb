# frozen_string_literal: true

class JsonRobotInterface
  include Crossbeams::Responses

  attr_reader :request, :input_payload, :action_type, :mac_addr, :params

  ACTION_TYPES = %i[requestPing requestSetup requestDateTime].freeze

  def initialize(request, input_payload)
    @request = request
    @input_payload = input_payload
  end

  def check_params
    # vres = validate_params
    # unless vres.success?
    #   @validation_errors = unwrap_failed_response(validation_failed_response(vres))
    #   return failed_response('validation errors')
    # end

    @action_type = input_payload.keys.first
    unless ACTION_TYPES.include?(@action_type)
      @validation_errors = "Action #{@action_type} is not a valid option."
      return failed_response('invalid action')
    end
    @params = input_payload[@action_type]
    @mac_addr = input_payload[@action_type][:MAC]
    ok_response
  end

  def process_invalid_params
    { responseStation: {
      MAC: @mac_addr,
      LCD1: @validation_errors,
      LCD2: '',
      LCD3: '',
      LCD4: '',
      green: 'false',
      orange: 'false',
      red: 'true'
    } }
  end

  def process_request
    # lookup MAC to resource to get device etc info...
    send(action_type)
  end

  private

  def validate_params
    # schema.call(input_payload)
  end

  def requestPing # rubocop:disable Naming/MethodName
    { responsePong: @params }
  end

  def requestSetup # rubocop:disable Naming/MethodName
    { responseSetup: { MAC: @mac_addr,
                       message: 'Test setup',
                       lowLimit: '850',
                       highLimit: '1150',
                       units: 'kg',
                       name: 'Weighbridge 1',
                       security: 'OPEN', # 'OPEN/REQUIRED',
                       date: Time.now.strftime('%Y-%m-%d'),
                       time: Time.now.strftime('%H:%M:%S'),
                       type: 'SOLAS-SCALE', # TERMINAL/SOLAS-SCALE/BARCODE-SCANNER/BIN-TIPPING',
                       serverURL: "#{request.base_url}/messcada/robot/api" } }
  end

  def requestDateTime # rubocop:disable Naming/MethodName
    { responseDateTime: { status: 'OK', MAC: @mac_addr, date: Time.now.strftime('%Y-%m-%d'), time: Time.now.strftime('%H:%M:%S') } }
  end
end
