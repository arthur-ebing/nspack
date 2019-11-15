# frozen_string_literal: true

module MesscadaApp
  class CreatePalletFromCarton < BaseService
    attr_reader :repo, :carton_id, :carton_quantity, :carton, :cartons_per_pallet, :pallet, :pallet_sequence

    def initialize(carton_id, carton_quantity)
      @carton_id = carton_id
      @carton_quantity = carton_quantity
    end

    def call
      @repo = MesscadaApp::MesscadaRepo.new
      @carton = find_carton

      res = create_pallet_and_sequences
      raise Crossbeams::InfoError, unwrap_failed_response(res) unless res.success

      ok_response
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

      @pallet = repo.create_pallet(res.to_h)

      ok_response
    end

    def set_pallet_params
      {
        status: AppConst::PALLETIZED_NEW_PALLET,
        location_id: resource_location,
        phc: carton[:phc],
        fruit_sticker_pm_product_id: carton[:fruit_sticker_pm_product_id],
        pallet_format_id: carton[:pallet_format_id],
        plt_packhouse_resource_id: carton[:packhouse_resource_id],
        plt_line_resource_id: carton[:production_line_id],
        pallet_number: carton[:pallet_number]
      }
    end

    def resource_location
      repo.find_resource_location_id(carton[:packhouse_resource_id])
    end

    # def resource_phc
    #   repo.find_resource_phc(carton[:production_line_id]) || repo.find_resource_phc(carton[:packhouse_resource_id])
    # end

    def validate_pallet_params(params)
      PalletSchema.call(params)
    end

    def create_pallet_sequence
      res = NewPalletSequence.new(carton_id, pallet, carton_quantity).call
      return res unless res.success

      ok_response
    end
  end
end
