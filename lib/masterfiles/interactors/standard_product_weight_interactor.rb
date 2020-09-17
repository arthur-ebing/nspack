# frozen_string_literal: true

module MasterfilesApp
  class StandardProductWeightInteractor < BaseInteractor
    def create_standard_product_weight(params) # rubocop:disable Metrics/AbcSize
      res = validate_standard_product_weight_params(params)
      return validation_failed_response(res) if res.failure?

      id = nil
      repo.transaction do
        ratio_to_standard_carton = calculate_ratio_to_standard_carton(res) unless res[:standard_carton_nett_weight].nil?
        attrs = if ratio_to_standard_carton
                  res.to_h.merge(ratio_to_standard_carton: ratio_to_standard_carton)
                else
                  res
                end
        id = repo.create_standard_product_weight(attrs)
        log_status(:standard_product_weights, id, 'CREATED')
        log_transaction
      end
      instance = standard_product_weight(id)
      success_response("Created standard product weight #{instance.id}", instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { id: ['This standard product weight already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_standard_product_weight(id, params)  # rubocop:disable Metrics/AbcSize
      res = validate_standard_product_weight_params(params)
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        ratio_to_standard_carton = calculate_ratio_to_standard_carton(res, id) unless res[:standard_carton_nett_weight].nil?
        attrs = if ratio_to_standard_carton
                  res.to_h.merge(ratio_to_standard_carton: ratio_to_standard_carton)
                else
                  res
                end
        repo.update_standard_product_weight(id, attrs)
        log_transaction
      end
      instance = standard_product_weight(id)
      success_response("Updated standard product weight #{instance.id}", instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_standard_product_weight(id)
      name = standard_product_weight(id).id
      repo.transaction do
        repo.delete_standard_product_weight(id)
        log_status(:standard_product_weights, id, 'DELETED')
        log_transaction
      end
      success_response("Deleted standard product weight #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def derive_ratios(id)
      instance = standard_product_weight(id)
      repo.transaction do
        repo.update_same_commodity_ratios(instance.commodity_id, instance.standard_carton_nett_weight, id)
      end
      success_response('Standard Carton ratios calculated successfully')
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def derive_all_ratios
      repo.transaction do
        repo.standard_carton_product_weights.each do |instance|
          repo.update_same_commodity_ratios(instance[:commodity_id], instance[:standard_carton_nett_weight], instance[:id])
        end
      end
      success_response('Standard Carton ratios calculated successfully')
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::StandardProductWeight.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    private

    def repo
      @repo ||= FruitSizeRepo.new
    end

    def standard_product_weight(id)
      repo.find_standard_product_weight_flat(id)
    end

    def calculate_ratio_to_standard_carton(attrs, standard_product_weight_id = nil)
      ratio_to_standard_carton = if attrs[:is_standard_carton]
                                   repo.update_same_commodity_ratios(attrs[:commodity_id], attrs[:standard_carton_nett_weight], standard_product_weight_id)
                                   1
                                 else
                                   std_carton_nett_weight = repo.standard_carton_nett_weight(attrs[:commodity_id])
                                   std_carton_nett_weight.nil? ? nil : std_carton_nett_weight / attrs[:standard_carton_nett_weight]
                                 end
      ratio_to_standard_carton.nil? ? nil : ratio_to_standard_carton.to_f.round(5)
    end

    def validate_standard_product_weight_params(params)
      StandardProductWeightSchema.call(params)
    end
  end
end
