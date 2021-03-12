# frozen_string_literal: true

module MesscadaApp
  class CreateCartonFromScannedCartonLabel < BaseService
    attr_reader :repo, :params, :carton_label_id, :carton_id

    def initialize(carton_label_id, params)
      @carton_label_id = carton_label_id
      @params = params
      @repo = MesscadaApp::MesscadaRepo.new
    end

    def call
      res = create_carton_label_carton
      raise Crossbeams::InfoError, unwrap_failed_response(res) unless res.success

      success_response('ok', carton_id: carton_id)
    end

    private

    def create_carton_label_carton # rubocop:disable Metrics/AbcSize
      return failed_response('Carton label not given') if carton_label_id.nil_or_empty?

      return failed_response("Carton label: #{carton_label_id} could not be found") unless carton_label_exists?

      return failed_response("Carton label: #{carton_label_id} already verified") if carton_label_carton_exists?

      res = validate_carton_params(params.merge(carton_label_id: carton_label_id))
      return validation_failed_response(res) if res.failure?

      @carton_id = repo.create(:cartons, res)

      ok_response
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def carton_label_exists?
      repo.carton_label_exists?(carton_label_id)
    end

    def carton_label_carton_exists?
      repo.carton_label_carton_exists?(carton_label_id)
    end

    def validate_carton_params(params)
      CartonSchema.call(params)
    end
  end
end
