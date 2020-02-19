# frozen_string_literal: true

class Nspack < Roda
  route 'hr', 'messcada' do |r|
    # REGISTER PERSONNEL IDENTIFIERS
    # --------------------------------------------------------------------------
    r.on 'register_id' do
      interactor = MesscadaApp::HrInteractor.new(system_user, {}, { route_url: request.path, request_ip: request.ip }, {})
      res = interactor.register_identifier(params)

      if res.success
        "Successfully registered #{params[:value]}"
      else
        "Unable to add #{params[:value]}. Please try again (#{res.message}"
      end
    end
    # Login/out
    # personnel_login_events (includes group id when applicable)
    # person, identifier?, group, login_at
    # personnel_logout_events (includes group id when applicable)
    # person, identifier?, group, logout_at
    # incentive_groups
    # group_id, opened_at, closed_at
  end
end
