# frozen_string_literal: true

module MesscadaApp
  class CartonVerificationAndWeighingAndLabeling < BaseService
    attr_reader :repo, :carton_label_id, :resource_code, :gross_weight, :uom, :params

    def initialize(params)
      @carton_label_id = params[:carton_number]
      @params = params
    end

    def call
      @repo = MesscadaApp::MesscadaRepo.new

      return failed_response("Carton / Bin:#{carton_label_id} already verified") if carton_label_carton_exists?

      res = carton_verification_and_weighing_and_labeling
      return res unless res.success

      ok_response
    end

    private

    def carton_label_carton_exists?
      repo.carton_label_carton_exists?(carton_label_id)
    end

    def carton_verification_and_weighing_and_labeling
      repo.transaction do
        res = MesscadaApp::CartonVerificationAndWeighing.new(params).call
        return res unless res.success

        print_carton_nett_weight_label(carton_label_carton_id)
      end
      ok_response
    end

    def carton_label_carton_id
      repo.carton_label_carton_id(carton_label_id)
    end

    def print_carton_nett_weight_label(id)
      instance = carton(id)
      attrs = { gross_weight: instance[:gross_weight],
                nett_weight: instance[:nett_weight],
                uom: uom }
      LabelPrintingApp::PrintLabel.call(AppConst::LABEL_BIN_BARCODE, instance, attrs)
    end

    def carton(id)
      repo.find_carton(id)
    end
  end
end
