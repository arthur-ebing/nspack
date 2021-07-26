# frozen_string_literal: true

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

    if interactor.device_handled_by_rmd?(params[:device])
      feedback = MesscadaApp::RobotFeedback.new(device: params[:device],
                                                status: false,
                                                line1: 'Application not available',
                                                line2: 'RMD (mobile device) is',
                                                line3: "acting as #{params[:device]}")
      return Crossbeams::RobotResponder.new(feedback).render
    end

    # --------------------------------------------------------------------------
    # SCAN CARTON - either to add to a pallet, as a QC carton or to return to bay
    # messcada/palletize/scan_carton
    # --------------------------------------------------------------------------
    r.on 'scan_carton' do
      res = MesscadaApp::AddIdentifierToLoginWithNo.call(params)
      res = interactor.scan_carton(res.instance) if res.success
      feedback = interactor.palletizing_robot_feedback(params[:device], res)
      Crossbeams::RobotResponder.new(feedback).render
    rescue Rack::QueryParser::InvalidParameterError => e
      ErrorMailer.send_exception_email(e, subject: 'Carton palletizing scan invalid parameter', message: "Invalid param from route: #{request.path} with #{request.query_string}")

      feedback = MesscadaApp::RobotFeedback.new(device: '',
                                                status: false,
                                                line1: 'Unable to read barcode')
      return Crossbeams::RobotResponder.new(feedback).render
    end

    # --------------------------------------------------------------------------
    # QC OUT - place the bay in state to scan a QC carton
    # --------------------------------------------------------------------------
    r.on 'qc_out' do
      res = MesscadaApp::AddIdentifierToLoginWithNo.call(params)
      res = interactor.qc_out(res.instance) if res.success
      feedback = interactor.palletizing_robot_feedback(params[:device], res)
      Crossbeams::RobotResponder.new(feedback).render
    end

    # --------------------------------------------------------------------------
    # RETURN TO BAY - place the bay in state to scan a carton from a partial pallet
    # --------------------------------------------------------------------------
    r.on 'return_to_bay' do
      res = MesscadaApp::AddIdentifierToLoginWithNo.call(params)
      res = interactor.return_to_bay(res.instance) if res.success
      feedback = interactor.palletizing_robot_feedback(params[:device], res)
      Crossbeams::RobotResponder.new(feedback).render
    end

    # --------------------------------------------------------------------------
    # REFRESH - Refresh the state of the bay
    # --------------------------------------------------------------------------
    r.on 'refresh' do
      res = MesscadaApp::AddIdentifierToLoginWithNo.call(params)
      res = interactor.refresh(res.instance) if res.success
      feedback = interactor.palletizing_robot_feedback(params[:device], res)
      Crossbeams::RobotResponder.new(feedback).render
    end

    # --------------------------------------------------------------------------
    # COMPLETE - Complete the current pallet and empty the bay
    # --------------------------------------------------------------------------
    r.on 'complete' do
      res = MesscadaApp::AddIdentifierToLoginWithNo.call(params)
      res = interactor.request_complete(res.instance) if res.success
      feedback = interactor.palletizing_robot_feedback(params[:device], res)
      Crossbeams::RobotResponder.new(feedback).render
    end

    # --------------------------------------------------------------------------
    # COMPLETE PALLET - Complete the current pallet and empty the bay
    # --------------------------------------------------------------------------
    r.on 'complete_pallet' do
      res = MesscadaApp::AddIdentifierToLoginWithNo.call(params)
      res = interactor.complete_pallet(res.instance) if res.success
      feedback = interactor.palletizing_robot_feedback(params[:device], res)
      Crossbeams::RobotResponder.new(feedback).render
    end

    # --------------------------------------------------------------------------
    # COMPLETE AUTOPACK_PALLET
    # --------------------------------------------------------------------------
    r.on 'complete_autopack_pallet' do
      res = MesscadaApp::AddIdentifierToLoginWithNo.call(params)
      res = interactor.complete_autopack_pallet(res.instance) if res.success
      feedback = interactor.palletizing_robot_feedback(params[:device], res)
      Crossbeams::RobotResponder.new(feedback).render
    end

    # --------------------------------------------------------------------------
    # TRANSFER CARTON - Transfer carton to the current bay from an empty bay
    # --------------------------------------------------------------------------
    r.on 'empty_bay_carton_transfer' do
      res = MesscadaApp::AddIdentifierToLoginWithNo.call(params)
      res = interactor.empty_bay_carton_transfer(res.instance) if res.success
      feedback = interactor.palletizing_robot_feedback(params[:device], res)
      Crossbeams::RobotResponder.new(feedback).render
    end

    # --------------------------------------------------------------------------
    # TRANSFER CARTON - Transfer carton to the current bay
    # --------------------------------------------------------------------------
    r.on 'transfer_carton' do
      res = MesscadaApp::AddIdentifierToLoginWithNo.call(params)
      res = interactor.transfer_carton(res.instance) if res.success
      feedback = interactor.palletizing_robot_feedback(params[:device], res)
      Crossbeams::RobotResponder.new(feedback).render
    end

  rescue Rack::QueryParser::InvalidParameterError => e
    ErrorMailer.send_exception_email(e,
                                     subject: 'Carton palletizing invalid parameter',
                                     message: "Invalid param from route: #{request.path} with #{request.query_string}.\nFrom ip: #{request.ip}")

    feedback = MesscadaApp::RobotFeedback.new(device: '',
                                              status: false,
                                              line1: 'Unable to read barcode')
    Crossbeams::RobotResponder.new(feedback).render
  end
end
