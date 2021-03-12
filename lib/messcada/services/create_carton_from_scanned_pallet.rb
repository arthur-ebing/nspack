# frozen_string_literal: true

module MesscadaApp
  class CreateCartonFromScannedPallet < BaseService
    attr_reader :repo, :params, :pallet_number, :carton_id

    def initialize(pallet_number, params)
      @pallet_number = pallet_number
      @params = params
      @repo = MesscadaApp::MesscadaRepo.new
    end

    def call
      res = create_pallet_number_carton
      raise Crossbeams::InfoError, unwrap_failed_response(res) unless res.success

      success_response('ok', carton_id: carton_id)
    end

    private

    def create_pallet_number_carton # rubocop:disable Metrics/AbcSize
      return failed_response('Pallet number not given') if pallet_number.nil_or_empty?

      return failed_response("Pallet number: #{pallet_number} could not be found") unless carton_label_exists_for_pallet?

      res = validate_carton_params(params.merge(carton_label_id: pallet_number_carton_label_id))
      return validation_failed_response(res) if res.failure?

      @carton_id = repo.create(:cartons, res)

      ok_response
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def validate_carton_params(params)
      CartonSchema.call(params)
    end

    def carton_label_exists_for_pallet?
      !pallet_number_carton_label_id.nil?
    end

    def pallet_number_carton_label_id
      @pallet_number_carton_label_id ||= repo.carton_label_id_for_pallet_no(pallet_number)
    end
  end
end
