# frozen_string_literal: true

module MesscadaApp
  class HrInteractor < BaseInteractor
    def register_identifier(params) # rubocop:disable Metrics/AbcSize
      res = validate_identifier_for_registration(params)
      return validation_failed_response(res) unless res.messages.empty?

      return success_response('Already registered.') if repo.exists?(:personnel_identifiers, identifier: res[:value])

      id = nil
      repo.transaction do
        id = repo.create_personnel_identifier(res)
        log_status(:personnel_identifiers, id, 'CREATED')
        log_transaction
      end
      success_response('Registered')
    rescue Crossbeams::InfoError => e
      ErrorMailer.send_exception_email(e, subject: self.class.name, message: decorate_mail_message('register_identifier'))
      puts e.message
      puts e.backtrace.join("\n")
      failed_response(e.message)
    end

    def start_bulk_registration(id)
      mes_module = DB[:mes_modules].where(id: id).get(:module_code)

      res = messerver_repo.bulk_registration_mode(mes_module)
      return res unless res.success

      DB[:mes_modules].where(id: id).update(bulk_registration_mode: true)
      success_response("Module #{mes_module} is in Bulk Registraion Mode", bulk_registration_mode: true)
    end

    def stop_bulk_registration(id)
      mes_module = DB[:mes_modules].where(id: id).get(:module_code)

      res = messerver_repo.bulk_registration_mode(mes_module, false)
      return res unless res.success

      DB[:mes_modules].where(id: id).update(bulk_registration_mode: false)
      success_response("Module #{mes_module} is out of Bulk Registraion Mode", bulk_registration_mode: false)
    end

    def logon(params)
      name = repo.contract_worker_name(params[:identifier])
      return failed_response("#{params[:identifier]} not assigned") if name.nil_or_empty?

      success_response('Logged on', contract_worker: name)
    end

    def logoff(params)
      name = repo.contract_worker_name(params[:identifier])
      return failed_response("#{params[:identifier]} not assigned") if name.nil_or_empty?

      success_response('Logged off', contract_worker: name)
    end

    private

    def repo
      @repo ||= HrRepo.new
    end

    def messerver_repo
      @messerver_repo ||= MesserverApp::MesserverRepo.new
    end

    def validate_identifier_for_registration(params)
      RegisterIdentifierSchema.call(params)
    end
  end
end
