# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
class Nspack < Roda # rubocop:disable Metrics/ClassLength
  route 'dispatch', 'rmd' do |r|
    # TRUCK ARRIVAL
    # --------------------------------------------------------------------------
    r.on 'truck_arrival' do
      # --------------------------------------------------------------------------
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

          form.add_field(:load_id, 'Load', scan: 'key248_all', required: true)
          form.add_csrf_tag csrf_tag
          view(inline: form.render, layout: :layout_rmd)
        end

        r.post do
          interactor = FinishedGoodsApp::LoadVehicleInteractor.new(current_user, {}, { route_url: request.path }, {})

          load_id = params[:load][:load_id]
          res = interactor.validate_load(load_id)
          if res.success
            r.redirect("/rmd/dispatch/truck_arrival/load_vehicles/#{res.instance[:load_id]}")
          else
            store_locally(:res, res)
            r.redirect('/rmd/dispatch/truck_arrival/load')
          end
        end
      end

      r.on 'load_vehicles', Integer do |load_id|
        r.on 'vehicle_type_changed' do
          if params[:changed_value].nil_or_empty?
            blank_json_response
          else
            value = MasterfilesApp::VehicleTypeRepo.new.find_vehicle_type(params[:changed_value])&.has_container
            json_change_select_value('load_vehicle_container', value)
          end
        end

        r.get do
          # find and initiate load_vehicle
          id = FinishedGoodsApp::LoadVehicleRepo.new.find_load_vehicles_by_load(load_id)
          form_state = FinishedGoodsApp::LoadVehicleRepo.new.find_load_vehicle(id).to_h
          form_state[:container] = MasterfilesApp::VehicleTypeRepo.new.find_vehicle_type(form_state[:vehicle_type_id])&.has_container.to_s
          form_state[:container] = 'true' unless FinishedGoodsApp::LoadContainerRepo.new.find_load_container_by_load(load_id).nil?

          # over ride instance if rmd_form had previous attempt
          res = retrieve_from_local_store(:res)
          unless res.nil?
            form_state = res.instance
            form_state[:error_message] = res.message
            form_state[:errors] = res.errors
          end

          form = Crossbeams::RMDForm.new(form_state,
                                         form_name: :load_vehicle,
                                         scan_with_camera: @rmd_scan_with_camera,
                                         notes: retrieve_from_local_store(:flash_notice),
                                         caption: 'Capture Vehicle',
                                         action: "/rmd/dispatch/truck_arrival/load_vehicles/#{load_id}",
                                         button_caption: 'Submit')

          form.behaviours do |behaviour|
            behaviour.dropdown_change :vehicle_type_id, notify: [{ url: "/rmd/dispatch/truck_arrival/load_vehicles/#{load_id}/vehicle_type_changed" }]
          end

          form.add_label(:id, 'load_vehicle_id', id, id, hide_on_load: true)
          form.add_label(:load_id, 'Load', load_id, load_id)
          form.add_field(:vehicle_number,
                         'Vehicle Number',
                         data_type: 'string')
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
                         required: false)
          form.add_select(:container,
                          'Container',
                          value: form_state[:container],
                          items: [false, true])
          form.add_csrf_tag csrf_tag
          view(inline: form.render, layout: :layout_rmd)
        end

        r.post do
          interactor = FinishedGoodsApp::LoadVehicleInteractor.new(current_user, {}, { route_url: request.path }, {})
          attrs = params[:load_vehicle]

          id = attrs[:id]
          # if load_vehicle exists
          res = id.nil_or_empty? ? interactor.create_load_vehicle(attrs) : interactor.update_load_vehicle(id, attrs)

          if res.success
            store_locally(:flash_notice, res.message)
            r.redirect("/rmd/dispatch/truck_arrival/load_containers/#{load_id}") if attrs[:container] == 'true'
            r.redirect('/rmd/dispatch/truck_arrival/load')
          else
            store_locally(:res, res)
            r.redirect("/rmd/dispatch/truck_arrival/load_vehicles/#{load_id}")
          end
        end
      end

      r.on 'load_containers', Integer do |load_id|
        r.get do
          # set defaults
          form_state = {}
          form_state[:verified_gross_weight_date] = Time.now

          # check if load_container exists
          id = FinishedGoodsApp::LoadContainerRepo.new.find_load_container_by_load(load_id)
          form_state = FinishedGoodsApp::LoadContainerRepo.new.find_load_container(id).to_h unless id.nil?

          # check if redirect from form error
          res = retrieve_from_local_store(:res)
          unless res.nil?
            form_state = res.instance
            form_state[:error_message] = res.message
            form_state[:errors] = res.errors
          end

          form = Crossbeams::RMDForm.new(form_state,
                                         form_name: :load_container,
                                         scan_with_camera: @rmd_scan_with_camera,
                                         notes: retrieve_from_local_store(:flash_notice),
                                         caption: 'Capture Container',
                                         action: "/rmd/dispatch/truck_arrival/load_containers/#{load_id}",
                                         button_caption: 'Submit')

          form.add_label(:id, 'load_container_id', id, id, hide_on_load: true)
          form.add_label(:load_id, 'Load', load_id, load_id)
          form.add_field(:container_code,
                         'Container Code',
                         data_type: 'string')
          form.add_field(:container_vents,
                         'Container Vents',
                         data_type: 'string')
          form.add_field(:container_seal_code,
                         'Container Seal Code',
                         data_type: 'string')
          form.add_field(:internal_container_code,
                         'Internal Container Code',
                         data_type: 'string')
          form.add_field(:container_temperature_rhine,
                         'Temperature Rhine',
                         data_type: 'number',
                         allow_decimals: true)
          form.add_field(:container_temperature_rhine2,
                         'Temperature Rhine2',
                         data_type: 'number',
                         allow_decimals: true,
                         required: false)
          form.add_field(:max_gross_weight,
                         'Max Gross Weight',
                         data_type: 'number',
                         allow_decimals: true)
          form.add_field(:tare_weight,
                         'Tare Weight',
                         data_type: 'number',
                         allow_decimals: true)
          form.add_field(:max_payload,
                         'Max Payload',
                         data_type: 'number',
                         allow_decimals: true)
          form.add_field(:actual_payload,
                         'Actual Payload',
                         data_type: 'number',
                         allow_decimals: true)
          form.add_select(:cargo_temperature_id,
                          'Cargo Temperature',
                          # disabled_items: MasterfilesApp::CargoTemperatureRepo.new.for_select_inactive_cargo_temperatures,
                          items: MasterfilesApp::CargoTemperatureRepo.new.for_select_cargo_temperatures,
                          prompt: true)
          form.add_select(:stack_type_id,
                          'Stack Type',
                          # disabled_items: MasterfilesApp::LoadContainerRepo.new.for_select_inactive_container_stack_types,
                          items: FinishedGoodsApp::LoadContainerRepo.new.for_select_container_stack_types)
          form.add_field(:verified_gross_weight,
                         'Verified Gross Weight',
                         data_type: 'number',
                         allow_decimals: true)
          form.add_label(:verified_gross_weight_date,
                         'Verified Gross Weight Date',
                         form_state[:verified_gross_weight_date],
                         form_state[:verified_gross_weight_date],
                         hide_on_load: false)
          form.add_csrf_tag csrf_tag
          view(inline: form.render, layout: :layout_rmd)
        end

        r.post do
          interactor = FinishedGoodsApp::LoadContainerInteractor.new(current_user, {}, { route_url: request.path }, {})
          attrs = params[:load_container]

          id = attrs[:id]
          # if load_container exists
          res = id.nil_or_empty? ? interactor.create_load_container(attrs) : interactor.update_load_container(id, attrs)

          if res.success
            store_locally(:flash_notice, res.message)
            r.redirect('/rmd/dispatch/truck_arrival/load')
          else
            store_locally(:res, res)
            r.redirect("/rmd/dispatch/truck_arrival/load_containers/#{load_id}")
          end
        end
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
