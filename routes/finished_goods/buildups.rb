# frozen_string_literal: true

class Nspack < Roda
  route 'buildups', 'rmd' do |r|
    interactor = FinishedGoodsApp::BuildupsInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

    # --------------------------------------------------------------------------
    # PALLET BUILDUP
    # --------------------------------------------------------------------------
    r.on 'pallet_buildup' do
      r.get do
        form_state = {}
        if (error = retrieve_from_local_store(:error))
          form_state.merge!(error_message: error.message)
          form_state.merge!(errors: error.errors) unless error.errors.nil_or_empty?
        end

        form = Crossbeams::RMDForm.new(form_state,
                                       form_name: :buildup,
                                       notes: nil,
                                       scan_with_camera: @rmd_scan_with_camera,
                                       caption: 'Pallet Buildup',
                                       action: '/rmd/buildups/pallet_buildup',
                                       button_caption: 'Next')

        form.behaviours do |behaviour|
          behaviour.input_change :auto_create_destination_pallet,
                                 notify: [{ url: '/rmd/buildups/auto_create_destination_pallet_clicked' }]
        end

        form.add_field(:pallet_number, 'Destination Pallet', scan: 'key248_all', scan_type: :pallet_number, submit_form: false, data_type: :number, required: false)
        form.add_toggle(:auto_create_destination_pallet, 'Auto Create Destination Pallet')
        form.add_field(:qty_to_move, 'Qty Cartons To Move', data_type: :number, required: true)
        form.add_field(:p1, 'Pallet Number', scan: 'key248_all', scan_type: :pallet_number, submit_form: false, data_type: :number, required: true)
        form.add_field(:p2, 'Pallet Number', scan: 'key248_all', scan_type: :pallet_number, submit_form: false, data_type: :number, required: false)
        form.add_field(:p3, 'Pallet Number', scan: 'key248_all', scan_type: :pallet_number, submit_form: false, data_type: :number, required: false)
        form.add_field(:p4, 'Pallet Number', scan: 'key248_all', scan_type: :pallet_number, submit_form: false, data_type: :number, required: false)
        form.add_field(:p5, 'Pallet Number', scan: 'key248_all', scan_type: :pallet_number, submit_form: false, data_type: :number, required: false)
        form.add_field(:p6, 'Pallet Number', scan: 'key248_all', scan_type: :pallet_number, submit_form: false, data_type: :number, required: false)
        form.add_field(:p7, 'Pallet Number', scan: 'key248_all', scan_type: :pallet_number, submit_form: false, data_type: :number, required: false)
        form.add_field(:p8, 'Pallet Number', scan: 'key248_all', scan_type: :pallet_number, submit_form: false, data_type: :number, required: false)
        form.add_field(:p9, 'Pallet Number', scan: 'key248_all', scan_type: :pallet_number, submit_form: false, data_type: :number, required: false)
        form.add_field(:p10, 'Pallet Number', scan: 'key248_all', scan_type: :pallet_number, submit_form: false, data_type: :number, required: false)
        form.add_csrf_tag csrf_tag
        view(inline: form.render, layout: :layout_rmd)
      end

      r.post do
        if (buildup_id = interactor.process_to_rejoin(params[:buildup]))
          return rejoin_cancel_screen(interactor, buildup_id, 'An incompleted process was found.', true)
        end

        res = interactor.process_to_cancel(params[:buildup])
        return rejoin_cancel_screen(interactor, res.instance[:process][:id], 'An incompleted process was found containing the following <br>pallets you have just scanned.', false, res.instance[:pallets]) if res.success

        res = interactor.buildup_pallet(params[:buildup])
        if res.success
          r.redirect("/rmd/buildups/move_cartons/#{res.instance[:id]}")
        else
          store_locally(:error, res)
          r.redirect('/rmd/buildups/pallet_buildup')
        end
      end
    end

    r.on 'move_cartons', Integer do |id|
      r.get do
        pallet_buildup = interactor.pallet_buildup(id)
        qty_cartons_remaining = pallet_buildup.qty_cartons_to_move - (pallet_buildup.cartons_moved ? pallet_buildup.cartons_moved.values.flatten.length : 0)

        form_state = {}
        if (error = retrieve_from_local_store(:error))
          form_state.merge!(error_message: error.message)
          form_state.merge!(errors: error.errors) unless error.errors.nil_or_empty?
        end

        form = Crossbeams::RMDForm.new(form_state,
                                       form_name: :move_cartons,
                                       notes: nil,
                                       scan_with_camera: @rmd_scan_with_camera,
                                       caption: 'Move Cartons',
                                       action: "/rmd/buildups/move_cartons/#{id}",
                                       button_caption: 'Submit')

        form.add_field(:carton_number, 'Carton Number', data_type: :number, scan: 'key248_all', scan_type: :carton_label_id, submit_form: true, required: false)
        form.add_label(:qty_cartons_remaining, 'Cartons Remaining', qty_cartons_remaining.negative? ? 0 : qty_cartons_remaining)

        # pallet_buildup.cartons_moved.reverse_each.to_h.each do |k, v|
        pallet_buildup.cartons_moved.to_h.each do |k, v|
          form.add_section_header('&nbsp;')
          form.add_section_header("Scanned Ctns For Pallet:   #{k}")
          v.each do |c|
            form.add_label(:moved_ctn, '', c)
          end
        end

        form.add_button('Cancel', "/rmd/buildups/buildup_cancel_confirm/#{id}")
        form.add_button('Complete', "/rmd/buildups/buildup_complete/#{id}") unless pallet_buildup.cartons_moved.empty?
        form.add_csrf_tag csrf_tag
        view(inline: form.render, layout: :layout_rmd)
      end

      r.post do
        pallet_buildup = interactor.pallet_buildup(id)
        if pallet_buildup.completed
          store_locally(:error, "carton scan:#{id} aborted.")
          r.redirect("/rmd/buildups/buildup_completed/#{id}")
        end

        res = interactor.move_carton(params[:move_cartons], id)
        if res.success
          qty_cartons_remaining = res.instance.qty_cartons_to_move - res.instance.cartons_moved.values.flatten.length
          r.redirect("/rmd/buildups/complete_confirmation/#{id}") if qty_cartons_remaining <= 0
        else
          store_locally(:error, res)
        end
        r.redirect("/rmd/buildups/move_cartons/#{id}")
      end
    end

    r.on 'complete_confirmation', Integer do |id|
      pallet_buildup = interactor.pallet_buildup(id)
      form = Crossbeams::RMDForm.new({},
                                     notes: nil,
                                     form_name: :buildup,
                                     scan_with_camera: @rmd_scan_with_camera,
                                     caption: 'Confirm Complete',
                                     reset_button: false,
                                     no_submit: false,
                                     action: "/rmd/buildups/buildup_complete_rejected/#{id}",
                                     button_caption: 'No')
      form.add_section_header("All #{pallet_buildup.cartons_moved.values.flatten.length} cartons scanned. Complete?")
      form.add_button('Yes', "/rmd/buildups/buildup_complete/#{id}")
      form.add_csrf_tag csrf_tag
      view(inline: form.render, layout: :layout_rmd)
    end

    r.on 'buildup_complete_rejected', Integer do |id|
      r.redirect("/rmd/buildups/move_cartons/#{id}")
    end

    r.on 'buildup_cancel_confirm', Integer do |id|
      pallet_buildup = interactor.pallet_buildup(id)

      form_state = {}
      if (error = retrieve_from_local_store(:error))
        form_state.merge!(error_message: error.message)
        form_state.merge!(errors: error.errors) unless error.errors.nil_or_empty?
      end

      form = Crossbeams::RMDForm.new(form_state,
                                     notes: nil,
                                     form_name: :buildup,
                                     scan_with_camera: @rmd_scan_with_camera,
                                     caption: 'Confirm Cancel',
                                     reset_button: false,
                                     no_submit: false,
                                     action: "/rmd/buildups/buildup_cancel_no/#{id}",
                                     button_caption: 'No')

      qty_cartons_remaining = pallet_buildup.qty_cartons_to_move - pallet_buildup.cartons_moved.values.flatten.length
      form.add_section_header("Are you sure you want to cancel the buildup? (#{pallet_buildup.cartons_moved.values.flatten.length} cartons scanned, #{qty_cartons_remaining.negative? ? 0 : qty_cartons_remaining} remaining)")
      form.add_button('Yes', "/rmd/buildups/buildup_cancel/#{id}")
      form.add_csrf_tag csrf_tag
      view(inline: form.render, layout: :layout_rmd)
    end

    r.on 'buildup_cancel_no', Integer do |id|
      r.redirect("/rmd/buildups/move_cartons/#{id}")
    end

    r.on 'buildup_cancel', Integer do |id|
      res = interactor.delete_pallet_buildup(id)

      unless res.success
        store_locally(:error, res)
        r.redirect("/rmd/buildups/buildup_cancel_confirm/#{id}")
      end

      form = Crossbeams::RMDForm.new({},
                                     notes: nil,
                                     form_name: :buildup,
                                     scan_with_camera: @rmd_scan_with_camera,
                                     caption: '',
                                     reset_button: false,
                                     no_submit: true,
                                     action: '',
                                     button_caption: '')

      form.add_section_header('buildup canceled ')
      form.add_csrf_tag csrf_tag
      view(inline: form.render, layout: :layout_rmd)
    end

    r.on 'buildup_complete', Integer do |id|
      res = interactor.complete_pallet_buildup(id)
      if res.success
        r.redirect("/rmd/buildups/buildup_completed/#{id}")
      else
        store_locally(:error, res)
        r.redirect("/rmd/buildups/move_cartons/#{id}")
      end
    end

    r.on 'buildup_completed', Integer do |id|
      form_state = {}
      if (error = retrieve_from_local_store(:error))
        form_state.merge!(error_message: error.is_a?(String) ? error : error.message)
        form_state.merge!(errors: error.errors) unless error.is_a?(String) || error.errors.nil_or_empty?
      end

      form = Crossbeams::RMDForm.new(form_state,
                                     notes: nil,
                                     form_name: :buildup,
                                     scan_with_camera: @rmd_scan_with_camera,
                                     caption: 'Pallet Buildup Completed',
                                     reset_button: false,
                                     no_submit: true,
                                     action: '/',
                                     button_caption: '')
      form.add_section_header("Pallet buildup:#{id} has been completed successfully")
      form.add_csrf_tag csrf_tag
      view(inline: form.render, layout: :layout_rmd)
    end

    r.on 'rejoin', Integer do |id|
      r.redirect("/rmd/buildups/move_cartons/#{id}")
    end

    r.on 'auto_create_destination_pallet_clicked' do
      hide =  case params[:changed_value]
              when 't'
                true
              when 'f', ''
                false
              end

      action = hide ? :hide_element : :show_element
      json_actions([OpenStruct.new(type: action, dom_id: 'buildup_pallet_number_row')])
    end
  end

  def rejoin_cancel_screen(interactor, id, err, rejoin = false, pallets = []) # rubocop:disable Metrics/AbcSize
    pallet_buildup = interactor.pallet_buildup(id)
    qty_cartons_remaining = pallet_buildup.qty_cartons_to_move - (pallet_buildup.cartons_moved ? pallet_buildup.cartons_moved.values.flatten.length : 0)

    form = Crossbeams::RMDForm.new({},
                                   form_name: :move_cartons,
                                   notes: "<label class='b mid-gray'>#{err}</label>",
                                   scan_with_camera: @rmd_scan_with_camera,
                                   action: "/rmd/buildups/buildup_cancel/#{id}",
                                   button_caption: 'Cancel')

    form.add_label(:id, 'Buildup Id', id)
    form.add_label(:created_at, 'Created At', pallet_buildup.created_at.strftime('%Y-%m-%d %H:%M:%S'))
    form.add_label(:destination_pallet_number, 'Dest Pallet Number', pallet_buildup.destination_pallet_number, nil, value_class: 'b orange')
    form.add_label(:qty_cartons_remaining, 'Cartons Remaining', qty_cartons_remaining.negative? ? 0 : qty_cartons_remaining)

    pallet_buildup.cartons_moved.to_h.each do |k, v|
      form.add_section_header('&nbsp;')
      header = pallets.include?(k) ? "Scanned Ctns For Pallet:   <label class='orange'>#{k}</label>" : "Scanned Ctns For Pallet:   #{k}"
      form.add_section_header(header)
      v.each do |c|
        form.add_label(:moved_ctn, '', c)
      end
    end

    form.add_section_header('&nbsp;')
    form.add_section_header('&nbsp;')
    if rejoin
      rejoin_label = 'Rejoin or'
      form.add_button('Rejoin', "/rmd/buildups/rejoin/#{id}")
    end
    form.add_section_header("Do you want to #{rejoin_label} Cancel this process?")
    form.add_csrf_tag csrf_tag
    view(inline: form.render, layout: :layout_rmd)
  end
end
