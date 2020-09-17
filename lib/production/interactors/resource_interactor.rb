# frozen_string_literal: true

module ProductionApp
  class ResourceInteractor < BaseInteractor # rubocop:disable Metrics/ClassLength
    def create_root_plant_resource(params) # rubocop:disable Metrics/AbcSize
      res = validate_plant_resource_params(params)
      return validation_failed_response(res) if res.failure?

      id = nil
      repo.transaction do
        id = repo.create_root_plant_resource(res)
        log_status('plant_resources', id, 'CREATED')
        log_transaction
      end
      instance = plant_resource(id)
      success_response("Created plant resource #{instance.plant_resource_code}",
                       instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { plant_resource_code: ['This plant resource already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def add_3_4_buttons # rubocop:disable Metrics/AbcSize
      qry = <<~SQL
        SELECT id, (SELECT id FROM plant_resource_types WHERE plant_resource_type_code = 'ROBOT_BUTTON') AS btn_type_id, plant_resource_code, description
        FROM plant_resources
        WHERE plant_resource_type_id = (SELECT id FROM plant_resource_types WHERE plant_resource_type_code = 'CLM_ROBOT')
      SQL
      DB[qry].all.each do |robot|
        btn3_code = "#{robot[:plant_resource_code]}-B3"
        btn3_desc = "#{robot[:description]} Button 3"
        btn4_code = "#{robot[:plant_resource_code]}-B4"
        btn4_desc = "#{robot[:description]} Button 4"
        create_plant_resource(robot[:id], plant_resource_type_id: robot[:btn_type_id].to_s, plant_resource_code: btn3_code, description: btn3_desc)
        create_plant_resource(robot[:id], plant_resource_type_id: robot[:btn_type_id].to_s, plant_resource_code: btn4_code, description: btn4_desc)
      end
    end

    def create_plant_resource(parent_id, params) # rubocop:disable Metrics/AbcSize
      res = validate_plant_resource_params(params)
      return validation_failed_response(res) if res.failure?

      id = nil
      repo.transaction do
        id = repo.create_child_plant_resource(parent_id, res)
        log_status('plant_resources', id, 'CREATED')
        log_transaction
      end
      instance = plant_resource(id)
      success_response("Created plant resource #{instance.plant_resource_code}",
                       instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { plant_resource_code: ['This plant resource already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_plant_resource(id, params) # rubocop:disable Metrics/AbcSize
      res = validate_plant_resource_params(params)
      return validation_failed_response(res) if res.failure?

      current = plant_resource(id)
      name_changed = current.plant_resource_code != res[:plant_resource_code]
      repo.transaction do
        repo.update_plant_resource(id, res, name_changed)
        log_transaction
      end
      instance = plant_resource(id)
      success_response("Updated plant resource #{instance.plant_resource_code}",
                       instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { plant_resource_code: ['This plant resource already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_plant_resource(id)
      name = plant_resource(id).plant_resource_code
      repo.transaction do
        repo.delete_plant_resource(id)
        log_status('plant_resources', id, 'DELETED')
        log_transaction
      end
      success_response("Deleted plant resource #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def set_module_resource(id, params)
      res = validate_system_resource_module_params(params)
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        repo.update_system_resource(id, res)
        log_transaction
      end
      instance = system_resource(id)
      success_response("Updated system resource #{instance.system_resource_code}",
                       instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def set_peripheral_resource(id, params)
      res = validate_system_resource_peripheral_params(params)
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        repo.update_system_resource(id, res)
        log_transaction
      end
      instance = system_resource(id)
      success_response("Updated system resource #{instance.system_resource_code}",
                       instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::PlantResource.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    def next_peripheral_code(plant_resource_type_id)
      return success_response('ok', next_code: '', readonly: false) if plant_resource_type_id.blank?

      code = repo.next_peripheral_code(plant_resource_type_id)
      success_response('ok', next_code: code, readonly: !code.empty?)
    end

    def link_peripherals(plant_resource_id, peripheral_ids)
      linked_items = nil
      repo.transaction do
        linked_items = repo.link_peripherals(plant_resource_id, peripheral_ids)
      end
      success_response('Linked peripherals to resource', linked_items)
    end

    def get_location_lookup(location_id)
      success_response('ok', MasterfilesApp::LocationRepo.new.find_location(location_id))
    end

    def system_resource_xml_for(id)
      success_response('ok',
                       config: ProductionApp::BuildModuleConfigXml.call(id).instance)
    end

    def system_resource_xml
      success_response('ok',
                       modules: ProductionApp::BuildModulesXml.call.instance,
                       peripherals: ProductionApp::BuildPeripheralsXml.call.instance)
    end

    def download_modules_xml
      success_response('ok', ProductionApp::BuildModulesXml.call.instance)
    end

    def download_peripherals_xml
      success_response('ok', ProductionApp::BuildPeripheralsXml.call.instance)
    end

    def bulk_add_ptms(id, params)
      res = validate_plant_resource_ptm_params(params)
      return validation_failed_response(res) if res.failure?

      srv_res = nil
      repo.transaction do
        srv_res = BulkAddPalletizerRobot.call(id, res)
      end
      srv_res
    end

    def bulk_add_clms(id, params)
      res = validate_plant_resource_clm_params(params)
      return validation_failed_response(res) if res.failure?
      return validation_failed_message_response(no_clms_per_printer: ['Not yet implemented - must be "1" for now']) if res[:no_clms_per_printer] != 1

      srv_res = nil
      repo.transaction do
        srv_res = BulkAddCartonLabelRobot.call(id, res)
      end
      srv_res
    end

    private

    def repo
      @repo ||= ResourceRepo.new
    end

    def plant_resource(id)
      repo.find_plant_resource(id)
    end

    def system_resource(id)
      repo.find_system_resource(id)
    end

    def validate_plant_resource_params(params)
      PlantResourceSchema.call(params)
    end

    def validate_plant_resource_ptm_params(params)
      PlantResourceBulkPtmSchema.call(params)
    end

    def validate_plant_resource_clm_params(params)
      PlantResourceBulkClmSchema.call(params)
    end

    def validate_system_resource_module_params(params)
      SystemResourceModuleSchema.call(params)
    end

    def validate_system_resource_peripheral_params(params)
      SystemResourcePeripheralSchema.call(params)
    end
  end
end
