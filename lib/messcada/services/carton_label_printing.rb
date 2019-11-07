# frozen_string_literal: true

module MesscadaApp
  class CartonLabelPrinting < BaseService
    attr_reader :repo, :carton_label_id, :uom, :request_ip

    def initialize(params, request_ip)
      @carton_label_id = params[:carton_number]
      @uom = params[:measurement_unit]
      @request_ip = request_ip
    end

    def call
      @repo = MesscadaApp::MesscadaRepo.new
      res = carton_label_printing
      raise Crossbeams::InfoError, unwrap_failed_response(res) unless res.success

      ok_response
    end

    private

    def carton_label_printing
      return failed_response("Carton / Bin:#{carton_label_id} not verified") unless carton_label_carton_exists?

      print_carton_nett_weight_label(carton)

      ok_response
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def carton_label_carton_exists?
      repo.carton_label_carton_exists?(carton_label_id)
    end

    def carton
      repo.where(:cartons, MesscadaApp::Carton, carton_label_id: carton_label_id)
    end

    def print_carton_nett_weight_label(instance)
      attrs = { gross_weight: instance[:gross_weight],
                nett_weight: instance[:nett_weight],
                weighed_date: Date.today.strftime('%Y-%m-%d'),
                uom_code: uom }
      LabelPrintingApp::PrintLabel.call(AppConst::LABEL_CARTON_VERIFICATION, instance.to_h.merge(attrs), { quantity: 1 }, request_ip)
    end
  end
end
