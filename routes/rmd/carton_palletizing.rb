# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
class Nspack < Roda # rubocop:disable Metrics/ClassLength
  route 'carton_palletizing', 'rmd' do |r| # rubocop:disable Metrics/BlockLength
    interactor = MesscadaApp::PalletizingInteractor.new(system_user, {}, { route_url: request.path, request_ip: request.ip }, {})

    # --------------------------------------------------------------------------
    # LOGIN AND ASSIGN BAY
    # --------------------------------------------------------------------------
    r.on 'login_to_bay' do
      # Choose palletizing bay & login
      # store locally
      # get: show form or redirect
      # post: redirect
      feedback = MesscadaApp::RobotFeedback.new(
        device: 'PTM-28',
        status: true,
        reader_id: '1'
        # line1: 'Fred Jones',
        # line2: 'Logged on'
      )
      show_robot_page(r, { device: 'PTM-28', reader_id: '1', identifier: '171807252866' }, feedback)
    end

    # Maybe check if user has been logged off via another device logon...

    r.on 'confirm_choice' do
      stash = retrieve_from_local_store(:robot_feedback)
      store_locally(:robot_feedback, stash) # Immediately store in case of reload
      identifier = stash.delete(:identifier)
      robot_feedback = MesscadaApp::RobotFeedback.new(stash)
      form_state = {
        device: robot_feedback.device,
        reader_id: robot_feedback.reader_id,
        identifier: identifier,
        line1: robot_feedback.line1,
        line2: robot_feedback.line2,
        line3: robot_feedback.line3,
        line4: robot_feedback.line4,
        line5: robot_feedback.line5,
        line6: robot_feedback.line6
      }
      form_state.merge!(error_message: 'Unable to process') unless robot_feedback.status
      form = Crossbeams::RMDForm.new(form_state,
                                     form_name: :palletizing,
                                     # notes: notice,
                                     scan_with_camera: @rmd_scan_with_camera,
                                     caption: 'Carton Palletizing',
                                     action: robot_feedback.confirm_url,
                                     button_caption: 'YES')

      form.add_label(:device, 'Device', robot_feedback.device)
      form.add_label(:login, 'Logged-in as', display_worker_name(identifier)) if AppConst::CR_PROD.incentive_palletizing
      lcd_opts = { as_table_cell: true }
      lcd_opts[:value_class] = 'red' unless robot_feedback.status
      lcd_opts[:value_class] = 'orange' if robot_feedback.orange
      form.add_label(:line1, '', robot_feedback.line1, robot_feedback.line1, lcd_opts)
      form.add_label(:line2, '', robot_feedback.line2, robot_feedback.line2, lcd_opts)
      form.add_label(:line3, '', robot_feedback.line3, robot_feedback.line3, lcd_opts)
      form.add_label(:line4, '', robot_feedback.line4, robot_feedback.line4, lcd_opts)
      form.add_label(:line5, '', robot_feedback.line5, robot_feedback.line5, lcd_opts)
      colour = :orange
      form.add_status_leds(colour)
      form.add_section_header(robot_feedback.confirm_text)
      form.add_button('NO', robot_feedback.cancel_url) unless robot_feedback.cancel_url == 'noop'
      form.add_button('NO', '/rmd/carton_palletizing/cancel_op') if robot_feedback.cancel_url == 'noop'
      form.add_label(:reader_id, 'Reader', robot_feedback.reader_id, robot_feedback.reader_id, hide_on_load: true)
      form.add_label(:identifier, 'Identifier', identifier, identifier, hide_on_load: true)
      form.add_csrf_tag csrf_tag
      view(inline: form.render, layout: :layout_rmd) # This might need to be a redirect to protect from reload-submit events
    end

    r.on 'cancel_op' do
      feedback = MesscadaApp::RobotFeedback.new(
        device: params[:palletizing][:device],
        status: true,
        reader_id: params[:palletizing][:reader_id],
        line1: 'Cancelled'
      )
      show_robot_page(r, { device: params[:palletizing][:device], reader_id: params[:palletizing][:reader_id], identifier: params[:palletizing][:identifier] }, feedback)
    end

    r.on 'robot_palletize' do
      stash = retrieve_from_local_store(:robot_feedback)
      store_locally(:robot_feedback, stash) # Immediately store in case of reload
      identifier = stash.delete(:identifier)
      robot_feedback = MesscadaApp::RobotFeedback.new(stash)
      form_state = {
        device: robot_feedback.device,
        reader_id: robot_feedback.reader_id,
        identifier: identifier,
        line1: robot_feedback.line1,
        line2: robot_feedback.line2,
        line3: robot_feedback.line3,
        line4: robot_feedback.line4,
        line5: robot_feedback.line5,
        line6: robot_feedback.line6
      }
      form_state.merge!(error_message: 'Unable to process') unless robot_feedback.status
      form = Crossbeams::RMDForm.new(form_state,
                                     form_name: :palletizing,
                                     # notes: notice,
                                     scan_with_camera: @rmd_scan_with_camera,
                                     caption: 'Carton Palletizing',
                                     action: '/rmd/carton_palletizing/scan_carton',
                                     button_caption: 'Submit')

      form.add_label(:device, 'Device', robot_feedback.device)
      form.add_label(:login, 'Logged-in as', display_worker_name(identifier)) if AppConst::CR_PROD.incentive_palletizing
      lcd_opts = { as_table_cell: true }
      lcd_opts[:value_class] = 'red' unless robot_feedback.status
      lcd_opts[:value_class] = 'orange' if robot_feedback.orange
      form.add_label(:line1, '', robot_feedback.line1, robot_feedback.line1, lcd_opts)
      form.add_label(:line2, '', robot_feedback.line2, robot_feedback.line2, lcd_opts)
      form.add_label(:line3, '', robot_feedback.line3, robot_feedback.line3, lcd_opts)
      form.add_label(:line4, '', robot_feedback.line4, robot_feedback.line4, lcd_opts)
      form.add_label(:line5, '', robot_feedback.line5, robot_feedback.line5, lcd_opts)
      colour = if robot_feedback.orange
                 :orange
               elsif robot_feedback.status
                 :green
               else
                 :red
               end
      form.add_status_leds(colour)
      form.add_field(:carton_number, 'Carton Number', scan: 'key248_all', scan_type: :carton_label_id, submit_form: true, required: false)
      form.add_button('Refresh', '/rmd/carton_palletizing/refresh')
      form.add_button('Complete', '/rmd/carton_palletizing/complete')
      form.add_button('QC Out', '/rmd/carton_palletizing/qc_out')
      form.add_button('Return to bay', '/rmd/carton_palletizing/return_to_bay')
      form.add_label(:reader_id, 'Reader', robot_feedback.reader_id, robot_feedback.reader_id, hide_on_load: true)
      form.add_label(:identifier, 'Identifier', identifier, identifier, hide_on_load: true)
      form.add_csrf_tag csrf_tag
      view(inline: form.render, layout: :layout_rmd) # This might need to be a redirect to protect from reload-submit events
    end

    r.on 'scan_carton' do
      res = MesscadaApp::AddIdentifierToLoginWithNo.call(params[:palletizing])
      id_params = get_keys_from_params(res)
      res = interactor.scan_carton(res.instance) if res.success
      feedback = interactor.palletizing_robot_feedback(params[:device], res)
      show_robot_page(r, id_params, feedback)
    end

    r.on 'qc_out' do
      res = MesscadaApp::AddIdentifierToLoginWithNo.call(params[:palletizing])
      id_params = get_keys_from_params(res)
      res = interactor.qc_out(res.instance) if res.success
      feedback = interactor.palletizing_robot_feedback(params[:device], res)
      show_robot_page(r, id_params, feedback)
    end

    r.on 'return_to_bay' do
      res = MesscadaApp::AddIdentifierToLoginWithNo.call(params[:palletizing])
      id_params = get_keys_from_params(res)
      res = interactor.return_to_bay(res.instance) if res.success
      feedback = interactor.palletizing_robot_feedback(params[:device], res)
      show_robot_page(r, id_params, feedback)
    end

    r.on 'refresh' do
      res = MesscadaApp::AddIdentifierToLoginWithNo.call(params[:palletizing])
      id_params = get_keys_from_params(res)
      res = interactor.refresh(res.instance) if res.success
      feedback = interactor.palletizing_robot_feedback(params[:device], res)
      show_robot_page(r, id_params, feedback)
    end

    r.on 'complete' do
      res = MesscadaApp::AddIdentifierToLoginWithNo.call(params[:palletizing])
      id_params = get_keys_from_params(res)
      res = interactor.request_complete(res.instance) if res.success
      feedback = interactor.palletizing_robot_feedback(params[:device], res)
      show_robot_page(r, id_params, feedback)
    end

    r.on 'complete_pallet' do
      res = MesscadaApp::AddIdentifierToLoginWithNo.call(params[:palletizing])
      id_params = get_keys_from_params(res)
      res = interactor.complete_pallet(res.instance) if res.success
      feedback = interactor.palletizing_robot_feedback(params[:device], res)
      show_robot_page(r, id_params, feedback)
    end

    r.on 'complete_autopack_pallet' do
      res = MesscadaApp::AddIdentifierToLoginWithNo.call(params[:palletizing])
      id_params = get_keys_from_params(res)
      res = interactor.complete_autopack_pallet(res.instance) if res.success
      feedback = interactor.palletizing_robot_feedback(params[:device], res)
      show_robot_page(r, id_params, feedback)
    end

    r.on 'empty_bay_carton_transfer' do
      res = MesscadaApp::AddIdentifierToLoginWithNo.call(params[:palletizing])
      id_params = get_keys_from_params(res)
      res = interactor.empty_bay_carton_transfer(res.instance) if res.success
      feedback = interactor.palletizing_robot_feedback(params[:device], res)
      show_robot_page(r, id_params, feedback)
    end

    r.on 'transfer_carton' do
      res = MesscadaApp::AddIdentifierToLoginWithNo.call(params[:palletizing])
      id_params = get_keys_from_params(res)
      res = interactor.transfer_carton(res.instance) if res.success
      feedback = interactor.palletizing_robot_feedback(params[:device], res)
      show_robot_page(r, id_params, feedback)
    end
  end

  def show_robot_page(rte, id_params, robot_feedback)
    stash = robot_feedback.to_h
    stash[:device] = id_params[:device]
    stash[:reader_id] = id_params[:reader_id]
    stash[:identifier] = id_params[:identifier]
    store_locally(:robot_feedback, stash)
    if robot_feedback.confirm_text
      rte.redirect '/rmd/carton_palletizing/confirm_choice'
    else
      rte.redirect '/rmd/carton_palletizing/robot_palletize'
    end
  end

  def get_keys_from_params(res)
    { device: res.instance[:device],
      reader_id: res.instance[:reader_id],
      identifier: res.instance[:identifier] }
  end
end
# rubocop:enable Metrics/BlockLength
