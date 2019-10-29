# frozen_string_literal: true

module FinishedGoodsApp
  class LoadInteractor < BaseInteractor
    def create_load(params) # rubocop:disable Metrics/AbcSize
      res = validate_load_params(params)
      return validation_failed_response(res) unless res.messages.empty?

      id = nil
      repo.transaction do
        load_res = CreateLoadService.call(res)
        id = load_res.instance
        raise Crossbeams::InfoError, load_res.message unless load_res.success

        log_transaction
      end
      instance = load_entity(id)
      success_response("Created load #{id}", instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { order_number: ['This load already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_load(id, params) # rubocop:disable Metrics/AbcSize
      res = validate_load_params(params)
      return validation_failed_response(res) unless res.messages.empty?

      repo.transaction do
        load_res = UpdateLoadService.call(id, res)
        raise Crossbeams::InfoError, load_res.message unless load_res.success

        log_transaction
      end
      instance = load_entity(id)
      success_response("Updated load #{id}", instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def allocate_pallets_from_multiselect(id, multiselect_list)
      repo.transaction do
        repo.allocate_pallets_from_multiselect(id, multiselect_list)
        log_transaction
      end
      success_response("Loaded pallets to load #{id} ")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def allocate_pallets_from_list(id, params)
      res = validate_pallet_list(params)
      return validation_failed_response(res) unless res.errors.empty?

      repo.transaction do
        load_res = repo.allocate_pallets_from_list(id, res)
        raise Crossbeams::InfoError, load_res.message unless load_res.success

        log_transaction
      end
      success_response("Loaded pallets to load #{id} ")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_load(id)
      load_voyage_id = LoadVoyageRepo.new.find_load_voyage_id(id)
      repo.transaction do
        # DELETE LOAD_VOYAGE
        LoadVoyageRepo.new.delete_load_voyage(load_voyage_id)
        log_status('load_voyages', load_voyage_id, 'DELETED')

        # DELETE LOAD
        repo.delete_load(id)
        log_status('loads', id, 'DELETED')
        log_transaction
      end
      success_response("Deleted load #{id}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::Load.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    private

    def repo
      @repo ||= LoadRepo.new
    end

    def load_entity(id)
      repo.find_load_flat(id)
    end

    def validate_load_params(params)
      LoadSchema.call(params)
    end

    def validate_pallet_list(params) # rubocop:disable Metrics/AbcSize
      attrs = params[:pallet_list].split(/\n|,/).map(&:strip).reject(&:empty?)
      pallet_numbers = attrs.map { |x| x }

      errors = attrs.reject { |x| x.match(/\A\d+\Z/) }
      message = "#{errors.join(', ')} must be numeric"
      return validation_failed_response(OpenStruct.new(messages: { pallet_list: [message] })) unless errors.nil_or_empty?

      pallet_exists = repo.pallets_exists(pallet_numbers)
      errors = (pallet_numbers - pallet_exists)
      message = "#{errors.join(', ')} doesn't exist"
      return validation_failed_response(OpenStruct.new(messages: { pallet_list: [message] })) unless errors.nil_or_empty?

      errors = repo.pallets_allocated(pallet_exists)
      message = "#{errors.join(', ')} already allocated"
      return validation_failed_response(OpenStruct.new(messages: { pallet_list: [message] })) unless errors.nil_or_empty?

      params[:pallet_list] = pallet_numbers
      PalletListSchema.call(params)
    end
  end
end
