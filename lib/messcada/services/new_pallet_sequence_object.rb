# frozen_string_literal: true

module MesscadaApp
  class NewPalletSequenceObject < BaseService
    attr_reader :repo, :carton_id, :carton, :carton_palletizing

    def initialize(user_name, carton_id, carton_quantity, carton_palletizing = false)
      @carton_id = carton_id
      @carton_quantity = carton_quantity
      @repo = MesscadaApp::MesscadaRepo.new
      @user_name = user_name
      @carton_palletizing = carton_palletizing
    end

    def call
      @carton = repo.find_carton(carton_id)
      return failed_response('Carton not found.') if carton.nil?

      params = pallet_params
      params.merge!(carton_params)
      res = PalletSequenceContract.new.call(params)
      return validation_failed_response(res) if res.failure?

      success_response('success', res.to_h)
    end

    private

    def carton_params
      carton_rejected_fields = %i[id nett_weight created_at updated_at scrapped_at]
      carton_rejected_fields << :pallet_number unless carton.carton_equals_pallet
      carton.to_h.reject { |k, _| carton_rejected_fields.include?(k) }
    end

    def pallet_params
      @carton_quantity ||= carton.cartons_per_pallet unless doing_carton_carton_palletizing?
      packhouse_no = repo.find_resource_packhouse_no(carton.packhouse_resource_id)
      {
        scanned_from_carton_id: carton_palletizing ? nil : carton_id,
        carton_quantity: @carton_quantity,
        pick_ref: UtilityFunctions.calculate_pick_ref(packhouse_no),
        created_by: @user_name
      }
    end

    def doing_carton_carton_palletizing?
      !carton.carton_equals_pallet && AppConst::USE_CARTON_PALLETIZING
    end
  end
end
