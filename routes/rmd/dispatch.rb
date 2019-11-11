# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
class Nspack < Roda # rubocop:disable Metrics/ClassLength
  route 'dispatch', 'rmd' do |r|
    # TRUCK ARRIVAL
    # --------------------------------------------------------------------------
    r.on 'truck_arrival' do
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
          form_state[:stack_type_id] = FinishedGoodsApp::LoadContainerRepo.new.find_stack_type_id('S')
          form_state[:verified_gross_weight_date] = Time.now
          if AppConst::VGM_REQUIRED
            res = FinishedGoodsApp::LoadContainerRepo.new.actual_payload_by_load(load_id)
            if res.success
              form_state[:actual_payload] = res.instance
            else
              form_state[:error_message] = "Pallet #{res.instance.join(', ')} has no nett weight"
              form_state[:actual_payload] = 'Error'
            end
          end

          # check if load_container exists
          container_id = FinishedGoodsApp::LoadContainerRepo.new.find_load_container_by_load(load_id)
          unless container_id.nil?
            form_state = form_state.merge(FinishedGoodsApp::LoadContainerRepo.new.find_load_container(container_id).to_h)
            form_state[:container] = 'true'
          end

          # check if load_vehicle exists
          vehicle_id = FinishedGoodsApp::LoadVehicleRepo.new.find_load_vehicle_from(load_id: load_id)
          form_state = form_state.merge(FinishedGoodsApp::LoadVehicleRepo.new.find_load_vehicle(vehicle_id).to_h) unless vehicle_id.nil?

          # override if redirect from error
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
                          # disabled_items: MasterfilesApp::VehicleTypeRepo.new.for_select_inactive_vehicle_types,
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
          form.add_field(:internal_container_code,
                         'Internal Container Code',
                         data_type: 'string',
                         required: false,
                         hide_on_load: !has_container)
          form.add_field(:container_temperature_rhine,
                         'Temperature Rhine',
                         data_type: 'number',
                         allow_decimals: true,
                         required: false,
                         hide_on_load: !has_container)
          form.add_field(:container_temperature_rhine2,
                         'Temperature Rhine2',
                         data_type: 'number',
                         allow_decimals: true,
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
                          # disabled_items: MasterfilesApp::CargoTemperatureRepo.new.for_select_inactive_cargo_temperatures,
                          items: MasterfilesApp::CargoTemperatureRepo.new.for_select_cargo_temperatures,
                          required: false,
                          hide_on_load: !has_container)
          form.add_select(:stack_type_id,
                          'Stack Type',
                          # disabled_items: MasterfilesApp::LoadContainerRepo.new.for_select_inactive_container_stack_types,
                          items: FinishedGoodsApp::LoadContainerRepo.new.for_select_container_stack_types,
                          required: false,
                          hide_on_load: !has_container)
          form.add_field(:verified_gross_weight,
                         'Verified Gross Weight',
                         data_type: 'number',
                         allow_decimals: true,
                         required: false,
                         hide_on_load: !has_container)
          form.add_label(:verified_gross_weight_date,
                         'Verified Gross Weight Date',
                         form_state[:verified_gross_weight_date],
                         form_state[:verified_gross_weight_date],
                         hide_on_load: !has_container)
          form.add_csrf_tag csrf_tag
          view(inline: form.render, layout: :layout_rmd)
        end

        r.post do
          attrs = params[:truck_arrival]
          interactor = FinishedGoodsApp::DispatchInteractor.new(current_user, {}, { route_url: request.path }, {})
          res = interactor.truck_arrival_service(attrs)

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
                         scan: 'key248_all',
                         scan_type: :load,
                         submit_form: true,
                         required: true)
          form.add_csrf_tag csrf_tag
          view(inline: form.render, layout: :layout_rmd)
        end

        r.post do
          interactor = FinishedGoodsApp::DispatchInteractor.new(current_user, {}, { route_url: request.path }, {})
          load_id = params[:load][:load_id]
          res = interactor.validate_load(load_id)
          if res.success
            r.redirect("/rmd/dispatch/truck_arrival/load/#{res.instance}")
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
      # --------------------------------------------------------------------------
      r.on 'load', Integer do |load_id|
        r.get do
          form_state = retrieve_from_local_store(:load_truck) || {}

          if form_state.empty?
            form_state[:load_id]        = load_id
            form_state[:voyage_code]    = FinishedGoodsApp::LoadRepo.new.find_load_flat(load_id)&.voyage_code
            vehicle_id                  = FinishedGoodsApp::LoadVehicleRepo.new.find_load_vehicle_from(load_id: load_id)
            form_state[:vehicle_number] = FinishedGoodsApp::LoadVehicleRepo.new.find_load_vehicle(vehicle_id)&.vehicle_number
            container_id                = FinishedGoodsApp::LoadContainerRepo.new.find_load_container_by_load(load_id)
            form_state[:container_code] = FinishedGoodsApp::LoadContainerRepo.new.find_load_container(container_id)&.container_code
            form_state[:allocated]      = FinishedGoodsApp::LoadRepo.new.find_pallet_numbers_from(load_id: load_id)
            form_state[:scanned]        = []
          end

          progress = "Pallets still to scan<br>#{form_state[:allocated].join('<br>')}<br>"
          progress = "#{progress}<br>Scanned Pallets<br>#{form_state[:scanned].join('<br>')}" unless form_state[:scanned].empty?

          store_locally(:load_truck, form_state)
          form = Crossbeams::RMDForm.new(form_state,
                                         form_name: :load_truck,
                                         progress: progress,
                                         scan_with_camera: @rmd_scan_with_camera,
                                         links: [{ caption: 'Cancel', url: '/rmd/dispatch/load_truck/load/clear', prompt: 'Cancel Load?' }],
                                         notes: retrieve_from_local_store(:flash_notice),
                                         caption: 'Scan Pallets',
                                         action: "/rmd/dispatch/load_truck/load/#{load_id}",
                                         button_caption: 'Submit')

          form.add_label(:load_id, 'Load', load_id)
          form.add_label(:voyage_code, 'Voyage Code', form_state[:voyage_code])
          form.add_label(:vehicle_number, 'Vehicle Number', form_state[:vehicle_number])
          form.add_label(:container_code, 'Container Code', form_state[:container_code])
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
          interactor = FinishedGoodsApp::LoadInteractor.new(current_user, {}, { route_url: request.path }, {})

          attrs = retrieve_from_local_store(:load_truck)
          scanned_number = params[:load_truck][:pallet_number]

          case scanned_number
          when *attrs[:allocated]
            attrs[:scanned] << attrs[:allocated].delete(scanned_number)
          when *attrs[:scanned]
            attrs[:allocated] << attrs[:scanned].delete(scanned_number)
          else
            flash_notice = rmd_error_message("Pallet number '#{scanned_number}', not on load #{load_id}")
            store_locally(:flash_notice, flash_notice)
          end

          if attrs[:allocated].empty?
            res = interactor.ship_load(attrs[:load_id])
            store_locally(:flash_notice, res.message)
            store_locally(:load_truck, nil)
            r.redirect('/rmd/dispatch/load_truck/load') if res.success
          end

          store_locally(:load_truck, attrs)
          r.redirect("/rmd/dispatch/load_truck/load/#{attrs[:load_id]}")
        end
      end

      r.on 'load' do
        r.on 'clear' do
          store_locally(:load_truck, nil)
          r.redirect('/rmd/dispatch/load_truck/load')
        end

        r.get do
          form_state = {}
          attrs = retrieve_from_local_store(:load_truck)
          unless attrs.nil?
            store_locally(:load_truck, attrs)
            r.redirect("/rmd/dispatch/load_truck/load/#{attrs[:load_id]}")
          end

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
                                         action: '/rmd/dispatch/load_truck/load',
                                         button_caption: 'Submit')

          form.add_field(:load_id,
                         'Load',
                         scan: 'key248_all',
                         scan_type: :load,
                         submit_form: true,
                         required: true)
          form.add_csrf_tag csrf_tag
          view(inline: form.render, layout: :layout_rmd)
        end

        r.post do
          interactor = FinishedGoodsApp::DispatchInteractor.new(current_user, {}, { route_url: request.path }, {})

          load_id = params[:load][:load_id]
          res = interactor.validate_load_truck(load_id)
          if res.success
            r.redirect("/rmd/dispatch/load_truck/load/#{res.instance}")
          else
            store_locally(:res, res)
            r.redirect('/rmd/dispatch/load_truck/load')
          end
        end
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
