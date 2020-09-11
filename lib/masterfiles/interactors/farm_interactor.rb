# frozen_string_literal: true

module MasterfilesApp
  class FarmInteractor < BaseInteractor # rubocop:disable Metrics/ClassLength
    def create_farm(params) # rubocop:disable Metrics/AbcSize
      res = validate_farm_params(params)
      return validation_failed_response(res) if res.failure?

      id = nil
      repo.transaction do
        response = repo.create_farm(res)
        id = response
        log_status('farms', id, 'CREATED')
        log_transaction
      end
      instance = farm(id)
      success_response("Created farm #{instance.farm_code}",
                       instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { farm_code: ['This farm already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_farm(id, params) # rubocop:disable Metrics/AbcSize
      res = validate_farm_params(params)
      return validation_failed_response(res) if res.failure?

      attrs = res.to_h
      attrs.delete(:puc_id)

      repo.transaction do
        repo.update_farm(id, attrs)
        log_transaction
      end
      instance = farm(id)
      success_response("Updated farm #{instance.farm_code}",
                       instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_farm(id)
      name = farm(id).farm_code
      repo.transaction do
        repo.delete_farm(id)
        log_status('farms', id, 'DELETED')
        log_transaction
      end
      success_response("Deleted farm #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def create_farm_section(farm_id, params) # rubocop:disable Metrics/AbcSize
      params[:farm_id] = farm_id
      res = validate_farm_section_params(params)
      return validation_failed_response(res) if res.failure?

      id = nil
      repo.transaction do
        id = repo.create_farm_section(params)
        log_status(:farm_sections, id, 'CREATED')
        log_transaction
      end
      instance = farm_section(id)
      success_response("Created farm section #{instance.farm_section_name}",
                       instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { farm_section_name: ['This farm section already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    rescue StandardError => e
      puts e.message
      puts e.backtrace.join("\n")
      failed_response(e.message)
    end

    def update_farm_section(id, params) # rubocop:disable Metrics/AbcSize
      params[:farm_id] = repo.get(:orchards, params[:orchard_ids][0], :farm_id)
      res = validate_farm_section_params(params)
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        repo.update_farm_section(id, params)
        log_transaction
      end
      instance = farm_section(id)
      success_response("Updated farm section #{instance.farm_section_name}",
                       instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_farm_section(id) # rubocop:disable Metrics/AbcSize
      name = farm_section(id).farm_section_name
      repo.transaction do
        repo.delete_farm_section(id)
        log_status(:farm_sections, id, 'DELETED')
        log_transaction
      end
      success_response("Deleted farm section #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    rescue Sequel::ForeignKeyConstraintViolation => e
      puts e.message
      failed_response("Unable to delete farm section. It is still referenced#{e.message.partition('referenced').last}")
    end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::Farm.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    def selected_farm_groups(owner_party_role_id)
      repo.for_select_farm_groups(where: { owner_party_role_id: owner_party_role_id })
    end

    def associate_farms_pucs(id, farms_pucs_ids)
      return validation_failed_response(OpenStruct.new(messages: { farms_pucs_ids: ['You did not choose a puc'] })) if farms_pucs_ids.empty?

      repo.transaction do
        repo.associate_farms_pucs(id, farms_pucs_ids)
      end
      success_response('Farm => Puc associated successfully')
    end

    private

    def repo
      @repo ||= FarmRepo.new
    end

    def farm(id)
      repo.find_farm(id)
    end

    def validate_farm_params(params)
      FarmSchema.call(params)
    end

    def farm_section(id)
      repo.find_farm_section(id)
    end

    def validate_farm_section_params(params)
      FarmSectionSchema.call(params)
    end
  end
end
