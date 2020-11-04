# frozen_string_literal: true

class Nspack < Roda
  route 'robot', 'messcada' do |r|
    # --------------------------------------------------------------------------
    # ROBOT API
    # --------------------------------------------------------------------------
    r.on 'api' do
      response['Content-Type'] = 'application/json'
      json_robot_interface = JsonRobotInterface.new(request, params)
      res = json_robot_interface.check_params
      if res.success
        json_robot_interface.process_request.to_json
      else
        json_robot_interface.process_invalid_params.to_json
      end
    end
  end
end
