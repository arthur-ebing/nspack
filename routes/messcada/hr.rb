# frozen_string_literal: true

class Nspack < Roda
  route 'hr', 'messcada' do |r|
    interactor = MesscadaApp::HrInteractor.new(system_user, {}, { route_url: request.path, request_ip: request.ip }, {})

    # REGISTER PERSONNEL IDENTIFIERS
    # --------------------------------------------------------------------------
    r.on 'register_id' do
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
      Crossbeams::RobotResponder.new(feedback).render
    end

    r.on 'logon' do
      res = MesscadaApp::AddSystemResourceIncentiveToParams.call(params, get_group_incentive: false)
      res = interactor.login_with_identifier(res.instance) if res.success

      if fetch?(r)
        { success: res.success,
          message: res.success ? "#{res.instance[:contract_worker]} logged on" : res.message }.to_json
      else
        feedback = if res.success
                     MesscadaApp::RobotFeedback.new(device: params[:device],
                                                    status: true,
                                                    line1: res.instance[:contract_worker],
                                                    line3: 'Logged on',
                                                    line4: res.message)
                   else
                     MesscadaApp::RobotFeedback.new(device: params[:device],
                                                    status: false,
                                                    line1: 'Cannot login',
                                                    line4: res.message)
                   end
        Crossbeams::RobotResponder.new(feedback).render
      end
    end

    r.on 'logoff' do
      res = MesscadaApp::AddSystemResourceIncentiveToParams.call(params, get_group_incentive: false)
      res = interactor.logout(res.instance) if res.success

      if fetch?(r)
        { success: res.success,
          message: res.success ? "#{res.instance[:contract_worker]} logged off" : res.message }.to_json
      else
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
        Crossbeams::RobotResponder.new(feedback).render
      end
    end

    r.on 'logon_with_no' do
      res = MesscadaApp::AddSystemResourceIncentiveToParams.call(params.merge(identifier_is_person: true), get_group_incentive: false)
      res = interactor.login_with_no(res.instance) if res.success

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
      resp = Crossbeams::RobotResponder.new(feedback)
      resp.extra_elements = { identifier: res.instance[:identifier] } if res.success && res.instance[:identifier]
      resp.render
    end

    r.on 'logoff_with_no' do
      res = MesscadaApp::AddSystemResourceIncentiveToParams.call(params.merge(identifier_is_person: true), get_group_incentive: false)
      res = interactor.logout_with_no(res.instance) if res.success

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
      Crossbeams::RobotResponder.new(feedback).render
    end

    r.on 'modules', Integer do |id|
      r.on 'start_bulk_registration' do
        r.get do
          show_partial do
            Messcada::Hr::Modules::Confirm.call(id,
                                                url: "/messcada/hr/modules/#{id}/start_bulk_registration",
                                                notice: 'Press the button to place this module in bulk regitration mode.<p>Then apply identifier tags or cards to the robot to register their codes.</p>',
                                                button_captions: ['Start', 'Starting...'])
          end
        end
        r.post do
          res = interactor.start_bulk_registration(id)
          if res.success
            update_grid_row(id, changes: { bulk_registration_mode: res.instance[:bulk_registration_mode] }, notice: res.message)
          else
            show_json_error(res.message, status: 200)
          end
        end
      end

      r.on 'stop_bulk_registration' do
        r.get do
          show_partial do
            Messcada::Hr::Modules::Confirm.call(id,
                                                url: "/messcada/hr/modules/#{id}/stop_bulk_registration",
                                                notice: 'Press the button to take this module out of bulk regitration mode.',
                                                button_captions: ['Stop', 'Stopping...'])
          end
        end
        r.post do
          res = interactor.stop_bulk_registration(id)
          if res.success
            update_grid_row(id, changes: { bulk_registration_mode: res.instance[:bulk_registration_mode] }, notice: res.message)
          else
            show_json_error(res.message)
          end
        end
      end
    end
  end
end
