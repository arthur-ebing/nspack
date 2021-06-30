# frozen_string_literal: true

module MesscadaApp
  class NewPalletSequenceObject < BaseService
    attr_reader :repo, :carton_id, :carton, :carton_quantity, :cartons_per_pallet, :user_name, :carton_palletizing, :carton_equals_pallet

    def initialize(user_name, carton_id, carton_quantity, carton_palletizing = false)
      @carton_id = carton_id
      @carton_quantity = carton_quantity
      @repo = MesscadaApp::MesscadaRepo.new
      @user_name = user_name
      @carton_palletizing = carton_palletizing
    end

    def call
      @carton = repo.find_carton(carton_id)
      @cartons_per_pallet = repo.find_cartons_per_pallet(carton[:cartons_per_pallet_id])
      @carton_equals_pallet = repo.carton_label_carton_equals_pallet(carton[:carton_label_id])

      make_pallet_sequence_object
    end

    private

    def make_pallet_sequence_object  # rubocop:disable Metrics/AbcSize
      attrs = pallet_sequence_carton_params.to_h.merge(pallet_sequence_pallet_params).to_h
      attrs = attrs.merge(created_by: user_name).to_h
      res = validate_pallet_sequence_params(attrs)
      return validation_failed_response(res) if res.failure?

      attrs = attrs.to_h
      treatment_ids = attrs.delete(:treatment_ids)
      attrs = attrs.merge(treatment_ids: "{#{treatment_ids.join(',')}}") unless treatment_ids.nil?

      success_response('success', attrs)
    end

    def pallet_sequence_carton_params
      # TODO: refactor: instead of reject change to select required fields.
      # method broke when added a field to find_carton

      carton_rejected_fields = %i[id resource_id label_name fruit_sticker_pm_product_id carton_label_id gross_weight nett_weight
                                  phc pallet_label_name active created_at updated_at packing_method_id palletizer_identifier_id palletizer_contract_worker_id
                                  pallet_sequence_id palletizing_bay_resource_id is_virtual scrapped scrapped_reason scrapped_at scrapped_sequence_id
                                  group_incentive_id rmt_bin_id dp_carton]
      carton_rejected_fields << :pallet_number unless carton_equals_pallet
      repo.find_carton(carton_id).to_h.reject { |k, _| carton_rejected_fields.include?(k) }
    end

    def pallet_sequence_pallet_params
      quantity = if !carton_equals_pallet && AppConst::USE_CARTON_PALLETIZING
                   carton_quantity
                 else
                   carton_quantity.nil? ? cartons_per_pallet : carton_quantity
                 end

      scanned_from_carton_id = carton_palletizing ? nil : carton_id
      {
        scanned_from_carton_id: scanned_from_carton_id,
        carton_quantity: quantity,
        pick_ref: UtilityFunctions.calculate_pick_ref(packhouse_no)
      }
    end

    def packhouse_no
      repo.find_resource_packhouse_no(carton[:packhouse_resource_id])
    end

    def validate_pallet_sequence_params(params)
      contract = PalletSequenceContract.new
      contract.call(params.transform_values { |v| v.is_a?(Sequel::Postgres::PGArray) ? v.to_a : v })
    end
  end
end
