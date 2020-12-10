# frozen_string_literal: true

module MesscadaApp
  class RobotHandleButtonCartonLabeling < BaseService
    attr_reader :robot_interface, :robot, :robot_params, :request, :system_user, :repo

    def initialize(robot_interface)
      @robot_interface = robot_interface
      @robot = robot_interface.robot
      @robot_params = robot_interface.robot_params
      @request = robot_interface.request
      @system_user = robot_interface.system_user
      @repo = LabelApp::PrinterRepo.new
    end

    def call # rubocop:disable Metrics/AbcSize
      params = { device: "#{robot.system_resource_code}-#{robot_params[:button]}", card_reader: '', identifier: robot_params[:id] }
      res = MesscadaApp::AddSystemResourceIncentiveToParams.call(params, has_button: true)

      if res.success
        cvl_res = nil
        repo.transaction do
          cvl_res = MesscadaApp::CartonLabeling.call(res.instance)
          repo.log_action(user_name: system_user.user_name, context: "Print label - #{robot.system_resource_code}", route_url: request.path, request_ip: request.ip)
        end
        config = prep_for_print(cvl_res.instance)
        print_label(config) # do this async?
        feedback = MesscadaApp::RobotFeedback.new(device: params[:device],
                                                  status: true,
                                                  short1: 'Label printed')
        robot_interface.respond(feedback, true, type: :user)
      else
        feedback = MesscadaApp::RobotFeedback.new(device: robot.system_resource_code,
                                                  status: false,
                                                  short1: 'Error',
                                                  short2: unwrap_failed_response(res))
        robot_interface.respond(feedback, false)
      end
    rescue Crossbeams::InfoError => e
      ErrorMailer.send_exception_email(e, subject: "INFO: #{self.class.name}", message: robot_interface.decorate_mail_message('carton_labeling')) if AppConst::ROBOT_DISPLAY_LINES != 4
      puts e.message
      puts e.backtrace.join("\n")
      feedback = MesscadaApp::RobotFeedback.new(device: robot.system_resource_code,
                                                status: false,
                                                short1: 'System error',
                                                short2: e.message)
      robot_interface.respond(feedback, false)
    rescue StandardError => e
      ErrorMailer.send_exception_email(e, subject: self.class.name, message: robot_interface.decorate_mail_message('carton_labeling'))
      puts e
      puts e.backtrace.join("\n")
      feedback = MesscadaApp::RobotFeedback.new(device: robot.system_resource_code,
                                                status: false,
                                                short1: 'System error',
                                                short2: e.message)
      robot_interface.respond(feedback, false)
    end

    private

    def prep_for_print(print_command)
      schema = Nokogiri::XML(print_command)
      label_name = schema.xpath('.//label/template').text
      quantity = schema.xpath('.//label/quantity').text
      printer = printer_for_robot
      vars = {}
      schema.xpath('.//label/fvalue').each_with_index { |node, i| vars["F#{i + 1}".to_sym] = node.text }

      OpenStruct.new(label_name: label_name,
                     quantity: quantity,
                     printer: printer,
                     vars: vars)
    end

    def print_label(config)
      repo = MesserverApp::MesserverRepo.new
      res = repo.print_published_label(config.label_name, config.vars, config.quantity, config.printer)
      raise Crossbeams::InfoError, res.message unless res.success
    end

    def printer_for_robot
      repo.printer_code_for_robot(robot.id)
    end
  end
end
