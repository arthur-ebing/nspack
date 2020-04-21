# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
class Nspack < Roda
  route 'carton_palletizing', 'messcada' do |r|
    # palletizing interactor...
    interactor = MesscadaApp::PalletizingInteractor.new(system_user, {}, { route_url: request.path, request_ip: request.ip }, {})

    # --------------------------------------------------------------------------
    # SCAN CARTON - either to add to a pallet, as a QC carton or to return to bay
    # messcada/palletize/scan_carton
    # --------------------------------------------------------------------------
    r.on 'scan_carton' do
      res = interactor.scan_carton(params)
      feedback = interactor.palletizing_robot_feedback(params[:device], res)
      Crossbeams::RobotResponder.new(feedback).render
    end

    # --------------------------------------------------------------------------
    # QC OUT - place the bay in state to scan a QC carton
    # --------------------------------------------------------------------------
    r.on 'qc_out' do
      res = interactor.qc_out(params)
      feedback = interactor.palletizing_robot_feedback(params[:device], res)
      Crossbeams::RobotResponder.new(feedback).render
    end

    # --------------------------------------------------------------------------
    # RETURN TO BAY - place the bay in state to scan a carton from a partial pallet
    # --------------------------------------------------------------------------
    r.on 'return_to_bay' do
      res = interactor.return_to_bay(params)
      feedback = interactor.palletizing_robot_feedback(params[:device], res)
      Crossbeams::RobotResponder.new(feedback).render
    end

    # --------------------------------------------------------------------------
    # REFRESH - Refresh the state of the bay
    # --------------------------------------------------------------------------
    r.on 'refresh' do
      res = interactor.refresh(params)
      feedback = interactor.palletizing_robot_feedback(params[:device], res)
      Crossbeams::RobotResponder.new(feedback).render
    end

    # --------------------------------------------------------------------------
    # COMPLETE - Complete the current pallet and empty the bay
    # --------------------------------------------------------------------------
    r.on 'complete' do
      res = interactor.complete(params)
      feedback = interactor.palletizing_robot_feedback(params[:device], res)
      Crossbeams::RobotResponder.new(feedback).render
    end
  end
end
# rubocop:enable Metrics/BlockLength
