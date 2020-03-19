# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
class Nspack < Roda # rubocop:disable ClassLength
  route 'finished_goods', 'rmd' do |r|
    r.on 'pallet_movements' do
      interactor = FinishedGoodsApp::PalletMovementsInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      # --------------------------------------------------------------------------
      # MOVE PALLET
      # --------------------------------------------------------------------------
      r.on 'move_pallet' do
        r.get do
          pallet = {}
          notice = retrieve_from_local_store(:flash_notice)
          from_state = retrieve_from_local_store(:from_state)
          pallet.merge!(from_state) unless from_state.nil?
          error = retrieve_from_local_store(:error)
          if error.is_a?(String)
            pallet.merge!(error_message: error)
          elsif !error.nil?
            pallet.merge!(error_message: error.message)
            pallet.merge!(errors: error.errors) unless error.errors.nil_or_empty?
          end

          form = Crossbeams::RMDForm.new(pallet,
                                         form_name: :pallet,
                                         notes: notice,
                                         scan_with_camera: @rmd_scan_with_camera,
                                         caption: 'Scan Pallet And Location',
                                         action: '/rmd/finished_goods/pallet_movements/move_pallet',
                                         button_caption: 'Submit')

          form.add_field(:location, 'Location', scan: 'key248_all', scan_type: :location, submit_form: false, required: true, lookup: true)
          form.add_label(:remaining_num_position, 'Remaining No Position', pallet[:remaining_num_position]) unless pallet[:remaining_num_position].nil_or_empty?
          form.add_label(:next_position, 'Next Position', pallet[:next_position]) unless pallet[:next_position].nil_or_empty?
          form.add_field(:pallet_number, 'Pallet Number', scan: 'key248_all', scan_type: :pallet_number, submit_form: true, data_type: :number, required: true)
          form.add_csrf_tag csrf_tag
          view(inline: form.render, layout: :layout_rmd)
        end

        r.post do
          pallet_number = MesscadaApp::ScannedPalletNumber.new(scanned_pallet_number: params[:pallet][:pallet_number]).pallet_number
          res = interactor.move_pallet(pallet_number, params[:pallet][:location], params[:pallet][:location_scan_field])

          if res.success
            scanned_locn_id = MasterfilesApp::LocationRepo.new.resolve_location_id_from_scan(params[:pallet][:location], params[:pallet][:location_scan_field])
            scanned_locn = MasterfilesApp::LocationRepo.new.find_location(scanned_locn_id)
            if AppConst::CALCULATE_PALLET_DECK_POSITIONS && scanned_locn.location_type_code == AppConst::LOCATION_TYPES_COLD_BAY_DECK
              positions = MasterfilesApp::LocationRepo.new.find_filled_deck_positions(scanned_locn_id)
              params[:pallet][:pallet_number] = nil
              params[:pallet][:remaining_num_position] = positions.min - 1
              params[:pallet][:next_position] = (positions.min - 1).positive? ? "#{scanned_locn.location_long_code}_P#{positions.min - 1}" : nil
              store_locally(:from_state, params[:pallet])
            end
            store_locally(:flash_notice, res.message)
          else
            store_locally(:error, res)
          end
          r.redirect('/rmd/finished_goods/pallet_movements/move_pallet')
        rescue Crossbeams::InfoError => e
          store_locally(:error, rmd_error_message(e))
          r.redirect('/rmd/finished_goods/pallet_movements/move_pallet')
        end
      end
    end

    # --------------------------------------------------------------------------
    # REPACK PALLET
    # --------------------------------------------------------------------------
    r.on 'repack_pallet' do
      interactor = MesscadaApp::MesscadaInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      r.on 'scan_pallet' do
        r.get do
          pallet = {}
          notice = retrieve_from_local_store(:flash_notice)
          error = retrieve_from_local_store(:error)
          pallet.merge!(error_message: error) unless error.nil?

          form = Crossbeams::RMDForm.new(pallet,
                                         notes: notice,
                                         form_name: :pallet,
                                         scan_with_camera: @rmd_scan_with_camera,
                                         caption: 'Scan Pallet',
                                         action: '/rmd/finished_goods/repack_pallet/scan_pallet',
                                         button_caption: 'Submit')

          form.add_field(:pallet_number, 'Pallet Number', scan: 'key248_all', scan_type: :pallet_number, submit_form: true, data_type: :number, required: true)
          form.add_csrf_tag csrf_tag
          view(inline: form.render, layout: :layout_rmd)
        end

        r.post do
          pallet_sequences = interactor.find_pallet_sequences_by_pallet_number(params[:pallet][:pallet_number])
          if pallet_sequences.empty?
            store_locally(:error, "Scanned Pallet:#{params[:pallet][:pallet_number]} doesn't exist")
            r.redirect('/rmd/finished_goods/repack_pallet/scan_pallet')
          else
            r.redirect("/rmd/finished_goods/repack_pallet/scan_pallet_sequence/#{pallet_sequences.first[:id]}")
          end
        end
      end

      r.on 'scan_pallet_sequence', Integer do |id|
        r.get do
          pallet_sequence = interactor.find_pallet_sequence_attrs(id)
          if pallet_sequence.nil_or_empty?
            store_locally(:error, "Pallet sequence:#{id} doesn't exist")
            r.redirect('/rmd/finished_goods/repack_pallet/scan_pallet')
          end

          ps_ids = interactor.find_pallet_sequences_from_same_pallet(id)

          error = retrieve_from_local_store(:error)
          pallet_sequence.merge!(error_message: error.message) unless error.nil?

          form = Crossbeams::RMDForm.new(pallet_sequence,
                                         form_name: :pallet,
                                         scan_with_camera: @rmd_scan_with_camera,
                                         caption: "View Pallet #{pallet_sequence[:pallet_number]}",
                                         step_and_total: [ps_ids.index(id) + 1, ps_ids.length],
                                         reset_button: false,
                                         action: "/rmd/finished_goods/repack_pallet/scan_pallet_sequence/#{id}",
                                         button_caption: 'Repack')
          fields_for_rmd_pallet_sequence_display(form, pallet_sequence)
          form.add_csrf_tag csrf_tag
          form.add_label(:verification_result, 'Verification Result', pallet_sequence[:verification_result])
          form.add_label(:verification_failure_reason, 'Verification Failure Reason', pallet_sequence[:verification_failure_reason])
          form.add_label(:fruit_sticker, 'Fruit Sticker', pallet_sequence[:fruit_sticker]) if AppConst::REQUIRE_FRUIT_STICKER_AT_PALLET_VERIFICATION
          form.add_prev_next_nav('/rmd/finished_goods/repack_pallet/scan_pallet_sequence/$:id$', ps_ids, id)
          view(inline: form.render, layout: :layout_rmd)
        end

        r.post do
          pallet_sequence = interactor.find_pallet_sequence_attrs(id)
          res = interactor.repack_pallet(pallet_sequence[:pallet_id])
          if res.success
            pallet_sequence_id = interactor.pallet_sequence_ids(res.instance[:new_pallet_id]).first
            store_locally(:flash_notice, res.message)
            r.redirect("/rmd/finished_goods/repack_pallet/print_pallet_labels/#{pallet_sequence_id}")
          else
            store_locally(:error, res)
            r.redirect("/rmd/finished_goods/repack_pallet/scan_pallet_sequence/#{id}")
          end

        rescue Crossbeams::InfoError => e
          store_locally(:error, rmd_error_message(e))
          r.redirect("/rmd/finished_goods/repack_pallet/scan_pallet_sequence/#{id}")
        end
      end

      r.on 'print_pallet_labels', Integer do |id|
        prod_interactor = ProductionApp::ProductionRunInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

        r.get do
          pallet_sequence = interactor.find_pallet_sequence_attrs(id)
          if pallet_sequence.nil_or_empty?
            store_locally(:error, "Pallet sequence:#{id} doesn't exist")
            r.redirect('/rmd/finished_goods/repack_pallet/scan_pallet')
          end

          ps_ids = interactor.find_pallet_sequences_from_same_pallet(id)

          printer_repo = LabelApp::PrinterRepo.new

          notice = retrieve_from_local_store(:flash_notice)
          error = retrieve_from_local_store(:error)
          pallet_sequence.merge!(error_message: error.message) unless error.nil?

          form = Crossbeams::RMDForm.new(pallet_sequence,
                                         notes: notice,
                                         form_name: :pallet,
                                         scan_with_camera: @rmd_scan_with_camera,
                                         caption: "View Pallet #{pallet_sequence[:pallet_number]}",
                                         step_and_total: [ps_ids.index(id) + 1, ps_ids.length],
                                         reset_button: false,
                                         action: "/rmd/finished_goods/repack_pallet/print_pallet_labels/#{id}",
                                         button_caption: 'Print')
          fields_for_rmd_pallet_sequence_display(form, pallet_sequence)
          form.add_csrf_tag csrf_tag
          form.add_label(:verification_result, 'Verification Result', pallet_sequence[:verification_result])
          form.add_label(:verification_failure_reason, 'Verification Failure Reason', pallet_sequence[:verification_failure_reason])
          form.add_label(:fruit_sticker, 'Fruit Sticker', pallet_sequence[:fruit_sticker]) if AppConst::REQUIRE_FRUIT_STICKER_AT_PALLET_VERIFICATION
          form.add_select(:pallet_label_name, 'Pallet Label', value: prod_interactor.find_pallet_label_name_by_resource_allocation_id(pallet_sequence[:resource_allocation_id]), items: prod_interactor.find_pallet_labels, required: false)
          form.add_select(:printer, 'Printer', items: printer_repo.select_printers_for_application(AppConst::PRINT_APP_PALLET), required: false, value: printer_repo.default_printer_for_application(AppConst::PRINT_APP_PALLET))
          form.add_field(:qty_to_print, 'Qty To Print', required: false, prompt: true, data_type: :number)
          form.add_prev_next_nav('/rmd/finished_goods/repack_pallet/print_pallet_labels/$:id$', ps_ids, id)
          view(inline: form.render, layout: :layout_rmd)
        end

        r.post do
          res = prod_interactor.print_pallet_label_from_sequence(id,
                                                                 pallet_label_name: params[:pallet][:pallet_label_name],
                                                                 no_of_prints: params[:pallet][:qty_to_print],
                                                                 printer: params[:pallet][:printer])
          if res.success
            store_locally(:flash_notice, "Labels For Pallet: #{params[:pallet][:pallet_number]} Printed Successfully")
          else
            store_locally(:error, res)
          end
          r.redirect("/rmd/finished_goods/repack_pallet/print_pallet_labels/#{id}")
        end
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
