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

    def re_receive_file(file)
      logger = Logger.new(File.join(ENV['ROOT'], 'log', 'edi_in.log'), 'weekly')
      new_path = File.join(AppConst::EDI_RECEIVE_DIR, File.basename(file))

      logger.info("Re-receive: Moving: #{file} to #{new_path}")
      FileUtils.mv(file, new_path)

      logger.info("Re-receive: Enqueuing #{new_path} for EdiApp::Job::ReceiveEdiIn")
      Que.enqueue new_path, job_class: 'EdiApp::Job::ReceiveEdiIn', queue: AppConst::QUEUE_NAME

      success_response('The file has been enqued to be re-processed.')
    end

    def re_receive_file_from_transaction(id)
      repo = EdiInRepo.new
      full_path = repo.file_path_for_edi_in_transaction(id)
      re_receive_file(full_path)
    end
  end
end
