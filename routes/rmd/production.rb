# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
class Nspack < Roda # rubocop:disable Metrics/ClassLength
  route 'production', 'rmd' do |r|
    # --------------------------------------------------------------------------
    # PALLET ENQUIRY
    # --------------------------------------------------------------------------
    r.on 'pallet_inquiry' do
      interactor = MesscadaApp::MesscadaInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})
      # --------------------------------------------------------------------------
      # PALLET
      # --------------------------------------------------------------------------
      r.on 'scan_pallet' do
        r.get do
          form_state = { error_message: retrieve_from_local_store(:error) }
          form = Crossbeams::RMDForm.new(form_state,
                                         form_name: :pallet_inquiry,
                                         scan_with_camera: @rmd_scan_with_camera,
                                         caption: 'Pallet Enquiry',
                                         action: '/rmd/production/pallet_inquiry/scan_pallet',
                                         button_caption: 'Submit')
          attrs = if AppConst::USE_CARTON_PALLETIZING
                    { name: :scanned_number, label: 'Pallet or Carton Number' }
                  else
                    { name: :pallet_number,  label: 'Pallet Number' }
                  end
          form.add_field(attrs[:name],
                         attrs[:label],
                         data_type: :number,
                         scan: 'key248_all',
                         scan_type: :pallet_number,
                         submit_form: true,
                         required: true)
          form.add_csrf_tag csrf_tag
          view(inline: form.render, layout: :layout_rmd)
        end

        r.post do
          res = interactor.get_pallet_sequence_id(params[:pallet_inquiry])
          if res.success
            r.redirect("/rmd/production/pallet_inquiry/scan_pallet_sequence/#{res.instance}")
          else
            store_locally(:error, res.message)
            r.redirect('/rmd/production/pallet_inquiry/scan_pallet')
          end
        end
      end

      # --------------------------------------------------------------------------
      # PALLET SEQUENCE
      # --------------------------------------------------------------------------
      r.on 'scan_pallet_sequence', Integer do |id|
        pallet_sequence = interactor.find_pallet_sequence_attrs(id)
        ps_ids = interactor.find_pallet_sequences_from_same_pallet(id) # => [1,2,3,4]

        form = Crossbeams::RMDForm.new({},
                                       form_name: :pallet,
                                       scan_with_camera: @rmd_scan_with_camera,
                                       caption: "View Pallet #{pallet_sequence[:pallet_number]}",
                                       step_and_total: [ps_ids.index(id) + 1, ps_ids.length],
                                       reset_button: false,
                                       no_submit: true,
                                       action: '/')
        fields_for_rmd_pallet_sequence_display(form, pallet_sequence)
        form.add_csrf_tag csrf_tag
        form.add_label(:verification_result,
                       'Verification Result',
                       pallet_sequence[:verification_result])
        form.add_label(:verification_failure_reason,
                       'Verification Failure Reason',
                       pallet_sequence[:verification_failure_reason])
        if AppConst::REQUIRE_FRUIT_STICKER_AT_PALLET_VERIFICATION
          form.add_label(:fruit_sticker,
                         'Fruit Sticker',
                         pallet_sequence[:fruit_sticker])
        end
        form.add_label(:gross_weight,
                       'Plt Gross',
                       pallet_sequence[:gross_weight])
        form.add_label(:nett_weight,
                       'Plt Nett',
                       pallet_sequence[:nett_weight])
        form.add_label(:sequence_nett_weight,
                       'Seq Nett',
                       pallet_sequence[:sequence_nett_weight])
        form.add_label(:allocated,
                       'Allocated',
                       pallet_sequence[:allocated])
        form.add_label(:in_stock,
                       'In stock',
                       pallet_sequence[:in_stock])
        fields_for_rmd_allocated_pallet_sequence_display(form, pallet_sequence) if pallet_sequence[:allocated]
        form.add_prev_next_nav('/rmd/production/pallet_inquiry/scan_pallet_sequence/$:id$', ps_ids, id)
        view(inline: form.render, layout: :layout_rmd)
      end
    end

    # --------------------------------------------------------------------------
    # PALLET Verification
    # --------------------------------------------------------------------------
    r.on 'pallet_verification' do
      interactor = MesscadaApp::MesscadaInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})
      # --------------------------------------------------------------------------
      # PALLET/CARTON
      # --------------------------------------------------------------------------
      r.on 'scan_pallet_or_carton' do
        r.redirect('/rmd/production/pallet_verification/combined_verification_scan_carton') if AppConst::COMBINE_CARTON_AND_PALLET_VERIFICATION
        r.get do
          form_state = { error_message: retrieve_from_local_store(:error_message) }

          form = Crossbeams::RMDForm.new(form_state,
                                         form_name: :pallet_verification,
                                         scan_with_camera: @rmd_scan_with_camera,
                                         notes: retrieve_from_local_store(:flash_notice),
                                         caption: 'Pallet Verification',
                                         action: '/rmd/production/pallet_verification/scan_pallet_or_carton',
                                         button_caption: 'Submit')
          attrs = if AppConst::USE_CARTON_PALLETIZING
                    { name: :scanned_number, label: 'Pallet or Carton Number' }
                  else
                    { name: :pallet_number,  label: 'Pallet Number' }
                  end
          form.add_field(attrs[:name],
                         attrs[:label],
                         data_type: :number,
                         scan: 'key248_all',
                         scan_type: :pallet_number,
                         submit_form: true,
                         required: true)
          form.add_csrf_tag csrf_tag
          view(inline: form.render, layout: :layout_rmd)
        end

        r.post do
          res = interactor.pallet_to_be_verified(params[:pallet_verification])
          if res.success
            r.redirect("/rmd/production/pallet_verification/verify_pallet_sequence/#{res.instance}")
          else
            store_locally(:error_message, res.message)
            r.redirect('/rmd/production/pallet_verification/scan_pallet_or_carton')
          end
        end
      end

      r.on 'combined_verification_scan_carton' do
        r.get do
          form_state = { error_message: retrieve_from_local_store(:error_message) }
          form = Crossbeams::RMDForm.new(form_state,
                                         form_name: :combined_verification,
                                         scan_with_camera: @rmd_scan_with_camera,
                                         notes: retrieve_from_local_store(:flash_notice),
                                         caption: 'Pallet/Carton Verification',
                                         action: '/rmd/production/pallet_verification/combined_verification_scan_carton',
                                         button_caption: 'Submit')
          form.add_field(:carton_number,
                         'Carton Number',
                         data_type: :number,
                         scan: 'key248_all',
                         scan_type: :carton_label_id,
                         submit_form: true,
                         required: true)
          form.add_csrf_tag csrf_tag
          view(inline: form.render, layout: :layout_rmd)
        end

        r.post do
          # # params[:carton][:carton_number] = MesscadaApp::ScannedCartonNumber.new(scanned_carton_number: params[:carton][:carton_number]).carton_number
          # pallet_number = params[:carton][:carton_number] if AppConst::CARTON_EQUALS_PALLET && interactor.pallet_exists?(params[:carton][:carton_number])
          #
          # unless pallet_number
          #   res = interactor.carton_verification(carton_number: params[:carton][:carton_number])
          #   pallet_number = AppConst::CARTON_EQUALS_PALLET ? params[:carton][:carton_number] : interactor.get_pallet_by_carton_label_id(params[:carton][:carton_number])
          #   unless res.success
          #     store_locally(:scan_carton_submit_error, "Error: #{unwrap_failed_response(res)}")
          #     r.redirect('/rmd/production/pallet_verification/combined_verification_scan_carton')
          #   end
          # end

          # res = interactor.validate_pallet_to_be_verified(pallet_number)
          res = interactor.carton_to_be_verified(params[:combined_verification])
          if res.success
            # r.redirect("/rmd/production/pallet_verification/verify_pallet_sequence/#{res.instance[:oldest_pallet_sequence_id]}")
            r.redirect("/rmd/production/pallet_verification/verify_pallet_sequence/#{res.instance}")
          else
            store_locally(:error_message, res.message)
            r.redirect('/rmd/production/pallet_verification/combined_verification_scan_carton')
          end
        end
      end

      # --------------------------------------------------------------------------
      # VERIFY PALLET SEQUENCE
      # --------------------------------------------------------------------------
      r.on 'verify_pallet_sequence', Integer do |id|
        pallet_sequence = interactor.find_pallet_sequence_attrs(id)
        ps_ids = interactor.find_pallet_sequences_from_same_pallet(id) # => [1,2,3,4]

        form_state = { gross_weight: pallet_sequence[:gross_weight]&.to_f }
        notice = retrieve_from_local_store(:flash_notice)
        error = retrieve_from_local_store(:verification_errors)
        form_state.merge!(error_message: error.message, errors: error.errors) unless error.nil?

        form = Crossbeams::RMDForm.new(form_state,
                                       form_name: :pallet,
                                       scan_with_camera: @rmd_scan_with_camera,
                                       caption: "View Pallet #{pallet_sequence[:pallet_number]}",
                                       step_and_total: [ps_ids.index(id) + 1, ps_ids.length],
                                       reset_button: false,
                                       notes: notice,
                                       action: "/rmd/production/pallet_verification/verify_pallet_sequence_submit/#{id}",
                                       button_id: 'SaveSeq',
                                       button_initially_hidden: true,
                                       button_caption: 'Save')
        form.behaviours do |behaviour|
          behaviour.dropdown_change :verification_result, notify: [{ url: '/rmd/production/pallet_verification/pallet_verification_result_combo_changed' }]
        end
        fields_for_rmd_pallet_sequence_display(form, pallet_sequence)
        form.add_label(:verified, 'Verified', pallet_sequence[:verified])
        form.add_select(:verification_result,
                        'Verification Result',
                        items: %w[unknown passed failed],
                        value: (pallet_sequence[:verification_result].nil_or_empty? ? 'unknown' : pallet_sequence[:verification_result]))
        form.add_select(:verification_failure_reason,
                        'Verification Failure Reason',
                        items: MasterfilesApp::QualityRepo.new.for_select_pallet_verification_failure_reasons,
                        hide_on_load: (pallet_sequence[:verification_result] != 'failed'),
                        value: pallet_sequence[:pallet_verification_failure_reason_id],
                        prompt: true,
                        required: false)
        if AppConst::REQUIRE_FRUIT_STICKER_AT_PALLET_VERIFICATION && pallet_sequence[:pallet_sequence_number] == 1
          form.add_select(:fruit_sticker_pm_product_id,
                          'Fruit Sticker',
                          items: MasterfilesApp::BomsRepo.new.find_pm_products_by_pm_type('fruit_sticker'),
                          value: pallet_sequence[:fruit_sticker_pm_product_id],
                          prompt: true)
          form.add_select(:fruit_sticker_pm_product_2_id,
                          'Fruit Sticker 2',
                          items: MasterfilesApp::BomsRepo.new.find_pm_products_by_pm_type('fruit_sticker'),
                          value: pallet_sequence[:fruit_sticker_pm_product_2_id],
                          prompt: true)
        end
        if AppConst::CAPTURE_PALLET_WEIGHT_AT_VERIFICATION
          form.add_field(:gross_weight,
                         'Gross Weight',
                         required: true,
                         data_type: :number)
        else
          form.add_label(:gross_weight,
                         'Gross Weight',
                         pallet_sequence[:gross_weight])
        end
        form.add_label(:nett_weight,
                       'Nett Weight',
                       pallet_sequence[:nett_weight]&.to_f)
        form.add_prev_next_nav('/rmd/production/pallet_verification/verify_pallet_sequence/$:id$', ps_ids, id)
        form.add_csrf_tag csrf_tag
        view(inline: form.render, layout: :layout_rmd)
      end

      r.on 'pallet_verification_result_combo_changed' do
        actions = [OpenStruct.new(type: params[:changed_value] == 'failed' ? :show_element : :hide_element, dom_id: 'pallet_verification_failure_reason_row'),
                   OpenStruct.new(type: params[:changed_value] != 'unknown' ? :show_element : :hide_element, dom_id: 'SaveSeq')]
        json_actions(actions)
      end

      r.on 'verify_pallet_sequence_submit', Integer do |id|
        res = interactor.verify_pallet_sequence(id, current_user, params[:pallet])
        if res.success
          store_locally(:flash_notice, (res.instance[:verification_completed] ? rmd_success_message('Pallet Verified Successfully') : rmd_info_message(res.message)))
        else
          store_locally(:verification_errors, res)
        end

        if res.instance[:verification_completed]
          r.redirect('/rmd/production/pallet_verification/scan_pallet_or_carton')
        else
          r.redirect("/rmd/production/pallet_verification/verify_pallet_sequence/#{id}")
        end
      end
    end

    # --------------------------------------------------------------------------
    # PALLETIZING
    # --------------------------------------------------------------------------
    r.on 'palletizing' do
      interactor = ProductionApp::ProductionRunInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})
      messcada_interactor = MesscadaApp::MesscadaInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      r.on 'create_new_pallet' do
        interactor.assert_permission!(:create_new_pallet)
        r.get do
          notice = retrieve_from_local_store(:flash_notice)
          form_state = {}
          error = retrieve_from_local_store(:errors)
          form_state.merge!(error_message: error.message, errors: error.errors) unless error.nil?
          form = Crossbeams::RMDForm.new(form_state,
                                         form_name: :carton,
                                         scan_with_camera: @rmd_scan_with_camera,
                                         notes: notice,
                                         caption: 'Scan Carton',
                                         action: '/rmd/production/palletizing/create_new_pallet',
                                         button_caption: 'Submit')
          form.add_field(:carton_number,
                         'Carton Number',
                         data_type: :number,
                         scan: 'key248_all',
                         scan_type: :carton_label_id,
                         submit_form: true,
                         required: true)
          form.add_csrf_tag csrf_tag
          view(inline: form.render, layout: :layout_rmd)
        end

        r.post do
          carton_number = params[:carton][:carton_number]
          val_res = interactor.validate_carton_number_for_palletizing(carton_number)
          unless val_res.success
            store_locally(:errors, val_res)
            r.redirect('/rmd/production/palletizing/create_new_pallet')
          end

          carton_id = (interactor.find_carton_by_carton_label_id(carton_number) || {})[:id]
          unless AppConst::CARTON_VERIFICATION_REQUIRED
            if carton_id.nil?
              res = messcada_interactor.carton_verification(carton_number: carton_number)
              unless res.success
                store_locally(:errors, res)
                r.redirect('/rmd/production/palletizing/create_new_pallet')
              end
              carton_id = interactor.find_carton_by_carton_label_id(carton_number)[:id]
            end
          end

          res = interactor.create_pallet_from_carton(carton_id)
          if res.success
            pallet_sequence = interactor.find_pallet_sequence_attrs(res.instance[:pallet_id], 1)
            r.redirect("/rmd/production/palletizing/print_or_edit_pallet_view/#{pallet_sequence[:id]}")
          else
            store_locally(:errors, res)
            r.redirect('/rmd/production/palletizing/create_new_pallet')
          end
        end
      end

      r.on 'carton_quantity_changed' do
        actions = [OpenStruct.new(type: :show_element, dom_id: 'UpdateSeq')]
        json_actions(actions)
      end

      r.on 'pallet_format_changed' do
        cpp = MasterfilesApp::PackagingRepo.new.find_cartons_per_pallet_by_seq_and_format(params[:pallet_pallet_number], params[:pallet_pallet_sequence_number], params[:changed_value])
        actions = [OpenStruct.new(type: :show_element, dom_id: 'UpdateSeq'),
                   OpenStruct.new(type: :replace_input_value,
                                  dom_id: 'pallet_carton_quantity',
                                  value: cpp ? cpp[:cartons_per_pallet] : nil)]
        json_actions(actions)
      end

      r.on 'update_pallet_sequence' do
        r.post do
          pallet_number = MesscadaApp::ScannedPalletNumber.new(scanned_pallet_number: params[:pallet][:pallet_number]).pallet_number
          pallet_sequence_id = interactor.find_pallet_sequence_by_pallet_number_and_pallet_sequence_number(pallet_number, params[:pallet][:pallet_sequence_number])

          new_pallet_format = MasterfilesApp::PackagingRepo.new.get_current_pallet_format_for_sequence(pallet_sequence_id) != params[:pallet][:pallet_format].to_i ? params[:pallet][:pallet_format].to_i : nil
          cpp = MasterfilesApp::PackagingRepo.new.find_cartons_per_pallet_by_seq_and_format(pallet_number, params[:pallet][:pallet_sequence_number], params[:pallet][:pallet_format])
          current_cartons_per_pallet_id = MesscadaApp::MesscadaRepo.new.find_pallet_sequence(pallet_sequence_id)[:cartons_per_pallet_id]
          new_cartons_per_pallet_id = cpp && cpp[:id] != current_cartons_per_pallet_id ? cpp[:id] : nil

          res = interactor.update_pallet_sequence_carton_qty(pallet_sequence_id, params[:pallet][:carton_quantity], new_pallet_format, new_cartons_per_pallet_id)
          if res.success
            store_locally(:flash_notice, "Pallet:#{params[:pallet][:pallet_number]} updated successfully.")
          else
            store_locally(:errors, "Error:#{unwrap_failed_response(res)}")
          end
          r.redirect("/rmd/production/palletizing/print_or_edit_pallet_view/#{pallet_sequence_id}")
        end
      end

      r.on 'print_pallet_labels', Integer do |id|
        r.post do
          res = interactor.print_pallet_label_from_sequence(id,
                                                            pallet_label_name: params[:pallet][:pallet_label_name],
                                                            no_of_prints: params[:pallet][:qty_to_print],
                                                            printer: params[:pallet][:printer])
          if res.success
            store_locally(:flash_notice, "Labels For Pallet: #{params[:pallet][:pallet_number]} Printed Successfully")
            r.redirect('/rmd/production/palletizing/create_new_pallet')
          else
            store_locally(:errors, "Printing Error: #{unwrap_failed_response(res)}")
            r.redirect("/rmd/production/palletizing/print_or_edit_pallet_view/#{id}")
          end
        end
      end

      r.on 'print_pallet_labels_for_edit_pallet_sequence', Integer do |id|
        r.post do
          res = interactor.print_pallet_label_from_sequence(id,
                                                            pallet_label_name: params[:pallet][:pallet_label_name],
                                                            no_of_prints: params[:pallet][:qty_to_print],
                                                            printer: params[:pallet][:printer])
          if res.success
            store_locally(:flash_notice, 'Labels Printed Successfully')
          else
            store_locally(:errors, error_message: "Printing Error: #{unwrap_failed_response(res)}")
          end
          r.redirect("/rmd/production/palletizing/edit_pallet_sequence_view/#{id}")
        end
      end

      r.on 'print_pallet_labels_for_add_sequence', Integer do |id|
        r.post do
          res = interactor.print_pallet_label_from_sequence(id,
                                                            pallet_label_name: params[:pallet][:pallet_label_name],
                                                            no_of_prints: params[:pallet][:qty_to_print],
                                                            printer: params[:pallet][:printer])
          if res.success
            store_locally(:flash_notice, 'Labels Printed Successfully')
          else
            store_locally(:errors, error_message: "Printing Error: #{unwrap_failed_response(res)}")
          end
          r.redirect("/rmd/production/palletizing/print_pallet_view/#{id}")
        end
      end

      r.on 'add_sequence_to_pallet_scan_carton', Integer do |id|
        form_state = {}
        if (current_state = retrieve_from_local_store(:current_form_state))
          form_state = current_state
        end
        error = retrieve_from_local_store(:errors)
        form_state.merge!(error_message: error, errors: { carton_number: [''] }) unless error.nil?
        form = Crossbeams::RMDForm.new(form_state,
                                       form_name: :pallet,
                                       scan_with_camera: @rmd_scan_with_camera,
                                       notes: nil,
                                       caption: 'Add New Sequence To Pallet: Scan Carton',
                                       action: "/rmd/production/palletizing/add_sequence_to_pallet_submit/#{id}",
                                       button_caption: 'Submit')
        form.add_field(:carton_number,
                       'Carton Number<br>(For New Sequence)',
                       data_type: :number,
                       scan: 'key248_all',
                       scan_type: :carton_label_id,
                       submit_form: false,
                       required: true,
                       prompt: false)
        form.add_field(:carton_quantity,
                       'Carton Qty',
                       required: true,
                       prompt: true,
                       data_type: :number)
        form.add_csrf_tag csrf_tag
        view(inline: form.render, layout: :layout_rmd)
      end

      r.on 'add_sequence_to_pallet_submit', Integer do |id|
        carton_number = params[:pallet][:carton_number]
        pallet_number = MesscadaApp::MesscadaRepo.new.find_pallet(id).pallet_number
        val_res = interactor.validate_carton_number_for_palletizing(carton_number)
        unless val_res.success
          store_locally(:current_form_state, carton_quantity: params[:pallet][:carton_quantity])
          store_locally(:errors, unwrap_failed_response(val_res))
          r.redirect("/rmd/production/palletizing/add_sequence_to_pallet_scan_carton/#{id}")
        end

        carton_id = (interactor.find_carton_by_carton_label_id(carton_number) || {})[:id]
        unless AppConst::CARTON_VERIFICATION_REQUIRED
          if carton_id.nil?
            res = messcada_interactor.carton_verification(carton_number: carton_number)
            unless res.success
              store_locally(:current_form_state, carton_quantity: params[:pallet][:carton_quantity])
              store_locally(:errors, unwrap_failed_response(res))
              r.redirect("/rmd/production/palletizing/add_sequence_to_pallet_scan_carton/#{id}")
            end
            carton_id = interactor.find_carton_by_carton_label_id(carton_number)[:id]
          end
        end

        res = interactor.add_sequence_to_pallet(current_user&.user_name, pallet_number, carton_id, params[:pallet][:carton_quantity])
        if res.success
          pallet_sequences = messcada_interactor.find_pallet_sequences_by_pallet_number(pallet_number)
          r.redirect("/rmd/production/palletizing/print_pallet_view/#{pallet_sequences.all.last[:id]}")
        else
          store_locally(:current_form_state, carton_quantity: params[:pallet][:carton_quantity])
          store_locally(:errors, unwrap_failed_response(res))
          r.redirect("/rmd/production/palletizing/add_sequence_to_pallet_scan_carton/#{id}")
        end
      end

      r.on 'add_sequence_to_pallet' do
        interactor.assert_permission!(:add_sequence_to_pallet)
        r.get do
          form_state = {}
          if (current_state = retrieve_from_local_store(:current_form_state))
            form_state = current_state
          end
          error = retrieve_from_local_store(:errors)
          form_state.merge!(error_message: error, errors: { pallet_number: [''], carton_number: [''] }) unless error.nil?
          form = Crossbeams::RMDForm.new(form_state,
                                         form_name: :pallet,
                                         scan_with_camera: @rmd_scan_with_camera,
                                         notes: nil,
                                         caption: 'Add New Sequence To Pallet',
                                         action: '/rmd/production/palletizing/add_sequence_to_pallet',
                                         button_caption: 'Submit')
          form.add_field(:pallet_number,
                         'Pallet Number',
                         scan: 'key248_all',
                         scan_type: :pallet_number,
                         submit_form: true,
                         data_type: :number,
                         required: true,
                         prompt: false)
          form.add_csrf_tag csrf_tag
          view(inline: form.render, layout: :layout_rmd)
        end

        r.post do
          pallet = ProductionApp::ProductionRunRepo.new.find_pallet_by_pallet_number(params[:pallet][:pallet_number])
          if !pallet.nil_or_empty?
            # store_locally(:add_sequence_pallet_number, params[:pallet][:pallet_number])
            r.redirect("/rmd/production/palletizing/add_sequence_to_pallet_scan_carton/#{pallet[:id]}")
          else
            store_locally(:errors, "Scanned Pallet:#{params[:pallet][:pallet_number]} doesn't exist")
            r.redirect('/rmd/production/palletizing/add_sequence_to_pallet')
          end
        end
      end

      r.on 'print_or_edit_pallet_view', Integer do |id|
        pallet_sequence = interactor.find_pallet_sequence_attrs_by_id(id)
        pallet_sequence.merge!(qty_to_print: 4)

        printer_repo = LabelApp::PrinterRepo.new

        notice = retrieve_from_local_store(:flash_notice)
        error = retrieve_from_local_store(:errors)
        pallet_sequence.merge!(error_message: error) unless error.nil?
        form = Crossbeams::RMDForm.new(pallet_sequence,
                                       notes: notice,
                                       form_name: :pallet,
                                       scan_with_camera: @rmd_scan_with_camera,
                                       caption: "Edit Pallet #{pallet_sequence[:pallet_number]}",
                                       reset_button: false,
                                       no_submit: false,
                                       action: '/rmd/production/palletizing/update_pallet_sequence',
                                       button_id: 'UpdateSeq',
                                       button_initially_hidden: true,
                                       button_caption: 'Save')
        form.behaviours do |behaviour|
          behaviour.input_change :carton_quantity, notify: [{ url: '/rmd/production/palletizing/carton_quantity_changed', param_keys: %i[pallet_pallet_number pallet_pallet_sequence_number pallet_carton_quantity] }]
          behaviour.input_change :pallet_format, notify: [{ url: '/rmd/production/palletizing/pallet_format_changed', param_keys: %i[pallet_pallet_number pallet_pallet_sequence_number pallet_carton_quantity] }]
        end
        fields_for_rmd_pallet_sequence_display(form, pallet_sequence, [:carton_quantity])
        form.add_csrf_tag csrf_tag
        form.add_select(:pallet_format,
                        'Pallet Format',
                        prompt: true,
                        value: MasterfilesApp::PackagingRepo.new.get_current_pallet_format_for_sequence(id),
                        items: MasterfilesApp::PackagingRepo.new.pallet_formats_for_select)
        form.add_field(:carton_quantity,
                       'Carton Qty',
                       required: true,
                       prompt: true,
                       data_type: :number)
        form.add_field(:qty_to_print,
                       'Qty To Print',
                       required: false,
                       prompt: true,
                       data_type: :number)
        form.add_select(:printer,
                        'Printer',
                        items: printer_repo.select_printers_for_application(AppConst::PRINT_APP_PALLET),
                        required: false,
                        value: printer_repo.default_printer_for_application(AppConst::PRINT_APP_PALLET))
        form.add_select(:pallet_label_name,
                        'Pallet Label',
                        value: interactor.find_pallet_label_name_by_resource_allocation_id(pallet_sequence[:resource_allocation_id]),
                        items: interactor.find_pallet_labels,
                        required: false)
        form.add_button('Print',
                        "/rmd/production/palletizing/print_pallet_labels/#{pallet_sequence[:id]}")
        view(inline: form.render, layout: :layout_rmd)
      end

      r.on 'print_pallet_view', Integer do |id|
        printer_repo = LabelApp::PrinterRepo.new
        pallet_sequence = messcada_interactor.find_pallet_sequence_attrs(id)
        pallet_sequence.merge!(qty_to_print: 4)
        ps_ids = messcada_interactor.find_pallet_sequences_from_same_pallet(id) # => [1,2,3,4]

        notice = retrieve_from_local_store(:flash_notice)
        form_state = {}
        error = retrieve_from_local_store(:errors)
        form_state.merge!(error_message: error[:error_message], errors: error[:errors]) unless error.nil?

        form = Crossbeams::RMDForm.new(form_state,
                                       form_name: :pallet,
                                       scan_with_camera: @rmd_scan_with_camera,
                                       caption: "Print Pallet #{pallet_sequence[:pallet_number]}",
                                       step_and_total: [ps_ids.index(id) + 1, ps_ids.length],
                                       notes: notice,
                                       reset_button: false,
                                       no_submit: false,
                                       action: "/rmd/production/palletizing/print_pallet_labels_for_add_sequence/#{id}",
                                       button_caption: 'Print')
        form.add_prev_next_nav('/rmd/production/palletizing/print_pallet_view/$:id$', ps_ids, id)
        fields_for_rmd_pallet_sequence_display(form, pallet_sequence)
        form.add_field(:qty_to_print,
                       'Qty To Print',
                       required: false,
                       prompt: true,
                       data_type: :number)
        form.add_select(:printer,
                        'Printer',
                        items: printer_repo.select_printers_for_application(AppConst::PRINT_APP_PALLET),
                        value: printer_repo.default_printer_for_application(AppConst::PRINT_APP_PALLET),
                        required: false)
        form.add_select(:pallet_label_name,
                        'Pallet Label',
                        value: interactor.find_pallet_label_name_by_resource_allocation_id(pallet_sequence[:resource_allocation_id]),
                        items: interactor.find_pallet_labels,
                        required: false)
        form.add_csrf_tag csrf_tag
        form.add_prev_next_nav('/rmd/production/palletizing/print_pallet_view/$:id$', ps_ids, id)
        view(inline: form.render, layout: :layout_rmd)
      end

      r.on 'edit_pallet_sequence_view', Integer do |id|
        pallet_sequence = messcada_interactor.find_pallet_sequence_attrs(id)
        ps_ids = messcada_interactor.find_pallet_sequences_from_same_pallet(id) # => [1,2,3,4]
        printer_repo = LabelApp::PrinterRepo.new

        notice = retrieve_from_local_store(:flash_notice)
        form_state = {}
        error = retrieve_from_local_store(:errors)
        form_state.merge!(error_message: error[:error_message], errors: error[:errors]) unless error.nil?
        form = Crossbeams::RMDForm.new(form_state,
                                       notes: notice,
                                       form_name: :pallet,
                                       scan_with_camera: @rmd_scan_with_camera,
                                       caption: 'Edit Pallet Sequence',
                                       step_and_total: [ps_ids.index(id) + 1, ps_ids.length],
                                       reset_button: false,
                                       no_submit: false,
                                       action: "/rmd/production/palletizing/edit_pallet_sequence_submit/#{pallet_sequence[:id]}",
                                       button_caption: 'Update')
        form.add_prev_next_nav('/rmd/production/palletizing/edit_pallet_sequence_view/$:id$', ps_ids, id)
        form.add_field(:carton_number,
                       'Carton Number<br>(To Replace Sequence)',
                       data_type: :number,
                       scan: 'key248_all',
                       scan_type: :carton_label_id,
                       submit_form: true,
                       required: false)
        form.add_field(:carton_quantity,
                       'Carton Qty',
                       required: false,
                       prompt: true,
                       data_type: :number)
        form.add_label(:current_carton_quantity,
                       'Current Carton Qty',
                       pallet_sequence[:carton_quantity])
        fields_for_rmd_pallet_sequence_display(form, pallet_sequence, [:carton_quantity])
        form.add_field(:qty_to_print,
                       'Qty To Print',
                       required: false,
                       prompt: true,
                       data_type: :number)
        form.add_select(:printer,
                        'Printer',
                        value: printer_repo.default_printer_for_application(AppConst::PRINT_APP_PALLET),
                        items: printer_repo.select_printers_for_application(AppConst::PRINT_APP_PALLET),
                        required: false)
        form.add_select(:pallet_label_name,
                        'Pallet Label',
                        value: interactor.find_pallet_label_name_by_resource_allocation_id(pallet_sequence[:resource_allocation_id]),
                        items: interactor.find_pallet_labels,
                        required: false)
        form.add_csrf_tag csrf_tag
        form.add_prev_next_nav('/rmd/production/palletizing/edit_pallet_sequence_view/$:id$', ps_ids, id)
        form.add_button('Print', "/rmd/production/palletizing/print_pallet_labels_for_edit_pallet_sequence/#{pallet_sequence[:id]}")
        view(inline: form.render, layout: :layout_rmd)
      end

      r.on 'edit_pallet_sequence_submit', Integer do |id|
        r.post do
          if !params[:pallet][:carton_number].nil_or_empty?
            carton_number = params[:pallet][:carton_number]
            val_res = interactor.validate_carton_number_for_palletizing(carton_number)
            unless val_res.success
              store_locally(:errors, val_res.to_h.merge(error_message: val_res[:message]))
              r.redirect("/rmd/production/palletizing/edit_pallet_sequence_view/#{id}")
            end

            carton_number = (carton = interactor.find_carton_by_carton_label_id(params[:pallet][:carton_number])) ? carton[:id] : nil
            unless AppConst::CARTON_VERIFICATION_REQUIRED
              unless carton_number
                res = messcada_interactor.carton_verification(carton_number: params[:pallet][:carton_number])
                unless res.success # rubocop:disable Metrics/BlockNesting
                  store_locally(:errors, error_message: "Error: #{unwrap_failed_response(res)}")
                  r.redirect("/rmd/production/palletizing/edit_pallet_sequence_view/#{id}")
                end
                carton_number = interactor.find_carton_by_carton_label_id(params[:pallet][:carton_number])[:id]
              end
            end

            res = interactor.replace_pallet_sequence(current_user&.user_name, carton_number, id, params[:pallet][:carton_quantity].nil_or_empty? ? nil : params[:pallet][:carton_quantity])
            if res.success
              store_locally(:flash_notice, 'Pallets Sequence Updated Successfully')
            else
              store_locally(:errors, error_message: "Error: #{unwrap_failed_response(res)}")
            end
          elsif !params[:pallet][:carton_quantity].nil_or_empty?
            res = interactor.update_pallet_sequence_carton_qty(id, params[:pallet][:carton_quantity])
            if res.success
              store_locally(:flash_notice, 'Pallets Sequence Updated Successfully')
            else
              store_locally(:errors, error_message: "Error: #{unwrap_failed_response(res)}")
            end
          else
            store_locally(:errors, error_message: 'You must scan a carton_number or carton_qty', errors: { carton_number: [''], carton_quantity: [''] })
          end
          r.redirect("/rmd/production/palletizing/edit_pallet_sequence_view/#{id}")
        end
      end

      r.on 'edit_pallet' do
        interactor.assert_permission!(:edit_pallet)
        r.get do
          form_state = {}
          error = retrieve_from_local_store(:errors)
          form_state.merge!(error_message: error.message, errors: error.errors) unless error.nil?
          form = Crossbeams::RMDForm.new(form_state,
                                         form_name: :pallet,
                                         scan_with_camera: @rmd_scan_with_camera,
                                         notes: nil,
                                         caption: 'Scan Pallet',
                                         action: '/rmd/production/palletizing/edit_pallet',
                                         button_caption: 'Submit')
          form.add_field(:pallet_number,
                         'Pallet Number',
                         scan: 'key248_all',
                         scan_type: :pallet_number,
                         submit_form: true,
                         data_type: :number,
                         required: true)
          form.add_csrf_tag csrf_tag
          view(inline: form.render, layout: :layout_rmd)
        end

        r.post do
          res = interactor.edit_pallet_validations(params[:pallet][:pallet_number])
          if res.success
            pallet_sequences = messcada_interactor.find_pallet_sequences_by_pallet_number(params[:pallet][:pallet_number])
            r.redirect("/rmd/production/palletizing/edit_pallet_sequence_view/#{pallet_sequences.all.last[:id]}")
          else
            store_locally(:errors, res)
            r.redirect('/rmd/production/palletizing/edit_pallet')
          end
        end
      end
    end

    # --------------------------------------------------------------------------
    # REPRINT PALLET LABEL
    # --------------------------------------------------------------------------
    r.on 'reprint_pallet_label' do
      interactor = ProductionApp::ProductionRunInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})
      messcada_interactor = MesscadaApp::MesscadaInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})
      printer_repo = LabelApp::PrinterRepo.new

      r.get do
        form_state = { qty_to_print: 4,
                       error_message: retrieve_from_local_store(:error_message) }

        form = Crossbeams::RMDForm.new(form_state,
                                       notes: retrieve_from_local_store(:flash_notice),
                                       form_name: :reprint_pallet_label,
                                       scan_with_camera: @rmd_scan_with_camera,
                                       caption: 'Reprint Pallet Label',
                                       action: '/rmd/production/reprint_pallet_label',
                                       button_caption: 'Submit')
        attrs = if AppConst::USE_CARTON_PALLETIZING
                  { name: :scanned_number,  label: 'Pallet or Carton Number' }
                else
                  { name: :pallet_number, label: 'Pallet Number' }
                end
        form.add_field(attrs[:name],
                       attrs[:label],
                       data_type: :number,
                       scan: 'key248_all',
                       scan_type: :pallet_number,
                       submit_form: true,
                       required: true)
        form.add_csrf_tag csrf_tag
        view(inline: form.render, layout: :layout_rmd)
        form.add_field(:qty_to_print,
                       'Qty To Print',
                       required: false,
                       prompt: true,
                       data_type: :number)
        form.add_select(:printer,
                        'Printer',
                        items: printer_repo.select_printers_for_application(AppConst::PRINT_APP_PALLET),
                        required: false,
                        value: printer_repo.default_printer_for_application(AppConst::PRINT_APP_PALLET))
        form.add_select(:pallet_label_name,
                        'Pallet Label',
                        items: interactor.find_pallet_labels,
                        required: false)
        form.add_csrf_tag csrf_tag
        view(inline: form.render, layout: :layout_rmd)
      end

      r.post do
        res = messcada_interactor.get_pallet_sequence_id(params[:reprint_pallet_label])
        if res.success
          res = interactor.print_pallet_label_from_sequence(res.instance,
                                                            pallet_label_name: params[:reprint_pallet_label][:pallet_label_name],
                                                            no_of_prints: params[:reprint_pallet_label][:qty_to_print],
                                                            printer: params[:reprint_pallet_label][:printer])
        end
        if res.success
          store_locally(:flash_notice, 'Labels Printed Successfully')
        else
          store_locally(:error_message, "Printing Error: #{unwrap_failed_response(res)}")
        end
        r.redirect('/rmd/production/reprint_pallet_label')
      end
    end
  end

  def fields_for_rmd_pallet_sequence_display(form, pallet_sequence, override = []) # rubocop:disable Metrics/AbcSize
    form.add_label(:pallet_number, 'Pallet Number', pallet_sequence[:pallet_number])
    form.add_label(:pallet_sequence_number, 'Pallet Sequence Number', pallet_sequence[:pallet_sequence_number])
    form.add_label(:build_status, 'Build Status', pallet_sequence[:build_status])
    form.add_label(:pallet_base, 'Pallet Base', pallet_sequence[:pallet_base])
    form.add_label(:stack_type, 'Stack Height', pallet_sequence[:stack_type])
    form.add_label(:pallet_carton_quantity, 'Pallet Carton Quantity', pallet_sequence[:pallet_carton_quantity])
    form.add_label(:carton_quantity, 'Carton Qty', pallet_sequence[:carton_quantity]) unless override.include?(:carton_quantity)
    form.add_label(:production_run_id, 'Production Run Id', pallet_sequence[:production_run_id])
    form.add_label(:farm, 'Farm Code', pallet_sequence[:farm])
    form.add_label(:orchard, 'Orchard Code', pallet_sequence[:orchard])
    form.add_label(:cultivar_group, 'Cultivar Group Code', pallet_sequence[:cultivar_group])
    form.add_label(:cultivar, 'Cultivar Code', pallet_sequence[:cultivar])
    form.add_label(:packhouse, 'Packhouse', pallet_sequence[:packhouse])
    form.add_label(:line, 'Production Line', pallet_sequence[:line])
    form.add_label(:commodity, 'Commodity', pallet_sequence[:commodity])
    form.add_label(:marketing_variety, 'Marketing Variety', pallet_sequence[:marketing_variety])
    form.add_label(:customer_variety, 'Customer Variety', pallet_sequence[:customer_variety])
    form.add_label(:basic_pack, 'Basic Pack', pallet_sequence[:basic_pack])
    form.add_label(:std_pack, 'Std Pack', pallet_sequence[:std_pack])
    form.add_label(:actual_count, 'Actual Count', pallet_sequence[:actual_count])
    form.add_label(:std_size, 'Std Size', pallet_sequence[:std_size])
    form.add_label(:size_ref, 'Size Reference', pallet_sequence[:size_ref])
    form.add_label(:marketing_org, 'Marketing Org', pallet_sequence[:marketing_org])
    form.add_label(:packed_tm_group, 'Packed Tm Group', pallet_sequence[:packed_tm_group])
    form.add_label(:mark, 'Mark', pallet_sequence[:mark])
    form.add_label(:inventory_code, 'Inventory Code', pallet_sequence[:inventory_code])
    form.add_label(:bom, 'Bom Code', pallet_sequence[:bom])
  end

  def fields_for_rmd_allocated_pallet_sequence_display(form, pallet_sequence) # rubocop:disable Metrics/AbcSize
    form.add_section_header('Load/Shipping')
    form.add_label(:order_number, 'Order Number', pallet_sequence[:order_number])
    form.add_label(:customer_order_number, 'Customer Order Number', pallet_sequence[:customer_order_number])
    form.add_label(:customer_reference, 'Customer Reference', pallet_sequence[:customer_reference])
    form.add_label(:customer, 'Customer', pallet_sequence[:customer])
    form.add_label(:target_customer, 'Target Customer', pallet_sequence[:target_customer])
    form.add_label(:vessel, 'Vessel', pallet_sequence[:vessel])
    form.add_label(:pol, 'POL', pallet_sequence[:pol])
    form.add_label(:pod, 'POD', pallet_sequence[:pod])
    form.add_label(:final_destination, 'Final Destination', pallet_sequence[:final_destination])
    form.add_label(:depot, 'Depot', pallet_sequence[:depot])
  end
end
# rubocop:enable Metrics/BlockLength
