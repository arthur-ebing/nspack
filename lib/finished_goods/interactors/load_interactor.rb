# frozen_string_literal: true

module FinishedGoodsApp
  class LoadInteractor < BaseInteractor
    def create_load(params) # rubocop:disable Metrics/AbcSize
      res = validate_load_params(params)
      return validation_failed_response(res) unless res.messages.empty?

      params = res.to_h
      load_id = nil
      repo.transaction do
        # CREATE VOYAGE
        params[:voyage], params[:load] = params.partition { |k, _| %i[voyage_type_id vessel_id voyage_number year].include? k }.map(&:to_h)
        voyage_id = FinishedGoodsApp::VoyageRepo.new.lookup_voyage(params[:voyage])
        voyage_id = VoyageRepo.new.create_voyage(params[:voyage]) if voyage_id.nil?
        log_status('voyages', voyage_id, 'CREATED')
        log_transaction

        # CREATE VOYAGE_PORT
        params[:voyage_port] = { pol_voyage_port_id: params[:load].delete(:pol_port_id), pod_voyage_port_id: params[:load].delete(:pod_port_id) }
        params[:voyage_port].each do |key, port_id|
          voyage_port_id = FinishedGoodsApp::VoyagePortRepo.new.lookup_voyage_port(voyage_id: voyage_id, port_id: port_id)
          voyage_port_id = VoyagePortRepo.new.create_voyage_port(voyage_id: voyage_id, port_id: port_id) if voyage_port_id.nil?
          log_status('voyage_ports', voyage_port_id, 'CREATED')
          log_transaction
          params[:load][key] = voyage_port_id
        end

        # CREATE LOAD
        params[:load_voyage], params[:load] = params[:load].partition { |k, _| %i[shipping_line_party_role_id shipper_party_role_id booking_reference memo_pad].include? k }.map(&:to_h)
        load_id = repo.create_load(params[:load])
        log_status('loads', load_id, 'CREATED')
        log_transaction

        # CREATE LOAD_VOYAGE
        params[:load_voyage][:voyage_id] = voyage_id
        params[:load_voyage][:load_id] = load_id
        load_voyages_id = LoadVoyageRepo.new.create_load_voyage(params[:load_voyage])
        log_status('load_voyages', load_voyages_id, 'CREATED')
        log_transaction
      end
      instance = load(load_id)
      success_response("Created load #{instance.order_number}",
                       instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { order_number: ['This load already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_load(load_id, params) # rubocop:disable Metrics/AbcSize
      res = validate_load_params(params)
      return validation_failed_response(res) unless res.messages.empty?

      params = res.to_h
      repo.transaction do
        # CREATE VOYAGE
        params[:voyage], params[:load] = params.partition { |k, _| %i[voyage_type_id vessel_id voyage_number year].include? k }.map(&:to_h)
        voyage_id = FinishedGoodsApp::VoyageRepo.new.lookup_voyage(params[:voyage])
        voyage_id = VoyageRepo.new.create_voyage(params[:voyage]) if voyage_id.nil?
        log_status('voyages', voyage_id, 'CREATED')
        log_transaction

        # CREATE VOYAGE_PORT
        params[:voyage_port] = { pol_voyage_port_id: params[:load].delete(:pol_port_id), pod_voyage_port_id: params[:load].delete(:pod_port_id) }
        params[:voyage_port].each do |key, port_id|
          voyage_port_id = FinishedGoodsApp::VoyagePortRepo.new.lookup_voyage_port(voyage_id: voyage_id, port_id: port_id)
          voyage_port_id = VoyagePortRepo.new.create_voyage_port(voyage_id: voyage_id, port_id: port_id) if voyage_port_id.nil?
          log_status('voyage_ports', voyage_port_id, 'CREATED')
          log_transaction
          params[:load][key] = voyage_port_id
        end

        # UPDATE LOAD
        params[:load_voyage], params[:load] = params[:load].partition { |k, _| %i[shipping_line_party_role_id shipper_party_role_id booking_reference memo_pad].include? k }.map(&:to_h)
        repo.update_load(load_id, params[:load])
        log_transaction

        # UPDATE LOAD_VOYAGE
        load_voyage_id = FinishedGoodsApp::LoadVoyageRepo.new.find_load_voyage_id(load_id: load_id)
        params[:load_voyage][:voyage_id] = voyage_id
        LoadVoyageRepo.new.update_load_voyage(load_voyage_id, params[:load_voyage])
        log_transaction
      end
      instance = load(load_id)
      success_response("Updated load #{instance.order_number}", instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_load(load_id) # rubocop:disable Metrics/AbcSize
      name = load(load_id).order_number
      load_voyage_id = FinishedGoodsApp::LoadVoyageRepo.new.find_load_voyage_id(load_id: load_id)

      repo.transaction do
        # DELETE LOAD_VOYAGE
        LoadVoyageRepo.new.delete_load_voyage(load_voyage_id)
        log_status('load_voyages', load_voyage_id, 'DELETED')
        log_transaction

        # DELETE LOAD
        repo.delete_load(load_id)
        log_status('loads', load_id, 'DELETED')
        log_transaction
      end
      success_response("Deleted load #{name}")
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

    def load(id)
      repo.find_load(id)
    end

    def validate_load_params(params)
      LoadSchema.call(params)
    end
  end
end
