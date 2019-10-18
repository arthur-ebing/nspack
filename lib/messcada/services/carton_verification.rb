# frozen_string_literal: true

module MesscadaApp
  class CartonVerification < BaseService
    attr_reader :repo, :carton_quantity, :carton_is_pallet, :carton_label_id, :resource_code

    def initialize(params)
      @carton_label_id = params[:carton_number]
      @resource_code = params[:device]
    end

    def call
      @repo = MesscadaApp::MesscadaRepo.new
      @carton_quantity = 1
      @carton_is_pallet = (AppConst::CARTONS_IS_PALLETS == 'true')
      return failed_response("Carton / Bin:#{carton_label_id} already verified") if carton_label_carton_exists?

      res = create_carton
      return res unless res.success

      ok_response
    end

    private

    def carton_label_carton_exists?
      repo.carton_label_carton_exists?(carton_label_id)
    end

    def create_carton
      carton_params = carton_label_carton_params.to_h.merge(carton_label_id: carton_label_id)

      repo.transaction do
        id = DB[:cartons].insert(carton_params)
        res = MesscadaApp::CreatePalletFromCarton.new(id, carton_quantity).call if carton_is_pallet
        return res unless res.success

        # ProductionApp::RunStatsUpdateJob.enqueue(id, 'CARTON_PACKED')
      end
      ok_response
    end

    def carton_label_carton_params
      repo.find_hash(:carton_labels, carton_label_id).reject { |k, _| %i[id resource_id label_name active created_at updated_at].include?(k) }
    end
  end
end
