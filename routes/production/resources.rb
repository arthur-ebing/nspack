# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
class Nspack < Roda # rubocop:disable Metrics/ClassLength
  route 'resources', 'production' do |r|
    # RESOURCE TYPES
    # --------------------------------------------------------------------------
    r.on 'plant_resource_types', Integer do |id|
      interactor = ProductionApp::ResourceTypeInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      # Check for notfound:
      r.on !interactor.exists?(:plant_resource_types, id) do
        handle_not_found(r)
      end

      r.on 'edit' do   # EDIT
        check_auth!('resources', 'edit')
        # interactor.assert_permission!(:edit, id)
        show_partial { Production::Resources::PlantResourceType::Edit.call(id) }
      end

      r.is do
        r.get do       # SHOW
          check_auth!('resources', 'read')
          show_partial { Production::Resources::PlantResourceType::Show.call(id) }
        end
        r.patch do     # UPDATE
          res = interactor.update_plant_resource_type(id, params[:plant_resource_type])
          if res.success
            row_keys = %i[
              plant_resource_type_code
              description
              attribute_rules
              behaviour_rules
            ]
            update_grid_row(id, changes: select_attributes(res.instance, row_keys), notice: res.message)
          else
            re_show_form(r, res) { Production::Resources::PlantResourceType::Edit.call(id, form_values: params[:plant_resource_type], form_errors: res.errors) }
          end
        end
        r.delete do    # DELETE >>>>>>>>>>>>>>>>>>> THIS SHOULD BE de-activate (only if not in use by active plant_resource) <<<<<<<<<<<<<<<
          check_auth!('resources', 'delete')
          # interactor.assert_permission!(:delete, id)
          res = interactor.delete_plant_resource_type(id)
          if res.success
            delete_grid_row(id, notice: res.message)
          else
            show_json_error(res.message, status: 200)
          end
        end
      end
    end

    r.on 'plant_resource_types' do
      interactor = ProductionApp::ResourceTypeInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})
      r.on 'new' do    # NEW
        check_auth!('resources', 'new')
        show_partial_or_page(r) { Production::Resources::PlantResourceType::New.call(remote: fetch?(r)) }
      end
      r.on 'refresh' do
        check_auth!('resources', 'new')
        msg = Crossbeams::Config::ResourceDefinitions.refresh_plant_resource_types
        flash[:notice] = msg
        redirect_to_last_grid(r)
      end
      r.post do        # CREATE
        res = interactor.create_plant_resource_type(params[:plant_resource_type])
        if res.success
          row_keys = %i[
            id
            plant_resource_type_code
            description
            attribute_rules
            behaviour_rules
          ]
          add_grid_row(attrs: select_attributes(res.instance, row_keys),
                       notice: res.message)
        else
          re_show_form(r, res, url: '/production/resources/plant_resource_types/new') do
            Production::Resources::PlantResourceType::New.call(form_values: params[:plant_resource_type],
                                                               form_errors: res.errors,
                                                               remote: fetch?(r))
          end
        end
      end
    end

    # PLANT RESOURCES
    # --------------------------------------------------------------------------
    r.on 'plant_resources', Integer do |id|
      interactor = ProductionApp::ResourceInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      # Check for notfound:
      r.on !interactor.exists?(:plant_resources, id) do
        handle_not_found(r)
      end

      r.on 'edit' do   # EDIT
        check_auth!('resources', 'edit')
        # interactor.assert_permission!(:edit, id)
        show_partial { Production::Resources::PlantResource::Edit.call(id) }
      end

      r.on 'add_child' do   # NEW CHILD
        r.get do
          check_auth!('resources', 'edit')
          interactor.assert_permission!(:add_child, id)
          show_partial { Production::Resources::PlantResource::New.call(id: id) }
        end
        r.post do
          res = interactor.create_plant_resource(id, params[:plant_resource])
          if res.success
            flash[:notice] = res.message
            redirect_to_last_grid(r)
          else
            re_show_form(r, res, url: "/production/resources/plant_resources/#{id}/add_child") do
              Production::Resources::PlantResource::New.call(id: id,
                                                             form_values: params[:plant_resource],
                                                             form_errors: res.errors,
                                                             remote: fetch?(r))
            end
          end
        end
      end

      r.on 'bulk_add' do
        r.on 'clm' do
          r.get do
            interactor.assert_permission!(:bulk_add_clm, id)
            show_partial { Production::Resources::PlantResource::BulkAddClm.call(id: id) }
          end
          r.post do
            res = interactor.bulk_add_clms(id, params[:resource])
            if res.success
              flash[:notice] = res.message
              redirect_to_last_grid(r)
            else
              re_show_form(r, res) { Production::Resources::PlantResource::BulkAddClm.call(id: id, form_values: params[:resource], form_errors: res.errors) }
            end
          end
        end

        r.on 'ptm' do
          r.get do
            interactor.assert_permission!(:bulk_add_ptm, id)
            show_partial { Production::Resources::PlantResource::BulkAddPtm.call(id: id) }
          end
          r.post do
            res = interactor.bulk_add_ptms(id, params[:resource])
            if res.success
              flash[:notice] = res.message
              redirect_to_last_grid(r)
            else
              re_show_form(r, res) { Production::Resources::PlantResource::BulkAddPtm.call(id: id, form_values: params[:resource], form_errors: res.errors) }
            end
          end
        end
      end

      r.on 'link_peripherals' do
        r.post do
          res = interactor.link_peripherals(id, multiselect_grid_choices(params))
          if fetch?(r)
            update_grid_row(id, changes: { linked_resources: res.instance }, notice: res.message)
          else
            flash[:notice] = res.message
            redirect_to_last_grid(r)
          end
        end
      end

      r.is do
        r.get do       # SHOW
          check_auth!('resources', 'read')
          show_partial { Production::Resources::PlantResource::Show.call(id) }
        end
        r.patch do     # UPDATE
          res = interactor.update_plant_resource(id, params[:plant_resource])
          if res.success
            flash[:notice] = res.message
            redirect_to_last_grid(r)
          else
            re_show_form(r, res) { Production::Resources::PlantResource::Edit.call(id, form_values: params[:plant_resource], form_errors: res.errors) }
          end
        end

        r.delete do    # DELETE
          check_auth!('resources', 'delete')
          # interactor.assert_permission!(:delete, id)
          res = interactor.delete_plant_resource(id)
          if res.success
            delete_grid_row(id, notice: res.message)
          else
            show_json_error(res.message, status: 200)
          end
        end
      end
    end

    r.on 'plant_resources' do
      interactor = ProductionApp::ResourceInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})
      r.on 'new' do    # NEW
        check_auth!('resources', 'new')
        show_partial_or_page(r) { Production::Resources::PlantResource::New.call(remote: fetch?(r)) }
      end

      r.on 'add_buttons' do
        interactor.add_3_4_buttons
        'DONE'
      end

      r.on 'next_code' do
        res = interactor.next_peripheral_code(params[:changed_value])
        json_actions(
          [
            OpenStruct.new(type: :replace_input_value, dom_id: 'plant_resource_plant_resource_code', value: res.instance[:next_code]),
            OpenStruct.new(type: :set_readonly, dom_id: 'plant_resource_plant_resource_code', readonly: res.instance[:readonly])
          ]
        )
      end

      r.on 'lookup_location', Integer do |location_id|
        res = interactor.get_location_lookup(location_id)
        json_actions([OpenStruct.new(type: :replace_input_value,
                                     dom_id: 'plant_resource_location_id',
                                     value: location_id),
                      OpenStruct.new(type: :replace_input_value,
                                     dom_id: 'plant_resource_location_long_code',
                                     value: res.instance.location_long_code)],
                     'Selected location')
      end

      r.post do        # CREATE
        res = interactor.create_root_plant_resource(params[:plant_resource])
        if res.success
          flash[:notice] = res.message
          redirect_to_last_grid(r)
        else
          re_show_form(r, res, url: '/production/resources/plant_resources/new') do
            Production::Resources::PlantResource::New.call(form_values: params[:plant_resource],
                                                           form_errors: res.errors,
                                                           remote: fetch?(r))
          end
        end
      end
    end

    # SYSTEM RESOURCE TYPES
    # --------------------------------------------------------------------------
    r.on 'system_resource_types', Integer do |id|
      interactor = ProductionApp::ResourceTypeInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      # Check for notfound:
      r.on !interactor.exists?(:system_resource_types, id) do
        handle_not_found(r)
      end

      r.is do
        r.get do       # SHOW
          check_auth!('resources', 'read')
          show_partial { Production::Resources::SystemResourceType::Show.call(id) }
        end
        r.delete do    # DELETE
          check_auth!('resources', 'delete')
          # interactor.assert_permission!(:delete, id)
          res = interactor.delete_system_resource_type(id)
          if res.success
            delete_grid_row(id, notice: res.message)
          else
            show_json_error(res.message, status: 200)
          end
        end
      end
    end

    # SYSTEM RESOURCES
    # --------------------------------------------------------------------------
    r.on 'system_resources', Integer do |id|
      interactor = ProductionApp::ResourceInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      # Check for notfound:
      r.on !interactor.exists?(:system_resources, id) do
        handle_not_found(r)
      end

      r.on 'set_module' do
        r.get do
          check_auth!('resources', 'edit')
          show_partial { Production::Resources::SystemResource::SetModule.call(id) }
        end
        r.post do
          res = interactor.set_module_resource(id, params[:system_resource])
          if res.success
            row_keys = %i[
              equipment_type
              module_function
              mac_address
              ip_address
              port
              ttl
              cycle_time
              publishing
              login
              logoff
              module_action
            ]
            update_grid_row(id, changes: select_attributes(res.instance, row_keys), notice: res.message)
          else
            re_show_form(r, res) { Production::Resources::SystemResource::SetModule.call(id, form_values: params[:system_resource], form_errors: res.errors) }
          end
        end
      end

      r.on 'set_peripheral' do
        r.get do
          check_auth!('resources', 'edit')
          show_partial { Production::Resources::SystemResource::SetPeripheral.call(id) }
        end
        r.post do
          res = interactor.set_peripheral_resource(id, params[:system_resource])
          if res.success
            row_keys = %i[
              equipment_type
              ip_address
              port
              ttl
              cycle_time
              peripheral_model
              connection_type
              printer_language
              print_username
              print_password
              pixels_mm
            ]
            update_grid_row(id, changes: select_attributes(res.instance, row_keys), notice: res.message)
          else
            re_show_form(r, res) { Production::Resources::SystemResource::SetModule.call(id, form_values: params[:system_resource], form_errors: res.errors) }
          end
        end
      end
    end

    r.on 'system_resources' do
      interactor = ProductionApp::ResourceInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      check_auth!('resources', 'read')
      res = interactor.system_resource_xml
      show_page { Production::Resources::SystemResource::ShowXml.call(res) }
      # view(inline: res.instance[:modules].to_s)
    end
  end
end
# rubocop:enable Metrics/BlockLength
