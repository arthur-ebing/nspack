# frozen_string_literal: true

module EdiApp
  class ActionsInteractor < BaseInteractor
    def send_ps(params)
      res = check_for_recent_job(params[:party_role_id])
      return res unless res.success

      EdiApp::SendEdiOut.call(AppConst::EDI_FLOW_PS, params[:party_role_id], @user.user_name)
    end

    def check_for_recent_job(id)
      return failed_response('There is already a job enqueued to send PS') if EdiApp::Job::SendEdiOut.enqueued_with_args?(AppConst::EDI_FLOW_PS, id)

      # Check for anything enqueued within 5 mins...
      ok_response
    end
  end
end
