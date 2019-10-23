# frozen_string_literal: true

class Nspack < Roda
  # --------------------------------------------------------------------------
  # DELIVERIES
  # --------------------------------------------------------------------------
  route 'production', 'rmd' do |r| # rubocop:disable Metrics/BlockLength
    r.on 'pallet_inquiry' do  # rubocop:disable Metrics/BlockLength
      interactor = MesscadaApp::MesscadaInteractor.new(current_user, {}, { route_url: request.path }, {})
      # --------------------------------------------------------------------------
      # /rmd/production/pallet_inquiry/scan_pallet
      # --------------------------------------------------------------------------
      r.on 'scan_pallet' do
        pallet = {}
        error = retrieve_from_local_store(:scan_pallet_submit_error)
        pallet = { error_message: error } unless error.nil?

        form = Crossbeams::RMDForm.new(pallet,
                                       form_name: :pallet,
                                       scan_with_camera: @rmd_scan_with_camera,
                                       caption: 'Scan Pallet',
                                       action: '/rmd/production/pallet_inquiry/scan_pallet_submit',
                                       button_caption: 'Submit')

        form.add_field(:pallet_number, 'Pallet Number', data_type: :number, required: true)
        form.add_csrf_tag csrf_tag
        view(inline: form.render, layout: :layout_rmd)
      end

      r.on 'scan_pallet_submit' do
        pallet_sequences = interactor.find_pallet_sequences_by_pallet_number(params[:pallet][:pallet_number])
        if pallet_sequences.empty?
          store_locally(:scan_pallet_submit_error, "scanned_pallet:#{params[:pallet][:pallet_number]}  doesn't exist")
          r.redirect('/rmd/production/pallet_inquiry/scan_pallet')
        else
          form = pallet_sequences_navigator_form(pallet_sequences.find { |p| p[:pallet_sequence_number] == 1 }, pallet_sequences.map { |p| p[:pallet_sequence_number] })
          view(inline: form.render, layout: :layout_rmd)
        end
      end

      r.on Integer do |id|
        # --------------------------------------------------------------------------
        # /rmd/production/pallet_inquiry/$:id$/navigate_to_sequence/#{pallet_sequence[:pallet_number]}
        # --------------------------------------------------------------------------
        r.on 'navigate_to_sequence' do
          r.on Integer do |pallet_num|
            pallet_sequences = interactor.find_pallet_sequences_by_pallet_number(pallet_num.to_s)
            form = pallet_sequences_navigator_form(pallet_sequences.find { |p| p[:pallet_sequence_number] == id }, pallet_sequences.map { |p| p[:pallet_sequence_number] })
            view(inline: form.render, layout: :layout_rmd)
          end
        end
      end
    end
  end

  def pallet_sequences_navigator_form(pallet_sequence, ids, action = nil, caption = nil) # rubocop:disable Metrics/AbcSize
    form = Crossbeams::RMDForm.new(pallet_sequence || {},
                                   form_name: :pallet,
                                   scan_with_camera: @rmd_scan_with_camera,
                                   caption: 'View Pallet',
                                   action: action,
                                   button_caption: caption)

    form.add_label(:pallet_number, 'Pallet Number', pallet_sequence[:pallet_number])
    form.add_label(:pallet_sequence_number, 'Pallet Sequence Number', pallet_sequence[:pallet_sequence_number])
    form.add_label(:build_status, 'Build Status', pallet_sequence[:build_status])
    form.add_label(:stack_type, 'Stack Height', pallet_sequence[:stack_type])
    form.add_label(:carton_quantity, 'Pallet Carton Quantity', pallet_sequence[:carton_quantity])
    form.add_label(:seq_carton_qty, 'Seq Carton Qty', pallet_sequence[:seq_carton_qty])
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
    form.add_label(:verification_result, 'Verification Result', pallet_sequence[:verification_result])
    form.add_label(:verification_failure_reason, 'Verification Failure Reason', pallet_sequence[:verification_failure_reason])
    form.add_label(:fruit_sticker, 'Fruit Sticker', pallet_sequence[:fruit_sticker]) if AppConst::REQUIRE_FRUIT_STICKER_AT_PALLET_VERIFICATION == 'true'
    form.add_csrf_tag csrf_tag

    form.add_prev_next_nav("/rmd/production/pallet_inquiry/$:id$/navigate_to_sequence/#{pallet_sequence[:pallet_number]}", ids, pallet_sequence[:pallet_sequence_number])

    form
  end
end
