# frozen_string_literal: true

class JsonRobotInterface # rubocop:disable Metrics/ClassLength
  include Crossbeams::Responses

  attr_reader :request, :input_payload, :action_type, :mac_addr, :robot_params, :resource_repo, :system_user, :robot, :inflector

  ACTION_TYPES = %i[requestPing requestSetup requestDateTime publishStatus publishBarcodeScan publishButton publishLogon publishLogoff].freeze
  # Not implemented: action for publishScaleWeight

  RESPONSE_TYPES = {
    station: :responseStation,
    user: :responseUser,
    key: :responseKeypad
  }.freeze

  def initialize(system_user, request, input_payload)
    @request = request
    @system_user = system_user
    @input_payload = input_payload
    @resource_repo = ProductionApp::ResourceRepo.new
    @inflector = Dry::Inflector.new
  end

  def check_params
    vres = validate_params
    return vres unless vres.success

    extract_params
    vres = validate_action
    return vres unless vres.success

    vres = find_and_validate_resource
    return vres unless vres.success

    ok_response
  end

  def process_invalid_params # rubocop:disable Metrics/CyclomaticComplexity
    puts "#{Time.now.strftime('%Y-%m-%d %H:%M:%S')} JSON ROBOT: Invalid params. #{@validation_errors.inspect} - #{input_payload.inspect}"

    return invalid_setup if @action_type && @action_type == :requestSetup

    lcd1, lcd2, lcd3, lcd4 = @validation_errors
    lcd4 ||= Time.now.strftime('%H:%M:%S')
    res = {
      responseStation: {
        MAC: @mac_addr,
        LCD1: lcd1 || '',
        LCD2: lcd2 || '',
        LCD3: lcd3 || '',
        LCD4: lcd4 || '',
        green: 'false',
        orange: 'false',
        red: 'true'
      }
    }
    p res
    res
  end

  def process_request
    puts "#{Time.now.strftime('%Y-%m-%d %H:%M:%S')} JSON ROBOT: #{@robot.system_resource_code} - #{input_payload.inspect}"

    send(inflector.underscore(action_type))
  end

  def respond(feedback, success, type: :station, orange: false)
    lcd1, lcd2, lcd3, lcd4 = feedback.four_lines
    res = {
      RESPONSE_TYPES[type] => {
        MAC: @mac_addr,
        LCD1: lcd1 || '',
        LCD2: lcd2 || '',
        LCD3: lcd3 || '',
        LCD4: lcd4 || '',
        green: true_state(success),
        orange: true_state(orange),
        red: false_state(success)
      }
    }
    p res
    res
  end

  def log_feedback(feedback, success)
    lcd1, lcd2, lcd3, lcd4 = feedback.four_lines
    cnt = 0
    lines = [lcd1, lcd2, lcd3, lcd4].map do |txt|
      cnt += 1
      txt.nil? ? nil : "line#{cnt}: #{txt}"
    end.compact
    "robot feedback - status: #{true_state(success)}, #{lines.join(' ')}"
  end

  def decorate_mail_message(message)
    "#{message}\n\nRequest path: #{@request.path}\n\nAction: #{@action_type}\n\nParams: #{@robot_params.inspect}\n\nMAC: #{@mac_addr}"
  end

  private

  def validate_params
    if input_payload.is_a?(Hash) &&
       input_payload.keys.length == 1 &&
       input_payload[input_payload.keys.first].is_a?(Hash)
      ok_response
    else
      @validation_errors = ['Invalid parameters']
      failed_response('validation errors')
    end
  end

  def extract_params
    @action_type = input_payload.keys.first
    @robot_params = input_payload[@action_type]
    @mac_addr = input_payload[@action_type][:MAC]
  end

  def validate_action
    if ACTION_TYPES.include?(@action_type)
      ok_response
    else
      @validation_errors = [@action_type, 'Unknown action']
      failed_response('Unknown action')
    end
  end

  def find_and_validate_resource
    @robot = resource_repo.find_robot_by_mac_addr(mac_addr)
    if @robot
      ok_response
    else
      @validation_errors = [@action_type, @mac_addr, 'Unconfigured MAC addr']
      failed_response('MAC addr not registered')
    end
  end

  # Robot actions
  # --------------------------
  def request_ping
    { responsePong: robot_params }
  end

  def request_setup
    # Get device resource to read:
    # - resource-specific hash (if present) e.g. weight units etc.
    # serverURL: "#{request.base_url}/messcada/robot/api" --- DO NOT SEND THIS, robot can not work with it!
    res = {
      responseSetup: { MAC: @mac_addr,
                       status: 'OK',
                       message: "#{@robot.system_resource_code} setup",
                       # lowLimit: '850',    # depends on robot type
                       # highLimit: '1150',  # depends on robot type
                       # units: 'kg',        # depends on robot type
                       name: @robot.description,
                       security: 'OPEN', # 'OPEN/REQUIRED', -- probably should remain open and the system checks that the payload includes identifier
                       date: Time.now.strftime('%Y-%m-%d'),
                       time: Time.now.strftime('%H:%M:%S'),
                       type: @robot.module_function || 'TERMINAL' } # TERMINAL/SOLAS-SCALE/BARCODE-SCANNER/BIN-TIPPING
    }
    p res
    res
  end

  def invalid_setup
    res = {
      responseSetup: { MAC: @mac_addr,
                       status: 'FAIL',
                       message: 'Unknown MAC addr',
                       name: 'UNKNOWN',
                       security: 'OPEN',
                       date: Time.now.strftime('%Y-%m-%d'),
                       time: Time.now.strftime('%H:%M:%S'),
                       type: 'TERMINAL' }
    }
    p res
    res
  end

  def request_date_time
    { responseDateTime: { status: 'OK', MAC: @mac_addr, date: Time.now.strftime('%Y-%m-%d'), time: Time.now.strftime('%H:%M:%S') } }
  end

  def publish_barcode_scan # rubocop:disable Metrics/AbcSize
    # from resource: is this bin_tip / bin_tip+weigh / palletize scan / verify ctn/plt / ...
    class_name = "MesscadaApp::RobotHandleScan#{inflector.classify(robot.module_action)}"
    klass = inflector.constantize(class_name)
    p "Handing work over to #{class_name}"
    klass.call(self)
  rescue NameError => e
    ErrorMailer.send_exception_email(e,
                                     subject: "#{self.class.name} scan handler",
                                     message: decorate_mail_message("There is no class named #{class_name} to handle #{robot.module_action} for #{robot.system_resource_code}."))
    puts e.message
    puts e.backtrace.join("\n")
    feedback = MesscadaApp::RobotFeedback.new(device: robot.system_resource_code,
                                              status: false,
                                              short1: 'System error',
                                              short2: 'Cannot process')
    respond(feedback, false)
  end

  def publish_button # rubocop:disable Metrics/AbcSize
    class_name = "MesscadaApp::RobotHandleButton#{inflector.classify(robot.module_action)}"
    klass = inflector.constantize(class_name)
    p "Handing work over to #{class_name}"
    klass.call(self)
  rescue NameError => e
    ErrorMailer.send_exception_email(e,
                                     subject: "#{self.class.name} button handler",
                                     message: decorate_mail_message("There is no class named #{class_name} to handle #{robot.module_action} for #{robot.system_resource_code}."))
    puts e.message
    puts e.backtrace.join("\n")
    feedback = MesscadaApp::RobotFeedback.new(device: robot.system_resource_code,
                                              status: false,
                                              short1: 'System error',
                                              short2: 'Cannot process')
    respond(feedback, false)
  end

  def register_identifier # rubocop:disable Metrics/AbcSize
    interactor = MesscadaApp::HrInteractor.new(system_user, {}, { route_url: request.path, request_ip: request.ip }, {})
    params = { device: robot.system_resource_code, value: robot_params[:id], card_reader: '1' }
    res = interactor.register_identifier(params)

    feedback = if res.success
                 MesscadaApp::RobotFeedback.new(device: params[:device],
                                                status: true,
                                                line1: params[:value],
                                                line4: res.message)
               else
                 MesscadaApp::RobotFeedback.new(device: params[:device],
                                                status: false,
                                                line1: "Cannot add #{params[:value]}",
                                                line3: 'Please try again',
                                                line4: res.message)
               end
    respond(feedback, res.success)
  end

  def publish_logon # rubocop:disable Metrics/AbcSize
    return register_identifier if robot.bulk_registration_mode

    interactor = MesscadaApp::HrInteractor.new(system_user, {}, { route_url: request.path, request_ip: request.ip }, {})
    params = { device: robot.system_resource_code, identifier: robot_params[:id], card_reader: '1' }
    AppConst.log_authentication("JSON robot login params: #{params.inspect}")
    res = MesscadaApp::AddSystemResourceIncentiveToParams.call(params, get_group_incentive: false)
    res = interactor.login_with_identifier(res.instance) if res.success

    feedback = if res.success
                 MesscadaApp::RobotFeedback.new(device: params[:device],
                                                status: true,
                                                line1: res.instance[:contract_worker],
                                                line4: 'Logged on')
               else
                 MesscadaApp::RobotFeedback.new(device: params[:device],
                                                status: false,
                                                line1: 'Cannot login',
                                                line4: res.message)
               end
    AppConst.log_authentication("JSON robot login result: #{log_feedback(feedback, res.success)}")
    respond(feedback, res.success)
  end

  def publish_logoff # rubocop:disable Metrics/AbcSize
    interactor = MesscadaApp::HrInteractor.new(system_user, {}, { route_url: request.path, request_ip: request.ip }, {})
    params = { device: robot.system_resource_code, card_reader: '1' }
    res = interactor.logout_device(params)

    feedback = if res.success
                 MesscadaApp::RobotFeedback.new(device: params[:device],
                                                status: true,
                                                line1: res.instance[:contract_worker],
                                                line4: 'Logged off')
               else
                 MesscadaApp::RobotFeedback.new(device: params[:device],
                                                status: false,
                                                line1: 'Cannot logout',
                                                line4: res.message)
               end
    respond(feedback, res.success)
  end

  def publish_status
    {} # Not sure what to return here...
  end

  def true_state(success)
    success ? 'true' : 'false'
  end

  def false_state(success)
    success ? 'false' : 'true'
  end
end
