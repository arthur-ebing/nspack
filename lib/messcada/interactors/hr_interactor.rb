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
      ErrorMailer.send_exception_email(e, subject: self.class.name, message: decorate_mail_message(__method__))
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

    def change_resource_to_group_login_mode(params)
      id = resource_repo.get_value(:system_resources, :id, system_resource_code: params[:device])
      return failed_response("Resource #{params[:device]} not found") if id.nil?

      resource_repo.update_system_resource(id, group_incentive: true)
      success_response('Changed to group login mode')
    end

    def change_resource_to_individual_login_mode(params)
      id = resource_repo.get_value(:system_resources, :id, system_resource_code: params[:device])
      return failed_response("Resource #{params[:device]} not found") if id.nil?

      resource_repo.update_system_resource(id, group_incentive: false, login: true)
      success_response('Changed to individual login mode')
    end

    def login_with_identifier(params) # rubocop:disable Metrics/AbcSize
      return failed_response("Login not set: #{params[:device]}") unless params[:system_resource][:login]

      name = repo.contract_worker_name(params[:identifier])

      if params[:system_resource][:group_incentive]
        login_group(name, params)
      else
        login_individual(name, params)
      end
    rescue StandardError => e
      ErrorMailer.send_exception_email(e, subject: self.class.name, message: decorate_mail_message(__method__))
      puts e.message
      puts e.backtrace.join("\n")
      failed_response(e.message)
    end

    def login_individual(name, params)
      res = nil
      repo.transaction do
        res = repo.login_worker(name, params)
      end
      res
    end

    def login_group(name, params)
      res = nil
      group_incentive_id = repo.active_group_incentive_id(params[:system_resource].id)
      system_resource = ProductionApp::SystemResourceWithIncentive.new(params[:system_resource].to_h.merge(group_incentive_id: group_incentive_id))
      repo.transaction do
        repo.logout_worker(system_resource[:contract_worker_id])
        res = group_incentive_login(system_resource, name)
      end
      res
    end

    def group_incentive_login(system_resource, contract_worker_name) # rubocop:disable Metrics/AbcSize
      packer_in_another_group = repo.packer_belongs_to_active_incentive_group?(system_resource[:contract_worker_id])

      # If there is no group for this resource, create it with this worker as a member:
      unless active_system_resource_group_exists?(system_resource.id)
        repo.create_group_incentive({ system_resource_id: system_resource.id, contract_worker_ids: [system_resource.contract_worker_id] })
        # Remove from previous group if allocated
        remove_packer_from_previous_incentive_group(system_resource) if packer_in_another_group
        return success_response('Packer logged on', contract_worker: contract_worker_name)
      end

      packer_already_in_group = repo.packer_belongs_to_incentive_group?(system_resource.group_incentive_id, system_resource[:contract_worker_id])
      return success_response('Packer already logged on', contract_worker: contract_worker_name) if packer_already_in_group

      return add_packer_to_incentive_group(system_resource, contract_worker_name) unless packer_in_another_group

      move_packer_to_incentive_group(system_resource, contract_worker_name)
    end

    def add_packer_to_incentive_group(system_resource, contract_worker_name)
      repo.add_packer_to_incentive_group(system_resource)

      success_response("Packer added to group #{system_resource[:group_incentive_id]}", contract_worker: contract_worker_name)
    end

    def remove_packer_from_previous_incentive_group(system_resource)
      prev_group_incentive_id = repo.contract_worker_active_group_incentive_id(system_resource[:contract_worker_id])
      repo.remove_packer_from_incentive_group(prev_group_incentive_id, system_resource[:contract_worker_id])
    end

    def move_packer_to_incentive_group(system_resource, contract_worker_name)
      prev_group_incentive_id = repo.contract_worker_active_group_incentive_id(system_resource[:contract_worker_id])
      repo.remove_packer_from_incentive_group(prev_group_incentive_id, system_resource[:contract_worker_id])
      repo.add_packer_to_incentive_group(system_resource)

      success_response("Packer moved from group #{prev_group_incentive_id} to group #{system_resource[:group_incentive_id]}", contract_worker: contract_worker_name)
    end

    def logout(params) # rubocop:disable Metrics/AbcSize, Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
      return failed_response("Login not set: #{params[:device]}") unless params[:system_resource][:login] && params[:system_resource][:logoff]

      name = repo.contract_worker_name(params[:identifier])
      return failed_response("#{params[:identifier]} not assigned") if name.nil_or_empty?

      # This temporary code put in place until the palletizing robot stops sending a logout with a login.
      if params[:device]
        system_resource_id = resource_repo.get_value(:system_resources, :id, system_resource_code: params[:device])
        plant_type = resource_repo.plant_resource_type_code_for_system_resource(system_resource_id)
        return success_response('Logout ignored for palletizing') if plant_type == Crossbeams::Config::ResourceDefinitions::PALLETIZING_ROBOT
      end

      res = nil
      repo.transaction do
        res = if params[:system_resource][:contract_worker_id]
                repo.logout_worker(params[:system_resource][:contract_worker_id])
              else
                repo.logout_device(params[:device])
              end
      end
      res
    rescue StandardError => e
      ErrorMailer.send_exception_email(e, subject: self.class.name, message: decorate_mail_message(__method__))
      puts e.message
      puts e.backtrace.join("\n")
      failed_response(e.message)
    end

    def login_with_no(params) # rubocop:disable Metrics/AbcSize
      return failed_response("Login not set: #{params[:device]}") unless params[:system_resource][:login]

      name = repo.contract_worker_name_by_no(params[:identifier])
      return failed_response("#{params[:identifier]} is not a valid personnel number") if name.nil_or_empty?

      if params[:system_resource][:group_incentive]
        login_group(name, params)
      else
        login_individual(name, params)
      end
    rescue StandardError => e
      ErrorMailer.send_exception_email(e, subject: self.class.name, message: decorate_mail_message(__method__))
      puts e.message
      puts e.backtrace.join("\n")
      failed_response(e.message)
    end

    def logout_with_no(params) # rubocop:disable Metrics/AbcSize
      return failed_response("Login not set: #{params[:device]}") unless params[:system_resource][:login] && params[:system_resource][:logoff]

      name = repo.contract_worker_name_by_no(params[:identifier])
      return failed_response("#{params[:identifier]} is not a valid personnel number") if name.nil_or_empty?

      res = nil
      repo.transaction do
        res = repo.logout_worker(params[:system_resource][:contract_worker_id])
      end
      res
    rescue StandardError => e
      ErrorMailer.send_exception_email(e, subject: self.class.name, message: decorate_mail_message(__method__))
      puts e.message
      puts e.backtrace.join("\n")
      failed_response(e.message)
    end

    def logout_device(params) # rubocop:disable Metrics/AbcSize
      res = nil
      repo.transaction do
        res = repo.logout_device(params[:device])
      end
      res
    rescue StandardError => e
      ErrorMailer.send_exception_email(e, subject: self.class.name, message: decorate_mail_message(__method__))
      puts e.message
      puts e.backtrace.join("\n")
      failed_response(e.message)
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

    def active_system_resource_group_exists?(system_resource_id)
      repo.active_system_resource_group_exists?(system_resource_id)
    end
  end
end
