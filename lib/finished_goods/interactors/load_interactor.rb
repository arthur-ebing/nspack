# frozen_string_literal: true

module FinishedGoodsApp
  class LoadInteractor < BaseInteractor # rubocop:disable Metrics/ClassLength
    def create_load(params) # rubocop:disable Metrics/AbcSize
      res = validate_load_params(params)
      return validation_failed_response(res) unless res.messages.empty?

      id = nil
      repo.transaction do
        load_res = CreateLoadService.call(res, @user.user_name)
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
        load_res = UpdateLoadService.call(id, res, @user.user_name)
        raise Crossbeams::InfoError, load_res.message unless load_res.success

        log_transaction
      end
      instance = load_entity(id)
      success_response("Updated load #{id}", instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def ship_load(id)
      repo.transaction do
        res = ShipLoad.call(id, @user.user_name)
        raise Crossbeams::InfoError, res.message unless res.success

        log_transaction
      end
      instance = load_entity(id)
      success_response("Shipped load #{id}", instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def unship_load(id)
      repo.transaction do
        res = UnshipLoad.call(id, @user.user_name)
        raise Crossbeams::InfoError, res.message unless res.success

        log_transaction
      end
      instance = load_entity(id)
      success_response("Unshipped load #{id}", instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def allocate_pallets_from_multiselect(id, pallet_sequence_id) # rubocop:disable Metrics/AbcSize
      pallet_numbers = repo.find_pallet_numbers_from(pallet_sequence_id: pallet_sequence_id)
      validated_pallet_numbers = repo.validate_pallets(pallet_numbers, shipped: false)
      new_allocation = repo.find_pallet_ids_from(pallet_numbers: validated_pallet_numbers)
      current_allocation = repo.find_pallet_ids_from(load_id: id)

      repo.transaction do
        repo.allocate_pallets(id, new_allocation - current_allocation, @user.user_name)
        repo.unallocate_pallets(current_allocation - new_allocation, @user.user_name)
        log_transaction
      end
      success_response("Load #{id} has been updated")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def allocate_pallets_from_list(id, params) # rubocop:disable Metrics/AbcSize
      res = validate_pallet_list(params)
      return validation_failed_response(res) unless res.success

      repo.transaction do
        load_res = repo.allocate_pallets(id, res.instance, @user.user_name)
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
      pallet_numbers = attrs.map { |x| x.gsub(/['"]/, '') }

      errors = pallet_numbers.reject { |x| x.match(/\A\d+\Z/) }
      message = "#{errors.join(', ')} must be numeric"
      return OpenStruct.new(success: false, messages: { pallet_list: [message] }) unless errors.nil_or_empty?

      errors = (pallet_numbers - repo.validate_pallets(pallet_numbers))
      message = "#{errors.join(', ')} doesn't exist"
      return OpenStruct.new(success: false, messages: { pallet_list: [message] }) unless errors.nil_or_empty?

      errors = repo.validate_pallets(pallet_numbers, allocated: true)
      message = "#{errors.join(', ')} already allocated"
      return OpenStruct.new(success: false, messages: { pallet_list: [message] }) unless errors.nil_or_empty?

      errors = repo.validate_pallets(pallet_numbers, shipped: true)
      message = "#{errors.join(', ')} already shipped"
      return OpenStruct.new(success: false, messages: { pallet_list: [message] }) unless errors.nil_or_empty?

      OpenStruct.new(success: true, instance: repo.find_pallet_ids_from(pallet_numbers: pallet_numbers))
    end
  end
end
