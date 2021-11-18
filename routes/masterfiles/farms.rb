# frozen_string_literal: true

class Nspack < Roda
  route 'farms', 'masterfiles' do |r|
    # PRODUCTION REGIONS
    # --------------------------------------------------------------------------
    r.on 'production_regions', Integer do |id|
      interactor = MasterfilesApp::ProductionRegionInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      # Check for notfound:
      r.on !interactor.exists?(:production_regions, id) do
        handle_not_found(r)
      end

      r.on 'edit' do   # EDIT
        check_auth!('farms', 'edit')
        interactor.assert_permission!(:edit, id)
        show_partial { Masterfiles::Farms::ProductionRegion::Edit.call(id) }
      end

      r.is do
        r.get do       # SHOW
          check_auth!('farms', 'read')
          show_partial { Masterfiles::Farms::ProductionRegion::Show.call(id) }
        end
        r.patch do     # UPDATE
          res = interactor.update_production_region(id, params[:production_region])
          if res.success
            row_keys = %i[
              id
              production_region_code
              description
              inspection_region
            ]
            update_grid_row(id, changes: select_attributes(res.instance, row_keys), notice: res.message)
          else
            re_show_form(r, res) { Masterfiles::Farms::ProductionRegion::Edit.call(id, form_values: params[:production_region], form_errors: res.errors) }
          end
        end
        r.delete do    # DELETE
          check_auth!('farms', 'delete')
          interactor.assert_permission!(:delete, id)
          res = interactor.delete_production_region(id)
          if res.success
            delete_grid_row(id, notice: res.message)
          else
            show_json_error(res.message, status: 200)
          end
        end
      end
    end

    r.on 'production_regions' do
      interactor = MasterfilesApp::ProductionRegionInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})
      r.on 'new' do    # NEW
        check_auth!('farms', 'new')
        show_partial_or_page(r) { Masterfiles::Farms::ProductionRegion::New.call(remote: fetch?(r)) }
      end
      r.post do        # CREATE
        res = interactor.create_production_region(params[:production_region])
        if res.success
          row_keys = %i[
            id
            production_region_code
            description
            inspection_region
          ]
          add_grid_row(attrs: select_attributes(res.instance, row_keys),
                       notice: res.message)
        else
          re_show_form(r, res, url: '/masterfiles/farms/production_regions/new') do
            Masterfiles::Farms::ProductionRegion::New.call(form_values: params[:production_region],
                                                           form_errors: res.errors,
                                                           remote: fetch?(r))
          end
        end
      end
    end

    # FARM GROUPS
    # --------------------------------------------------------------------------
    r.on 'farm_groups', Integer do |id|
      interactor = MasterfilesApp::FarmGroupInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      # Check for notfound:
      r.on !interactor.exists?(:farm_groups, id) do
        handle_not_found(r)
      end

      r.on 'edit' do   # EDIT
        check_auth!('farms', 'edit')
        interactor.assert_permission!(:edit, id)
        show_partial { Masterfiles::Farms::FarmGroup::Edit.call(id) }
      end

      r.is do
        r.get do       # SHOW
          check_auth!('farms', 'read')
          show_partial { Masterfiles::Farms::FarmGroup::Show.call(id) }
        end
        r.patch do     # UPDATE
          res = interactor.update_farm_group(id, params[:farm_group])
          if res.success
            update_grid_row(id, changes: { owner_party_role_id: res.instance[:owner_party_role_id], farm_group_code: res.instance[:farm_group_code], description: res.instance[:description] }, notice: res.message)
          else
            re_show_form(r, res) { Masterfiles::Farms::FarmGroup::Edit.call(id, form_values: params[:farm_group], form_errors: res.errors) }
          end
        end
        r.delete do    # DELETE
          check_auth!('farms', 'delete')
          interactor.assert_permission!(:delete, id)
          res = interactor.delete_farm_group(id)
          if res.success
            delete_grid_row(id, notice: res.message)
          else
            show_json_error(res.message, status: 200)
          end
        end
      end
    end

    r.on 'farm_groups' do
      interactor = MasterfilesApp::FarmGroupInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})
      r.on 'new' do    # NEW
        check_auth!('farms', 'new')
        show_partial_or_page(r) { Masterfiles::Farms::FarmGroup::New.call(remote: fetch?(r)) }
      end
      r.post do        # CREATE
        res = interactor.create_farm_group(params[:farm_group])
        if res.success
          row_keys = %i[
            id
            owner_party_role_id
            farm_group_code
            description
            active
          ]
          add_grid_row(attrs: select_attributes(res.instance, row_keys),
                       notice: res.message)
        else
          re_show_form(r, res, url: '/masterfiles/farms/farm_groups/new') do
            Masterfiles::Farms::FarmGroup::New.call(form_values: params[:farm_group],
                                                    form_errors: res.errors,
                                                    remote: fetch?(r))
          end
        end
      end
    end

    # FARMS
    # --------------------------------------------------------------------------
    r.on 'farms', Integer do |id|
      interactor = MasterfilesApp::FarmInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      # Check for notfound:
      r.on !interactor.exists?(:farms, id) do
        handle_not_found(r)
      end

      r.on 'edit' do   # EDIT
        check_auth!('farms', 'edit')
        interactor.assert_permission!(:edit, id)
        show_partial { Masterfiles::Farms::Farm::Edit.call(id) }
      end

      r.on 'owner_party_role_changed' do
        farm_groups = interactor.selected_farm_groups(params[:changed_value])
        json_replace_select_options('farm_farm_group_id', farm_groups)
      end

      r.on 'list_farm_orchards' do
        check_auth!('farms', 'edit')
        r.redirect "/list/orchards/with_params?key=standard&orchards.farm_id=#{id}"
      end

      r.on 'list_farm_sections' do
        check_auth!('farms', 'edit')
        r.redirect "/list/farm_sections/with_params?key=standard&farm_sections.farm_id=#{id}"
      end

      r.on 'link_farm_pucs' do
        r.post do
          res = interactor.associate_farms_pucs(id, multiselect_grid_choices(params))
          if fetch?(r)
            update_grid_row(id, changes: { puc_codes: res.instance }, notice: res.message)
          else
            flash[:notice] = res.message
            r.redirect '/list/pucs'
          end
        end
      end

      r.on 'new_farm_section' do    # NEW
        r.get do
          check_auth!('farms', 'new')
          show_partial_or_page(r) { Masterfiles::Farms::FarmSection::New.call(id, remote: fetch?(r)) }
        end

        r.post do        # CREATE
          res = interactor.create_farm_section(id, params[:farm_section])
          if res.success
            row_keys = %i[
              id
              farm_manager_party_role_id
              farm_section_name
              description
              orchards
              farm_manager_party_role
            ]
            add_grid_row(attrs: select_attributes(res.instance, row_keys),
                         notice: res.message)
          else
            re_show_form(r, res, url: "/masterfiles/farms/farms/#{id}/new_farm_section") do
              Masterfiles::Farms::FarmSection::New.call(id,
                                                        form_values: params[:farm_section],
                                                        form_errors: res.errors,
                                                        remote: fetch?(r))
            end
          end
        end
      end

      r.on 'orchards' do
        interactor = MasterfilesApp::OrchardInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})
        r.on 'new' do
          check_auth!('farms', 'new')
          show_partial_or_page(r) { Masterfiles::Farms::Orchard::New.call(id, remote: fetch?(r)) }
        end

        r.post do        # CREATE
          res = interactor.create_orchard(params[:orchard])
          if res.success
            row_keys = %i[
              id
              farm_id
              puc_id
              orchard_code
              description
              active
              cultivar_ids
              puc_code
              cultivar_names
            ]
            json_actions([OpenStruct.new(type: :replace_input_value,
                                         dom_id: 'orchard_orchard_code',
                                         value: ''),
                          OpenStruct.new(type: :replace_input_value,
                                         dom_id: 'orchard_description',
                                         value: ''),
                          OpenStruct.new(type: :clear_form_validation,
                                         dom_id: 'orchard_form'),
                          OpenStruct.new(type: :add_grid_row,
                                         attrs: select_attributes(res.instance, row_keys))],
                         res.message,
                         keep_dialog_open: true)
          else
            re_show_form(r, res, url: "/masterfiles/farms/farms/#{id}/orchards/new") do
              Masterfiles::Farms::Orchard::New.call(id,
                                                    form_values: params[:orchard],
                                                    form_errors: res.errors,
                                                    remote: fetch?(r))
            end
          end
        end
      end

      r.is do
        r.get do       # SHOW
          check_auth!('farms', 'read')
          show_partial { Masterfiles::Farms::Farm::Show.call(id) }
        end
        r.patch do     # UPDATE
          res = interactor.update_farm(id, params[:farm])
          if res.success
            row_keys = %i[
              owner_party_role_id
              pdn_region_id
              farm_group_id
              farm_code
              description
              farm_group_code
              owner_party_role
              pdn_region_production_region_code
              active
              location_long_code
            ]
            update_grid_row(id, changes: select_attributes(res.instance, row_keys), notice: res.message)
          else
            re_show_form(r, res) { Masterfiles::Farms::Farm::Edit.call(id, form_values: params[:farm], form_errors: res.errors) }
          end
        end
        r.delete do    # DELETE
          check_auth!('farms', 'delete')
          interactor.assert_permission!(:delete, id)
          res = interactor.delete_farm(id)
          if res.success
            delete_grid_row(id, notice: res.message)
          else
            show_json_error(res.message, status: 200)
          end
        end
      end
    end

    r.on 'farms' do
      interactor = MasterfilesApp::FarmInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})
      r.on 'new' do    # NEW
        check_auth!('farms', 'new')
        show_partial_or_page(r) { Masterfiles::Farms::Farm::New.call(remote: fetch?(r)) }
      end
      r.post do        # CREATE
        res = interactor.create_farm(params[:farm])
        if res.success
          row_keys = %i[
            id
            owner_party_role_id
            pdn_region_id
            farm_group_id
            farm_code
            description
            farm_group_code
            owner_party_role
            pdn_region_production_region_code
            active
            location_long_code
          ]
          add_grid_row(attrs: select_attributes(res.instance, row_keys),
                       notice: res.message)
        else
          re_show_form(r, res, url: '/masterfiles/farms/farms/new') do
            Masterfiles::Farms::Farm::New.call(form_values: params[:farm],
                                               form_errors: res.errors,
                                               remote: fetch?(r))
          end
        end
      end
    end

    # ORCHARDS
    # --------------------------------------------------------------------------
    r.on 'orchards', Integer do |id|
      interactor = MasterfilesApp::OrchardInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})
      # Check for notfound:
      r.on !interactor.exists?(:orchards, id) do
        handle_not_found(r)
      end

      r.on 'edit' do   # EDIT
        check_auth!('farms', 'edit')
        interactor.assert_permission!(:edit, id)
        show_partial { Masterfiles::Farms::Orchard::Edit.call(id) }
      end

      r.on 'farm_changed' do
        farm_pucs = interactor.selected_farm_pucs(params[:changed_value])
        json_replace_select_options('orchard_puc_id', farm_pucs)
      end

      r.is do
        r.get do       # SHOW
          check_auth!('farms', 'read')
          show_partial { Masterfiles::Farms::Orchard::Show.call(id) }
        end
        r.patch do     # UPDATE
          res = interactor.update_orchard(id, params[:orchard])
          if res.success
            row_keys = %i[
              farm_id
              puc_id
              orchard_code
              description
              active
              cultivar_ids
              puc_code
              cultivar_names
            ]
            update_grid_row(id, changes: select_attributes(res.instance, row_keys), notice: res.message)
          else
            re_show_form(r, res) { Masterfiles::Farms::Orchard::Edit.call(id, form_values: params[:orchard], form_errors: res.errors) }
          end
        end
        r.delete do    # DELETE
          check_auth!('farms', 'delete')
          interactor.assert_permission!(:delete, id)
          res = interactor.delete_orchard(id)
          if res.success
            delete_grid_row(id, notice: res.message)
          else
            show_json_error(res.message, status: 200)
          end
        end
      end
    end

    # PUCS
    # --------------------------------------------------------------------------
    r.on 'pucs', Integer do |id|
      interactor = MasterfilesApp::PucInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})
      # Check for notfound:
      r.on !interactor.exists?(:pucs, id) do
        handle_not_found(r)
      end

      r.on 'edit' do   # EDIT
        check_auth!('farms', 'edit')
        interactor.assert_permission!(:edit, id)
        show_partial { Masterfiles::Farms::Puc::Edit.call(id) }
      end

      r.is do
        r.get do       # SHOW
          check_auth!('farms', 'read')
          show_partial { Masterfiles::Farms::Puc::Show.call(id) }
        end
        r.patch do     # UPDATE
          res = interactor.update_puc(id, params[:puc])
          if res.success
            update_grid_row(id, changes: { puc_code: res.instance[:puc_code], gap_code: res.instance[:gap_code],
                                           gap_code_valid_from: res.instance[:gap_code_valid_from],
                                           gap_code_valid_until: res.instance[:gap_code_valid_until] }, notice: res.message)
          else
            re_show_form(r, res) { Masterfiles::Farms::Puc::Edit.call(id, form_values: params[:puc], form_errors: res.errors) }
          end
        end
        r.delete do    # DELETE
          check_auth!('farms', 'delete')
          interactor.assert_permission!(:delete, id)
          res = interactor.delete_puc(id)
          if res.success
            delete_grid_row(id, notice: res.message)
          else
            show_json_error(res.message, status: 200)
          end
        end
      end
    end

    r.on 'pucs' do
      interactor = MasterfilesApp::PucInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})
      r.on 'new' do    # NEW
        check_auth!('farms', 'new')
        show_partial_or_page(r) { Masterfiles::Farms::Puc::New.call(remote: fetch?(r)) }
      end
      r.post do        # CREATE
        res = interactor.create_puc(params[:puc])
        if res.success
          row_keys = %i[
            id
            puc_code
            gap_code
            active
            gap_code_valid_from
            gap_code_valid_until
          ]
          add_grid_row(attrs: select_attributes(res.instance, row_keys),
                       notice: res.message)
        else
          re_show_form(r, res, url: '/masterfiles/farms/pucs/new') do
            Masterfiles::Farms::Puc::New.call(form_values: params[:puc],
                                              form_errors: res.errors,
                                              remote: fetch?(r))
          end
        end
      end
    end

    # RMT CONTAINER TYPES
    # --------------------------------------------------------------------------
    r.on 'rmt_container_types', Integer do |id|
      interactor = MasterfilesApp::RmtContainerTypeInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      # Check for notfound:
      r.on !interactor.exists?(:rmt_container_types, id) do
        handle_not_found(r)
      end

      r.on 'edit' do   # EDIT
        check_auth!('farms', 'edit')
        interactor.assert_permission!(:edit, id)
        show_partial { Masterfiles::Farms::RmtContainerType::Edit.call(id) }
      end

      r.is do
        r.get do       # SHOW
          check_auth!('farms', 'read')
          show_partial { Masterfiles::Farms::RmtContainerType::Show.call(id) }
        end
        r.patch do     # UPDATE
          res = interactor.update_rmt_container_type(id, params[:rmt_container_type])
          if res.success
            update_grid_row(id, changes: {
                              container_type_code: res.instance[:container_type_code],
                              inner_container_type: res.instance[:rmt_inner_container_type],
                              description: res.instance[:description]
                            },
                                notice: res.message)
          else
            re_show_form(r, res) { Masterfiles::Farms::RmtContainerType::Edit.call(id, form_values: params[:rmt_container_type], form_errors: res.errors) }
          end
        end
        r.delete do    # DELETE
          check_auth!('farms', 'delete')
          interactor.assert_permission!(:delete, id)
          res = interactor.delete_rmt_container_type(id)
          if res.success
            delete_grid_row(id, notice: res.message)
          else
            show_json_error(res.message, status: 200)
          end
        end
      end
    end

    r.on 'rmt_container_types' do
      interactor = MasterfilesApp::RmtContainerTypeInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})
      r.on 'new' do    # NEW
        check_auth!('farms', 'new')
        show_partial_or_page(r) { Masterfiles::Farms::RmtContainerType::New.call(remote: fetch?(r)) }
      end
      r.post do        # CREATE
        res = interactor.create_rmt_container_type(params[:rmt_container_type])
        if res.success
          row_keys = %i[
            id
            container_type_code
            inner_container_type
            description
          ]
          add_grid_row(attrs: select_attributes(res.instance, row_keys),
                       notice: res.message)
        else
          re_show_form(r, res, url: '/masterfiles/farms/rmt_container_types/new') do
            Masterfiles::Farms::RmtContainerType::New.call(form_values: params[:rmt_container_type],
                                                           form_errors: res.errors,
                                                           remote: fetch?(r))
          end
        end
      end
    end

    # RMT CONTAINER MATERIAL TYPES
    # --------------------------------------------------------------------------
    r.on 'rmt_container_material_types', Integer do |id|
      interactor = MasterfilesApp::RmtContainerMaterialTypeInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      # Check for notfound:
      r.on !interactor.exists?(:rmt_container_material_types, id) do
        handle_not_found(r)
      end

      r.on 'edit' do   # EDIT
        check_auth!('farms', 'edit')
        interactor.assert_permission!(:edit, id)
        show_partial { Masterfiles::Farms::RmtContainerMaterialType::Edit.call(id) }
      end

      r.is do
        r.get do       # SHOW
          check_auth!('farms', 'read')
          show_partial { Masterfiles::Farms::RmtContainerMaterialType::Show.call(id) }
        end
        r.patch do     # UPDATE
          res = interactor.update_rmt_container_material_type(id, params[:rmt_container_material_type])
          if res.success
            update_grid_row(id, changes: { rmt_container_type_id: res.instance[:rmt_container_type_id], container_material_type_code: res.instance[:container_material_type_code],
                                           description: res.instance[:description], tare_weight: res.instance[:tare_weight] },
                                notice: res.message)
          else
            re_show_form(r, res) { Masterfiles::Farms::RmtContainerMaterialType::Edit.call(id, form_values: params[:rmt_container_material_type], form_errors: res.errors) }
          end
        end
        r.delete do    # DELETE
          check_auth!('farms', 'delete')
          interactor.assert_permission!(:delete, id)
          res = interactor.delete_rmt_container_material_type(id)
          if res.success
            delete_grid_row(id, notice: res.message)
          else
            show_json_error(res.message, status: 200)
          end
        end
      end
    end

    r.on 'rmt_container_material_types' do
      interactor = MasterfilesApp::RmtContainerMaterialTypeInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})
      r.on 'new' do    # NEW
        check_auth!('farms', 'new')
        show_partial_or_page(r) { Masterfiles::Farms::RmtContainerMaterialType::New.call(remote: fetch?(r)) }
      end
      r.post do        # CREATE
        res = interactor.create_rmt_container_material_type(params[:rmt_container_material_type])
        if res.success
          row_keys = %i[
            id
            rmt_container_type_id
            container_material_type_code
            description
            tare_weight
          ]
          add_grid_row(attrs: select_attributes(res.instance, row_keys),
                       notice: res.message)
        else
          re_show_form(r, res, url: '/masterfiles/farms/rmt_container_material_types/new') do
            Masterfiles::Farms::RmtContainerMaterialType::New.call(form_values: params[:rmt_container_material_type],
                                                                   form_errors: res.errors,
                                                                   remote: fetch?(r))
          end
        end
      end
    end

    # FARM SECTIONS
    # --------------------------------------------------------------------------
    r.on 'farm_sections', Integer do |id|
      interactor = MasterfilesApp::FarmInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      # Check for notfound:
      r.on !interactor.exists?(:farm_sections, id) do
        handle_not_found(r)
      end

      r.on 'edit' do   # EDIT
        check_auth!('farms', 'edit')
        # interactor.assert_permission!(:edit, id)
        show_partial { Masterfiles::Farms::FarmSection::Edit.call(id) }
      end

      r.is do
        r.get do       # SHOW
          check_auth!('farms', 'read')
          show_partial { Masterfiles::Farms::FarmSection::Show.call(id) }
        end
        r.patch do     # UPDATE
          res = interactor.update_farm_section(id, params[:farm_section])
          if res.success
            update_grid_row(id, changes: { farm_manager_party_role: res.instance[:farm_manager_party_role],
                                           farm_section_name: res.instance[:farm_section_name],
                                           orchards: res.instance[:orchards],
                                           description: res.instance[:description] },
                                notice: res.message)
          else
            re_show_form(r, res) { Masterfiles::Farms::FarmSection::Edit.call(id, form_values: params[:farm_section], form_errors: res.errors) }
          end
        end
        r.delete do    # DELETE
          check_auth!('farms', 'delete')
          interactor.assert_permission!(:delete, id)
          res = interactor.delete_farm_section(id)
          if res.success
            delete_grid_row(id, notice: res.message)
          else
            show_json_error(res.message, status: 200)
          end
        end
      end
    end

    # REGISTERED ORCHARDS
    # --------------------------------------------------------------------------
    r.on 'registered_orchards', Integer do |id|
      interactor = MasterfilesApp::RegisteredOrchardInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      # Check for notfound:
      r.on !interactor.exists?(:registered_orchards, id) do
        handle_not_found(r)
      end

      r.on 'edit' do   # EDIT
        check_auth!('farms', 'edit')
        interactor.assert_permission!(:edit, id)
        show_partial { Masterfiles::Farms::RegisteredOrchard::Edit.call(id) }
      end

      r.is do
        r.get do       # SHOW
          check_auth!('farms', 'read')
          show_partial { Masterfiles::Farms::RegisteredOrchard::Show.call(id) }
        end
        r.patch do     # UPDATE
          res = interactor.update_registered_orchard(id, params[:registered_orchard])
          if res.success
            row_keys = %i[
              orchard_code
              cultivar_code
              puc_code
              description
              marketing_orchard
            ]
            update_grid_row(id, changes: select_attributes(res.instance, row_keys), notice: res.message)
          else
            re_show_form(r, res) { Masterfiles::Farms::RegisteredOrchard::Edit.call(id, form_values: params[:registered_orchard], form_errors: res.errors) }
          end
        end
        r.delete do    # DELETE
          check_auth!('farms', 'delete')
          interactor.assert_permission!(:delete, id)
          res = interactor.delete_registered_orchard(id)
          if res.success
            delete_grid_row(id, notice: res.message)
          else
            show_json_error(res.message, status: 200)
          end
        end
      end
    end

    r.on 'registered_orchards' do
      interactor = MasterfilesApp::RegisteredOrchardInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})
      r.on 'new' do    # NEW
        check_auth!('farms', 'new')
        show_partial_or_page(r) { Masterfiles::Farms::RegisteredOrchard::New.call(remote: fetch?(r)) }
      end
      r.post do        # CREATE
        res = interactor.create_registered_orchard(params[:registered_orchard])
        if res.success
          row_keys = %i[
            id
            orchard_code
            cultivar_code
            puc_code
            description
            marketing_orchard
            active
          ]
          add_grid_row(attrs: select_attributes(res.instance, row_keys),
                       notice: res.message)
        else
          re_show_form(r, res, url: '/masterfiles/farms/registered_orchards/new') do
            Masterfiles::Farms::RegisteredOrchard::New.call(form_values: params[:registered_orchard],
                                                            form_errors: res.errors,
                                                            remote: fetch?(r))
          end
        end
      end
    end
  end
end
