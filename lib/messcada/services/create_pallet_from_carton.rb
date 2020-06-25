# frozen_string_literal: true

module MesscadaApp
  class CreatePalletFromCarton < BaseService
    attr_reader :repo, :carton_id, :carton_quantity, :carton, :cartons_per_pallet, :pallet_id, :pallet_sequence_id,
                :user_name, :palletizing_bay_resource_id

    def initialize(user, carton_id, carton_quantity, palletizing_bay_resource_id = nil)
      @carton_id = carton_id
      @carton_quantity = carton_quantity
      @user_name = user&.user_name
      @palletizing_bay_resource_id = palletizing_bay_resource_id
    end

    def call
      @repo = MesscadaApp::MesscadaRepo.new
      @carton = find_carton

      res = create_pallet_and_sequences
      raise Crossbeams::InfoError, unwrap_failed_response(res) unless res.success

      success_response('ok', pallet_id: pallet_id, pallet_sequence_id: pallet_sequence_id)
    end

    private

    def find_carton
      repo.find_carton(carton_id)
    end

    def create_pallet_and_sequences
      return failed_response("Carton / Bin:#{carton_id} not verified") unless carton_exists?

      res = create_pallet
      return res unless res.success

      res = create_pallet_sequence
      return res unless res.success

      ok_response
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def carton_exists?
      repo.carton_exists?(carton_id)
    end

    def create_pallet
      pallet_params = set_pallet_params
      res = validate_pallet_params(pallet_params)
      return validation_failed_response(res) unless res.messages.empty?

      @pallet_id = repo.create_pallet(user_name, res.to_h)

      ok_response
    end

    def set_pallet_params  # rubocop:disable Metrics/AbcSize
      if !AppConst::CARTON_EQUALS_PALLET && AppConst::USE_CARTON_PALLETIZING && carton_quantity == 1
        partially_palletized = true
        status = AppConst::PALLETIZING
      else
        status = AppConst::PALLETIZED_NEW_PALLET
        partially_palletized = false
      end

      params = {
        status: status,
        partially_palletized: partially_palletized,
        location_id: resource_location,
        phc: carton[:phc],
        fruit_sticker_pm_product_id: carton[:fruit_sticker_pm_product_id],
        pallet_format_id: carton[:pallet_format_id],
        plt_packhouse_resource_id: carton[:packhouse_resource_id],
        plt_line_resource_id: carton[:production_line_id],
        palletizing_bay_resource_id: palletizing_bay_resource_id
      }
      params[:pallet_number] = carton[:pallet_number] if AppConst::CARTON_EQUALS_PALLET
      params
    end

    def resource_location
      repo.find_resource_location_id(carton[:packhouse_resource_id])
    end

    def validate_pallet_params(params)
      PalletSchema.call(params)
    end

    def create_pallet_sequence
      res = NewPalletSequence.call(user_name, carton_id, pallet_id, carton_quantity)
      return res unless res.success

      @pallet_sequence_id = res.instance[:pallet_sequence_id]
      ok_response
    end
  end
end
