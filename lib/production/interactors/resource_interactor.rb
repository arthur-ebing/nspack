# frozen_string_literal: true

module ProductionApp
  class ResourceInteractor < BaseInteractor # rubocop:disable Metrics/ClassLength
    def create_root_plant_resource(params) # rubocop:disable Metrics/AbcSize
      res = validate_plant_resource_params(params)
      return validation_failed_response(res) unless res.messages.empty?

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
      return validation_failed_response(res) unless res.messages.empty?

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
      return validation_failed_response(res) unless res.messages.empty?

      repo.transaction do
        repo.update_plant_resource(id, res)
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

    private

    def repo
      @repo ||= ResourceRepo.new
    end

    def plant_resource(id)
      repo.find_plant_resource(id)
    end

    def validate_plant_resource_params(params)
      PlantResourceSchema.call(params)
    end
  end
end
