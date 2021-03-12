# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
class Nspack < Roda
  route 'carton_palletizing', 'messcada' do |r|
    # palletizing interactor...
    interactor = MesscadaApp::PalletizingInteractor.new(system_user, {}, { route_url: request.path, request_ip: request.ip }, {})

    ok_to_palletize = AppConst::USE_CARTON_PALLETIZING
    ok_to_palletize = false if AppConst::CR_PROD.carton_equals_pallet?
    unless ok_to_palletize
      feedback = MesscadaApp::RobotFeedback.new(device: params[:device],
                                                status: false,
                                                line1: 'Application not available',
                                                line2: 'Please contact support')
      return Crossbeams::RobotResponder.new(feedback).render
    end

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
      res = interactor.request_complete(params)
      feedback = interactor.palletizing_robot_feedback(params[:device], res)
      Crossbeams::RobotResponder.new(feedback).render
    end

    # --------------------------------------------------------------------------
    # COMPLETE PALLET - Complete the current pallet and empty the bay
    # --------------------------------------------------------------------------
    r.on 'complete_pallet' do
      res = interactor.complete_pallet(params)
      feedback = interactor.palletizing_robot_feedback(params[:device], res)
      Crossbeams::RobotResponder.new(feedback).render
    end

    # --------------------------------------------------------------------------
    # COMPLETE AUTOPACK_PALLET
    # --------------------------------------------------------------------------
    r.on 'complete_autopack_pallet' do
      res = interactor.complete_autopack_pallet(params)
      feedback = interactor.palletizing_robot_feedback(params[:device], res)
      Crossbeams::RobotResponder.new(feedback).render
    end

    # --------------------------------------------------------------------------
    # TRANSFER CARTON - Transfer carton to the current bay from an empty bay
    # --------------------------------------------------------------------------
    r.on 'empty_bay_carton_transfer' do
      res = interactor.empty_bay_carton_transfer(params)
      feedback = interactor.palletizing_robot_feedback(params[:device], res)
      Crossbeams::RobotResponder.new(feedback).render
    end

    # --------------------------------------------------------------------------
    # TRANSFER CARTON - Transfer carton to the current bay
    # --------------------------------------------------------------------------
    r.on 'transfer_carton' do
      res = interactor.transfer_carton(params)
      feedback = interactor.palletizing_robot_feedback(params[:device], res)
      Crossbeams::RobotResponder.new(feedback).render
    end
  end
end
# rubocop:enable Metrics/BlockLength
