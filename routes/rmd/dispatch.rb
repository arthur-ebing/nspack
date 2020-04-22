# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
class Nspack < Roda # rubocop:disable Metrics/ClassLength
  route 'dispatch', 'rmd' do |r|
    @repo = BaseRepo.new
    # ALLOCATE PALLETS TO LOAD
    # --------------------------------------------------------------------------
    r.on 'allocate' do
      interactor = FinishedGoodsApp::LoadInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})
      # --------------------------------------------------------------------------
      r.on 'load', Integer do |load_id|
        r.on 'complete_allocation' do
          allocated = interactor.stepper(:allocate).allocated
          initial_allocated = interactor.stepper(:allocate).initial_allocated

          res = interactor.allocate_multiselect(load_id, allocated, initial_allocated)
          if res.success
            interactor.stepper(:allocate).clear
            store_locally(:flash_notice, rmd_success_message(res.message))
            r.redirect('/rmd/dispatch/allocate/load')
          else
            store_locally(:flash_notice, rmd_error_message(res.message))
            r.redirect("/rmd/dispatch/allocate/load/#{load_id}")
          end
        end

        r.get do
          form_state = interactor.stepper(:allocate).form_state
          r.redirect('/rmd/dispatch/allocate/load') if form_state.empty?

          progress = interactor.stepper(:allocate).allocation_progress
          links = [{ caption: 'Cancel', url: '/rmd/dispatch/allocate/load/clear', prompt: 'Cancel Load?' }]
          links << { caption: 'Complete allocation', url: "/rmd/dispatch/allocate/load/#{load_id}/complete_allocation", prompt: 'Complete allocation?' } unless progress.nil?

          form = Crossbeams::RMDForm.new(form_state,
                                         form_name: :allocate,
                                         scan_with_camera: @rmd_scan_with_camera,
                                         progress: progress,
                                         links: links,
                                         notes: retrieve_from_local_store(:flash_notice),
                                         caption: 'Allocate Pallets',
                                         action: "/rmd/dispatch/allocate/load/#{load_id}",
                                         button_caption: 'Submit')

          form.add_label(:load_id, 'Load', load_id)
          form.add_label(:voyage_code, 'Voyage Code', form_state[:voyage_code])
          form.add_label(:container_code, 'Container Code', form_state[:container_code]) unless form_state[:container_code].nil?

          form.add_field(:pallet_number,
                         'Pallet',
                         scan: 'key248_all',
                         scan_type: :pallet_number,
                         submit_form: true,
                         data_type: 'number',
                         required: true)

          form.add_csrf_tag csrf_tag
          view(inline: form.render, layout: :layout_rmd)
        end

        r.post do
          scanned_number = MesscadaApp::ScannedPalletNumber.new(scanned_pallet_number: params[:allocate][:pallet_number]).pallet_number
          res = interactor.stepper_allocate_pallet(:allocate, load_id, scanned_number)
          message = res.success ? rmd_success_message(res.message) : rmd_error_message(res.message)
          store_locally(:flash_notice, message)
          r.redirect("/rmd/dispatch/allocate/load/#{load_id}")
        rescue Crossbeams::InfoError => e
          store_locally(:flash_notice, rmd_error_message(e))
          r.redirect("/rmd/dispatch/allocate/load/#{load_id}")
        end
      end

      r.on 'load' do
        r.on 'clear' do
          interactor.stepper(:allocate).clear
          r.redirect('/rmd/dispatch/allocate/load')
        end

        r.get do
          form_state = {}
          current_load = interactor.stepper(:allocate)
          r.redirect("/rmd/dispatch/allocate/load/#{current_load.id}") unless current_load&.id.nil?

          form_state = current_load.form_state if current_load&.error?
          form = Crossbeams::RMDForm.new(form_state,
                                         form_name: :allocate,
                                         scan_with_camera: @rmd_scan_with_camera,
                                         notes: retrieve_from_local_store(:flash_notice),
                                         caption: 'Scan Load',
                                         action: '/rmd/dispatch/allocate/load',
                                         button_caption: 'Submit')

          form.add_field(:load_id,
                         'Load',
                         data_type: 'number',
                         scan: 'key248_all',
                         scan_type: :load,
                         submit_form: true,
                         required: true)
          form.add_csrf_tag csrf_tag
          view(inline: form.render, layout: :layout_rmd)
        end

        r.post do
          current_load = interactor.stepper(:allocate)
          load_id = params[:allocate][:load_id]
          res = interactor.validate_load(load_id)

          if res.success
            current_load.setup_load(load_id)
            r.redirect("/rmd/dispatch/allocate/load/#{load_id}")
          else
            current_load.write(form_state: { error_message: res.message, errors: res.errors })
            r.redirect('/rmd/dispatch/allocate/load')
          end
        end
      end
    end

    # TRUCK ARRIVAL
    # --------------------------------------------------------------------------
    r.on 'truck_arrival' do
      interactor = FinishedGoodsApp::LoadInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})
      # --------------------------------------------------------------------------
      r.on 'load', Integer do |load_id|
        r.on 'vehicle_type_changed' do
          if params[:changed_value].nil_or_empty?
            blank_json_response
          else
            value = MasterfilesApp::VehicleTypeRepo.new.find_vehicle_type(params[:changed_value])&.has_container
            UiRules::ChangeRenderer.render_json(:rmd_load,
                                                self,
                                                :change_container_use,
                                                use_container: value,
                                                load_id: load_id)
          end
        end

        r.on 'container_changed' do
          UiRules::ChangeRenderer.render_json(:rmd_load,
                                              self,
                                              :change_container_use,
                                              use_container: params[:changed_value] == 't',
                                              load_id: load_id)
        end

        r.get do
          # set defaults
          form_state = {}
          form_state[:stack_type_id] = @repo.get_id(:container_stack_types, stack_type_code: 'S')
          form_state[:actual_payload] = FinishedGoodsApp::LoadContainerRepo.new.actual_payload_from(load_id: load_id) if AppConst::VGM_REQUIRED
          form_state[:cargo_temperature_id] = MasterfilesApp::CargoTemperatureRepo.new.cargo_temperature_id_for(AppConst::DEFAULT_CARGO_TEMP_ON_ARRIVAL)

          # checks if load_container exists
          container_id = @repo.get_id(:load_containers, load_id: load_id)
          unless container_id.nil?
            form_state = form_state.merge(FinishedGoodsApp::LoadContainerRepo.new.find_load_container_flat(container_id).to_h)
            form_state[:container] = 'true'
          end

          # checks if load_vehicle exists
          vehicle_id = FinishedGoodsApp::LoadVehicleRepo.new.find_load_vehicle_from(load_id: load_id)
          form_state = form_state.merge(FinishedGoodsApp::LoadVehicleRepo.new.find_load_vehicle(vehicle_id).to_h) unless vehicle_id.nil?

          # overrides if redirect from error
          res = retrieve_from_local_store(:res)
          unless res.nil?
            form_state = res.instance
            form_state[:error_message] = res.message
            form_state[:errors] = res.errors
          end

          has_container = form_state[:container] == 'true'
          form = Crossbeams::RMDForm.new(form_state,
                                         form_name: :truck_arrival,
                                         scan_with_camera: @rmd_scan_with_camera,
                                         notes: retrieve_from_local_store(:flash_notice),
                                         caption: 'Capture Vehicle',
                                         action: "/rmd/dispatch/truck_arrival/load/#{load_id}",
                                         button_caption: 'Submit')
          form.behaviours do |behaviour|
            behaviour.dropdown_change :vehicle_type_id,
                                      notify: [{ url: "/rmd/dispatch/truck_arrival/load/#{load_id}/vehicle_type_changed" }]
            behaviour.input_change :container,
                                   notify: [{ url: "/rmd/dispatch/truck_arrival/load/#{load_id}/container_changed" }]
          end

          form.add_label(:load_id, 'Load', load_id, load_id)
          form.add_label(:vehicle_id, 'vehicle_id', vehicle_id, vehicle_id, hide_on_load: true)
          form.add_label(:container_id, 'container_id', container_id, container_id, hide_on_load: true)
          form.add_field(:vehicle_number,
                         'Vehicle Number',
                         data_type: 'string',
                         force_uppercase: true,
                         required: true)
          form.add_select(:vehicle_type_id,
                          'Vehicle Type',
                          items: MasterfilesApp::VehicleTypeRepo.new.for_select_vehicle_types,
                          prompt: true)
          form.add_select(:haulier_party_role_id,
                          'Haulier',
                          items: MasterfilesApp::PartyRepo.new.for_select_party_roles,
                          prompt: true)
          form.add_field(:vehicle_weight_out,
                         'Vehicle Weight Out',
                         data_type: 'number',
                         allow_decimals: true,
                         required: false)
          form.add_field(:driver_name, 'Driver')
          form.add_field(:driver_cell_number, 'Driver Cell no')
          form.add_field(:dispatch_consignment_note_number,
                         'Consignment Note Number',
                         data_type: 'string',
                         required: false,
                         hide_on_load: true)
          form.add_toggle(:container,
                          'Container')

          form.add_section_header(rmd_info_message('Container Info'),
                                  id: 'container_info_section',
                                  hide_on_load: !has_container)
          form.add_field(:container_code,
                         'Container Code',
                         data_type: 'string',
                         required: false,
                         force_uppercase: true,
                         hide_on_load: !has_container)
          form.add_field(:container_vents,
                         'Container Vents',
                         data_type: 'string',
                         required: false,
                         hide_on_load: !has_container)
          form.add_field(:container_seal_code,
                         'Container Seal Code',
                         data_type: 'string',
                         required: false,
                         hide_on_load: !has_container)
          form.add_field(:container_temperature_rhine,
                         'Temperature Rhine',
                         data_type: 'string',
                         scan: 'key248_all',
                         required: false,
                         hide_on_load: !has_container)
          form.add_field(:container_temperature_rhine2,
                         'Temperature Rhine2',
                         data_type: 'string',
                         scan: 'key248_all',
                         required: false,
                         hide_on_load: !has_container)
          form.add_field(:max_gross_weight,
                         'Max Gross Weight',
                         data_type: 'number',
                         allow_decimals: true,
                         required: false,
                         hide_on_load: !has_container)
          if AppConst::VGM_REQUIRED
            form.add_field(:tare_weight,
                           'Tare Weight',
                           data_type: 'number',
                           allow_decimals: true,
                           required: false,
                           hide_on_load: !has_container)
            form.add_field(:max_payload,
                           'Max Payload',
                           data_type: 'number',
                           allow_decimals: true,
                           required: false,
                           hide_on_load: !has_container)
            form.add_label(:actual_payload,
                           'Calculated Payload',
                           form_state[:actual_payload],
                           form_state[:actual_payload],
                           hide_on_load: !has_container)
          end
          form.add_select(:cargo_temperature_id,
                          'Cargo Temperature',
                          items: MasterfilesApp::CargoTemperatureRepo.new.for_select_cargo_temperatures,
                          required: false,
                          hide_on_load: !has_container)
          form.add_select(:stack_type_id,
                          'Stack Type',
                          items: FinishedGoodsApp::LoadContainerRepo.new.for_select_container_stack_types,
                          required: false,
                          hide_on_load: !has_container)
          form.add_csrf_tag csrf_tag
          view(inline: form.render, layout: :layout_rmd)
        end

        r.post do
          attrs = params[:truck_arrival]
          res = interactor.truck_arrival(attrs)

          if res.success
            store_locally(:flash_notice, rmd_success_message(res.message))
            r.redirect('/rmd/dispatch/truck_arrival/load')
          else
            res.instance = attrs
            store_locally(:res, res)
            r.redirect("/rmd/dispatch/truck_arrival/load/#{attrs[:load_id]}")
          end
        end
      end

      r.on 'load' do
        r.get do
          form_state = {}
          res = retrieve_from_local_store(:res)
          unless res.nil?
            form_state = res.instance
            form_state[:error_message] = res.message
            form_state[:errors] = res.errors
          end

          form = Crossbeams::RMDForm.new(form_state,
                                         form_name: :load,
                                         scan_with_camera: @rmd_scan_with_camera,
                                         notes: retrieve_from_local_store(:flash_notice),
                                         caption: 'Scan Load',
                                         action: '/rmd/dispatch/truck_arrival/load',
                                         button_caption: 'Submit')

          form.add_field(:load_id,
                         'Load',
                         data_type: 'number',
                         scan: 'key248_all',
                         scan_type: :load,
                         submit_form: true,
                         required: true)
          form.add_csrf_tag csrf_tag
          view(inline: form.render, layout: :layout_rmd)
        end

        r.post do
          load_id = params[:load][:load_id]
          res = interactor.validate_load(load_id)
          if res.success
            r.redirect("/rmd/dispatch/truck_arrival/load/#{load_id}")
          else
            store_locally(:res, res)
            r.redirect('/rmd/dispatch/truck_arrival/load')
          end
        end
      end
    end

    # LOAD TRUCK
    # --------------------------------------------------------------------------
    r.on 'load_truck' do
      interactor = FinishedGoodsApp::LoadInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})
      # --------------------------------------------------------------------------
      r.on 'load', Integer do |load_id|
        r.get do
          form_state = interactor.stepper(:load_truck).form_state
          r.redirect('/rmd/dispatch/load_truck/load') if form_state.empty?

          form = Crossbeams::RMDForm.new(form_state,
                                         form_name: :load_truck,
                                         progress: interactor.stepper(:load_truck).progress,
                                         scan_with_camera: @rmd_scan_with_camera,
                                         links: [{ caption: 'Cancel', url: '/rmd/dispatch/load_truck/load/clear', prompt: 'Cancel Load?' }],
                                         notes: retrieve_from_local_store(:flash_notice),
                                         caption: 'Scan Pallets',
                                         action: "/rmd/dispatch/load_truck/load/#{load_id}",
                                         button_caption: 'Submit')

          form.add_label(:load_id, 'Load', load_id)
          form.add_label(:voyage_code, 'Voyage Code', form_state[:voyage_code])
          form.add_label(:vehicle_number, 'Vehicle Number', form_state[:vehicle_number])
          form.add_label(:container_code, 'Container Code', form_state[:container_code]) unless form_state[:container_code].nil?
          form.add_label(:allocation_count, 'Allocation Count', form_state[:allocation_count]) unless form_state[:allocation_count]&.zero?

          form.add_field(:pallet_number,
                         'Pallet',
                         scan: 'key248_all',
                         scan_type: :pallet_number,
                         submit_form: true,
                         data_type: 'number',
                         required: true)

          form.add_csrf_tag csrf_tag
          view(inline: form.render, layout: :layout_rmd)
        end

        r.post do
          scanned_number = MesscadaApp::ScannedPalletNumber.new(scanned_pallet_number: params[:load_truck][:pallet_number]).pallet_number
          res = interactor.stepper_load_pallet(:load_truck, load_id, scanned_number)
          if res.instance[:load_complete]
            form_state = interactor.stepper(:load_truck).form_state || {}
            interactor.stepper(:load_truck).clear
            store_locally(:flash_notice, rmd_success_message(res.message))
            if form_state[:container_code].nil_or_empty?
              r.redirect('/rmd/dispatch/load_truck/load')
            else
              store_locally(:temp_tail, OpenStruct.new(instance: { pallet_number: scanned_number }))
              r.redirect('/rmd/dispatch/temp_tail')
            end
          end
          message = res.success ? rmd_success_message(res.message) : rmd_error_message(res.message)
          store_locally(:flash_notice, message)
          r.redirect("/rmd/dispatch/load_truck/load/#{load_id}")
        rescue Crossbeams::InfoError => e
          store_locally(:flash_notice, rmd_error_message(e))
          r.redirect("/rmd/dispatch/load_truck/load/#{load_id}")
        end
      end

      r.on 'load' do
        r.on 'clear' do
          interactor.stepper(:load_truck).clear
          r.redirect('/rmd/dispatch/load_truck/load')
        end

        r.get do
          form_state = {}
          current_load = interactor.stepper(:load_truck)
          r.redirect("/rmd/dispatch/load_truck/load/#{current_load.id}") unless current_load&.id.nil?

          form_state = current_load.form_state if current_load&.error?
          form = Crossbeams::RMDForm.new(form_state,
                                         form_name: :load,
                                         scan_with_camera: @rmd_scan_with_camera,
                                         notes: retrieve_from_local_store(:flash_notice),
                                         caption: 'Scan Load',
                                         action: '/rmd/dispatch/load_truck/load',
                                         button_caption: 'Submit')

          form.add_field(:load_id,
                         'Load',
                         data_type: 'number',
                         scan: 'key248_all',
                         scan_type: :load,
                         submit_form: true,
                         required: true)
          form.add_csrf_tag csrf_tag
          view(inline: form.render, layout: :layout_rmd)
        end

        r.post do
          current_load = interactor.stepper(:load_truck)
          load_id = params[:load][:load_id]
          res = interactor.validate_load_truck(load_id)

          if res.success
            current_load.setup_load(load_id)
            r.redirect("/rmd/dispatch/load_truck/load/#{load_id}")
          else
            current_load.write(form_state: { error_message: res.message, errors: res.errors })
            r.redirect('/rmd/dispatch/load_truck/load')
          end
        end
      end
    end

    # SET TEMP TAIL
    # --------------------------------------------------------------------------
    r.on 'temp_tail' do
      interactor = FinishedGoodsApp::LoadInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      r.get do
        form_state = {}
        res = retrieve_from_local_store(:temp_tail)
        unless res.nil?
          form_state = res.instance
          form_state[:error_message] = res.message
          form_state[:errors] = res.errors
        end
        form = Crossbeams::RMDForm.new(form_state,
                                       form_name: :set_temp_tail,
                                       scan_with_camera: @rmd_scan_with_camera,
                                       notes: retrieve_from_local_store(:flash_notice),
                                       caption: 'Set Temp Tail',
                                       action: '/rmd/dispatch/temp_tail',
                                       button_caption: 'Submit')

        form.add_field(:pallet_number,
                       'Pallet',
                       scan: 'key248_all',
                       scan_type: :pallet_number,
                       data_type: 'number',
                       required: true)
        form.add_field(:temp_tail,
                       'Temp',
                       scan: 'key248_all',
                       submit_form: true,
                       data_type: 'string',
                       required: true)
        form.add_csrf_tag csrf_tag
        view(inline: form.render, layout: :layout_rmd)
      end

      r.post do
        res = interactor.update_pallets_temp_tail(params[:set_temp_tail])
        if res.success
          store_locally(:flash_notice, rmd_success_message(res.message))
          r.redirect('/rmd/home')
        else
          store_locally(:temp_tail, res)
          r.redirect('/rmd/dispatch/temp_tail')
        end
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
