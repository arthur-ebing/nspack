# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
class Nspack < Roda
  route 'xml', 'messcada' do |r|
    response['Content-Type'] = 'application/xml'
    xml_interpreter = MesscadaXMLInterpreter.new(request)
    interactor = MesscadaApp::MesscadaInteractor.new(system_user, {}, { route_url: request.path, request_ip: request.ip }, {})

    # --------------------------------------------------------------------------
    # BIN TIPPING FROM MAF
    # --------------------------------------------------------------------------
    r.on 'bin_tipping' do
      r.post 'can_dump' do
        params = xml_interpreter.params_for_can_bin_be_tipped
        res = interactor.can_tip_bin?(params)
        s = if res.success
              %(<ContainerMove PID="200" Mode="5" Status="true" RunNumber="#{res.instance[:run_id]}" Red="false" Yellow="false" Green="true" Msg="#{res.message}" />)
            else
              %(<ContainerMove PID="200" Mode="5" Status="false" RunNumber="" Red="true" Yellow="false" Green="false" Msg="#{unwrap_failed_response(res)}" />)
            end
        puts "MESSCADA XML - response: #{s}"
        s
      rescue Crossbeams::FrameworkError => e
        s = %(<ContainerMove PID="200" Mode="5" Status="false" RunNumber="" Red="true" Yellow="false" Green="false" Msg="#{e.message}" />)
        puts "MESSCADA XML - response: #{s}"
        s
      end

      r.post 'dump' do
        params = xml_interpreter.params_for_tipped_bin
        res = interactor.tip_rmt_bin(params)
        s = if res.success
              %(<ContainerMove PID="200" Mode="6" Status="true" RunNumber="#{res.instance[:run_id]}" Red="false" Yellow="false" Green="true" Msg="#{res.message}" />)
            else
              %(<ContainerMove PID="200" Mode="6" Status="false" RunNumber="" Red="true" Yellow="false" Green="false" Msg="#{unwrap_failed_response(res)}" />)
            end
        puts "MESSCADA XML - response: #{s}"
        s
      rescue Crossbeams::FrameworkError => e
        s = %(<ContainerMove PID="200" Mode="6" Status="false" RunNumber="" Red="true" Yellow="false" Green="false" Msg="#{e.message}" />)
        puts "MESSCADA XML - response: #{s}"
        s
      end
    end

    # --------------------------------------------------------------------------
    # CARTON LABELING FROM MAF / ITPC (LINE SCANNING)
    # --------------------------------------------------------------------------
    r.on 'carton_labeling' do
      r.is do
        r.post do
          params = xml_interpreter.params_for_carton_labeling
          res = MesscadaApp::AddSystemResourceIncentiveToParams.call(params)
          res = interactor.xml_carton_labeling(res.instance) if res.success
          if res.success
            res.instance
          else
            s = %(<ProductLabel PID="223" Status="false" Threading="true" LabelRenderAmount="0" Msg="#{res.message}" />)
            puts "MESSCADA XML - response: #{s}"
            s
          end
        end
      end
    end

    # CHANGE DEVICE TO GROUP LOGIN MODE
    # --------------------------------------------------------------------------
    r.on 'system_resource' do
      hr_interactor = MesscadaApp::HrInteractor.new(system_user, {}, { route_url: request.path, request_ip: request.ip }, {})
      params = xml_interpreter.params_for_login_mode_switch
      r.on 'change_to_group_login' do
        res = hr_interactor.change_resource_to_group_login_mode(params)

        feedback = if res.success
                     MesscadaApp::RobotFeedback.new(device: params[:device],
                                                    status: true,
                                                    line1: res.message)
                   else
                     MesscadaApp::RobotFeedback.new(device: params[:device],
                                                    status: false,
                                                    line1: 'Cannot change to group mode',
                                                    line4: res.message)
                   end
        Crossbeams::RobotResponder.new(feedback).render
      end

      # CHANGE DEVICE TO INDIVIDUAL LOGIN MODE
      # --------------------------------------------------------------------------
      r.on 'change_to_individual_login' do
        res = hr_interactor.change_resource_to_individual_login_mode(params)

        feedback = if res.success
                     MesscadaApp::RobotFeedback.new(device: params[:device],
                                                    status: true,
                                                    line1: res.message)
                   else
                     MesscadaApp::RobotFeedback.new(device: params[:device],
                                                    status: false,
                                                    line1: 'Cannot change to individual mode',
                                                    line4: res.message)
                   end
        Crossbeams::RobotResponder.new(feedback).render
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
