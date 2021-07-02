# frozen_string_literal: true

module FinishedGoodsApp
  class VoyageInteractor < BaseInteractor
    def create_voyage(params)
      res = validate_voyage_params(params)
      return validation_failed_response(res) if res.failure?

      id = nil
      repo.transaction do
        id = repo.create_voyage(res)
        log_status(:voyages, id, 'CREATED')
        log_transaction
      end
      instance = voyage(id)
      success_response("Created voyage #{instance.voyage_number}", instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { voyage_number: ['This voyage already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_voyage(id, params)
      res = UpdateVoyageSchema.call(params)
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        repo.update_voyage(id, res)
        log_transaction
      end
      instance = voyage(id)
      success_response("Updated voyage #{instance.voyage_number}", instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_voyage(id) # rubocop:disable Metrics/AbcSize
      name = voyage(id).voyage_number
      vessel_id = voyage(id).vessel_id

      if id == FinishedGoodsApp::VoyageRepo.new.last_voyage_created(vessel_id)
        repo.transaction do
          # DELETE VOYAGE_PORT
          voyage_ports = FinishedGoodsApp::VoyageRepo.new.find_voyage_flat(id)&.voyage_ports
          voyage_ports.each do |voyage_port|
            VoyagePortRepo.new.delete_voyage_port(voyage_port[:id])
            log_status(:voyage_ports, voyage_port[:id], 'DELETED')
            log_transaction
          end

          # DELETE VOYAGE
          repo.delete_voyage(id)
          log_status(:voyages, id, 'DELETED')
          log_transaction
        end
        success_response("Deleted voyage #{name}")
      else
        repo.transaction do
          repo.update_voyage(id,  active: false)
          log_status(:voyages, id, 'DEACTIVATED')
          log_transaction
        end
        success_response("Deactivated voyage #{name}")
      end
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def complete_a_voyage(id)
      name = voyage(id).voyage_number
      repo.transaction do
        repo.update_voyage(id, completed_at: DateTime.now.to_s)
        complete_a_record(:voyages, id, enqueue_job: false)
        log_transaction
      end
      success_response("Completed voyage #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::Voyage.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    private

    def repo
      @repo ||= VoyageRepo.new
    end

    def voyage(id)
      repo.find_voyage_flat(id)
    end

    def validate_voyage_params(params)
      VoyageSchema.call(params)
    end
  end
end
