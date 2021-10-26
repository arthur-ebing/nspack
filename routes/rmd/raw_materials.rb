# frozen_string_literal: true

class Nspack < Roda
  route 'raw_materials', 'rmd' do |r|
    r.on 'dispatch' do
      # --------------------------------------------------------------------------
      # BIN LOADS
      # --------------------------------------------------------------------------
      r.on 'bin_load', Integer do |bin_load_id|
        interactor = RawMaterialsApp::BinLoadInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})
        stepper = interactor.stepper(:bin_load)
        r.get do
          form_state = stepper.form_state
          r.redirect('/rmd/raw_materials/dispatch/bin_load') if form_state.empty?

          form = Crossbeams::RMDForm.new(form_state,
                                         form_name: :bin_load,
                                         progress: stepper.progress,
                                         scan_with_camera: @rmd_scan_with_camera,
                                         links: [{ caption: 'Cancel', url: '/rmd/raw_materials/dispatch/bin_load/clear', prompt: 'Cancel Bin Load?' }],
                                         notes: retrieve_from_local_store(:flash_notice),
                                         caption: 'Scan Bins',
                                         action: "/rmd/raw_materials/dispatch/bin_load/#{bin_load_id}",
                                         button_caption: 'Submit')

          form.add_label(:bin_load_id, 'Bin Load', bin_load_id)
          form.add_label(:customer, 'Customer', form_state[:customer])
          form.add_label(:transporter, 'Transporter', form_state[:transporter])
          form.add_label(:dest_depot, 'Destination Depot', form_state[:dest_depot])
          form.add_label(:qty_bins, 'qty Bins', form_state[:qty_bins])
          form.add_field(:bin_asset_number, 'Bin Asset Number', scan: 'key248_all', scan_type: :bin_asset, required: true, submit_form: true)

          form.add_csrf_tag csrf_tag
          view(inline: form.render, layout: :layout_rmd)
        end

        r.post do
          res = interactor.scan_bin_to_bin_load(params[:bin_load])
          if res.success
            stepper.allocate(res.instance)
            if stepper.ready_to_ship?
              res = interactor.allocate_and_ship_bin_load(bin_load_id, stepper.loaded)
              if res.success
                stepper.clear
                store_locally(:flash_notice, rmd_success_message(res.message))
                r.redirect('/rmd/raw_materials/dispatch/bin_load')
              else
                store_locally(:flash_notice, rmd_error_message(res.message))
              end
            end

            store_locally(:flash_notice, rmd_success_message(stepper.message)) if stepper.message
            store_locally(:flash_notice, rmd_warning_message(stepper.warning)) if stepper.warning
            store_locally(:flash_notice, rmd_error_message(stepper.error)) if stepper.error
          else
            store_locally(:flash_notice, rmd_error_message(res.message))
          end
          r.redirect("/rmd/raw_materials/dispatch/bin_load/#{bin_load_id}")
        end
      end

      r.on 'bin_load' do
        interactor = RawMaterialsApp::BinLoadInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})
        stepper = interactor.stepper(:bin_load)
        r.on 'clear' do
          stepper.clear
          r.redirect('/rmd/raw_materials/dispatch/bin_load')
        end

        r.get do
          form_state = {}
          r.redirect("/rmd/raw_materials/dispatch/bin_load/#{stepper.bin_load_id}") unless stepper.bin_load_id.nil?

          form_state = stepper.form_state if stepper.error?
          form = Crossbeams::RMDForm.new(form_state,
                                         form_name: :bin_load,
                                         scan_with_camera: @rmd_scan_with_camera,
                                         notes: retrieve_from_local_store(:flash_notice),
                                         caption: 'Scan Bin Load',
                                         action: '/rmd/raw_materials/dispatch/bin_load',
                                         button_caption: 'Submit')

          form.add_field(:bin_load_id,
                         'Bin Load',
                         data_type: 'number',
                         scan: 'key248_all',
                         scan_type: :load,
                         submit_form: true,
                         required: true)
          form.add_csrf_tag csrf_tag
          view(inline: form.render, layout: :layout_rmd)
        end

        r.post do
          res = interactor.scan_bin_load(params[:bin_load])
          if res.success
            stepper.setup_load(res.instance.id)
            r.redirect("/rmd/raw_materials/dispatch/bin_load/#{res.instance.id}")
          else
            store_locally(:flash_notice, rmd_error_message(res.message))
            r.redirect('/rmd/raw_materials/dispatch/bin_load')
          end
        end
      end
    end

    # --------------------------------------------------------------------------
    # PALBIN LOADS
    # --------------------------------------------------------------------------
    r.on 'receive_bin' do
      interactor = RawMaterialsApp::RmtBinInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})
      repo = RawMaterialsApp::RmtDeliveryRepo.new
      stepper = interactor.stepper(:receive_bin)

      r.on 'cancel' do
        stepper.clear
        r.redirect('/rmd/raw_materials/receive_bin')
      end

      r.on 'complete' do
        stepper.complete
        stepper.clear
        r.redirect('/rmd/home')
      end

      r.get do
        form_state = stepper.form_state
        form_state[:error_message] = retrieve_from_local_store(:flash_notice)
        form = Crossbeams::RMDForm.new(form_state,
                                       form_name: :receive_bin,
                                       progress: stepper.progress,
                                       scan_with_camera: @rmd_scan_with_camera,
                                       notes: stepper.notes,
                                       links: stepper.links,
                                       caption: 'Scan to Receive Bin',
                                       action: '/rmd/raw_materials/receive_bin',
                                       button_caption: 'Submit')
        hash = form_state[:entity]
        unless hash.nil_or_empty?
          form.add_label(:bin_asset_number, 'Bin Asset Number', hash[:bin_asset_number])
          form.add_label(:farm, 'Farm', hash[:farm_code])
          form.add_label(:puc, 'PUC', hash[:puc_code])
          form.add_label(:orchard, 'Orchard', hash[:orchard_code])
          form.add_label(:cultivar, 'Cultivar', hash[:cultivar_name])
          form.add_label(:class, 'Class', hash[:class_code])
          form.add_label(:pack, 'Pack', hash[:container_material_type_code])
          form.add_label(:gross_weight, 'Gross Weight', hash[:gross_weight])
          form.add_label(:nett_weight, 'Nett Weight', hash[:nett_weight])
        end

        form.add_field(:bin_asset_number,
                       'Bin Asset Number',
                       data_type: 'number',
                       scan: 'key248_all',
                       scan_type: :pallet_number,
                       submit_form: true,
                       required: true)

        form.add_csrf_tag csrf_tag
        view(inline: form.render, layout: :layout_rmd)
      end

      r.post do
        bin_asset_number = params[:receive_bin][:bin_asset_number]
        bin_id = repo.get_id(:rmt_bins, bin_asset_number: bin_asset_number)
        res = interactor.check(:receive, bin_id)
        if res.success
          stepper.scan(bin_asset_number)
        else
          store_locally(:flash_notice, rmd_error_message(res.message))
        end
        r.redirect('/rmd/raw_materials/receive_bin')
      end
    end

    # --------------------------------------------------------------------------
    # BINS TO PALLETS
    # --------------------------------------------------------------------------
    r.on 'convert_bins_to_pallets' do
      r.get do
        retrieve_from_local_store(:bin_scans)
        retrieve_from_local_store(:bin_seqs)
        retrieve_from_local_store('1'.to_sym)
        retrieve_from_local_store('2'.to_sym)
        retrieve_from_local_store('3'.to_sym)

        repo = MasterfilesApp::PackagingRepo.new
        form_state = retrieve_from_local_store(:form_state)
        error = retrieve_from_local_store(:error)
        form_state.merge!(error_message: error[:message], errors:  error[:errors]) unless error.nil?

        default_pallet_format = AppConst::CR_RMT.default_bin_pallet_value(:pallet_format).to_h

        form = Crossbeams::RMDForm.new(form_state,
                                       form_name: :bins,
                                       scan_with_camera: @rmd_scan_with_camera,
                                       caption: 'Scan Bins',
                                       action: '/rmd/raw_materials/convert_bins_to_pallets',
                                       button_caption: 'Submit')

        form.add_field(:bin_asset_number1, 'Bin Number 1', scan: 'key248_all', scan_type: :bin_asset, submit_form: false, required: true)
        form.add_field(:bin_asset_number2, 'Bin Number 2', scan: 'key248_all', scan_type: :bin_asset, submit_form: false, required: false)
        form.add_field(:bin_asset_number3, 'Bin Number 3', scan: 'key248_all', scan_type: :bin_asset, submit_form: false, required: false)
        form.add_select(:pallet_format_id,
                        'Pallet Format',
                        items: repo.for_select_pallet_formats(where: { bin: true }),
                        value: repo.pallet_formats_for_pallet_base_and_stack_type(default_pallet_format[:pallet_base], default_pallet_format[:stack_type]),
                        required: true,
                        prompt: true)

        form.add_csrf_tag csrf_tag
        view(inline: form.render, layout: :layout_rmd)
      end

      r.post do
        interactor = RawMaterialsApp::RmtBinInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})
        res = interactor.convert_bins_to_pallets(params[:bins])
        if res.success
          store_locally(:bin_scans, params[:bins])
          store_locally(:bin_seqs, res.instance[:bins])
          r.redirect('/rmd/raw_materials/bin_pallet_sequence_info_collect_nav/1')
        else
          store_locally(:error, message: res.message,  errors: res.errors)
          store_locally(:form_state, params[:bins])
          r.redirect('/rmd/raw_materials/convert_bins_to_pallets')
        end
      end
    end

    r.on 'bin_pallet_sequence_info_collect_nav', Integer do |id|
      r.get do
        repo = ProductionApp::ResourceRepo.new
        fruit_size_repo = MasterfilesApp::FruitSizeRepo.new
        cultivar_repo = MasterfilesApp::CultivarRepo.new
        fruit_repo = MasterfilesApp::FruitRepo.new
        party_repo = MasterfilesApp::PartyRepo.new
        if (form_state = retrieve_from_local_store(id.to_s.to_sym))
          store_locally(id.to_s.to_sym, form_state)
        else
          form_state = { sell_by_code: AppConst::CR_RMT.default_bin_pallet_value(:sell_by_code) }
        end

        bin_scans = retrieve_from_local_store(:bin_scans)
        bin_asset_number = bin_scans["bin_asset_number#{id}".to_sym]
        bin = repo.where(:rmt_bins, RawMaterialsApp::RmtBin, bin_asset_number: bin_asset_number)
        store_locally(:bin_scans, bin_scans)

        error = retrieve_from_local_store(:error)
        form_state.merge!(error_message: error[:message]) unless error.nil?

        bin_seqs = retrieve_from_local_store(:bin_seqs)
        form_state.store(:bin_asset_number, bin.bin_asset_number)
        store_locally(:bin_seqs, bin_seqs)
        form = Crossbeams::RMDForm.new(form_state,
                                       form_name: :pallet_info,
                                       scan_with_camera: @rmd_scan_with_camera,
                                       caption: 'Capture Bin Pallet Sequence Info',
                                       step_and_total: [bin_seqs.index(id) + 1, bin_seqs.length],
                                       reset_button: false,
                                       no_submit: false,
                                       button_caption: 'Save',
                                       action: "/rmd/raw_materials/bin_pallet_sequence_info_collect_nav/#{id}")

        form.add_select(:production_line_id, 'Production Line',
                        items: repo.for_select_plant_resources_of_type('LINE'),
                        value: repo.get_bin_production_line(bin.bin_asset_number),
                        prompt: true,
                        required: true)
        form.add_select(:basic_pack_code_id,
                        'Basic Pack',
                        items: fruit_size_repo.for_select_basic_packs(where: { bin: true }),
                        value: repo.get_value(:basic_pack_codes, :id, basic_pack_code: AppConst::CR_RMT.default_bin_pallet_value(:basic_pack)),
                        required: true,
                        prompt: true)
        form.add_select(:marketing_variety_id,
                        'Marketing Variety',
                        items: bin.cultivar_id ? cultivar_repo.for_select_cultivar_marketing_varieties(bin.cultivar_id) : cultivar_repo.for_select_cultivar_group_marketing_varieties(bin.cultivar_group_id),
                        value: cultivar_repo.find_marketing_variety_by_cultivar_code(bin.cultivar_id),
                        required: true,
                        prompt: true)
        form.add_select(:grade_id,
                        'Grade',
                        items: repo.select_values(:grades, %i[grade_code id], rmt_grade: true),
                        value: bin.rmt_class_id && (grade_id = fruit_repo.find_grade_by_rmt_class(bin.rmt_class_id)) ? grade_id : repo.get_value(:grades, :id, grade_code: AppConst::CR_RMT.default_bin_pallet_value(:grade)),
                        required: true,
                        prompt: true)
        form.add_select(:fruit_size_ref_id,
                        'Size Ref',
                        items: fruit_size_repo.for_select_fruit_size_references,
                        value: bin.rmt_size_id && (fruit_size_ref_id = fruit_size_repo.find_fruit_size_ref_by_rmt_size(bin.rmt_size_id)) ? fruit_size_ref_id : repo.get_value(:fruit_size_references, :id, size_reference: AppConst::CR_RMT.default_bin_pallet_value(:unknown_size_ref)),
                        required: true,
                        prompt: true)
        form.add_select(:packed_tm_group_id,
                        'Packed TM Group',
                        items: MasterfilesApp::TargetMarketRepo.new.for_select_packed_tm_groups,
                        value: EdiApp::PoInRepo.new.find_packed_tm_group_id(AppConst::CR_RMT.default_bin_pallet_value(:packed_tm_group)),
                        required: true,
                        prompt: true)
        form.add_select(:marketing_party_role_id,
                        'Marketing Org',
                        items: party_repo.for_select_party_roles(AppConst::ROLE_MARKETER),
                        value: party_repo.find_party_role_from_org_code_for_role(AppConst::CR_RMT.default_bin_pallet_value(:marketing_org), AppConst::ROLE_MARKETER),
                        required: true,
                        prompt: true)
        form.add_select(:mark_id,
                        'Mark',
                        items: MasterfilesApp::MarketingRepo.new.for_select_marks,
                        value: repo.get_value(:marks, :id, mark_code: AppConst::CR_RMT.default_bin_pallet_value(:mark)),
                        required: true,
                        prompt: true)
        form.add_select(:inventory_code_id,
                        'Inventory Code',
                        items: fruit_repo.for_select_inventory_codes,
                        value: repo.get_value(:inventory_codes, :id, inventory_code: AppConst::CR_RMT.default_bin_pallet_value(:inventory_code)),
                        required: true,
                        prompt: true)
        form.add_field(:sell_by_code, 'Sell By Code', required: true)
        form.add_field(:bin_asset_number, 'Bin Number1', required: true, hide_on_load: true)
        form.add_prev_next_nav('/rmd/raw_materials/bin_pallet_sequence_info_collect_nav/$:id$', bin_seqs, id)
        form.add_button('Convert To Pallet', '/rmd/raw_materials/convert_bins_to_pallets_complete')
        form.add_csrf_tag csrf_tag
        view(inline: form.render, layout: :layout_rmd)
      end

      r.post do
        store_locally(id.to_s.to_sym, params[:pallet_info])
        r.redirect("/rmd/raw_materials/bin_pallet_sequence_info_collect_nav/#{id}")
      end
    end

    r.on 'convert_bins_to_pallets_complete' do
      r.post do
        interactor = RawMaterialsApp::RmtBinInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

        bins_info = []
        (bin_seqs = retrieve_from_local_store(:bin_seqs)).sort.each do |id|
          store_locally(:bin_seqs, bin_seqs)
          if (bin_info = retrieve_from_local_store(id.to_s.to_sym)).nil?
            store_locally(:error, message: "Pallet Info for Bin #{id} has not been captured yet")
            r.redirect("/rmd/raw_materials/bin_pallet_sequence_info_collect_nav/#{id}")
          end
          bins_info << bin_info
          store_locally(id.to_s.to_sym, bin_info)
        end

        bin_scans = retrieve_from_local_store(:bin_scans)
        pallet_format_id = bin_scans[:pallet_format_id]
        res = interactor.create_pallet_from_bins(pallet_format_id, bins_info)
        if res.success
          r.redirect("/rmd/raw_materials/print_bins_pallet/#{res.instance[:pallet_id]}")
        else
          store_locally(:bin_scans, bin_scans)
          store_locally(:error, message: "Error: #{unwrap_failed_response(res)}")
          r.redirect('/rmd/raw_materials/bin_pallet_sequence_info_collect_nav/1')
        end
      end
    end

    r.on 'print_bins_pallet', Integer do |id|
      r.get do
        pallet_sequences = MesscadaApp::MesscadaRepo.new.find_pallet_sequences_by_pallet(id).sort_by { |s| s[:id] }
        single_pallet_sequences_view = {}
        pallet_sequences[0].each_key do |k|
          single_pallet_sequences_view.store(k, pallet_sequences.sort_by { |s| s[:id] }.map { |s| s[k] }.compact.uniq.join(', '))
        end
        form_state = { no_of_prints: 4 }
        error = retrieve_from_local_store(:error)
        form_state.merge!(error_message: error[:message]) unless error.nil?

        form = Crossbeams::RMDForm.new(form_state,
                                       form_name: :pallet,
                                       scan_with_camera: @rmd_scan_with_camera,
                                       caption: "Print Pallet #{single_pallet_sequences_view[:pallet_number]}",
                                       notes: retrieve_from_local_store(:flash_notice),
                                       reset_button: false,
                                       action: "/rmd/raw_materials/print_bins_pallet/#{id}",
                                       button_caption: 'Print')

        fields_for_rmd_pallet_sequence_display(form, single_pallet_sequences_view)

        form.add_field(:no_of_prints,
                       'Qty To Print',
                       required: false,
                       prompt: true,
                       data_type: :number)
        form.add_select(:printer,
                        'Printer',
                        items: LabelApp::PrinterRepo.new.select_printers_for_application(AppConst::PRINT_APP_PALLET),
                        value: LabelApp::PrinterRepo.new.default_printer_for_application(AppConst::PRINT_APP_PALLET),
                        required: false)
        form.add_select(:pallet_label_name,
                        'Pallet Label',
                        value: ProductionApp::ProductionRunRepo.new.find_pallet_label_name_by_resource_allocation_id(pallet_sequences[0][:resource_allocation_id]),
                        items: ProductionApp::ProductionRunRepo.new.find_pallet_labels,
                        required: false)
        form.add_csrf_tag csrf_tag
        view(inline: form.render, layout: :layout_rmd)
      end

      r.post do
        prod_interactor = ProductionApp::ProductionRunInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

        res = prod_interactor.print_pallet_label(id, params[:pallet])
        if res.success
          store_locally(:flash_notice, 'Labels For Pallet Printed Successfully')
        else
          store_locally(:error, message: unwrap_failed_response(res))
        end
        r.redirect("/rmd/raw_materials/print_bins_pallet/#{id}")
      end
    end

    # --------------------------------------------------------------------------
    # BIN ENQUIRY
    # --------------------------------------------------------------------------
    r.on 'bin_enquiry' do
      interactor = RawMaterialsApp::RmtBinInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      r.on 'scan_bin' do
        r.get do
          form_state = retrieve_from_local_store(:errors).to_h
          form = Crossbeams::RMDForm.new(form_state,
                                         form_name: :bin_enquiry,
                                         scan_with_camera: @rmd_scan_with_camera,
                                         caption: 'Bin Enquiry',
                                         notes: retrieve_from_local_store(:flash_notice),
                                         action: '/rmd/raw_materials/bin_enquiry/scan_bin',
                                         button_caption: 'Submit')
          form.add_field(:bin_number, 'Bin Number', data_type: :number, scan: 'key248_all', scan_type: :bin_asset, submit_form: true, required: true)
          form.add_csrf_tag csrf_tag
          view(inline: form.render, layout: :layout_rmd)
        end

        r.post do
          res = interactor.validate_bin(params[:bin_enquiry][:bin_number])
          if res.success
            r.redirect("/rmd/raw_materials/bin_enquiry/view_bin/#{res.instance[:id]}")
          else
            store_locally(:errors, errors: res.errors, error_message: unwrap_failed_response(res))
            r.redirect('/rmd/raw_materials/bin_enquiry/scan_bin')
          end
        end
      end

      r.on 'view_bin', Integer do |id|
        rmt_bin = interactor.rmt_bin_attrs_for_display(id)
        form = Crossbeams::RMDForm.new({},
                                       form_name: :rmt_bin,
                                       scan_with_camera: @rmd_scan_with_camera,
                                       caption: "View Bin #{rmt_bin[:bin_asset_number]}",
                                       reset_button: false,
                                       no_submit: true,
                                       action: '/')
        fields_for_rmd_rmt_bin_display(form, rmt_bin)
        fields_for_rmd_rmt_bin_presort_staging_run_display(form, rmt_bin) if rmt_bin[:staged_for_presorting]
        fields_for_rmd_presort_bin_info_display(form, rmt_bin) if AppConst::CR_RMT.presort_plant_integration? && !rmt_bin[:main_presort_run_lot_number].nil?
        fields_for_rmd_rmt_bin_other_info_display(form, rmt_bin) if AppConst::CR_RMT.show_kromco_attributes? && !rmt_bin[:legacy_data].nil?
        fields_for_rmd_rmt_bin_tripsheet_info_display(form, id)

        form.add_csrf_tag csrf_tag
        view(inline: form.render, layout: :layout_rmd)
      end
    end
  end

  # --------------------------------------------------------------------------
  # DELIVERIES
  # --------------------------------------------------------------------------
  route 'rmt_deliveries', 'rmd' do |r|
    # --------------------------------------------------------------------------
    # BINS
    # --------------------------------------------------------------------------
    r.on 'rmt_bins', Integer do |id|
      interactor = RawMaterialsApp::RmtBinInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      r.on 'new' do # NEW
        new_bin_screen(id, '/rmd/rmt_deliveries/rmt_bins/new')
      end

      r.on 'new_delivery_bin' do # NEW
        store_locally(:new_bin_mode, :edit_delivery)
        new_bin_screen(id, '/rmd/rmt_deliveries/rmt_bins/new')
      end

      r.on 'print_rebin' do
        r.get do
          printer_repo = LabelApp::PrinterRepo.new
          bin_asset_number, delivery_id = printer_repo.get_value(:rmt_bins, %i[bin_asset_number rmt_delivery_id], id: id)
          form_state = { qty_to_print: 2 }
          error = retrieve_from_local_store(:errors)
          notice = retrieve_from_local_store(:flash_notice)
          form_state.merge!(error_message: error[:message], errors:  error[:errors]) unless error.nil?

          form = Crossbeams::RMDForm.new(form_state,
                                         notes: notice,
                                         form_name: :rmt_bin,
                                         scan_with_camera: @rmd_scan_with_camera,
                                         caption: 'Print Rebin',
                                         reset_button: false,
                                         action: "/rmd/rmt_deliveries/rmt_bins/#{id}/print_rebin",
                                         button_caption: 'Submit')

          form.add_label(:delivery_number, 'Delivery Number', delivery_id)
          form.add_label(:bin_asset_number, 'Bin Number', bin_asset_number)
          form.add_field(:qty_to_print, 'Qty To Print', required: false, prompt: true, data_type: :number)
          form.add_select(:printer,
                          'Printer',
                          items: printer_repo.select_printers_for_application(AppConst::PRINT_APP_REBIN),
                          required: false)
          form.add_select(:rebin_label,
                          'Rebin Label',
                          items: printer_repo.find_rebin_labels,
                          required: false)
          form.add_csrf_tag csrf_tag
          view(inline: form.render, layout: :layout_rmd)
        end

        r.post do
          res = interactor.print_rebin_labels(id, params[:rmt_bin])
          if res.success
            store_locally(:flash_notice, "Rebin: #{res.instance[:bin_asset_number]} printed successfully")
            r.redirect('/rmd/rmt_deliveries/rmt_bins/print_rebin_labels_complete')
          else
            store_locally(:errors, res)
            r.redirect("/rmd/rmt_deliveries/rmt_bins/#{id}/print_rebin")
          end
        end
      end
    end

    r.on 'rmt_bins' do
      interactor = RawMaterialsApp::RmtBinInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      r.on 'new' do # NEW
        r.get do
          new_bin_screen(nil, '/rmd/rmt_deliveries/rmt_bins/new')
        end

        r.post do # CREATE
          id = params[:rmt_bin][:delivery_id]
          params[:rmt_bin].delete_if { |k, _v| k == :delivery_id }
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

      r.on 'print_rebin_labels_complete' do
        form = Crossbeams::RMDForm.new({},
                                       notes: nil,
                                       form_name: :print_rebin,
                                       scan_with_camera: @rmd_scan_with_camera,
                                       caption: 'Rebin Label Completed',
                                       reset_button: false,
                                       no_submit: true,
                                       action: '/',
                                       button_caption: '')
        form.add_section_header('Labels printed successfully')
        form.add_csrf_tag csrf_tag
        view(inline: form.render, layout: :layout_rmd)
      end

      r.on 'rmt_bin_delivery_id_combo_changed' do
        actions = []
        if !params[:changed_value].to_s.empty?
          bin_delivery = RawMaterialsApp::RmtDeliveryRepo.new.get_bin_delivery(params[:changed_value])
          actions << OpenStruct.new(type: :replace_inner_html,
                                    dom_id: 'rmt_bin_delivery_code_value',
                                    value: bin_delivery[:id])
          actions << OpenStruct.new(type: :replace_inner_html,
                                    dom_id: 'rmt_bin_farm_code_value',
                                    value: bin_delivery[:farm_code])
          actions << OpenStruct.new(type: :replace_inner_html,
                                    dom_id: 'rmt_bin_puc_code_value',
                                    value: bin_delivery[:puc_code])
          actions << OpenStruct.new(type: :replace_inner_html,
                                    dom_id: 'rmt_bin_orchard_code_value',
                                    value: bin_delivery[:orchard_code])
          actions << OpenStruct.new(type: :replace_inner_html,
                                    dom_id: 'rmt_bin_cultivar_code_value',
                                    value: bin_delivery[:cultivar_name])
          actions << OpenStruct.new(type: :replace_inner_html,
                                    dom_id: 'rmt_bin_date_picked_value',
                                    value: bin_delivery[:date_picked])
          actions << OpenStruct.new(type: :replace_inner_html,
                                    dom_id: 'rmt_bin_date_delivered_value',
                                    value: bin_delivery[:date_delivered])
          actions << OpenStruct.new(type: :replace_inner_html,
                                    dom_id: 'rmt_bin_qty_bins_tipped_value',
                                    value: bin_delivery[:qty_bins_tipped])
          actions << OpenStruct.new(type: :replace_inner_html,
                                    dom_id: 'rmt_bin_qty_bins_received_value',
                                    value: bin_delivery[:qty_bins_received])
        else
          actions << OpenStruct.new(type: :replace_inner_html,
                                    dom_id: 'rmt_bin_delivery_code_value',
                                    value: nil)
          actions << OpenStruct.new(type: :replace_inner_html,
                                    dom_id: 'rmt_bin_farm_code_value',
                                    value: nil)
          actions << OpenStruct.new(type: :replace_inner_html,
                                    dom_id: 'rmt_bin_puc_code_value',
                                    value: nil)
          actions << OpenStruct.new(type: :replace_inner_html,
                                    dom_id: 'rmt_bin_orchard_code_value',
                                    value: nil)
          actions << OpenStruct.new(type: :replace_inner_html,
                                    dom_id: 'rmt_bin_cultivar_code_value',
                                    value: nil)
          actions << OpenStruct.new(type: :replace_inner_html,
                                    dom_id: 'rmt_bin_date_picked_value',
                                    value: nil)
          actions << OpenStruct.new(type: :replace_inner_html,
                                    dom_id: 'rmt_bin_date_delivered_value',
                                    value: nil)
          actions << OpenStruct.new(type: :replace_inner_html,
                                    dom_id: 'rmt_bin_qty_bins_tipped_value',
                                    value: nil)
          actions << OpenStruct.new(type: :replace_inner_html,
                                    dom_id: 'rmt_bin_qty_bins_received_value',
                                    value: nil)
        end

        json_actions(actions)
      end

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
        res = interactor.move_bin(id, params[:bin][:location], params[:bin][:location_scan_field])
        if res.success
          store_locally(:flash_notice, unwrap_failed_response(res))
          r.redirect('/rmd/rmt_deliveries/rmt_bins/move_rmt_bin')
        else
          store_locally(:errors, error_message: "Error: #{unwrap_failed_response(res)}")
          r.redirect("/rmd/rmt_deliveries/rmt_bins/scan_location/#{id}")
        end
      end

      # MOVE MULTIPLE BINS
      # --------------------------------------------------------------------------

      r.on 'move_multiple_bins', Integer do |scanned_locn_id|
        r.on 'complete_move' do
          moved_bins_count = (retrieve_from_local_store(:moved_bins) || []).count
          location_code = interactor.location_short_code_for(scanned_locn_id)
          store_locally(:flash_notice, rmd_success_message("#{moved_bins_count} bins have been moved to location #{location_code}"))
          r.redirect('/rmd/rmt_deliveries/rmt_bins/move_multiple_bins')
        end

        r.get do
          bin = {}

          error = retrieve_from_local_store(:error)
          if error.is_a?(String)
            bin.merge!(error_message: error)
          elsif !error.nil?
            bin.merge!(error_message: error.message)
            bin.merge!(errors: error.errors) unless error.errors.nil_or_empty?
          end

          form = Crossbeams::RMDForm.new(bin,
                                         form_name: :bin,
                                         notes: retrieve_from_local_store(:flash_notice),
                                         scan_with_camera: @rmd_scan_with_camera,
                                         caption: 'Scan Bins',
                                         action: "/rmd/rmt_deliveries/rmt_bins/move_multiple_bins/#{scanned_locn_id}",
                                         button_caption: 'Submit')

          location_code = interactor.location_short_code_for(scanned_locn_id)
          form.add_label(:location, 'Location', location_code)
          form.add_field(:bin_number, 'Bin Number', scan: 'key248_all', scan_type: :bin_asset, required: false, submit_form: true)

          moved_bins = retrieve_from_local_store(:moved_bins) || []
          unless moved_bins.empty?
            store_locally(:moved_bins, moved_bins)
            form.add_section_header('Bins Moved')
            moved_bins.each { |bin_number| form.add_label(:bin_number, '', bin_number) }
            form.add_button('Complete Move', "/rmd/rmt_deliveries/rmt_bins/move_multiple_bins/#{scanned_locn_id}/complete_move")
          end

          form.add_csrf_tag csrf_tag
          view(inline: form.render, layout: :layout_rmd)
        end

        r.post do
          val_res = interactor.validate_bin(params[:bin][:bin_number])
          unless val_res.success
            store_locally(:error, val_res)
            r.redirect("/rmd/rmt_deliveries/rmt_bins/move_multiple_bins/#{scanned_locn_id}")
          end

          res = interactor.move_location_bin(val_res.instance[:id], scanned_locn_id)
          if res.success
            bin_number = AppConst::USE_PERMANENT_RMT_BIN_BARCODES ? val_res.instance[:bin_asset_number] : val_res.instance[:id]
            moved_bins = retrieve_from_local_store(:moved_bins) || []
            moved_bins << bin_number
            store_locally(:moved_bins, moved_bins)
            store_locally(:flash_notice, res.message)
          else
            store_locally(:error, res)
          end
          r.redirect("/rmd/rmt_deliveries/rmt_bins/move_multiple_bins/#{scanned_locn_id}")
        rescue Crossbeams::InfoError => e
          store_locally(:error, rmd_error_message(e.message))
          r.redirect("/rmd/rmt_deliveries/rmt_bins/move_multiple_bins/#{scanned_locn_id}")
        end
      end

      r.on 'move_multiple_bins' do
        r.get do
          form_state = retrieve_from_local_store(:error).to_h
          form = Crossbeams::RMDForm.new(form_state,
                                         form_name: :bin,
                                         notes: retrieve_from_local_store(:flash_notice),
                                         scan_with_camera: @rmd_scan_with_camera,
                                         caption: 'Scan Location',
                                         action: '/rmd/rmt_deliveries/rmt_bins/move_multiple_bins',
                                         button_caption: 'Submit')
          form.add_field(:location, 'Location', scan: 'key248_all', scan_type: :location, submit_form: true, required: true, lookup: true)
          form.add_csrf_tag csrf_tag
          view(inline: form.render, layout: :layout_rmd)
        end

        r.post do
          val_res = interactor.validate_location(params[:bin][:location], params[:bin][:location_scan_field])
          if val_res.success
            scanned_locn_id = val_res.instance
            r.redirect("/rmd/rmt_deliveries/rmt_bins/move_multiple_bins/#{scanned_locn_id}")
          else
            store_locally(:error, val_res)
            r.redirect('/rmd/rmt_deliveries/rmt_bins/move_multiple_bins')
          end
        rescue Crossbeams::InfoError => e
          store_locally(:error, rmd_error_message(e.message))
          r.redirect('/rmd/rmt_deliveries/rmt_bins/move_multiple_bins')
        end
      end

      # --------------------------------------------------------------------------
      # CREATE RMT REBIN
      # --------------------------------------------------------------------------
      r.on 'create_rebin' do
        r.get do
          form_state = { bin_fullness: AppConst::BIN_FULL }
          error = retrieve_from_local_store(:errors)
          notice = retrieve_from_local_store(:flash_notice)
          if (details = retrieve_from_local_store(:form_state))
            prod_run = ProductionApp::ProductionRunRepo.new.find_production_run_flat(details[:production_run_rebin_id])
            details.merge!(prod_run.to_h)
          end
          form_state.merge!(error_message: error[:error_message], errors:  {}) unless error.nil?
          form_state.merge!(details) unless details.nil?

          default_rmt_container_type = RawMaterialsApp::RmtDeliveryRepo.new.rmt_container_type_by_container_type_code(AppConst::DEFAULT_RMT_CONTAINER_TYPE)
          capture_container_material_owner = AppConst::DELIVERY_CAPTURE_CONTAINER_MATERIAL_OWNER

          form = Crossbeams::RMDForm.new(form_state,
                                         notes: notice,
                                         form_name: :rmt_bin,
                                         scan_with_camera: @rmd_scan_with_camera,
                                         caption: 'Create Rebin',
                                         reset_button: false,
                                         action: '/rmd/rmt_deliveries/rmt_bins/create_rebin',
                                         button_caption: 'Submit')

          form.behaviours do |behaviour|
            behaviour.dropdown_change :production_line_id, notify: [{ url: '/rmd/rmt_deliveries/rmt_bins/rmt_bin_production_line_id_combo_changed' }]
            behaviour.dropdown_change :production_run_rebin_id, notify: [{ url: '/rmd/rmt_deliveries/rmt_bins/rmt_bin_production_run_rebin_id_combo_changed' }]
            behaviour.input_change :bin_asset_number, notify: [{ url: '/rmd/rmt_deliveries/rmt_bins/bin_asset_number_changed' }]
            behaviour.dropdown_change :rmt_container_material_type_id, notify: [{ url: '/rmd/rmt_deliveries/rmt_bins/rmt_bin_rebin_container_material_type_combo_changed' }] if capture_container_material_owner
          end

          # form.add_field(:bin_asset_number, 'Bin Number', scan: 'key248_all', scan_type: :bin_asset, required: true, submit_form: false)
          form.add_select(:rmt_class_id, 'RMT Class', items: MasterfilesApp::FruitRepo.new.for_select_rmt_classes, prompt: true, required: true)
          form.add_select(:production_line_id, 'Production Line', items: ProductionApp::ResourceRepo.new.for_select_plant_resources_of_type('LINE'), prompt: true, required: true)
          form.add_select(:production_run_rebin_id, 'Production Run', items: form_state[:production_line_id] ? ProductionApp::ProductionRunRepo.new.for_select_production_runs_for_line(form_state[:production_line_id]) : [], prompt: true, required: true)
          form.add_label(:farm, 'Farm', form_state[:farm_code])
          form.add_label(:puc, 'PUC', form_state[:puc_code])
          form.add_label(:orchard, 'Orchard', form_state[:orchard_code])
          form.add_label(:cultivar, 'Cultivar', form_state[:cultivar_name])
          form.add_label(:cultivar_group, 'Cultivar Group', form_state[:cultivar_group_code])
          form.add_label(:season, 'Season', form_state[:season_code])
          form.add_select(:bin_fullness, 'Bin Fullness', items: AppConst::BIN_FULLNESS_OPTIONS, prompt: true)

          form.add_select(:rmt_container_material_type_id, 'Container Material Type',
                          items: MasterfilesApp::RmtContainerMaterialTypeRepo.new.for_select_rmt_container_material_types(where: { rmt_container_type_id: default_rmt_container_type[:id] }),
                          required: true, prompt: true)

          if capture_container_material_owner
            form.add_select(:rmt_material_owner_party_role_id, 'Container Material Owner',
                            items: !details.nil? && !details[:rmt_container_material_type_id].to_s.empty? ? RawMaterialsApp::RmtDeliveryRepo.new.find_container_material_owners_by_container_material_type(details[:rmt_container_material_type_id]) : [],
                            required: true, prompt: true)
          end

          form.add_field(:gross_weight, 'Gross Weight', data_type: 'number')
          form.add_csrf_tag csrf_tag
          view(inline: form.render, layout: :layout_rmd)
        end

        r.post do
          res = interactor.create_rebin(params[:rmt_bin])
          if res.success
            store_locally(:flash_notice, "Rebin: #{res.instance[:bin_asset_number]} created successfully")
            r.redirect("/rmd/rmt_deliveries/rmt_bins/#{res.instance[:id]}/print_rebin")
          else
            store_locally(:errors, error_message: "Error: #{unwrap_failed_response(res)}")
            store_locally(:form_state, params[:rmt_bin])
            r.redirect('/rmd/rmt_deliveries/rmt_bins/create_rebin')
          end
        end
      end

      # --------------------------------------------------------------------------
      # EDIT RMT REBIN
      # --------------------------------------------------------------------------
      r.on 'edit_rebin' do
        r.get do
          notice = retrieve_from_local_store(:flash_notice)
          form_state = {}
          error = retrieve_from_local_store(:errors)
          form_state.merge!(error_message: error[:error_message], errors:  { bin_number: [''] }) unless error.nil?
          form = Crossbeams::RMDForm.new(form_state,
                                         form_name: :bin,
                                         notes: notice,
                                         scan_with_camera: @rmd_scan_with_camera,
                                         caption: 'Scan Rebin',
                                         action: '/rmd/rmt_deliveries/rmt_bins/edit_rebin',
                                         button_caption: 'Submit')
          form.add_field(:bin_number, 'Rebin Number', scan: 'key248_all', scan_type: :bin_asset, required: true, submit_form: true)
          form.add_csrf_tag csrf_tag
          view(inline: form.render, layout: :layout_rmd)
        end

        r.post do
          res = interactor.validate_rebin(params[:bin][:bin_number])
          if res.success
            r.redirect("/rmd/rmt_deliveries/rmt_bins/rebins/#{res.instance[:id]}")
          else
            store_locally(:errors, error_message: "Error: #{unwrap_failed_response(res)}")
            r.redirect('/rmd/rmt_deliveries/rmt_bins/edit_rebin')
          end
        end
      end

      r.on 'rebins', Integer do |id|
        r.get do
          rebin = interactor.rebin_details(id)
          form_state = rebin
          error = retrieve_from_local_store(:errors)
          notice = retrieve_from_local_store(:flash_notice)
          form_state.merge!(error_message: error[:error_message], errors:  {}) unless error.nil?

          default_rmt_container_type = RawMaterialsApp::RmtDeliveryRepo.new.rmt_container_type_by_container_type_code(AppConst::DEFAULT_RMT_CONTAINER_TYPE)
          capture_container_material_owner = AppConst::DELIVERY_CAPTURE_CONTAINER_MATERIAL_OWNER

          form = Crossbeams::RMDForm.new(form_state,
                                         notes: notice,
                                         form_name: :rmt_bin,
                                         scan_with_camera: @rmd_scan_with_camera,
                                         caption: 'Update Rebin',
                                         reset_button: false,
                                         action: "/rmd/rmt_deliveries/rmt_bins/rebins/#{id}",
                                         button_caption: 'Submit')

          form.behaviours do |behaviour|
            behaviour.dropdown_change :production_line_id, notify: [{ url: '/rmd/rmt_deliveries/rmt_bins/rmt_bin_production_line_id_combo_changed' }]
            behaviour.dropdown_change :production_run_rebin_id, notify: [{ url: '/rmd/rmt_deliveries/rmt_bins/rmt_bin_production_run_rebin_id_combo_changed' }]
            behaviour.input_change :bin_asset_number, notify: [{ url: '/rmd/rmt_deliveries/rmt_bins/bin_asset_number_changed' }]
            behaviour.dropdown_change :rmt_container_material_type_id, notify: [{ url: '/rmd/rmt_deliveries/rmt_bins/rmt_bin_rebin_container_material_type_combo_changed' }] if capture_container_material_owner
          end

          form.add_select(:rmt_class_id, 'RMT Class', items: MasterfilesApp::FruitRepo.new.for_select_rmt_classes, required: true)
          form.add_select(:production_line_id, 'Production Line', items: ProductionApp::ResourceRepo.new.for_select_plant_resources_of_type('LINE'), prompt: true, required: true)
          form.add_select(:production_run_rebin_id, 'Production Run', items: ProductionApp::ProductionRunRepo.new.for_select_production_runs_for_line(rebin[:production_line_id]), prompt: true, required: true)
          form.add_label(:farm, 'Farm', form_state[:farm_code])
          form.add_label(:puc, 'PUC', form_state[:puc_code])
          form.add_label(:orchard, 'Orchard', form_state[:orchard_code])
          form.add_label(:cultivar, 'Cultivar', form_state[:cultivar_name])
          form.add_label(:cultivar_group, 'Cultivar Group', form_state[:cultivar_group_code])
          form.add_label(:season, 'Season', form_state[:season_code])
          form.add_select(:bin_fullness, 'Bin Fullness', items: AppConst::BIN_FULLNESS_OPTIONS, prompt: true)

          form.add_select(:rmt_container_material_type_id, 'Container Material Type',
                          items: MasterfilesApp::RmtContainerMaterialTypeRepo.new.for_select_rmt_container_material_types(where: { rmt_container_type_id: default_rmt_container_type[:id] }),
                          required: true, prompt: true)

          if capture_container_material_owner
            form.add_select(:rmt_material_owner_party_role_id, 'Container Material Owner',
                            items: RawMaterialsApp::RmtDeliveryRepo.new.find_container_material_owners_by_container_material_type(rebin[:rmt_container_material_type_id]),
                            required: true, prompt: true)
          end

          form.add_field(:gross_weight, 'Gross Weight', data_type: 'number')
          form.add_csrf_tag csrf_tag
          view(inline: form.render, layout: :layout_rmd)
        end

        r.post do
          res = interactor.update_rebin(id, params[:rmt_bin])
          if res.success
            store_locally(:flash_notice, "Rebin: #{res.instance[:bin_asset_number]} updated successfully")
            r.redirect("/rmd/rmt_deliveries/rmt_bins/#{res.instance[:id]}/print_rebin")
          else
            store_locally(:errors, error_message: "Error: #{unwrap_failed_response(res)}")
            r.redirect("/rmd/rmt_deliveries/rmt_bins/rebins/#{id}")
          end
        end
      end

      r.on 'rmt_bin_production_line_id_combo_changed' do
        actions = [OpenStruct.new(type: :replace_inner_html,
                                  dom_id: 'rmt_bin_orchard_value',
                                  value: '&nbsp;'),
                   OpenStruct.new(type: :replace_inner_html,
                                  dom_id: 'rmt_bin_season_value',
                                  value: '&nbsp;'),
                   OpenStruct.new(type: :replace_inner_html,
                                  dom_id: 'rmt_bin_cultivar_value',
                                  value: '&nbsp;')]
        if !params[:changed_value].to_s.empty?
          production_runs = ProductionApp::ProductionRunRepo.new.for_select_production_runs_for_line(params[:changed_value])
          production_runs.unshift([[]])
          actions << OpenStruct.new(type: :replace_select_options,
                                    dom_id: 'rmt_bin_production_run_rebin_id',
                                    options_array: production_runs)
        else
          actions << OpenStruct.new(type: :replace_select_options,
                                    dom_id: 'rmt_bin_production_run_rebin_id',
                                    options_array: [])
        end
        json_actions(actions)
      end

      r.on 'bin_asset_number_changed' do
        repo = MasterfilesApp::RmtContainerMaterialTypeRepo.new
        default_rmt_container_type_id = RawMaterialsApp::RmtDeliveryRepo.new.rmt_container_type_by_container_type_code(AppConst::DEFAULT_RMT_CONTAINER_TYPE)[:id]
        items = repo.for_select_rmt_container_material_types(where: { rmt_container_type_id: default_rmt_container_type_id })
        items.unshift([[]])
        container_material_owners = []
        if (default_rmt_container_material_type = repo.find_bin_rmt_container_material_type(params[:changed_value])) && items.include?([default_rmt_container_material_type[:container_material_type_code], default_rmt_container_material_type[:id]])
          items.unshift([default_rmt_container_material_type[:container_material_type_code], default_rmt_container_material_type[:id]])
          container_material_owners = RawMaterialsApp::RmtDeliveryRepo.new.find_container_material_owners_by_container_material_type(default_rmt_container_material_type[:id])
          container_material_owners.unshift([[]])
        end

        actions = [OpenStruct.new(type: :replace_select_options,
                                  dom_id: 'rmt_bin_rmt_container_material_type_id',
                                  options_array: items.uniq),
                   OpenStruct.new(type: :replace_select_options,
                                  dom_id: 'rmt_bin_rmt_material_owner_party_role_id',
                                  options_array: container_material_owners)]
        json_actions(actions)
      end

      r.on 'rmt_bin_rebin_container_material_type_combo_changed' do
        if !params[:changed_value].to_s.empty?
          params[:rmt_bin_bin_asset_number]
          container_material_owners = RawMaterialsApp::RmtDeliveryRepo.new.find_container_material_owners_by_container_material_type(params[:changed_value])
          container_material_owners.unshift([[]])
          json_replace_select_options('rmt_bin_rmt_material_owner_party_role_id', container_material_owners)
        else
          json_replace_select_options('rmt_bin_rmt_material_owner_party_role_id', [])
        end
      end

      r.on 'rmt_bin_production_run_rebin_id_combo_changed' do
        actions = if !params[:changed_value].to_s.empty?
                    prod_run = ProductionApp::ProductionRunRepo.new.find_production_run_flat(params[:changed_value])
                    [OpenStruct.new(type: :replace_inner_html,
                                    dom_id: 'rmt_bin_orchard_value',
                                    value: prod_run[:orchard_code]),
                     OpenStruct.new(type: :replace_inner_html,
                                    dom_id: 'rmt_bin_season_value',
                                    value: prod_run[:season_code]),
                     OpenStruct.new(type: :replace_inner_html,
                                    dom_id: 'rmt_bin_farm_value',
                                    value: prod_run[:farm_code]),
                     OpenStruct.new(type: :replace_inner_html,
                                    dom_id: 'rmt_bin_puc_value',
                                    value: prod_run[:puc_code]),
                     OpenStruct.new(type: :replace_inner_html,
                                    dom_id: 'rmt_bin_cultivar_group_value',
                                    value: prod_run[:cultivar_group_code]),
                     OpenStruct.new(type: :replace_inner_html,
                                    dom_id: 'rmt_bin_cultivar_value',
                                    value: prod_run[:cultivar_name])]
                  else
                    [OpenStruct.new(type: :replace_inner_html,
                                    dom_id: 'rmt_bin_orchard_value',
                                    value: '&nbsp;'),
                     OpenStruct.new(type: :replace_inner_html,
                                    dom_id: 'rmt_bin_season_value',
                                    value: '&nbsp;'),
                     OpenStruct.new(type: :replace_inner_html,
                                    dom_id: 'rmt_bin_farm_value',
                                    value: '&nbsp;'),
                     OpenStruct.new(type: :replace_inner_html,
                                    dom_id: 'rmt_bin_puc_value',
                                    value: '&nbsp;'),
                     OpenStruct.new(type: :replace_inner_html,
                                    dom_id: 'rmt_bin_cultivar_group_value',
                                    value: '&nbsp;'),
                     OpenStruct.new(type: :replace_inner_html,
                                    dom_id: 'rmt_bin_cultivar_value',
                                    value: '&nbsp;')]
                  end
        json_actions(actions)
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

      r.on 'render_edit_rmt_bin', Integer do |id|
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
        form.add_label(:puc_code, 'PUC', bin[:puc_code])
        form.add_label(:orchard_code, 'Orchard', bin[:orchard_code])
        form.add_label(:cultivar_name, 'Cultivar', bin[:cultivar_name])
        form.add_field(:qty_bins, 'Qty Bins', hide_on_load: true)
        form.add_select(:bin_fullness, 'Bin Fullness', items: AppConst::BIN_FULLNESS_OPTIONS, prompt: true)
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
        form.add_label(:puc_code, 'PUC', delivery[:puc_code])
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
        # container_material_type_combo_changed('delivery')
        if !params[:changed_value].to_s.empty?
          container_material_owners = RawMaterialsApp::RmtDeliveryRepo.new.find_container_material_owners_for_container_material_type(params[:changed_value])
          container_material_owners.unshift([[]])
          json_replace_select_options('delivery_rmt_material_owner_party_role_id', container_material_owners)
        else
          json_replace_select_options('delivery_rmt_material_owner_party_role_id', [])
        end
      end

      r.on 'bin_edit_rmt_container_type_combo_changed' do
        rmt_container_type_combo_changed('rmt_bin')
      end

      r.on 'bin_edit_container_material_type_combo_changed' do
        container_material_type_combo_changed('rmt_bin')
      end

      r.on 'receive_rmt_bins', Integer do |id|
        delivery = interactor.get_delivery_confirmation_details(id)
        default_rmt_container_type = RawMaterialsApp::RmtDeliveryRepo.new.rmt_container_type_by_container_type_code(AppConst::DEFAULT_RMT_CONTAINER_TYPE)

        capture_container_material = AppConst::DELIVERY_CAPTURE_CONTAINER_MATERIAL
        capture_container_material_owner = AppConst::DELIVERY_CAPTURE_CONTAINER_MATERIAL_OWNER
        capture_inner_bins = AppConst::DELIVERY_CAPTURE_INNER_BINS && !default_rmt_container_type[:id].nil? && MasterfilesApp::RmtContainerTypeRepo.new.find_rmt_container_type(default_rmt_container_type[:id])&.rmt_inner_container_type_id

        notice = retrieve_from_local_store(:flash_notice)
        rmt_container_material_type_id = retrieve_from_local_store(:rmt_container_material_type_id)
        rmt_material_owner_party_role_id = retrieve_from_local_store(:rmt_material_owner_party_role_id)
        form_state = { bin_fullness: AppConst::BIN_FULL, qty_bins: 1, rmt_container_material_type_id: rmt_container_material_type_id, rmt_material_owner_party_role_id: rmt_material_owner_party_role_id }
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
        form.add_label(:puc_code, 'PUC', delivery[:puc_code])
        form.add_label(:orchard_code, 'Orchard', delivery[:orchard_code])
        form.add_label(:bins_received, 'Bins Received', delivery[:bins_received])
        form.add_label(:qty_bins_remaining, 'Qty Bins Remaining', delivery[:qty_bins_remaining])
        form.add_select(:rmt_container_type_id, 'Container Type', items: MasterfilesApp::RmtContainerTypeRepo.new.for_select_rmt_container_types, value: default_rmt_container_type[:id], required: true, prompt: true)
        form.add_select(:rmt_class_id, 'RMT Class', items: MasterfilesApp::FruitRepo.new.for_select_rmt_classes, prompt: true, required: false)

        if capture_container_material
          form.add_select(:rmt_container_material_type_id, 'Container Material Type',
                          items: MasterfilesApp::RmtContainerMaterialTypeRepo.new.for_select_rmt_container_material_types(where: { rmt_container_type_id: default_rmt_container_type[:id] }),
                          required: true, prompt: true)
        end

        if capture_container_material && capture_container_material_owner
          rmt_material_owner_party_role_ids = rmt_container_material_type_id ? RawMaterialsApp::RmtDeliveryRepo.new.find_container_material_owners_by_container_material_type(rmt_container_material_type_id) : []
          form.add_select(:rmt_material_owner_party_role_id, 'Container Material Owner',
                          items: rmt_material_owner_party_role_ids,
                          required: true, prompt: true)
        end

        form.add_field(:bin_fullness, 'Bin Fullness', hide_on_load: true)
        form.add_field(:qty_bins, 'Qty Bins', hide_on_load: true)
        if capture_inner_bins
          form.add_field(:qty_inner_bins, 'Qty Inner Bins', data_type: 'number')
        else
          form.add_label(:qty_inner_bins, 'Qty Inner Bins', '1', '1', hide_on_load: true)
        end

        form.add_field(:bin_asset_number1, 'Asset Number1', scan: 'key248_all', scan_type: :bin_asset, submit_form: false, required: true)
        delivery[:qty_bins_remaining] = AppConst::BIN_SCANNING_BATCH_SIZE.to_i unless delivery[:qty_bins_remaining] < AppConst::BIN_SCANNING_BATCH_SIZE.to_i
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
        params[:delivery].delete_if { |k, _v| k.to_s.include?('scan_field') }
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
          store_locally(:rmt_container_material_type_id, params[:delivery][:rmt_container_material_type_id])
          store_locally(:rmt_material_owner_party_role_id, params[:delivery][:rmt_material_owner_party_role_id])
          r.redirect("/rmd/rmt_deliveries/rmt_bins/receive_rmt_bins/#{id}")
        end
      end

      r.on 'receive_single_bin' do
        id = interactor.find_current_delivery
        if id.nil_or_empty?
          return new_bin_screen(nil, '/rmd/rmt_deliveries/rmt_bins/receive_single_bin_submit') if AppConst::USE_PERMANENT_RMT_BIN_BARCODES

          receive_single_bin_error_screen('There Is No Current Delivery To Add Bins To')
        elsif RawMaterialsApp::RmtDeliveryInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {}).delivery_tipped?(id)
          receive_single_bin_error_screen('Cannot Add Bin To Current Delivery. Delivery Has Been Tipped')
        else
          new_bin_screen(id, '/rmd/rmt_deliveries/rmt_bins/receive_single_bin_submit')
        end
      end

      r.on 'create_bin_tripsheet' do
        r.get do
          form_state = retrieve_from_local_store(:form_state).to_h
          notice = form_state[:flash_notice]
          form = Crossbeams::RMDForm.new(form_state,
                                         form_name: :tripsheet,
                                         notes: notice,
                                         scan_with_camera: @rmd_scan_with_camera,
                                         caption: 'Create Bins Tripsheet',
                                         reset_button: false,
                                         no_submit: false,
                                         action: '/rmd/rmt_deliveries/rmt_bins/create_bin_tripsheet',
                                         button_caption: 'Submit')

          form.behaviours do |behaviour|
            behaviour.input_change :move_bins_from_another_tripsheet,
                                   notify: [{ url: '/rmd/rmt_deliveries/rmt_bins/move_bins_clicked' }]
          end

          form.add_select(:planned_location_to_id,
                          'Location',
                          items: MasterfilesApp::LocationRepo.new.find_locations_by_location_type_and_storage_type(AppConst::LOCATION_TYPES_WAREHOUSE, AppConst::STORAGE_TYPE_BINS),
                          required: true,
                          prompt: true)
          form.add_toggle(:move_bins_from_another_tripsheet, 'Move Bins From Another Tripsheet')
          form.add_field(:tripsheet_number, 'Tripsheet Number',
                         scan: 'key248_all',
                         scan_type: :vehicle_job,
                         submit_form: false,
                         required: false,
                         hide_on_load: form_state[:move_bins_from_another_tripsheet] != 't',
                         lookup: false)
          form.add_csrf_tag csrf_tag
          view(inline: form.render, layout: :layout_rmd)
        end

        r.post do
          res = interactor.create_bin_tripsheet(params[:tripsheet][:planned_location_to_id], params[:tripsheet][:move_bins_from_another_tripsheet], params[:tripsheet][:tripsheet_number])
          if res.success
            r.redirect("/rmd/rmt_deliveries/rmt_bins/add_bin_to_tripsheet/#{res.instance}")
          else
            store_locally(:form_state, { error_message: res[:message], errors: res[:errors] }.merge!(params[:tripsheet]))
            r.redirect('/rmd/rmt_deliveries/rmt_bins/create_bin_tripsheet')
          end
        end
      end

      r.on 'move_bins_clicked' do
        show =  case params[:changed_value]
                when 't'
                  true
                when 'f', ''
                  false
                end

        action = show ? :show_element : :hide_element
        json_actions([OpenStruct.new(type: action, dom_id: 'tripsheet_tripsheet_number_row')])
      end

      r.on 'add_bin_to_tripsheet', Integer do |id|
        r.get do
          form_state = {}
          error = retrieve_from_local_store(:errors)
          form_state.merge!(error_message: error[:message], errors: error[:errors]) unless error.nil?
          form = Crossbeams::RMDForm.new(form_state,
                                         form_name: :bin,
                                         scan_with_camera: @rmd_scan_with_camera,
                                         caption: 'Scan Tripsheet Bin',
                                         action: "/rmd/rmt_deliveries/rmt_bins/add_bin_to_tripsheet/#{id}",
                                         button_caption: 'Submit')
          form.add_label(:tripsheet_number, 'Tripsheet Number', id)
          form.add_field(:bin_number, 'Bin Number', scan: 'key248_all', scan_type: :bin_asset, required: false, submit_form: true)

          bins = interactor.tripsheet_bins(id)
          unless bins.empty?
            form.add_section_header('Bins On Tripsheet')
            bins.each do |o|
              form.add_label(:tripsheet_pallet, '', o[:bin_asset_number])
            end
          end

          form.add_select(:printer,
                          'Printer',
                          items: LabelApp::PrinterRepo.new.select_printers_for_application(AppConst::PRINT_APP_PALLET_TRIPSHEET),
                          value: LabelApp::PrinterRepo.new.default_printer_for_application(AppConst::PRINT_APP_PALLET_TRIPSHEET),
                          required: false,
                          prompt: true)

          form.add_button('Cancel', "/rmd/rmt_deliveries/rmt_bins/cancel_bins_tripsheet/#{id}")
          form.add_button('Complete', "/rmd/rmt_deliveries/rmt_bins/complete_bins_tripsheet/#{id}")
          form.add_csrf_tag csrf_tag
          view(inline: form.render, layout: :layout_rmd)
        end

        r.post do
          res = interactor.add_bin_to_tripsheet(id, params[:bin][:bin_number])
          store_locally(:errors, res) unless res.success
          r.redirect("/rmd/rmt_deliveries/rmt_bins/add_bin_to_tripsheet/#{id}")
        end
      end

      r.on 'cancel_bins_tripsheet', Integer do |id|
        res = interactor.cancel_bins_tripheet(id)
        if res.success
          store_locally(:form_state, flash_notice: res.message)
          r.redirect('/rmd/rmt_deliveries/rmt_bins/create_bin_tripsheet')
        else
          store_locally(:errors, res)
          r.redirect("/rmd/rmt_deliveries/rmt_bins/add_bin_to_tripsheet/#{id}")
        end
      end

      r.on 'complete_bins_tripsheet', Integer do |id|
        res = interactor.complete_bins_tripsheet(id)
        if res.success
          jasper_params = JasperParams.new('delivery_tripsheet',
                                           current_user.login_name,
                                           vehicle_job_id: id)
          jasper_params.mode = :print
          printer_id = params[:bin][:printer] # interactor.default_printer_for_application(AppConst::PRINT_APP_PALLET_TRIPSHEET)
          jasper_params.printer = interactor.find_printer(printer_id)&.printer_code
          res = CreateJasperReport.call(jasper_params)

          if res.success
            store_locally(:form_state, flash_notice: res.message)
            r.redirect('/rmd/rmt_deliveries/rmt_bins/create_bin_tripsheet')
          end
        end

        store_locally(:errors, res)
        r.redirect("/rmd/rmt_deliveries/rmt_bins/add_bin_to_tripsheet/#{id}")
      end

      r.on 'continue_bins_tripsheet' do
        r.get do
          form_state = {}
          notice = retrieve_from_local_store(:flash_notice)
          error = retrieve_from_local_store(:errors)
          form_state.merge!(error_message: error[:message], errors: error[:errors]) unless error.nil?
          form = Crossbeams::RMDForm.new(form_state,
                                         form_name: :vehicle_job,
                                         notes: notice,
                                         scan_with_camera: @rmd_scan_with_camera,
                                         caption: 'Scan Tripsheet',
                                         action: '/rmd/rmt_deliveries/rmt_bins/continue_bins_tripsheet',
                                         button_caption: 'Submit')

          form.add_field(:tripsheet_number, 'Tripsheet Number', scan: 'key248_all', scan_type: :vehicle_job, submit_form: false, required: true, lookup: false)
          form.add_csrf_tag csrf_tag
          view(inline: form.render, layout: :layout_rmd)
        end

        r.post do
          res = interactor.can_continue_bin_tripsheet(params[:vehicle_job][:tripsheet_number])
          if res.success
            r.redirect("/rmd/rmt_deliveries/rmt_bins/add_bin_to_tripsheet/#{params[:vehicle_job][:tripsheet_number]}")
          else
            store_locally(:errors, res)
            r.redirect('/rmd/rmt_deliveries/rmt_bins/continue_bins_tripsheet')
          end
        end
      end

      r.on 'offload_bins' do
        r.get do
          notice = retrieve_from_local_store(:flash_notice)
          form_state = {}
          error = retrieve_from_local_store(:error)
          form_state.merge!(error_message: error[:message]) unless error.nil?
          form = Crossbeams::RMDForm.new(form_state,
                                         form_name: :vehicle,
                                         notes: notice,
                                         scan_with_camera: @rmd_scan_with_camera,
                                         caption: 'Scan Tripsheet And Location',
                                         action: '/rmd/rmt_deliveries/rmt_bins/offload_bins',
                                         button_caption: 'Submit')

          form.add_field(:vehicle_job, 'Tripsheet Number', scan: 'key248_all', scan_type: :vehicle_job, submit_form: false, required: true, lookup: false)
          form.add_select(:location,
                          'Location',
                          items: interactor.find_locations_by_location_type_and_storage_type(AppConst::LOCATION_TYPES_WAREHOUSE, AppConst::STORAGE_TYPE_BINS),
                          required: true,
                          prompt: true)
          form.add_csrf_tag csrf_tag
          view(inline: form.render, layout: :layout_rmd)
        end

        r.post do
          res = interactor.validate_bins_tripsheet_to_offload_(params[:vehicle][:vehicle_job], params[:vehicle][:location])
          if res.success
            store_locally(:flash_notice, res.message)
            r.redirect("/rmd/rmt_deliveries/rmt_bins/scan_bin_to_offload/#{params[:vehicle][:vehicle_job]}")
          else
            store_locally(:error, res)
            r.redirect('/rmd/rmt_deliveries/rmt_bins/offload_bins')
          end
        end
      end

      r.on 'scan_bin_to_offload', Integer do |id|
        r.get do
          notice = retrieve_from_local_store(:flash_notice)
          form_state = {}
          error = retrieve_from_local_store(:error)
          form_state.merge!(error_message: error[:message]) unless error.nil?
          form = Crossbeams::RMDForm.new(form_state,
                                         form_name: :bin,
                                         notes: notice,
                                         scan_with_camera: @rmd_scan_with_camera,
                                         caption: 'Offload Bin',
                                         action: "/rmd/rmt_deliveries/rmt_bins/scan_bin_to_offload/#{id}",
                                         button_caption: 'Submit')

          loaded, offloaded = interactor.loaded_and_offloaded_bins(id)
          form.add_label(:location, 'Location', interactor.get_vehicle_job_location(id))
          form.add_field(:bin_number, 'Bin Number', scan: 'key248_all', scan_type: :bin_asset, required: false, submit_form: true)

          unless loaded.empty?
            form.add_section_header('Bins Still On Load')
            loaded.each do |l|
              form.add_label(:loaded_bin, '', l[:bin_asset_number])
            end
          end

          unless offloaded.empty?
            form.add_section_header('Pallets Already Offloaded')
            offloaded.each do |o|
              form.add_label(:offloaded_bin, '', o[:bin_asset_number])
            end
          end

          form.add_csrf_tag csrf_tag
          view(inline: form.render, layout: :layout_rmd)
        end

        r.post do
          res = interactor.validate_bin_to_offload(id, params[:bin][:bin_number])
          if res.success
            bin = interactor.find_rmt_bin_flat(res.instance)
            form = Crossbeams::RMDForm.new({ id: bin[:id] },
                                           form_name: :bin,
                                           scan_with_camera: @rmd_scan_with_camera,
                                           caption: 'Confirm Offload Bin',
                                           reset_button: false,
                                           no_submit: false,
                                           action: "/rmd/rmt_deliveries/rmt_bins/accept_bin_offload/#{id}",
                                           button_caption: 'Accept')
            form.add_label(:tripsheet, 'Tripsheet', id)
            form.add_label(:delivery, 'Delivery', bin[:rmt_delivery_id])
            form.add_field(:id, 'Id', required: false, hide_on_load: true)
            form.add_label(:bin_asset_number, 'Asset Number', bin[:bin_asset_number])
            form.add_label(:bin_fullness, 'Bin Fullness', bin[:bin_fullness])
            form.add_label(:farm, 'Farm', bin[:farm_code])
            form.add_label(:orchard, 'Orchard', bin[:orchard_code])
            form.add_label(:puc, 'Puc', bin[:puc_code])
            form.add_label(:cultivar, 'Cultivar', bin[:cultivar_name])
            form.add_label(:commodity, 'Commodity Code', bin[:commodity_code])
            form.add_label(:class, 'Class Code', bin[:class_code])
            form.add_label(:size, 'Size Code', bin[:size_code])
            form.add_label(:bin_type, 'Bin Type', bin[:container_material_type_code])
            form.add_label(:rebin_run_id, 'Rebin Run', bin[:production_run_rebin_id])
            form.add_button('Reject', "/rmd/rmt_deliveries/rmt_bins/reject_bin_offload/#{id}")
            form.add_csrf_tag csrf_tag
            view(inline: form.render, layout: :layout_rmd)
          else
            store_locally(:error, res)
            r.redirect "/rmd/rmt_deliveries/rmt_bins/scan_bin_to_offload/#{id}"
          end
        end
      end

      r.on 'accept_bin_offload', Integer do |id|
        res = interactor.offload_bin(id, params[:bin][:id])
        if res.success
          if res.instance[:vehicle_job_offloaded]
            form = Crossbeams::RMDForm.new(nil,
                                           form_name: :pallet,
                                           scan_with_camera: @rmd_scan_with_camera,
                                           caption: 'Tripsheet Completed Successfully',
                                           action: '/',
                                           reset_button: false,
                                           no_submit: true,
                                           button_caption: '')

            form.add_section_header("#{res.instance[:pallets_moved]} Pallets have been moved to location #{res.instance[:location]}")
            form.add_csrf_tag csrf_tag
            return view(inline: form.render, layout: :layout_rmd)
          end
        else
          store_locally(:error, res)
        end

        r.redirect "/rmd/rmt_deliveries/rmt_bins/scan_bin_to_offload/#{id}"
      end

      r.on 'reject_bin_offload', Integer do |id|
        r.redirect "/rmd/rmt_deliveries/rmt_bins/scan_bin_to_offload/#{id}"
      end

      r.on 'receive_single_bin_submit' do
        id = params[:rmt_bin][:delivery_id]
        params[:rmt_bin].delete_if { |k, _v| k == :delivery_id }
        res = interactor.create_rmt_bin(id, params[:rmt_bin])
        if res.success
          notes = 'Bin Created Successfully'
        else
          params[:rmt_bin][:error_message] = res.message
          params[:rmt_bin][:errors] = res.errors
          store_locally(:bin, params[:rmt_bin])
        end
        new_bin_screen(id, '/rmd/rmt_deliveries/rmt_bins/receive_single_bin_submit', notes)
      end

      r.on 'set_bin_level', Integer do |id|
        notice = retrieve_from_local_store(:flash_notice)
        form_state = { bin_fullness: AppConst::BIN_FULL }

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

        form.add_field(:bin_asset_number, 'Asset Number',
                       scan: 'key248_all',
                       scan_type: :bin_asset,
                       required: false,
                       submit_form: false)
        form.add_select(:bin_fullness, 'Bin Fullness', items: AppConst::BIN_FULLNESS_OPTIONS, prompt: true)
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

      r.on 'set_bin_level_complete', Integer do |id|
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
        form.add_label(:puc_code, 'PUC', delivery[:puc_code])
        form.add_label(:orchard_code, 'Orchard', delivery[:orchard_code])
        form.add_label(:truck_registration_number, 'Truck Reg Number', delivery[:truck_registration_number])
        form.add_label(:date_delivered, 'Date Delivered', delivery[:date_delivered])
        form.add_csrf_tag csrf_tag
        view(inline: form.render, layout: :layout_rmd)
      end
    end
  end

  def rmt_container_type_combo_changed(form_name) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    actions = []
    if !params[:changed_value].to_s.empty?
      rmt_container_material_type_ids = MasterfilesApp::RmtContainerMaterialTypeRepo.new.for_select_rmt_container_material_types(where: { rmt_container_type_id: params[:changed_value] })
      rmt_container_material_type_ids.unshift([[]])
      if AppConst::DELIVERY_CAPTURE_CONTAINER_MATERIAL
        actions << OpenStruct.new(type: :replace_select_options,
                                  dom_id: "#{form_name}_rmt_container_material_type_id",
                                  options_array: rmt_container_material_type_ids)
      end
      if AppConst::DELIVERY_CAPTURE_CONTAINER_MATERIAL && AppConst::DELIVERY_CAPTURE_INNER_BINS
        actions << OpenStruct.new(type: MasterfilesApp::RmtContainerTypeRepo.new.find_rmt_container_type(params[:changed_value])&.rmt_inner_container_type_id ? :show_element : :hide_element,
                                  dom_id: "#{form_name}_qty_inner_bins_row")
      end
    else
      if AppConst::DELIVERY_CAPTURE_CONTAINER_MATERIAL
        actions << OpenStruct.new(type: :replace_select_options,
                                  dom_id: "#{form_name}_rmt_container_material_type_id",
                                  options_array: [])
      end
      if AppConst::DELIVERY_CAPTURE_CONTAINER_MATERIAL && AppConst::DELIVERY_CAPTURE_INNER_BINS
        actions << OpenStruct.new(type: :hide_element,
                                  dom_id: "#{form_name}_qty_inner_bins_row")
      end
    end

    if AppConst::DELIVERY_CAPTURE_CONTAINER_MATERIAL && AppConst::DELIVERY_CAPTURE_CONTAINER_MATERIAL_OWNER
      actions << OpenStruct.new(type: :replace_select_options,
                                dom_id: "#{form_name}_rmt_material_owner_party_role_id",
                                options_array: [])
    end

    json_actions(actions)
  end

  def container_material_type_combo_changed(form_name)
    if !params[:changed_value].to_s.empty?
      container_material_owners = RawMaterialsApp::RmtDeliveryRepo.new.find_container_material_owners_by_container_material_type(params[:changed_value])
      container_material_owners.unshift([[]])
      json_replace_select_options("#{form_name}_rmt_material_owner_party_role_id", container_material_owners)
    else
      json_replace_select_options("#{form_name}_rmt_material_owner_party_role_id", [])
    end
  end

  def receive_single_bin_error_screen(error)
    form_state = { error_message: error }

    form = Crossbeams::RMDForm.new(form_state,
                                   notes: nil,
                                   form_name: :rmt_bin,
                                   scan_with_camera: @rmd_scan_with_camera,
                                   caption: 'Receive Single Bin',
                                   reset_button: false,
                                   no_submit: true)

    form.add_csrf_tag csrf_tag
    view(inline: form.render, layout: :layout_rmd)
  end

  def new_bin_screen(delivery_id, action, notes = nil) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    bin_delivery = RawMaterialsApp::RmtDeliveryRepo.new.get_bin_delivery(delivery_id)
    bin_delivery = {} if !bin_delivery && AppConst::USE_PERMANENT_RMT_BIN_BARCODES
    if bin_delivery
      default_rmt_container_type = RawMaterialsApp::RmtDeliveryRepo.new.rmt_container_type_by_container_type_code(AppConst::DEFAULT_RMT_CONTAINER_TYPE)
      details = retrieve_from_local_store(:bin) || { bin_fullness: AppConst::BIN_FULL }

      capture_inner_bins = AppConst::DELIVERY_CAPTURE_INNER_BINS && !default_rmt_container_type[:id].nil? && !MasterfilesApp::RmtContainerTypeRepo.new.find_rmt_container_type(default_rmt_container_type[:id])&.rmt_inner_container_type_id
      capture_container_material = AppConst::DELIVERY_CAPTURE_CONTAINER_MATERIAL
      capture_container_material_owner = AppConst::DELIVERY_CAPTURE_CONTAINER_MATERIAL_OWNER

      form = Crossbeams::RMDForm.new(details,
                                     form_name: :rmt_bin,
                                     scan_with_camera: @rmd_scan_with_camera,
                                     notes: notes,
                                     caption: 'New Bin',
                                     action: action,
                                     button_caption: 'Submit')

      form.behaviours do |behaviour|
        behaviour.dropdown_change :delivery_id, notify: [{ url: '/rmd/rmt_deliveries/rmt_bins/rmt_bin_delivery_id_combo_changed' }]
        behaviour.dropdown_change :rmt_container_type_id, notify: [{ url: '/rmd/rmt_deliveries/rmt_bins/rmt_bin_rmt_container_type_combo_changed' }] if capture_container_material
        behaviour.dropdown_change :rmt_container_material_type_id, notify: [{ url: '/rmd/rmt_deliveries/rmt_bins/rmt_bin_container_material_type_combo_changed' }] if capture_container_material && capture_container_material_owner
      end

      form.add_label(:delivery_code, 'Delivery', bin_delivery[:id], nil, as_table_cell: true)
      form.add_label(:farm_code, 'Farm', bin_delivery[:farm_code], nil, as_table_cell: true)
      form.add_label(:puc_code, 'PUC', bin_delivery[:puc_code], nil, as_table_cell: true)
      form.add_label(:orchard_code, 'Orchard', bin_delivery[:orchard_code], nil, as_table_cell: true)
      form.add_label(:cultivar_code, 'Cultivar', bin_delivery[:cultivar_name], nil, as_table_cell: true)
      form.add_label(:date_picked, 'Date Picked', bin_delivery[:date_picked], nil, as_table_cell: true)
      form.add_label(:date_delivered, 'Date Delivered', bin_delivery[:date_delivered], nil, as_table_cell: true)
      form.add_label(:qty_bins_tipped, 'Qty Bins Tipped', bin_delivery[:qty_bins_tipped], nil, as_table_cell: true)
      form.add_label(:qty_bins_received, 'Qty Bins Received', bin_delivery[:qty_bins_received], nil, as_table_cell: true)

      delivery_codes = []
      delivery_codes = RawMaterialsApp::RmtDeliveryRepo.new.for_select_delivery_context_info unless retrieve_from_local_store(:new_bin_mode) == :edit_delivery
      delivery_codes.unshift(["#{bin_delivery[:id]}_#{bin_delivery[:puc_code]}_#{bin_delivery[:orchard_code]}_#{bin_delivery[:cultivar_code]}_#{bin_delivery[:date_delivered]}", bin_delivery[:id]]) unless bin_delivery.empty?
      form.add_select(:delivery_id, 'Delivery', items: delivery_codes.uniq, value: bin_delivery[:id], prompt: true, required: true)
      form.add_select(:rmt_class_id, 'RMT Class', items: MasterfilesApp::FruitRepo.new.for_select_rmt_classes, prompt: true, required: false)
      form.add_select(:rmt_container_type_id, 'Container Type', items: MasterfilesApp::RmtContainerTypeRepo.new.for_select_rmt_container_types, value: default_rmt_container_type[:id],
                                                                required: true, prompt: true)
      form.add_label(:qty_bins, 'Qty Bins', 1, 1)
      if capture_inner_bins
        form.add_field(:qty_inner_bins, 'Qty Inner Bins', data_type: 'number')
      else
        form.add_label(:qty_inner_bins, 'Qty Inner Bins', '1', '1', hide_on_load: true)
      end
      form.add_select(:bin_fullness, 'Bin Fullness', items: AppConst::BIN_FULLNESS_OPTIONS, prompt: true)
      form.add_field(:gross_weight, 'Gross Weight', required: false)

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
    else
      view(inline: rmd_warning_message('RMT Delivery not found'), layout: :layout_rmd)
    end
  end

  def fields_for_rmd_rmt_bin_display(form, rmt_bin) # rubocop:disable Metrics/AbcSize
    form.add_label(:bin_asset_number, 'Bin Asset Number', rmt_bin[:bin_asset_number])
    form.add_label(:bin_id, 'Bin Id', rmt_bin[:id])
    form.add_label(:location, 'Location', rmt_bin[:location_long_code])
    form.add_label(:status, 'Status', rmt_bin[:status])
    form.add_label(:cultivar_group, 'Cultivar Group', rmt_bin[:cultivar_group_code])
    form.add_label(:cultivar_name, 'Cultivar', rmt_bin[:cultivar_name])
    form.add_label(:class_code, 'Class', rmt_bin[:class_code])
    form.add_label(:size_code, 'Size', rmt_bin[:size_code])
    form.add_label(:farm_code, 'Farm', rmt_bin[:farm_code])
    form.add_label(:puc_code, 'Puc', rmt_bin[:puc_code])
    form.add_label(:orchard_code, 'Orchard', rmt_bin[:orchard_code])
    form.add_label(:rmt_delivery_id, 'Delivery', rmt_bin[:rmt_delivery_id])
    form.add_label(:production_run_tipped_id, 'Tipped Run', rmt_bin[:production_run_tipped_id])
    form.add_label(:production_run_rebin_id, 'Rebin Run', rmt_bin[:production_run_rebin_id])
    form.add_label(:container_material_type_code, 'Container Material Type', rmt_bin[:container_material_type_code])
    form.add_label(:container_material_owner_code, 'Container Material Owner', rmt_bin[:material_owner])
    form.add_label(:qty_inner_bins, 'Qty Inner Bins', rmt_bin[:qty_inner_bins]) unless rmt_bin[:rmt_inner_container_type_id].nil?
    form.add_label(:gross_weight, 'Gross Weight', rmt_bin[:gross_weight])
    form.add_label(:nett_weight, 'Nett Weight', rmt_bin[:nett_weight])
    form.add_label(:bin_fullness, 'Bin Fullness', rmt_bin[:bin_fullness])
    form.add_label(:bin_received_date_time, 'Received At', rmt_bin[:bin_received_date_time])
    form.add_label(:bin_load, 'Load Id', rmt_bin[:bin_load_id])
    form.add_label(:converted_from_pallet, 'Converted_from_pallet?', rmt_bin[:converted_from_pallet_sequence_id].nil?)
    form.add_label(:exit_ref, 'Exit Ref', rmt_bin[:exit_ref])
  end

  def fields_for_rmd_rmt_bin_presort_staging_run_display(form, rmt_bin)
    form.add_section_header('PRESORT STAGING INFO')
    form.add_label(:staged_for_presorting_at, 'Staged For Presorted At', rmt_bin[:staged_for_presorting_at])
    form.add_label(:presort_staging_run_child_id, 'Presort Staging Run Child Id', rmt_bin[:presort_staging_run_child_id])
    form.add_label(:presort_tip_lot_number, 'Presort Tip Lot Number', rmt_bin[:presort_tip_lot_number])
    form.add_label(:tipped_in_presort_at, 'Tipped In presort At', rmt_bin[:tipped_in_presort_at])
    form.add_label(:presort_unit, 'Presort Unit', rmt_bin[:presort_unit])
  end

  def fields_for_rmd_presort_bin_info_display(form, rmt_bin) # rubocop:disable Metrics/AbcSize
    form.add_section_header('PRESORT BIN INFO')
    form.add_label(:main_presort_run_lot_number, 'Main Presort Run Lot Number', rmt_bin[:main_presort_run_lot_number])
    unless rmt_bin[:legacy_data].nil?
      form.add_label(:numero_lot_max, 'Numero Lot Max', rmt_bin[:legacy_data]['numero_lot_max'])
      form.add_label(:code_cumul, 'Code Cumul', rmt_bin[:legacy_data]['code_cumul'])
    end

    bin_sequences = RawMaterialsApp::RmtDeliveryRepo.new.pallet_sequences_attrs_for_rmt_bin(rmt_bin[:id])
    form.add_section_header('SEQUENCES')
    bin_sequences.each do |seq|
      form.add_label(:pallet_number, 'Pallet Number', seq[:pallet_number])
      form.add_label(:pallet_sequence_number, 'Seq Number', seq[:pallet_sequence_number])
      form.add_label(:farm_code, 'Farm', seq[:farm_code])
      form.add_label(:orchard_code, 'Orchard', seq[:orchard_code])
      form.add_label(:nett_weight, 'Nett weight', seq[:nett_weight])
    end
  end

  def fields_for_rmd_rmt_bin_other_info_display(form, rmt_bin)
    form.add_section_header('OTHER INFO')
    form.add_label(:cold_store_type, 'Cold Store Type', rmt_bin[:legacy_data]['cold_store_type'])
    form.add_label(:treatment_code, 'Treatment Code', rmt_bin[:legacy_data]['treatment_code'])
    form.add_label(:ripe_point_code, 'Ripe Point Code', rmt_bin[:legacy_data]['ripe_point_code'])
    form.add_label(:track_slms_indicator_1_code, 'Track Indicator Code', rmt_bin[:legacy_data]['track_slms_indicator_1_code'])
    form.add_label(:track_slms_indicator_2_code, 'Track Indicator Code 2', rmt_bin[:legacy_data]['track_slms_indicator_2_code'])
  end

  def fields_for_rmd_rmt_bin_tripsheet_info_display(form, rmt_bin_id)
    tripsheet = RawMaterialsApp::RmtDeliveryRepo.new.most_recent_tripsheet_for_rmt_bin(rmt_bin_id)
    return if tripsheet.nil?

    form.add_section_header('TRIPSHEET INFO')
    form.add_label(:tripsheet_number, 'Tripsheet Number', tripsheet[:id])
    form.add_label(:location, 'Location', tripsheet[:location_long_code])
    form.add_label(:loaded_at, 'Loaded At', tripsheet[:loaded_at])
    form.add_label(:offloaded_at, 'Offloaded At', tripsheet[:offloaded_at])
  end
end
