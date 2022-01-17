# frozen_string_literal: true

module RawMaterialsApp
  module Job
    class GenerateDeliveryReport < BaseQueJob
      self.maximum_retry_count = 0

      def run(id, output_dir)
        rmt_delivery = RawMaterialsApp::RmtDeliveryRepo.new.find_rmt_delivery_flat(id)
        file_name = [rmt_delivery.farm_code,
                     rmt_delivery.orchard_code,
                     rmt_delivery.cultivar_code,
                     rmt_delivery.reference_number,
                     id,
                     Time.now.strftime('%Y_%m_%d')].join('_')

        jasper_params = JasperParams.new('delivery',
                                         'System',
                                         delivery_id: id,
                                         client_code: AppConst::CLIENT_CODE)
        jasper_params.output_dir = output_dir
        jasper_params.file_name = file_name
        # FarmNumber_OrchardNumber_CultivarCode_ReferenceNumber_DeliveryID_Date
        res = CreateJasperReport.call(jasper_params)

        raise res.message unless res.success

        finish
      end
    end
  end
end
