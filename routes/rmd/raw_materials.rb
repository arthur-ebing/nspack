# frozen_string_literal: true

class Nspack < Roda # rubocop:disable ClassLength
  # --------------------------------------------------------------------------
  # DELIVERIES
  # --------------------------------------------------------------------------
  route 'rmt_deliveries', 'rmd' do |r| # rubocop:disable Metrics/BlockLength
    # --------------------------------------------------------------------------
    # BINS
    # --------------------------------------------------------------------------
    r.on 'rmt_bins', Integer do |id| # rubocop:disable Metrics/BlockLength
      interactor = RawMaterialsApp::RmtBinInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      r.on 'new' do # rubocop:disable Metrics/BlockLength    # NEW
        bin_delivery = RawMaterialsApp::RmtDeliveryRepo.new.get_bin_delivery(id)
        default_rmt_container_type = RawMaterialsApp::RmtDeliveryRepo.new.rmt_container_type_by_container_type_code(AppConst::DELIVERY_DEFAULT_RMT_CONTAINER_TYPE)
        details = retrieve_from_local_store(:bin) || { cultivar_id: bin_delivery[:cultivar_id], bin_fullness: :Full }

        capture_inner_bins = AppConst::DELIVERY_CAPTURE_INNER_BINS && !default_rmt_container_type[:id].nil?
        capture_nett_weight = AppConst::DELIVERY_CAPTURE_BIN_WEIGHT_AT_FRUIT_RECEPTION
        capture_container_material = AppConst::DELIVERY_CAPTURE_CONTAINER_MATERIAL
        capture_container_material_owner = AppConst::DELIVERY_CAPTURE_CONTAINER_MATERIAL_OWNER

        form = Crossbeams::RMDForm.new(details,
                                       form_name: :rmt_bin,
                                       scan_with_camera: @rmd_scan_with_camera,
                                       caption: 'New Bin',
                                       action: "/rmd/rmt_deliveries/rmt_bins/#{id}/rmt_bins",
                                       button_caption: 'Submit')

        form.behaviours do |behaviour|
          behaviour.dropdown_change :rmt_container_type_id, notify: [{ url: '/rmd/rmt_deliveries/rmt_bins/rmt_bin_rmt_container_type_combo_changed' }] if capture_container_material
          behaviour.dropdown_change :rmt_container_material_type_id, notify: [{ url: '/rmd/rmt_deliveries/rmt_bins/rmt_bin_container_material_type_combo_changed' }] if capture_container_material && capture_container_material_owner
        end

        form.add_label(:farm_code, 'Farm', bin_delivery[:farm_code], nil, as_table_cell: true)
        form.add_label(:puc_code, 'Puc', bin_delivery[:puc_code], nil, as_table_cell: true)
        form.add_label(:orchard_code, 'Orchard', bin_delivery[:orchard_code], nil, as_table_cell: true)
        form.add_label(:date_picked, 'Date Picked', bin_delivery[:date_picked], nil, as_table_cell: true)
        form.add_label(:date_delivered, 'Date Delivered', bin_delivery[:date_delivered], nil, as_table_cell: true)
        form.add_label(:qty_bins_tipped, 'Qty Bins Tipped', bin_delivery[:qty_bins_tipped], nil, as_table_cell: true)
        form.add_label(:qty_bins_received, 'Qty Bins Received', bin_delivery[:qty_bins_received], nil, as_table_cell: true)
        form.add_select(:rmt_container_type_id, 'Container Type', items: MasterfilesApp::RmtContainerTypeRepo.new.for_select_rmt_container_types, value: default_rmt_container_type[:id],
                                                                  required: true, prompt: true)
        form.add_label(:qty_bins, 'Qty Bins', 1, 1)
        if capture_inner_bins
          form.add_field(:qty_inner_bins, 'Qty Inner Bins', data_type: 'number')
        else
          form.add_label(:qty_inner_bins, 'Qty Inner Bins', '1', '1', hide_on_load: true)
        end
        form.add_select(:bin_fullness, 'Bin Fullness', items: %w[Quarter Half Three\ Quarters Full], prompt: true)
        form.add_field(:nett_weight, 'Nett Weight', required: false) if capture_nett_weight
        if capture_container_material
          form.add_select(:rmt_container_material_type_id, 'Container Material Type',
                          items: MasterfilesApp::RmtContainerMaterialTypeRepo.new.for_select_rmt_container_material_types(where: { rmt_container_type_id: default_rmt_container_type[:id] }),
                          required: true, prompt: true)
        end
        if capture_container_material && capture_container_material_owner
          form.add_select(:rmt_material_owner_party_role_id, 'Container Material Owner',
                          items: !details[:rmt_container_material_type_id].to_s.empty? ? RawMaterialsApp::RmtDeliveryRepo.new.find_container_material_owners_by_container_material_type(details[:rmt_container_material_type_id]) : [],
                          required: true, prompt: true)
        end
        form.add_field(:bin_asset_number, 'Asset Number', scan: 'key248_all', scan_type: :bin_asset, required: true)
        form.add_csrf_tag csrf_tag
        view(inline: form.render, layout: :layout_rmd)
      end

      r.post do # CREATE
        res = interactor.create_rmt_bin(id, params[:rmt_bin])
        if res.success
          flash[:notice] = 'Bin Created Successfully'
          r.redirect("/raw_materials/deliveries/rmt_deliveries/#{id}/edit")
        else
          params[:rmt_bin][:error_message] = res.message
          params[:rmt_bin][:errors] = res.errors
          store_locally(:bin, params[:rmt_bin])
          r.redirect("/rmd/rmt_deliveries/rmt_bins/#{id}/new")
        end
      end
    end

    r.on 'rmt_bins' do # rubocop:disable Metrics/BlockLength
      interactor = RawMaterialsApp::RmtBinInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      r.on 'rmt_bin_rmt_container_type_combo_changed' do
        rmt_container_type_combo_changed('rmt_bin')
      end

      r.on 'rmt_bin_container_material_type_combo_changed' do
        container_material_type_combo_changed('rmt_bin')
      end

      # --------------------------------------------------------------------------
      # MOVE RMT BIN
      # --------------------------------------------------------------------------
      r.on 'move_rmt_bin' do
        r.get do
          notice = retrieve_from_local_store(:flash_notice)
          form_state = {}
          error = retrieve_from_local_store(:errors)
          form_state.merge!(error_message: error[:error_message], errors:  { bin_number: [''] }) unless error.nil?
          form = Crossbeams::RMDForm.new(form_state,
                                         form_name: :bin,
                                         notes: notice,
                                         scan_with_camera: @rmd_scan_with_camera,
                                         caption: 'Scan Bin',
                                         action: '/rmd/rmt_deliveries/rmt_bins/move_rmt_bin',
                                         button_caption: 'Submit')
          form.add_field(:bin_number, 'Bin Number', scan: 'key248_all', scan_type: :bin_asset, required: true, submit_form: true)
          form.add_csrf_tag csrf_tag
          view(inline: form.render, layout: :layout_rmd)
        end

        r.post do
          res = interactor.validate_bin(params[:bin][:bin_number])
          if res.success
            r.redirect("/rmd/rmt_deliveries/rmt_bins/scan_location/#{res.instance[:id]}")
          else
            store_locally(:errors, error_message: "Error: #{unwrap_failed_response(res)}")
            r.redirect('/rmd/rmt_deliveries/rmt_bins/move_rmt_bin')
          end
        end
      end

      r.on 'scan_location', Integer do |id|
        r.get do
          bin = RawMaterialsApp::RmtDeliveryRepo.new.find_rmt_bin(id)
          notice = retrieve_from_local_store(:flash_notice)
          form_state = {}
          error = retrieve_from_local_store(:errors)
          form_state.merge!(error_message: error[:error_message], errors:  { location: [''] }) unless error.nil?
          form = Crossbeams::RMDForm.new(form_state,
                                         form_name: :bin,
                                         notes: notice,
                                         scan_with_camera: @rmd_scan_with_camera,
                                         caption: 'Scan Bin',
                                         action: "/rmd/rmt_deliveries/rmt_bins/move_rmt_bin_submit/#{id}",
                                         button_caption: 'Move Bin')
          form.add_label(:bin_number, 'Bin Number', AppConst::USE_PERMANENT_RMT_BIN_BARCODES ? bin[:bin_asset_number] : bin[:id])
          form.add_field(:location, 'Location', scan: 'key248_all', scan_type: :location, submit_form: true, required: true, lookup: false)
          form.add_csrf_tag csrf_tag
          view(inline: form.render, layout: :layout_rmd)
        end
      end

      r.on 'move_rmt_bin_submit', Integer do |id|
        res = interactor.move_bin(id, params[:bin][:location], !params[:bin][:location_scan_field].nil_or_empty?)
        if res.success
          store_locally(:flash_notice, unwrap_failed_response(res))
          r.redirect('/rmd/rmt_deliveries/rmt_bins/move_rmt_bin')
        else
          store_locally(:errors, error_message: "Error: #{unwrap_failed_response(res)}")
          r.redirect("/rmd/rmt_deliveries/rmt_bins/scan_location/#{id}")
        end
      end

      # --------------------------------------------------------------------------
      # EDIT RMT BIN
      # --------------------------------------------------------------------------
      r.on 'edit_rmt_bin' do
        r.get do
          notice = retrieve_from_local_store(:flash_notice)
          form_state = {}
          error = retrieve_from_local_store(:errors)
          form_state.merge!(error_message: error[:error_message], errors:  { bin_number: [''] }) unless error.nil?
          form = Crossbeams::RMDForm.new(form_state,
                                         form_name: :bin,
                                         notes: notice,
                                         scan_with_camera: @rmd_scan_with_camera,
                                         caption: 'Scan Bin',
                                         action: '/rmd/rmt_deliveries/rmt_bins/edit_rmt_bin',
                                         button_caption: 'Submit')
          form.add_field(:bin_number, 'Bin Number', scan: 'key248_all', scan_type: :bin_asset, required: true, submit_form: true)
          form.add_csrf_tag csrf_tag
          view(inline: form.render, layout: :layout_rmd)
        end

        r.post do
          res = interactor.validate_bin(params[:bin][:bin_number])
          if res.success
            r.redirect("/rmd/rmt_deliveries/rmt_bins/render_edit_rmt_bin/#{res.instance[:id]}")
          else
            store_locally(:errors, error_message: "Error: #{unwrap_failed_response(res)}")
            r.redirect('/rmd/rmt_deliveries/rmt_bins/edit_rmt_bin')
          end
        end
      end

      r.on 'render_edit_rmt_bin', Integer do |id| # rubocop:disable Metrics/BlockLength
        bin = interactor.bin_details(id)
        form_state = { bin_fullness: bin[:bin_fullness], qty_bins: bin[:qty_bins] }
        error = retrieve_from_local_store(:errors)
        form_state.merge!(error_message: error[:error_message], errors:  { delivery_number: [''] }) unless error.nil?

        form = Crossbeams::RMDForm.new(form_state,
                                       notes: nil,
                                       form_name: :rmt_bin,
                                       scan_with_camera: @rmd_scan_with_camera,
                                       caption: 'Update Bin',
                                       reset_button: false,
                                       no_submit: false,
                                       action: "/rmd/rmt_deliveries/rmt_bins/edit_rmt_bin_submit/#{bin[:id]}",
                                       button_caption: 'Update')

        capture_container_material = AppConst::DELIVERY_CAPTURE_CONTAINER_MATERIAL
        capture_container_material_owner = AppConst::DELIVERY_CAPTURE_CONTAINER_MATERIAL_OWNER

        form.behaviours do |behaviour|
          behaviour.dropdown_change :rmt_container_type_id, notify: [{ url: '/rmd/rmt_deliveries/rmt_bins/bin_edit_rmt_container_type_combo_changed' }] if capture_container_material
          behaviour.dropdown_change :rmt_container_material_type_id, notify: [{ url: '/rmd/rmt_deliveries/rmt_bins/bin_edit_container_material_type_combo_changed' }] if capture_container_material && capture_container_material_owner
        end

        form.add_label(:delivery_number, 'Delivery Number', bin[:rmt_delivery_id])
        form.add_label(:farm_code, 'Farm', bin[:farm_code])
        form.add_label(:puc_code, 'Puc', bin[:puc_code])
        form.add_label(:orchard_code, 'Orchard', bin[:orchard_code])
        form.add_label(:cultivar_name, 'Cultivar', bin[:cultivar_name])
        form.add_field(:qty_bins, 'Qty Bins', hide_on_load: true)
        form.add_select(:bin_fullness, 'Bin Fullness', items: %w[Quarter Half Three\ Quarters Full], prompt: true)
        form.add_select(:rmt_container_type_id, 'Container Type', items: MasterfilesApp::RmtContainerTypeRepo.new.for_select_rmt_container_types, value: bin[:rmt_container_type_id], required: true, prompt: true)

        if capture_container_material
          form.add_select(:rmt_container_material_type_id, 'Container Material Type',
                          items: MasterfilesApp::RmtContainerMaterialTypeRepo.new.for_select_rmt_container_material_types(where: { rmt_container_type_id: bin[:rmt_container_type_id] }),
                          required: true, prompt: true, value: bin[:rmt_container_material_type_id])
        end

        if capture_container_material && capture_container_material_owner
          form.add_select(:rmt_material_owner_party_role_id, 'Container Material Owner',
                          items: RawMaterialsApp::RmtDeliveryRepo.new.find_container_material_owners_by_container_material_type(bin[:rmt_container_material_type_id]),
                          required: true, prompt: true, value: bin[:rmt_material_owner_party_role_id])
        end
        form.add_csrf_tag csrf_tag
        view(inline: form.render, layout: :layout_rmd)
      end

      r.on 'edit_rmt_bin_submit', Integer do |id|
        res = interactor.pdt_update_rmt_bin(id, params[:rmt_bin])
        if res.success
          store_locally(:flash_notice, "Bin: #{id} Updated Successfully")
          r.redirect('/rmd/rmt_deliveries/rmt_bins/edit_rmt_bin')
        else
          store_locally(:errors, error_message: "Error: #{unwrap_failed_response(res)}")
          r.redirect("/rmd/rmt_deliveries/rmt_bins/render_edit_rmt_bin/#{id}")
        end
      end

      # --------------------------------------------------------------------------
      # BIN RECEPTION SCANNING
      # --------------------------------------------------------------------------
      r.on 'bin_reception_scanning' do
        r.get do
          notice = retrieve_from_local_store(:flash_notice)
          form_state = {}
          error = retrieve_from_local_store(:errors)
          form_state.merge!(error_message: error[:error_message], errors:  { delivery_number: [''] }) unless error.nil?
          form = Crossbeams::RMDForm.new(form_state,
                                         form_name: :bin_reception,
                                         notes: notice,
                                         scan_with_camera: @rmd_scan_with_camera,
                                         caption: 'Scan Delivery',
                                         action: '/rmd/rmt_deliveries/rmt_bins/bin_reception_scanning',
                                         button_caption: 'Submit')
          form.add_field(:delivery_number, 'Delivery', scan: 'key248_all', scan_type: :delivery, data_type: 'number', submit_form: true, required: false)
          form.add_csrf_tag csrf_tag
          view(inline: form.render, layout: :layout_rmd)
        end

        r.post do
          res = interactor.validate_delivery(params[:bin_reception][:delivery_number])
          if res.success
            r.redirect("/rmd/rmt_deliveries/rmt_bins/delivery_confirmation/#{params[:bin_reception][:delivery_number]}")
          else
            store_locally(:errors, error_message: "Error: #{unwrap_failed_response(res)}")
            r.redirect('/rmd/rmt_deliveries/rmt_bins/bin_reception_scanning')
          end
        end
      end

      r.on 'delivery_confirmation', Integer do |id|
        delivery = interactor.get_delivery_confirmation_details(id)
        form = Crossbeams::RMDForm.new({},
                                       notes: nil,
                                       form_name: :delivery,
                                       scan_with_camera: @rmd_scan_with_camera,
                                       caption: 'Confirm Delivery',
                                       reset_button: false,
                                       no_submit: false,
                                       action: "/rmd/rmt_deliveries/rmt_bins/cancel_bin_reception/#{id}",
                                       button_caption: 'Cancel')
        form.add_label(:delivery_number, 'Delivery Number', delivery[:id])
        form.add_label(:cultivar_group_code, 'Cultivar Group', delivery[:cultivar_group_code])
        form.add_label(:cultivar_name, 'Cultivar', delivery[:cultivar_name])
        form.add_label(:farm_code, 'Farm', delivery[:farm_code])
        form.add_label(:puc_code, 'Puc', delivery[:puc_code])
        form.add_label(:orchard_code, 'Orchard', delivery[:orchard_code])
        form.add_label(:truck_registration_number, 'Truck Reg Number', delivery[:truck_registration_number])
        form.add_label(:date_delivered, 'Date Delivered', delivery[:date_delivered])
        form.add_label(:bins_received, 'Bins Received', delivery[:bins_received])
        form.add_label(:qty_bins_remaining, 'Qty Bins Remaining', delivery[:qty_bins_remaining])
        form.add_button('Next', "/rmd/rmt_deliveries/rmt_bins/receive_rmt_bins/#{id}")
        form.add_csrf_tag csrf_tag
        view(inline: form.render, layout: :layout_rmd)
      end

      r.on 'cancel_bin_reception', Integer do |id|
        store_locally(:flash_notice, "Bin Reception For Delivery: #{id} Cancelled Successfully")
        r.redirect('/rmd/rmt_deliveries/rmt_bins/bin_reception_scanning')
      end

      r.on 'bin_reception_rmt_container_type_combo_changed' do
        rmt_container_type_combo_changed('delivery')
      end

      r.on 'bin_reception_container_material_type_combo_changed' do
        container_material_type_combo_changed('delivery')
      end

      r.on 'bin_edit_rmt_container_type_combo_changed' do
        rmt_container_type_combo_changed('rmt_bin')
      end

      r.on 'bin_edit_container_material_type_combo_changed' do
        container_material_type_combo_changed('rmt_bin')
      end

      r.on 'receive_rmt_bins', Integer do |id| # rubocop:disable Metrics/BlockLength
        delivery = interactor.get_delivery_confirmation_details(id)
        default_rmt_container_type = RawMaterialsApp::RmtDeliveryRepo.new.rmt_container_type_by_container_type_code(AppConst::DELIVERY_DEFAULT_RMT_CONTAINER_TYPE)

        capture_container_material = AppConst::DELIVERY_CAPTURE_CONTAINER_MATERIAL
        capture_container_material_owner = AppConst::DELIVERY_CAPTURE_CONTAINER_MATERIAL_OWNER

        notice = retrieve_from_local_store(:flash_notice)
        form_state = { bin_fullness: :Full, qty_bins: 1 }
        error = retrieve_from_local_store(:errors)
        form_state.merge!(error_message: error[:message], errors: error[:errors]) unless error.nil?
        form = Crossbeams::RMDForm.new(form_state,
                                       notes: notice,
                                       form_name: :delivery,
                                       scan_with_camera: @rmd_scan_with_camera,
                                       caption: 'Receive Bins',
                                       reset_button: false,
                                       no_submit: false,
                                       action: "/rmd/rmt_deliveries/rmt_bins/receive_rmt_bins_submit/#{id}",
                                       button_caption: 'Submit')

        form.behaviours do |behaviour|
          behaviour.dropdown_change :rmt_container_type_id, notify: [{ url: '/rmd/rmt_deliveries/rmt_bins/bin_reception_rmt_container_type_combo_changed' }] if capture_container_material
          behaviour.dropdown_change :rmt_container_material_type_id, notify: [{ url: '/rmd/rmt_deliveries/rmt_bins/bin_reception_container_material_type_combo_changed' }] if capture_container_material && capture_container_material_owner
        end

        form.add_label(:delivery_number, 'Delivery Number', delivery[:id])
        form.add_label(:cultivar_group_code, 'Cultivar Group', delivery[:cultivar_group_code])
        form.add_label(:cultivar_name, 'Cultivar', delivery[:cultivar_name])
        form.add_label(:farm_code, 'Farm', delivery[:farm_code])
        form.add_label(:puc_code, 'Puc', delivery[:puc_code])
        form.add_label(:orchard_code, 'Orchard', delivery[:orchard_code])
        form.add_label(:bins_received, 'Bins Received', delivery[:bins_received])
        form.add_label(:qty_bins_remaining, 'Qty Bins Remaining', delivery[:qty_bins_remaining])
        form.add_select(:rmt_container_type_id, 'Container Type', items: MasterfilesApp::RmtContainerTypeRepo.new.for_select_rmt_container_types, value: default_rmt_container_type[:id], required: true, prompt: true)

        if capture_container_material
          form.add_select(:rmt_container_material_type_id, 'Container Material Type',
                          items: MasterfilesApp::RmtContainerMaterialTypeRepo.new.for_select_rmt_container_material_types(where: { rmt_container_type_id: default_rmt_container_type[:id] }),
                          required: true, prompt: true)
        end

        if capture_container_material && capture_container_material_owner
          form.add_select(:rmt_material_owner_party_role_id, 'Container Material Owner',
                          items: [],
                          required: true, prompt: true)
        end

        form.add_field(:bin_fullness, 'Bin Fullness', hide_on_load: true)
        form.add_field(:qty_bins, 'Qty Bins', hide_on_load: true)

        form.add_field(:bin_asset_number1, 'Asset Number1', scan: 'key248_all', scan_type: :bin_asset, submit_form: false, required: true)
        if delivery[:qty_bins_remaining] > 1
          (1..(delivery[:qty_bins_remaining] - 1)).each do |c|
            form.add_field("bin_asset_number#{c + 1}".to_sym, "Asset Number#{c + 1}", scan: 'key248_all', scan_type: :bin_asset, submit_form: false, required: false)
          end
        end

        form.add_csrf_tag csrf_tag
        view(inline: form.render, layout: :layout_rmd)
      end

      r.on 'receive_rmt_bins_submit', Integer do |id|
        params[:delivery].delete_if { |_k, v| v.nil_or_empty? }
        res = interactor.create_rmt_bins(id, params[:delivery])
        if res.success
          delivery = interactor.get_delivery_confirmation_details(id)
          if delivery[:qty_bins_remaining].positive?
            store_locally(:flash_notice, res.message)
            r.redirect("/rmd/rmt_deliveries/rmt_bins/receive_rmt_bins/#{id}")
          else
            store_locally(:flash_notice, "All #{delivery[:bins_received]} bins for delivery:#{id} have already been received(scanned) successfully")
            r.redirect("/rmd/rmt_deliveries/rmt_bins/set_bin_level/#{id}")
          end
        else
          store_locally(:errors, res)
          r.redirect("/rmd/rmt_deliveries/rmt_bins/receive_rmt_bins/#{id}")
        end
      end

      r.on 'set_bin_level', Integer do |id|
        notice = retrieve_from_local_store(:flash_notice)
        form_state = { bin_fullness: :Full }

        error = retrieve_from_local_store(:errors)
        form_state.merge!(error_message: error[:message], errors: error[:errors]) unless error.nil?

        form = Crossbeams::RMDForm.new(form_state,
                                       notes: notice,
                                       form_name: :bin,
                                       scan_with_camera: @rmd_scan_with_camera,
                                       caption: 'Set Bin Level',
                                       reset_button: false,
                                       no_submit: false,
                                       action: "/rmd/rmt_deliveries/rmt_bins/set_bin_level_complete/#{id}",
                                       button_caption: 'Finish')

        form.add_field(:bin_asset_number, 'Asset Number', scan: 'key248_all', scan_type: :bin_asset, required: true, submit_form: false)
        form.add_select(:bin_fullness, 'Bin Fullness', items: %w[Quarter Half Three\ Quarters Full], prompt: true)
        form.add_button('Next Bin', "/rmd/rmt_deliveries/rmt_bins/set_bin_level_next/#{id}")
        form.add_csrf_tag csrf_tag
        view(inline: form.render, layout: :layout_rmd)
      end

      r.on 'set_bin_level_next', Integer do |id|
        if RawMaterialsApp::RmtDeliveryRepo.new.exists?(:rmt_bins, bin_asset_number: params[:bin][:bin_asset_number], rmt_delivery_id: id)
          store_locally(:flash_notice, "Bin:#{params[:bin][:bin_asset_number]} level set to: #{params[:bin][:bin_fullness]} successfully")
          interactor.update_rmt_bin_asset_level(params[:bin][:bin_asset_number], params[:bin][:bin_fullness])
        else
          store_locally(:errors, message:  "Bin:#{params[:bin][:bin_asset_number]} does not belong to the scanned delivery:#{id}")
        end
        r.redirect("/rmd/rmt_deliveries/rmt_bins/set_bin_level/#{id}")
      end

      r.on 'set_bin_level_complete', Integer do |id| # rubocop:disable Metrics/BlockLength
        if RawMaterialsApp::RmtDeliveryRepo.new.exists?(:rmt_bins, bin_asset_number: params[:bin][:bin_asset_number], rmt_delivery_id: id)
          store_locally(:flash_notice, "Bin:#{params[:bin][:bin_asset_number]} level set to: #{params[:bin][:bin_fullness]} successfully")
          interactor.update_rmt_bin_asset_level(params[:bin][:bin_asset_number], params[:bin][:bin_fullness])

          delivery = interactor.get_delivery_confirmation_details(id)
          form = Crossbeams::RMDForm.new({},
                                         notes: nil,
                                         form_name: :delivery,
                                         scan_with_camera: @rmd_scan_with_camera,
                                         caption: 'Delivery',
                                         reset_button: false,
                                         no_submit: true,
                                         action: '',
                                         button_caption: 'Cancel')
          form.add_label(:delivery_number, 'Delivery Number', delivery[:id])
          form.add_label(:cultivar_group_code, 'Cultivar Group', delivery[:cultivar_group_code])
          form.add_label(:cultivar_name, 'Cultivar', delivery[:cultivar_name])
          form.add_label(:farm_code, 'Farm', delivery[:farm_code])
          form.add_label(:puc_code, 'Puc', delivery[:puc_code])
          form.add_label(:orchard_code, 'Orchard', delivery[:orchard_code])
          form.add_label(:truck_registration_number, 'Truck Reg Number', delivery[:truck_registration_number])
          form.add_label(:date_delivered, 'Date Delivered', delivery[:date_delivered])
          form.add_csrf_tag csrf_tag
          view(inline: form.render, layout: :layout_rmd)

        else
          store_locally(:errors, message:  "Bin:#{params[:bin][:bin_asset_number]} does not belong to the scanned delivery:#{id}")
          r.redirect("/rmd/rmt_deliveries/rmt_bins/set_bin_level/#{id}")
        end
      end
    end
  end

  def rmt_container_type_combo_changed(form_name) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    actions = []
    if !params[:changed_value].to_s.empty?
      rmt_container_material_type_ids = MasterfilesApp::RmtContainerMaterialTypeRepo.new.for_select_rmt_container_material_types(where: { rmt_container_type_id: params[:changed_value] })
      rmt_container_material_type_ids.unshift(['Select a value', nil])
      if AppConst::DELIVERY_CAPTURE_CONTAINER_MATERIAL
        actions << OpenStruct.new(type: :replace_select_options,
                                  dom_id: "#{form_name}_rmt_container_material_type_id",
                                  options_array: rmt_container_material_type_ids)
      end
      if AppConst::DELIVERY_CAPTURE_CONTAINER_MATERIAL && AppConst::DELIVERY_CAPTURE_INNER_BINS
        actions << OpenStruct.new(type: MasterfilesApp::RmtContainerTypeRepo.new.find_container_type(params[:changed_value])&.rmt_inner_container_type_id ? :show_element : :hide_element,
                                  dom_id: "#{form_name}_qty_inner_bins_row")
      end
    else
      if AppConst::DELIVERY_CAPTURE_CONTAINER_MATERIAL
        actions << OpenStruct.new(type: :replace_select_options,
                                  dom_id: "#{form_name}_rmt_container_material_type_id",
                                  options_array: [['Select a value', nil]])
      end
      if AppConst::DELIVERY_CAPTURE_CONTAINER_MATERIAL && AppConst::DELIVERY_CAPTURE_INNER_BINS
        actions << OpenStruct.new(type: :hide_element,
                                  dom_id: "#{form_name}_qty_inner_bins_row")
      end
    end

    if AppConst::DELIVERY_CAPTURE_CONTAINER_MATERIAL && AppConst::DELIVERY_CAPTURE_CONTAINER_MATERIAL_OWNER
      actions << OpenStruct.new(type: :replace_select_options,
                                dom_id: "#{form_name}_rmt_material_owner_party_role_id",
                                options_array: [['Select a value', nil]])
    end

    json_actions(actions)
  end

  def container_material_type_combo_changed(form_name)
    if !params[:changed_value].to_s.empty?
      container_material_owners = RawMaterialsApp::RmtDeliveryRepo.new.find_container_material_owners_by_container_material_type(params[:changed_value])
      container_material_owners.unshift(['Select a value', nil])
      json_replace_select_options("#{form_name}_rmt_material_owner_party_role_id", container_material_owners)
    else
      json_replace_select_options("#{form_name}_rmt_material_owner_party_role_id", [['Select a value', nil]])
    end
  end
end
