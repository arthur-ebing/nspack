# frozen_string_literal: true

module RawMaterialsApp
  class RmtBinInteractor < BaseInteractor
    def create_rmt_bin(delivery_id, params) # rubocop:disable Metrics/AbcSize
      delivery = find_rmt_delivery(delivery_id)
      params = params.merge(get_header_inherited_field(delivery, params[:rmt_container_type_id]))
      res = validate_rmt_bin_params(params)
      return validation_failed_response(res) unless res.messages.empty?

      id = nil
      repo.transaction do
        id = repo.create_rmt_bin(res)
        log_status('rmt_bins', id, 'BIN_RECEIVED')
        log_transaction
      end
      instance = rmt_bin(id)
      success_response("Created rmt bin #{instance.status}",
                       instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { status: ['This rmt bin already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def get_header_inherited_field(delivery, container_type_id)
      # TO DO: rmt_inner_container_material_id #HANS : There's more than one value. Which one to set
      # Are the farm_id and puc_id also inherited from delivery header???
      { rmt_delivery_id: delivery.id,
        orchard_id: delivery.orchard_id,
        season_id: delivery.season_id,
        bin_received_date_time: delivery.date_delivered.to_s, # TO DO: ask James
        farm_id: delivery.farm_id,
        puc_id: delivery.puc_id,
        rmt_inner_container_type_id: repo.rmt_container_type_rmt_inner_container_type(container_type_id) }
    end

    def update_rmt_bin(id, params) # rubocop:disable Metrics/AbcSize
      delivery = find_rmt_delivery_by_bin_id(id)
      params = params.merge(get_header_inherited_field(delivery, params[:rmt_container_type_id]))
      res = validate_rmt_bin_params(params)
      return validation_failed_response(res) unless res.messages.empty?

      repo.transaction do
        repo.update_rmt_bin(id, res)
        log_transaction
      end
      instance = rmt_bin(id)
      success_response("Updated rmt bin #{instance.status}",
                       instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_rmt_bin(id)
      name = rmt_bin(id).status
      repo.transaction do
        repo.delete_rmt_bin(id)
        log_status('rmt_bins', id, 'DELETED')
        log_transaction
      end
      success_response("Deleted rmt bin #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def find_container_material_owners_by_container_material_type(container_material_type_id)
      repo.find_container_material_owners_by_container_material_type(container_material_type_id)
    end

    def find_rmt_delivery(id)
      repo.find(:rmt_deliveries, RawMaterialsApp::RmtDelivery, id)
    end

    def find_rmt_delivery_by_bin_id(id)
      repo.find_rmt_delivery_by_bin_id(id)
    end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::RmtBin.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    private

    def repo
      @repo ||= RmtDeliveryRepo.new
    end

    def rmt_bin(id)
      repo.find_rmt_bin(id)
    end

    def validate_rmt_bin_params(params)
      RmtBinSchema.call(params)
    end
  end
end
