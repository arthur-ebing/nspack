# frozen_string_literal: true

module MesscadaApp
  # Take params, lookup system resource and some related attributes
  # and merge them into the params as { system_resource: SystemResourceWithIncentive }.
  class AddSystemResourceIncentiveToParams < BaseService
    attr_reader :params, :get_group_incentive, :sys_res, :repo, :resource_repo, :device, :origin, :has_button

    def initialize(params, has_button: false, get_group_incentive: true)
      super()
      @params = params
      @has_button = has_button
      @device = if has_button
                  ar = params[:device].split('-')
                  ar.take(ar.length - 1).join('-')
                else
                  params[:device]
                end
      @origin = if has_button
                  params[:device]
                else
                  params[:packpoint]
                end
      @get_group_incentive = get_group_incentive
      @repo = MesscadaApp::HrRepo.new
      @resource_repo = ProductionApp::ResourceRepo.new
      # work out packpoint if required...
      @button_packpoint = @resource_repo.packpoint_for_button(params[:device]) if has_button
    end

    def call # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      # If a button was pressed, make sure it has been defined as a system resource or packpoint.
      # (button could be defined in the robot config, but not in the system_resources table)
      raise Crossbeams::InfoError, "#{params[:device]} does not exist" if has_button && @button_packpoint.nil? && params[:packpoint].nil?

      @sys_res = resource_repo.system_resource_incentive_settings(device, params[:packpoint] || @button_packpoint, origin, params[:card_reader])
      return failed_response("#{device} is not configured") if sys_res.nil?
      return success_response('ok', merge_incentive_just_system_resource) if !sys_res.login && !sys_res.group_incentive
      return merge_incentive_contract_worker unless get_group_incentive && sys_res.group_incentive

      merge_incentive_group_incentive
    rescue StandardError => e
      ErrorMailer.send_exception_email(e, subject: "#{self.class.name} : #{e.message}", message: <<~STR)
        params: #{params.inspect}
        device: #{device}
        origin: #{origin}
        btnpck: #{@button_packpoint}

        #{e.message}
      STR
      puts e.message
      puts e.backtrace.join("\n")
      failed_response(e.message)
    end

    private

    def merge_incentive_just_system_resource
      params.merge(system_resource: ProductionApp::SystemResourceWithIncentive.new(sys_res.to_h))
    end

    def merge_incentive_contract_worker # rubocop:disable Metrics/AbcSize
      res = if params[:identifier_is_person]
              validate_personnel_number(params[:identifier])
            else
              validate_device_identifier(params[:identifier])
            end
      return res unless res.success

      sys = sys_res.to_h.merge(res.instance)
      success_response('ok', params.merge(system_resource: ProductionApp::SystemResourceWithIncentive.new(sys)))
    end

    def validate_personnel_number(personnel_number)
      contract_worker_id = repo.contract_worker_id_from_personnel_number(personnel_number)
      return failed_response('This personnel number does not exist') if contract_worker_id.nil?

      success_response('ok', { personnel_identifier_id: nil, contract_worker_id: contract_worker_id, identifier: nil })
    end

    def validate_device_identifier(identifier)
      personnel_identifier_id = repo.personnel_identifier_id_from_device_identifier(identifier)
      return failed_response('Invalid identifier') if personnel_identifier_id.nil?

      contract_worker_id = repo.contract_worker_id_from_personnel_id(personnel_identifier_id)
      return failed_response("#{identifier} not assigned") if contract_worker_id.nil?

      success_response('ok', { personnel_identifier_id: personnel_identifier_id, contract_worker_id: contract_worker_id, identifier: identifier })
    end

    def merge_incentive_group_incentive
      group_incentive_id = repo.active_group_incentive_id(sys_res.id)
      return failed_response('No active group') if group_incentive_id.nil?

      attrs = params.merge(system_resource: ProductionApp::SystemResourceWithIncentive.new(sys_res.to_h.merge(group_incentive_id: group_incentive_id)))
      success_response('ok', attrs)
    end
  end
end
