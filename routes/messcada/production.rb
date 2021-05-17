# frozen_string_literal: true

class Nspack < Roda
  route 'production', 'messcada' do |r|
    # --------------------------------------------------------------------------
    # PALLET VERIFICATION/WEIGHING/LABELLING
    # view-source:http://192.168.43.148:9296/messcada/production/pallet_verification/pallet_weighing/pallet_labeling?pallet_number=123&device=CLM101B1&gross_weight=1134&measurement_unit=kg
    # --------------------------------------------------------------------------
    r.on 'pallet_verification' do
      r.on 'pallet_weighing' do
        r.on 'pallet_labeling' do
          interactor = MesscadaApp::MesscadaInteractor.new(system_user, {}, { route_url: request.path, request_ip: request.ip }, {})
          prod_run_interactor = ProductionApp::ProductionRunInteractor.new(system_user, {}, { route_url: request.path, request_ip: request.ip }, {})

          res = interactor.pallet_weighing_for_labeling(system_user, params)
          res = prod_run_interactor.print_pallet_label(res.instance[:pallet_id], printer:  LabelApp::PrinterRepo.new.robot_peripheral_printer(params[:device]), pallet_label_name: AppConst::DEFAULT_PALLET_LABEL_NAME) if res.success

          feedback = if res.success
                       MesscadaApp::RobotFeedback.new(device: params[:device],
                                                      status: true,
                                                      line1: res.message)
                     else
                       MesscadaApp::RobotFeedback.new(device: params[:device],
                                                      status: false,
                                                      msg: unwrap_failed_response(res))
                     end
          Crossbeams::RobotResponder.new(feedback).render
        end
      end
    end
  end
end
