# frozen_string_literal: true

module MesscadaApp
  class CartonVerificationAndWeighingAndLabeling < BaseService
    attr_reader :repo, :carton_label_id, :resource_code, :gross_weight, :uom, :params, :request_ip

    def initialize(params, request_ip)
      @carton_label_id = params[:carton_number]
      @params = params.to_h.merge(carton_and_pallet_verification: false)
      @uom = params[:measurement_unit]
      @request_ip = request_ip
    end

    def call
      @repo = MesscadaApp::MesscadaRepo.new

      return failed_response("Carton / Bin:#{carton_label_id} already verified") if carton_label_carton_exists?

      res = carton_verification_and_weighing_and_labeling
      raise Crossbeams::InfoError, unwrap_failed_response(res) unless res.success

      ok_response
    end

    private

    def carton_label_carton_exists?
      repo.carton_label_carton_exists?(carton_label_id)
    end

    def carton_verification_and_weighing_and_labeling
      MesscadaApp::CartonVerificationAndWeighing.new(params).call
      print_carton_nett_weight_label(carton_label_carton_id)

      ok_response
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def carton_label_carton_id
      repo.carton_label_carton_id(carton_label_id)
    end

    def print_carton_nett_weight_label(id)
      instance = carton(id)
      attrs = { gross_weight: instance[:gross_weight],
                nett_weight: instance[:nett_weight],
                weighed_date: Date.today.strftime('%Y-%m-%d'),
                uom_code: uom }
      LabelPrintingApp::PrintLabel.call(AppConst::LABEL_CARTON_VERIFICATION, instance.to_h.merge(attrs), { quantity: 1 }, request_ip)
    end

    def carton(id)
      repo.find_carton(id)
    end
  end
end
