# frozen_string_literal: true

module RawMaterialsApp
  class BinLoadInteractor < BaseInteractor # rubocop:disable Metrics/ClassLength
    def create_bin_load(params) # rubocop:disable Metrics/AbcSize
      res = validate_bin_load_params(params)
      return validation_failed_response(res) unless res.messages.empty?

      id = nil
      repo.transaction do
        id = repo.create_bin_load(res)
        log_status(:bin_loads, id, 'CREATED')
        log_transaction
      end
      instance = bin_load(id)
      success_response("Created Bin Load #{instance.id}", instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { id: ['This Bin Load already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_bin_load(id, params)
      res = validate_bin_load_params(params)
      return validation_failed_response(res) unless res.messages.empty?

      repo.transaction do
        repo.update_bin_load(id, res)
        log_transaction
      end
      instance = bin_load(id)
      success_response("Updated Bin Load #{instance.id}", instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_bin_load(id)
      name = bin_load(id).id
      repo.transaction do
        repo.delete_bin_load(id)
        log_status(:bin_loads, id, 'DELETED')
        log_transaction
      end
      success_response("Deleted Bin Load #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def complete_bin_load(id)
      params = { completed: true, completed_at: Time.now }

      repo.transaction do
        repo.update_bin_load(id, params)
        log_status(:bin_loads, id, 'COMPLETED')
        log_transaction
      end
      instance = bin_load(id)
      success_response("Completed Bin Load #{instance.id}", instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def reopen_bin_load(id)
      repo.transaction do
        repo.update_bin_load(id, completed: false, completed_at: nil)
        log_status(:bin_loads, id, 'REOPENED')
        log_transaction
      end
      instance = bin_load(id)
      success_response("Reopened Bin Load #{instance.id}", instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def ship_bin_load(id, product_bin)
      repo.transaction do
        repo.ship_bin_load(id, product_bin, @user)
        log_transaction
      end
      instance = bin_load(id)
      success_response("Shipped Bin Load #{instance.id}", instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def unship_bin_load(id)
      repo.transaction do
        repo.unship_bin_load(id, @user)
        log_transaction
      end
      instance = bin_load(id)
      success_response("Unshipped Bin Load #{instance.id}", instance)
    rescue Sequel::UniqueConstraintViolation
      failed_response('Bin Asset Number allocated elsewhere, Unable to unship load.')
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def stepper(step_key)
      @stepper ||= BinLoadStep.new(step_key, @user, @context.request_ip)
    end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::BinLoad.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    def validate!(task, id = nil, params = nil)
      res = TaskPermissionCheck::BinLoad.call(task, id, params)
      raise Crossbeams::InfoError, res.message unless res.success
    end

    def rmt_bins_matching_bin_load(column, args)
      repo.rmt_bins_matching_bin_load(column, args)
    end

    private

    def repo
      @repo ||= BinLoadRepo.new
    end

    def bin_load(id)
      repo.find_bin_load(id)
    end

    def validate_bin_load_params(params)
      BinLoadSchema.call(params)
    end
  end
end
