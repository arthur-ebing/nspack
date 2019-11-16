# frozen_string_literal: true

module MesscadaApp
  class CartonVerification < BaseService
    attr_reader :repo, :carton_quantity, :carton_is_pallet, :carton_label_id, :resource_code

    def initialize(params, carton_and_pallet_verification)
      @carton_label_id = params[:carton_number]
      @resource_code = params[:device] unless carton_and_pallet_verification
    end

    def call
      @repo = MesscadaApp::MesscadaRepo.new
      @carton_quantity = 1
      @carton_is_pallet = AppConst::CARTON_EQUALS_PALLET
      res = carton_verification
      raise Crossbeams::InfoError, unwrap_failed_response(res) unless res.success

      ok_response
    end

    private

    def carton_verification  # rubocop:disable Metrics/AbcSize
      return failed_response("Carton / Bin:#{carton_label_id} already verified") if carton_label_carton_exists?

      carton_params = carton_label_carton_params.to_h.merge(carton_label_id: carton_label_id)

      id = DB[:cartons].insert(carton_params)
      MesscadaApp::CreatePalletFromCarton.new(id, carton_quantity).call if carton_is_pallet

      ok_response
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def carton_label_carton_exists?
      repo.carton_label_carton_exists?(carton_label_id)
    end

    def carton_label_carton_params
      repo.find_hash(:carton_labels, carton_label_id).reject { |k, _| %i[id resource_id label_name carton_equals_pallet active created_at updated_at].include?(k) }
    end
  end
end
