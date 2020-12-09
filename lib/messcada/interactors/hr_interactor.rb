# frozen_string_literal: true

module MesscadaApp
  class HrInteractor < BaseInteractor # rubocop:disable Metrics/ClassLength
    def register_identifier(params) # rubocop:disable Metrics/AbcSize
      res = validate_identifier_for_registration(params)
      return validation_failed_response(res) if res.failure?

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

      res = messerver_repo.bulk_registration_mode(mes_module, start: false)
      return res unless res.success

      DB[:mes_modules].where(id: id).update(bulk_registration_mode: false)
      success_response("Module #{mes_module} is out of Bulk Registraion Mode", bulk_registration_mode: false)
    end

    # Take params, lookup system resource and some related attributes
    # and merge them into the params as { system_resource: SystemResourceWithIncentive }.
    def merge_system_resource_incentive(params, has_button: false) # rubocop:disable Metrics/AbcSize
      device = if has_button
                 ar = params[:device].split('-')
                 ar.take(ar.length - 1).join('-')
               else
                 params[:device]
               end
      sys_res = resource_repo.system_resource_incentive_settings(device)
      return failed_response("#{device} is not configured") if sys_res.nil?
      return success_response('ok', merge_incentive_just_system_resource(sys_res, params)) if !sys_res.login && !sys_res.group_incentive
      return merge_incentive_contract_worker(sys_res, params) unless sys_res.group_incentive

      merge_incentive_group_incentive(sys_res, params)
    end

    def merge_incentive_just_system_resource(sys_res, params)
      params.merge(system_resource: ProductionApp::SystemResourceWithIncentive.new(sys_res.to_h))
    end

    def merge_incentive_contract_worker(sys_res, params)
      res = validate_device_identifier(params[:identifier])
      return res unless res.success

      sys = sys_res.to_h.merge(res.instance)
      success_response('ok', params.merge(system_resource: ProductionApp::SystemResourceWithIncentive.new(sys)))
    end

    def validate_device_identifier(identifier)
      personnel_identifier_id = repo.personnel_identifier_id_from_device_identifier(identifier)
      return failed_response('Invalid identifier') if personnel_identifier_id.nil?

      contract_worker_id = repo.contract_worker_id_from_personnel_id(personnel_identifier_id)
      return failed_response('This identifier is not assigned') if contract_worker_id.nil?

      success_response('ok', { personnel_identifier_id: personnel_identifier_id, contract_worker_id: contract_worker_id })
    end

    def merge_incentive_group_incentive(sys_res, params)
      group_incentive_id = get_system_resource_group_incentive(sys_res.id)
      return failed_response('There is no active group') if group_incentive_id.nil?

      res = validate_device_identifier(params[:identifier])
      return res unless res.success

      default = res.instance.merge({ group_incentive_id: group_incentive_id })
      attrs = params.merge(system_resource: ProductionApp::SystemResourceWithIncentive.new(sys_res.to_h.merge(default)))
      success_response('ok', attrs)
    end

    def logon(params)  # rubocop:disable Metrics/AbcSize
      return ok_response unless params[:system_resource][:login]

      name = repo.contract_worker_name(params[:identifier])
      return success_response('Logged on', contract_worker: name)  unless params[:system_resource][:group_incentive]

      res = nil
      repo.transaction do
        res = group_incentive_login(params[:system_resource], name)
      end
      res
    rescue Crossbeams::InfoError => e
      ErrorMailer.send_exception_email(e, subject: self.class.name, message: decorate_mail_message('logon'))
      puts e.message
      puts e.backtrace.join("\n")
      failed_response(e.message)
    rescue StandardError => e
      ErrorMailer.send_exception_email(e, subject: self.class.name, message: decorate_mail_message('logon'))
      puts e.message
      puts e.backtrace.join("\n")
      failed_response(e.message)
    end

    def group_incentive_login(system_resource, contract_worker_name)
      packer_already_in_group = repo.packer_belongs_to_incentive_group?(system_resource[:group_incentive_id], system_resource[:contract_worker_id])
      return success_response('Packer already logged on', contract_worker: contract_worker_name) if packer_already_in_group

      packer_in_another_group = repo.packer_belongs_to_active_incentive_group?(system_resource[:contract_worker_id])
      return add_packer_to_incentive_group(system_resource, contract_worker_name) unless packer_in_another_group

      move_packer_to_incentive_group(system_resource, contract_worker_name)
    end

    def add_packer_to_incentive_group(system_resource, contract_worker_name)
      repo.add_packer_to_incentive_group(system_resource)

      success_response("Packer added to group #{system_resource[:group_incentive_id]}", contract_worker: contract_worker_name)
    end

    def move_packer_to_incentive_group(system_resource, contract_worker_name)
      prev_group_incentive_id = repo.contract_worker_active_group_incentive_id(system_resource[:contract_worker_id])
      repo.remove_packer_from_incentive_group(prev_group_incentive_id, system_resource[:contract_worker_id])
      repo.add_packer_to_incentive_group(system_resource)

      success_response("Packer moved from group #{prev_group_incentive_id} to group #{system_resource[:group_incentive_id]}", contract_worker: contract_worker_name)
    end

    def logoff(params)
      name = repo.contract_worker_name(params[:identifier])
      return failed_response("#{params[:identifier]} not assigned") if name.nil_or_empty?

      success_response('Logged off', contract_worker: name)
    end

    def logon_with_no(params)
      name = repo.contract_worker_name_by_no(params[:identifier])
      return failed_response("#{params[:identifier]} is not a valid personnel number") if name.nil_or_empty?

      success_response('Logged on', contract_worker: name)
    end

    def logoff_with_no(params)
      name = repo.contract_worker_name_by_no(params[:identifier])
      return failed_response("#{params[:identifier]} is not a valid personnel number") if name.nil_or_empty?

      success_response('Logged off', contract_worker: name)
    end

    private

    def repo
      @repo ||= HrRepo.new
    end

    def messerver_repo
      @messerver_repo ||= MesserverApp::MesserverRepo.new
    end

    def resource_repo
      @resource_repo ||= ProductionApp::ResourceRepo.new
    end

    def validate_identifier_for_registration(params)
      RegisterIdentifierSchema.call(params)
    end

    def get_system_resource_group_incentive(system_resource_id)
      repo.create_group_incentive({ system_resource_id: system_resource_id }) unless active_system_resource_group_exists?(system_resource_id)
      repo.active_group_incentive_id(system_resource_id)
    end

    def active_system_resource_group_exists?(system_resource_id)
      repo.active_system_resource_group_exists?(system_resource_id)
    end
  end
end
