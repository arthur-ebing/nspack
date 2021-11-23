# frozen_string_literal: true

class Nspack < Roda
  route 'depot_buildups', 'rmd' do |r|
    interactor = FinishedGoodsApp::BuildupsInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

    # --------------------------------------------------------------------------
    # PALLET BUILDUP
    # --------------------------------------------------------------------------
    r.on 'depot_pallet_buildup', Integer do |id|
      r.on 'move_sequence_cartons' do
        r.get do
          form_state = {}
          if (error = retrieve_from_local_store(:error))
            form_state.merge!(error_message: error.message)
            form_state.merge!(errors: error.errors) unless error.errors.nil_or_empty?
          end

          depot_pallet_buildup = interactor.depot_pallet_buildup(id)
          form = Crossbeams::RMDForm.new(form_state,
                                         form_name: :buildup_sequences,
                                         notes: nil,
                                         scan_with_camera: @rmd_scan_with_camera,
                                         caption: 'Move Sequence Cartons',
                                         action: "/rmd/depot_buildups/depot_pallet_buildup/#{id}/move_sequence_cartons",
                                         button_caption: 'Submit')

          depot_pallet_buildup.source_pallets.each do |pallet_number|
            sequences = interactor.depot_buildup_pallet_sequences(pallet_number)
            form.add_section_header(pallet_number)
            sequences.each do |seq|
              form.add_section_header("Pallet Sequence Number  #{seq[:pallet_sequence_number]}")
              # form.add_label(:pallet_sequence_number, 'Pallet Sequence Number', seq[:pallet_sequence_number], nil, value_class: 'tc b black')
              form.add_label(:origin, 'Origin', "#{seq[:farm]}_#{seq[:puc]}_#{seq[:orchard]}_#{seq[:commodity]}_#{seq[:cultivar_group]}_#{seq[:cultivar]}")
              form.add_label(:production_run, 'Production Run Id', "#{seq[:production_run_id]}:#{seq[:created_at].to_datetime.strftime('%Y-%m-%d %H:%M')}")
              form.add_label(:product, 'Product', "#{seq[:commodity]}_#{seq[:marketing_variety]}_#{seq[:actual_count]}_#{seq[:size_ref]}_#{seq[:grade]}_#{seq[:rmt_class_code]}_#{seq[:basic_pack]}_#{seq[:std_pack]}_#{seq[:sell_by_code]}_#{seq[:inventory_code]}")
              form.add_label(:cnt_qty, 'Sequence Carton Quantity', seq[:carton_quantity])
              form.add_field("#{pallet_number}_#{seq[:pallet_sequence_number]}".to_sym, 'Quantity Cartons To Move', data_type: :number, required: false)
            end
            form.add_section_header('&nbsp;')
          end
          form.add_csrf_tag csrf_tag
          view(inline: form.render, layout: :layout_rmd)
        end

        r.post do
          res = interactor.move_sequence_cartons(id, params[:buildup_sequences])
          unless res.success
            store_locally(:error, res)
            r.redirect("/rmd/depot_buildups/depot_pallet_buildup/#{id}/move_sequence_cartons")
          end
          r.redirect("/rmd/depot_buildups/depot_pallet_buildup/#{id}/depot_pallet_buildup_complete")
        end
      end

      r.on 'depot_pallet_buildup_complete' do
        r.get do
          form_state = {}
          if (error = retrieve_from_local_store(:error))
            form_state.merge!(error_message: error.message)
            form_state.merge!(errors: error.errors) unless error.errors.nil_or_empty?
          end

          form = Crossbeams::RMDForm.new(form_state,
                                         notes: nil,
                                         form_name: :depot_buildup,
                                         scan_with_camera: @rmd_scan_with_camera,
                                         caption: 'Confirm Complete',
                                         reset_button: false,
                                         no_submit: false,
                                         action: "/rmd/depot_buildups/depot_pallet_buildup/#{id}/depot_pallet_buildup_rejected",
                                         button_caption: 'Cancel')
          form.add_section_header(interactor.complete_depot_buildup_message(id))
          form.add_button('Complete', "/rmd/depot_buildups/depot_pallet_buildup/#{id}/depot_pallet_buildup_complete")
          form.add_csrf_tag csrf_tag
          view(inline: form.render, layout: :layout_rmd)
        end

        r.post do
          res = interactor.complete_depot_pallet_buildup(id)
          unless res.success
            store_locally(:error, res)
            r.redirect("/rmd/depot_buildups/depot_pallet_buildup/#{id}/depot_pallet_buildup_complete")
          end

          form = Crossbeams::RMDForm.new(nil,
                                         notes: nil,
                                         form_name: :depot_buildup,
                                         scan_with_camera: @rmd_scan_with_camera,
                                         caption: 'Depot Buildup Completed',
                                         reset_button: false,
                                         no_submit: true,
                                         action: '/')
          form.add_section_header(res.message)
          form.add_csrf_tag csrf_tag
          view(inline: form.render, layout: :layout_rmd)
        end
      end

      r.on 'depot_pallet_buildup_rejected' do
        res = interactor.delete_depot_pallet_buildup(id)
        unless res.success
          store_locally(:error, res)
          r.redirect("/rmd/depot_buildups/depot_pallet_buildup/#{id}/move_sequence_cartons")
        end

        form = Crossbeams::RMDForm.new(nil,
                                       form_name: :depot_buildup,
                                       scan_with_camera: @rmd_scan_with_camera,
                                       caption: 'Depot Pallet Buildup Completed',
                                       reset_button: false,
                                       no_submit: true,
                                       action: '/',
                                       button_caption: '')
        form.add_section_header("Pallet buildup:#{id} has been aborted")
        form.add_csrf_tag csrf_tag
        view(inline: form.render, layout: :layout_rmd)
      end
    end

    r.on 'depot_pallet_buildup' do
      r.get do
        plan_pallet_buildup_form('/rmd/depot_buildups/depot_pallet_buildup')
      end

      r.post do
        res = interactor.buildup_depot_pallet(params[:buildup])
        if res.success
          r.redirect("/rmd/depot_buildups/depot_pallet_buildup/#{res.instance}/move_sequence_cartons")
        else
          store_locally(:error, res)
          r.redirect('/rmd/depot_buildups/depot_pallet_buildup')
        end
      end
    end
  end
end
