# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
class Nspack < Roda # rubocop:disable Metrics/ClassLength
  route 'shipping', 'masterfiles' do |r|
    # VEHICLE TYPES
    # --------------------------------------------------------------------------
    r.on 'vehicle_types', Integer do |id|
      interactor = MasterfilesApp::VehicleTypeInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      # Check for notfound:
      r.on !interactor.exists?(:vehicle_types, id) do
        handle_not_found(r)
      end

      r.on 'edit' do   # EDIT
        check_auth!('shipping', 'edit')
        interactor.assert_permission!(:edit, id)
        show_partial { Masterfiles::Shipping::VehicleType::Edit.call(id) }
      end

      r.is do
        r.get do       # SHOW
          check_auth!('shipping', 'read')
          show_partial { Masterfiles::Shipping::VehicleType::Show.call(id) }
        end
        r.patch do     # UPDATE
          res = interactor.update_vehicle_type(id, params[:vehicle_type])
          if res.success
            update_grid_row(id, changes: { vehicle_type_code: res.instance[:vehicle_type_code], description: res.instance[:description], has_container: res.instance[:has_container] },
                                notice: res.message)
          else
            re_show_form(r, res) { Masterfiles::Shipping::VehicleType::Edit.call(id, form_values: params[:vehicle_type], form_errors: res.errors) }
          end
        end
        r.delete do    # DELETE
          check_auth!('shipping', 'delete')
          interactor.assert_permission!(:delete, id)
          res = interactor.delete_vehicle_type(id)
          if res.success
            delete_grid_row(id, notice: res.message)
          else
            show_json_error(res.message, status: 200)
          end
        end
      end
    end

    r.on 'vehicle_types' do
      interactor = MasterfilesApp::VehicleTypeInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})
      r.on 'new' do    # NEW
        check_auth!('shipping', 'new')
        show_partial_or_page(r) { Masterfiles::Shipping::VehicleType::New.call(remote: fetch?(r)) }
      end
      r.post do        # CREATE
        res = interactor.create_vehicle_type(params[:vehicle_type])
        if res.success
          row_keys = %i[
            id
            vehicle_type_code
            description
            has_container
            active
          ]
          add_grid_row(attrs: select_attributes(res.instance, row_keys),
                       notice: res.message)
        else
          re_show_form(r, res, url: '/masterfiles/shipping/vehicle_types/new') do
            Masterfiles::Shipping::VehicleType::New.call(form_values: params[:vehicle_type],
                                                         form_errors: res.errors,
                                                         remote: fetch?(r))
          end
        end
      end
    end

    # VOYAGE TYPES
    # --------------------------------------------------------------------------
    r.on 'voyage_types', Integer do |id|
      interactor = MasterfilesApp::VoyageTypeInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      # Check for notfound:
      r.on !interactor.exists?(:voyage_types, id) do
        handle_not_found(r)
      end

      r.on 'edit' do   # EDIT
        check_auth!('shipping', 'edit')
        interactor.assert_permission!(:edit, id)
        show_partial { Masterfiles::Shipping::VoyageType::Edit.call(id) }
      end

      r.is do
        r.get do       # SHOW
          check_auth!('shipping', 'read')
          show_partial { Masterfiles::Shipping::VoyageType::Show.call(id) }
        end
        r.patch do     # UPDATE
          res = interactor.update_voyage_type(id, params[:voyage_type])
          if res.success
            update_grid_row(id, changes: { voyage_type_code: res.instance[:voyage_type_code],
                                           industry_description: res.instance[:industry_description],
                                           description: res.instance[:description] }, notice: res.message)
          else
            re_show_form(r, res) { Masterfiles::Shipping::VoyageType::Edit.call(id, form_values: params[:voyage_type], form_errors: res.errors) }
          end
        end
        r.delete do    # DELETE
          check_auth!('shipping', 'delete')
          interactor.assert_permission!(:delete, id)
          res = interactor.delete_voyage_type(id)
          if res.success
            delete_grid_row(id, notice: res.message)
          else
            show_json_error(res.message, status: 200)
          end
        end
      end
    end

    r.on 'voyage_types' do
      interactor = MasterfilesApp::VoyageTypeInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})
      r.on 'new' do    # NEW
        check_auth!('shipping', 'new')
        show_partial_or_page(r) { Masterfiles::Shipping::VoyageType::New.call(remote: fetch?(r)) }
      end
      r.post do        # CREATE
        res = interactor.create_voyage_type(params[:voyage_type])
        if res.success
          row_keys = %i[
            id
            voyage_type_code
            industry_description
            description
            active
          ]
          add_grid_row(attrs: select_attributes(res.instance, row_keys), notice: res.message)
        else
          re_show_form(r, res, url: '/masterfiles/shipping/voyage_types/new') do
            Masterfiles::Shipping::VoyageType::New.call(form_values: params[:voyage_type],
                                                        form_errors: res.errors,
                                                        remote: fetch?(r))
          end
        end
      end
    end

    # PORT TYPES
    # --------------------------------------------------------------------------
    r.on 'port_types', Integer do |id|
      interactor = MasterfilesApp::PortTypeInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      # Check for notfound:
      r.on !interactor.exists?(:port_types, id) do
        handle_not_found(r)
      end

      r.on 'edit' do   # EDIT
        check_auth!('shipping', 'edit')
        interactor.assert_permission!(:edit, id)
        show_partial { Masterfiles::Shipping::PortType::Edit.call(id) }
      end

      r.is do
        r.get do       # SHOW
          check_auth!('shipping', 'read')
          show_partial { Masterfiles::Shipping::PortType::Show.call(id) }
        end
        r.patch do     # UPDATE
          res = interactor.update_port_type(id, params[:port_type])
          if res.success
            update_grid_row(id, changes: { port_type_code: res.instance[:port_type_code],
                                           description: res.instance[:description] }, notice: res.message)
          else
            re_show_form(r, res) { Masterfiles::Shipping::PortType::Edit.call(id, form_values: params[:port_type], form_errors: res.errors) }
          end
        end
        r.delete do    # DELETE
          check_auth!('shipping', 'delete')
          interactor.assert_permission!(:delete, id)
          res = interactor.delete_port_type(id)
          if res.success
            delete_grid_row(id, notice: res.message)
          else
            show_json_error(res.message, status: 200)
          end
        end
      end
    end

    r.on 'port_types' do
      interactor = MasterfilesApp::PortTypeInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})
      r.on 'new' do    # NEW
        check_auth!('shipping', 'new')
        show_partial_or_page(r) { Masterfiles::Shipping::PortType::New.call(remote: fetch?(r)) }
      end
      r.post do        # CREATE
        res = interactor.create_port_type(params[:port_type])
        if res.success
          row_keys = %i[
            id
            port_type_code
            description
            active
          ]
          add_grid_row(attrs: select_attributes(res.instance, row_keys),
                       notice: res.message)
        else
          re_show_form(r, res, url: '/masterfiles/shipping/port_types/new') do
            Masterfiles::Shipping::PortType::New.call(form_values: params[:port_type],
                                                      form_errors: res.errors,
                                                      remote: fetch?(r))
          end
        end
      end
    end

    # PORTS
    # --------------------------------------------------------------------------
    r.on 'ports', Integer do |id|
      interactor = MasterfilesApp::PortInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      # Check for notfound:
      r.on !interactor.exists?(:ports, id) do
        handle_not_found(r)
      end

      r.on 'edit' do   # EDIT
        check_auth!('shipping', 'edit')
        interactor.assert_permission!(:edit, id)
        show_partial { Masterfiles::Shipping::Port::Edit.call(id) }
      end

      r.is do
        r.get do       # SHOW
          check_auth!('shipping', 'read')
          show_partial { Masterfiles::Shipping::Port::Show.call(id) }
        end
        r.patch do     # UPDATE
          res = interactor.update_port(id, params[:port])
          if res.success
            row_keys = %i[
              port_code
              city_name
              description
              port_type_codes
              voyage_type_codes
              active
            ]
            update_grid_row(id, changes: select_attributes(res.instance, row_keys), notice: res.message)
          else
            re_show_form(r, res) { Masterfiles::Shipping::Port::Edit.call(id, form_values: params[:port], form_errors: res.errors) }
          end
        end
        r.delete do    # DELETE
          check_auth!('shipping', 'delete')
          interactor.assert_permission!(:delete, id)
          res = interactor.delete_port(id)
          if res.success
            delete_grid_row(id, notice: res.message)
          else
            show_json_error(res.message, status: 200)
          end
        end
      end
    end

    r.on 'ports' do
      interactor = MasterfilesApp::PortInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})
      r.on 'new' do    # NEW
        check_auth!('shipping', 'new')
        show_partial_or_page(r) { Masterfiles::Shipping::Port::New.call(remote: fetch?(r)) }
      end
      r.post do        # CREATE
        res = interactor.create_port(params[:port])
        if res.success
          row_keys = %i[
            id
            port_code
            city_name
            description
            port_type_codes
            voyage_type_codes
            active
          ]
          add_grid_row(attrs: select_attributes(res.instance, row_keys),
                       notice: res.message)
        else
          re_show_form(r, res, url: '/masterfiles/shipping/ports/new') do
            Masterfiles::Shipping::Port::New.call(form_values: params[:port],
                                                  form_errors: res.errors,
                                                  remote: fetch?(r))
          end
        end
      end
    end

    # VESSEL TYPES
    # --------------------------------------------------------------------------
    r.on 'vessel_types', Integer do |id|
      interactor = MasterfilesApp::VesselTypeInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      # Check for notfound:
      r.on !interactor.exists?(:vessel_types, id) do
        handle_not_found(r)
      end

      r.on 'edit' do   # EDIT
        check_auth!('shipping', 'edit')
        interactor.assert_permission!(:edit, id)
        show_partial { Masterfiles::Shipping::VesselType::Edit.call(id) }
      end

      r.is do
        r.get do       # SHOW
          check_auth!('shipping', 'read')
          show_partial { Masterfiles::Shipping::VesselType::Show.call(id) }
        end
        r.patch do     # UPDATE
          res = interactor.update_vessel_type(id, params[:vessel_type])
          if res.success
            update_grid_row(id, changes: { vessel_type_id: res.instance[:vessel_type_id],
                                           vessel_type_code: res.instance[:vessel_type_code],
                                           description: res.instance[:description] }, notice: res.message)
          else
            re_show_form(r, res) { Masterfiles::Shipping::VesselType::Edit.call(id, form_values: params[:vessel_type], form_errors: res.errors) }
          end
        end
        r.delete do    # DELETE
          check_auth!('shipping', 'delete')
          interactor.assert_permission!(:delete, id)
          res = interactor.delete_vessel_type(id)
          if res.success
            delete_grid_row(id, notice: res.message)
          else
            show_json_error(res.message, status: 200)
          end
        end
      end
    end

    r.on 'vessel_types' do
      interactor = MasterfilesApp::VesselTypeInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})
      r.on 'new' do    # NEW
        check_auth!('shipping', 'new')
        show_partial_or_page(r) { Masterfiles::Shipping::VesselType::New.call(remote: fetch?(r)) }
      end
      r.post do        # CREATE
        res = interactor.create_vessel_type(params[:vessel_type])
        if res.success
          row_keys = %i[
            id
            vessel_type_id
            vessel_type_code
            voyage_type_code
            description
            active
          ]
          add_grid_row(attrs: select_attributes(res.instance, row_keys),
                       notice: res.message)
        else
          re_show_form(r, res, url: '/masterfiles/shipping/vessel_types/new') do
            Masterfiles::Shipping::VesselType::New.call(form_values: params[:vessel_type],
                                                        form_errors: res.errors,
                                                        remote: fetch?(r))
          end
        end
      end
    end

    # VESSELS
    # --------------------------------------------------------------------------
    r.on 'vessels', Integer do |id|
      interactor = MasterfilesApp::VesselInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      # Check for notfound:
      r.on !interactor.exists?(:vessels, id) do
        handle_not_found(r)
      end

      r.on 'edit' do   # EDIT
        check_auth!('shipping', 'edit')
        interactor.assert_permission!(:edit, id)
        show_partial { Masterfiles::Shipping::Vessel::Edit.call(id) }
      end

      r.is do
        r.get do       # SHOW
          check_auth!('shipping', 'read')
          show_partial { Masterfiles::Shipping::Vessel::Show.call(id) }
        end
        r.patch do     # UPDATE
          res = interactor.update_vessel(id, params[:vessel])
          if res.success
            row_keys = %i[
              id
              vessel_type_id
              vessel_code
              description
              vessel_type_code
              voyage_type_code
              active
            ]
            update_grid_row(id, changes: select_attributes(res.instance, row_keys), notice: res.message)
          else
            re_show_form(r, res) { Masterfiles::Shipping::Vessel::Edit.call(id, form_values: params[:vessel], form_errors: res.errors) }
          end
        end
        r.delete do    # DELETE
          check_auth!('shipping', 'delete')
          interactor.assert_permission!(:delete, id)
          res = interactor.delete_vessel(id)
          if res.success
            delete_grid_row(id, notice: res.message)
          else
            show_json_error(res.message, status: 200)
          end
        end
      end
    end

    r.on 'vessels' do
      interactor = MasterfilesApp::VesselInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})
      r.on 'new' do    # NEW
        check_auth!('shipping', 'new')
        show_partial_or_page(r) { Masterfiles::Shipping::Vessel::New.call(remote: fetch?(r)) }
      end
      r.post do        # CREATE
        res = interactor.create_vessel(params[:vessel])
        if res.success
          row_keys = %i[
            id
            vessel_type_id
            vessel_code
            description
            vessel_type_code
            voyage_type_code
            active
          ]
          add_grid_row(attrs: select_attributes(res.instance, row_keys), notice: res.message)
        else
          re_show_form(r, res, url: '/masterfiles/shipping/vessels/new') do
            Masterfiles::Shipping::Vessel::New.call(form_values: params[:vessel],
                                                    form_errors: res.errors,
                                                    remote: fetch?(r))
          end
        end
      end
    end

    # DEPOTS
    # --------------------------------------------------------------------------
    r.on 'depots', Integer do |id|
      interactor = MasterfilesApp::DepotInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      # Check for notfound:
      r.on !interactor.exists?(:depots, id) do
        handle_not_found(r)
      end

      r.on 'edit' do   # EDIT
        check_auth!('shipping', 'edit')
        interactor.assert_permission!(:edit, id)
        show_partial { Masterfiles::Shipping::Depot::Edit.call(id) }
      end

      r.is do
        r.get do       # SHOW
          check_auth!('shipping', 'read')
          show_partial { Masterfiles::Shipping::Depot::Show.call(id) }
        end
        r.patch do     # UPDATE
          res = interactor.update_depot(id, params[:depot])
          if res.success
            row_keys = %i[
              city_id
              city_name
              depot_code
              bin_depot
              description
            ]
            update_grid_row(id, changes: select_attributes(res.instance, row_keys), notice: res.message)
          else
            re_show_form(r, res) { Masterfiles::Shipping::Depot::Edit.call(id, form_values: params[:depot], form_errors: res.errors) }
          end
        end
        r.delete do    # DELETE
          check_auth!('shipping', 'delete')
          interactor.assert_permission!(:delete, id)
          res = interactor.delete_depot(id)
          if res.success
            delete_grid_row(id, notice: res.message)
          else
            show_json_error(res.message, status: 200)
          end
        end
      end
    end

    r.on 'depots' do
      interactor = MasterfilesApp::DepotInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})
      r.on 'new' do    # NEW
        check_auth!('shipping', 'new')
        show_partial_or_page(r) { Masterfiles::Shipping::Depot::New.call(remote: fetch?(r)) }
      end
      r.post do        # CREATE
        res = interactor.create_depot(params[:depot])
        if res.success
          row_keys = %i[
            id
            city_id
            depot_code
            description
            city_name
            bin_depot
            active
          ]
          add_grid_row(attrs: select_attributes(res.instance, row_keys),
                       notice: res.message)
        else
          re_show_form(r, res, url: '/masterfiles/shipping/depots/new') do
            Masterfiles::Shipping::Depot::New.call(form_values: params[:depot],
                                                   form_errors: res.errors,
                                                   remote: fetch?(r))
          end
        end
      end
    end

    # CARGO TEMPERATURES
    # --------------------------------------------------------------------------
    r.on 'cargo_temperatures', Integer do |id|
      interactor = MasterfilesApp::CargoTemperatureInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      # Check for notfound:
      r.on !interactor.exists?(:cargo_temperatures, id) do
        handle_not_found(r)
      end

      r.on 'edit' do   # EDIT
        check_auth!('shipping', 'edit')
        interactor.assert_permission!(:edit, id)
        show_partial { Masterfiles::Shipping::CargoTemperature::Edit.call(id) }
      end

      r.is do
        r.get do       # SHOW
          check_auth!('shipping', 'read')
          show_partial { Masterfiles::Shipping::CargoTemperature::Show.call(id) }
        end
        r.patch do     # UPDATE
          res = interactor.update_cargo_temperature(id, params[:cargo_temperature])
          if res.success
            row_keys = %i[
              temperature_code
              description
              set_point_temperature
              load_temperature
            ]
            update_grid_row(id, changes: select_attributes(res.instance, row_keys), notice: res.message)
          else
            re_show_form(r, res) { Masterfiles::Shipping::CargoTemperature::Edit.call(id, form_values: params[:cargo_temperature], form_errors: res.errors) }
          end
        end
        r.delete do    # DELETE
          check_auth!('shipping', 'delete')
          interactor.assert_permission!(:delete, id)
          res = interactor.delete_cargo_temperature(id)
          if res.success
            delete_grid_row(id, notice: res.message)
          else
            show_json_error(res.message, status: 200)
          end
        end
      end
    end

    r.on 'cargo_temperatures' do
      interactor = MasterfilesApp::CargoTemperatureInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})
      r.on 'new' do    # NEW
        check_auth!('shipping', 'new')
        show_partial_or_page(r) { Masterfiles::Shipping::CargoTemperature::New.call(remote: fetch?(r)) }
      end
      r.post do        # CREATE
        res = interactor.create_cargo_temperature(params[:cargo_temperature])
        if res.success
          row_keys = %i[
            id
            temperature_code
            description
            set_point_temperature
            load_temperature
            active
          ]
          add_grid_row(attrs: select_attributes(res.instance, row_keys),
                       notice: res.message)
        else
          re_show_form(r, res, url: '/masterfiles/shipping/cargo_temperatures/new') do
            Masterfiles::Shipping::CargoTemperature::New.call(form_values: params[:cargo_temperature],
                                                              form_errors: res.errors,
                                                              remote: fetch?(r))
          end
        end
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
