# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
class Nspack < Roda
  route 'production', 'messcada' do |r| # rubocop:disable Metrics/BlockLength
    # --------------------------------------------------------------------------
    # PALLET VERIFICATION/WEIGHING/LABELLING
    # view-source:http://192.168.43.148:9296/messcada/production/pallet_verification/pallet_weighing/pallet_labeling?pallet_number=123&device=CLM101B1&gross_weight=1134&measurement_unit=kg
    # --------------------------------------------------------------------------
    r.on 'pallet_verification' do
      r.on 'pallet_weighing' do
        r.on 'pallet_labeling' do
          interactor = MesscadaApp::MesscadaInteractor.new(system_user, {}, { route_url: request.path, request_ip: request.ip }, {})
          prod_run_interactor = ProductionApp::ProductionRunInteractor.new(system_user, {}, { route_url: request.path, request_ip: request.ip }, {})

          res = if AppConst::COMBINE_CARTON_AND_PALLET_VERIFICATION
                  interactor.carton_to_be_verified(params)
                else
                  interactor.pallet_to_be_verified(params)
                end

          return render_error_result(res) unless res.success

          seq1 = res.instance
          interactor.find_pallet_sequences_from_same_pallet(seq1).each do |id|
            res = interactor.verify_pallet_sequence(id, system_user, verification_result: 'passed')
            return render_error_result(res) unless res.success
          end

          res = interactor.fg_pallet_weighing(bin_number: params[:pallet_number], gross_weight: params[:gross_weight], measurement_unit: params[:measurement_unit])
          return render_error_result(res) unless res.success

          res = prod_run_interactor.print_pallet_label_from_sequence(seq1, params[:device], pallet_label_name: AppConst::DEFAULT_PALLET_LABEL_NAME)
          return render_error_result(res) unless res.success

          feedback = MesscadaApp::RobotFeedback.new(device: params[:device],
                                                    status: true,
                                                    line1: res.message)
          Crossbeams::RobotResponder.new(feedback).render
        end
      end
    end
  end

  def render_error_result(res)
    feedback = MesscadaApp::RobotFeedback.new(device: params[:device],
                                              status: true,
                                              msg: unwrap_failed_response(res))
    Crossbeams::RobotResponder.new(feedback).render
  end
end
# rubocop:enable Metrics/BlockLength
