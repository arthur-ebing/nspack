# frozen_string_literal: true

class Nspack < Roda
  route 'dispatch', 'raw_materials' do |r|
    # BIN LOAD PURPOSES
    # --------------------------------------------------------------------------
    r.on 'bin_load_purposes', Integer do |id|
      interactor = RawMaterialsApp::BinLoadPurposeInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      # Check for notfound:
      r.on !interactor.exists?(:bin_load_purposes, id) do
        handle_not_found(r)
      end

      r.on 'edit' do   # EDIT
        check_auth!('dispatch', 'edit')
        interactor.assert_permission!(:edit, id)
        show_partial { RawMaterials::Dispatch::BinLoadPurpose::Edit.call(id) }
      end

      r.is do
        r.get do       # SHOW
          check_auth!('dispatch', 'read')
          show_partial { RawMaterials::Dispatch::BinLoadPurpose::Show.call(id) }
        end
        r.patch do     # UPDATE
          res = interactor.update_bin_load_purpose(id, params[:bin_load_purpose])
          if res.success
            update_grid_row(id, changes: { purpose_code: res.instance[:purpose_code], description: res.instance[:description] },
                                notice: res.message)
          else
            re_show_form(r, res) { RawMaterials::Dispatch::BinLoadPurpose::Edit.call(id, form_values: params[:bin_load_purpose], form_errors: res.errors) }
          end
        end
        r.delete do    # DELETE
          check_auth!('dispatch', 'delete')
          interactor.assert_permission!(:delete, id)
          res = interactor.delete_bin_load_purpose(id)
          if res.success
            delete_grid_row(id, notice: res.message)
          else
            show_json_error(res.message, status: 200)
          end
        end
      end
    end

    r.on 'bin_load_purposes' do
      interactor = RawMaterialsApp::BinLoadPurposeInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})
      r.on 'new' do    # NEW
        check_auth!('dispatch', 'new')
        show_partial_or_page(r) { RawMaterials::Dispatch::BinLoadPurpose::New.call(remote: fetch?(r)) }
      end
      r.post do        # CREATE
        res = interactor.create_bin_load_purpose(params[:bin_load_purpose])
        if res.success
          row_keys = %i[
            id
            purpose_code
            description
            active
          ]
          add_grid_row(attrs: select_attributes(res.instance, row_keys),
                       notice: res.message)
        else
          re_show_form(r, res, url: '/raw_materials/dispatch/bin_load_purposes/new') do
            RawMaterials::Dispatch::BinLoadPurpose::New.call(form_values: params[:bin_load_purpose],
                                                             form_errors: res.errors,
                                                             remote: fetch?(r))
          end
        end
      end
    end

    # BIN LOADS
    # --------------------------------------------------------------------------
    r.on 'bin_loads', Integer do |id|
      interactor = RawMaterialsApp::BinLoadInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      # Check for notfound:
      r.on !interactor.exists?(:bin_loads, id) do
        handle_not_found(r)
      end

      # BIN LOAD PRODUCTS
      # --------------------------------------------------------------------------
      r.on 'bin_load_products' do
        interactor = RawMaterialsApp::BinLoadProductInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

        r.on 'new' do    # NEW
          check_auth!('dispatch', 'new')
          show_partial_or_page(r) { RawMaterials::Dispatch::BinLoadProduct::New.call(id, remote: fetch?(r)) }
        end
        r.post do        # CREATE
          res = interactor.create_bin_load_product(params[:bin_load_product])
          if res.success
            flash[:notice] = res.message
            redirect_via_json "/raw_materials/dispatch/bin_loads/#{id}"
          else
            re_show_form(r, res, url: "/raw_materials/dispatch/bin_loads/#{id}/bin_load_products/new") do
              RawMaterials::Dispatch::BinLoadProduct::New.call(id,
                                                               form_values: params[:bin_load_product],
                                                               form_errors: res.errors,
                                                               remote: fetch?(r))
            end
          end
        end
      end

      # BIN LOADS
      r.on 'complete' do
        check_auth!('dispatch', 'edit')
        res = interactor.complete_bin_load(id)
        flash[res.success ? :notice : :error] = res.message
        r.redirect "/raw_materials/dispatch/bin_loads/#{id}"
      end

      r.on 'reopen' do
        check_auth!('dispatch', 'edit')
        res = interactor.reopen_bin_load(id)
        flash[res.success ? :notice : :error] = res.message
        r.redirect "/raw_materials/dispatch/bin_loads/#{id}"
      end

      r.on 'unallocate' do
        check_auth!('dispatch', 'edit')
        res = interactor.unallocate_bin_load(id)
        flash[res.success ? :notice : :error] = res.message
        r.redirect "/raw_materials/dispatch/bin_loads/#{id}"
      end

      r.on 'ship' do
        check_auth!('dispatch', 'edit')
        res = interactor.ship_bin_load(id)
        flash[res.success ? :notice : :error] = res.message
        r.redirect "/raw_materials/dispatch/bin_loads/#{id}"
      end

      r.on 'shipped_at' do
        r.get do       # SHIP
          check_auth!('dispatch', 'edit')
          show_partial_or_page(r) { RawMaterials::Dispatch::BinLoad::Ship.call(id) }
        end

        r.post do # UPDATE
          res = interactor.shipped_at_bin_load(id, params[:bin_load])
          if res.success
            flash[:notice] = res.message
            r.redirect '/list/bin_loads'
          else
            re_show_form(r, res, url: "/raw_materials/dispatch/bin_loads/#{id}/shipped_at") do
              RawMaterials::Dispatch::BinLoad::Ship.call(id, form_values: params[:bin_load], form_errors: res.errors)
            end
          end
        end
      end

      r.on 'unship' do
        check_auth!('dispatch', 'edit')
        res = interactor.unship_bin_load(id)
        flash[res.success ? :notice : :error] = res.message
        r.redirect "/raw_materials/dispatch/bin_loads/#{id}"
      end

      r.on 're_send_hbs_edi' do
        check_auth!('dispatch', 'edit')
        res = interactor.send_hbs_edi(id)
        update_dialog_content(content: wrap_content_in_style(res.message, res.success ? :success : :error, caption: ''))
      end

      r.on 'delete' do    # DELETE
        check_auth!('dispatch', 'delete')
        res = interactor.delete_bin_load(id)
        flash[res.success ? :notice : :error] = res.message
        r.redirect "/raw_materials/dispatch/bin_loads/#{id}"
      end

      r.on 'edit' do   # EDIT
        check_auth!('dispatch', 'edit')
        interactor.assert_permission!(:edit, id)
        show_partial_or_page(r) { RawMaterials::Dispatch::BinLoad::Edit.call(id) }
      end

      r.is do
        r.get do       # SHOW
          check_auth!('dispatch', 'read')
          show_partial_or_page(r) { RawMaterials::Dispatch::BinLoad::Show.call(id) }
        end

        r.patch do     # UPDATE
          res = interactor.update_bin_load(id, params[:bin_load])
          if res.success
            flash[:notice] = res.message
            r.redirect "/raw_materials/dispatch/bin_loads/#{id}"
          else
            re_show_form(r, res, url: "/raw_materials/dispatch/bin_loads/#{id}/edit") do
              RawMaterials::Dispatch::BinLoad::Edit.call(id, form_values: params[:bin_load], form_errors: res.errors)
            end
          end
        end
      end
    end

    r.on 'bin_loads' do
      interactor = RawMaterialsApp::BinLoadInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})
      r.on 'new' do    # NEW
        check_auth!('dispatch', 'new')
        show_partial_or_page(r) { RawMaterials::Dispatch::BinLoad::New.call(remote: fetch?(r)) }
      end
      r.post do        # CREATE
        res = interactor.create_bin_load(params[:bin_load])
        if res.success
          flash[:notice] = res.message
          redirect_via_json "/raw_materials/dispatch/bin_loads/#{res.instance.id}"
        else
          re_show_form(r, res, url: '/raw_materials/dispatch/bin_loads/new') do
            RawMaterials::Dispatch::BinLoad::New.call(form_values: params[:bin_load],
                                                      form_errors: res.errors,
                                                      remote: fetch?(r))
          end
        end
      end
    end

    # BIN LOAD PRODUCTS
    # --------------------------------------------------------------------------
    r.on 'bin_load_products', Integer do |id|
      interactor = RawMaterialsApp::BinLoadProductInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      # Check for notfound:
      r.on !interactor.exists?(:bin_load_products, id) do
        handle_not_found(r)
      end

      r.on 'edit' do   # EDIT
        check_auth!('dispatch', 'edit')
        interactor.assert_permission!(:edit, id)
        show_partial { RawMaterials::Dispatch::BinLoadProduct::Edit.call(id) }
      end

      r.on 'allocate' do
        check_auth!('dispatch', 'edit')
        show_partial_or_page(r) { RawMaterials::Dispatch::BinLoadProduct::Allocate.call(id) }
      end

      r.on 'scan_bins' do
        r.get do
          check_auth!('dispatch', 'edit')
          show_partial_or_page(r) { RawMaterials::Dispatch::BinLoadProduct::ScanBins.call(id) }
        end
        r.patch do
          res = interactor.allocate_scanned_bin_load_product(id, params[:bin_load_product])
          if res.success
            flash[:notice] = res.message
            r.redirect "/raw_materials/dispatch/bin_load_products/#{id}/allocate"
          else
            re_show_form(r, res, url: "/raw_materials/dispatch/bin_load_products/#{id}/scan_bins") do
              RawMaterials::Dispatch::BinLoadProduct::ScanBins.call(id,
                                                                    form_values: params[:bin_load_product],
                                                                    form_errors: res.errors)
            end
          end
        end
      end

      r.on 'allocate_multiselect' do
        check_auth!('dispatch', 'edit')
        interactor.assert_permission!(:edit, id)
        res = interactor.allocate_bin_load_product(id, bin_ids: multiselect_grid_choices(params))
        flash[res.success ? :notice : :error] = res.message
        r.redirect "/raw_materials/dispatch/bin_load_products/#{id}/allocate"
      end

      r.is do
        r.get do       # SHOW
          check_auth!('dispatch', 'read')
          show_partial { RawMaterials::Dispatch::BinLoadProduct::Show.call(id) }
        end
        r.patch do     # UPDATE
          res = interactor.update_bin_load_product(id, params[:bin_load_product])
          if res.success
            flash[:notice] = res.message
            redirect_via_json "/raw_materials/dispatch/bin_loads/#{res.instance.bin_load_id}"
          else
            re_show_form(r, res) { RawMaterials::Dispatch::BinLoadProduct::Edit.call(id, form_values: params[:bin_load_product], form_errors: res.errors) }
          end
        end
        r.delete do    # DELETE
          check_auth!('dispatch', 'delete')
          interactor.assert_permission!(:delete, id)
          res = interactor.delete_bin_load_product(id)
          if res.success
            redirect_via_json "/raw_materials/dispatch/bin_loads/#{res.instance.bin_load_id}"
          else
            show_json_error(res.message, status: 200)
          end
        end
      end
    end

    r.on 'bin_load_products' do
      r.on 'cultivar_group_changed' do
        actions = []
        list = if params[:changed_value].nil_or_empty?
                 MasterfilesApp::CultivarRepo.new.for_select_cultivars
               else
                 MasterfilesApp::CultivarRepo.new.for_select_cultivars(where: { cultivar_group_id: params[:changed_value] })
               end
        actions << OpenStruct.new(type: :replace_select_options, dom_id: 'bin_load_product_cultivar_id', options_array: list)
        json_actions(actions)
      end

      r.on 'rmt_container_material_type_changed' do
        actions = []
        repo = MasterfilesApp::PartyRepo.new
        list = if params[:changed_value].nil_or_empty?
                 repo.for_select_party_roles(AppConst::ROLE_RMT_BIN_OWNER)
               else
                 party_role_ids = repo.select_values(:rmt_container_material_owners, :rmt_material_owner_party_role_id, rmt_container_material_type_id: params[:changed_value])
                 repo.for_select_party_roles(AppConst::ROLE_RMT_BIN_OWNER, where: { id: party_role_ids })
               end
        actions << OpenStruct.new(type: :replace_select_options, dom_id: 'bin_load_product_rmt_material_owner_party_role_id', options_array: list)
        json_actions(actions)
      end

      r.on 'farm_changed' do
        actions = []
        puc_list = if params[:changed_value].nil_or_empty?
                     MasterfilesApp::FarmRepo.new.for_select_pucs
                   else
                     MasterfilesApp::FarmRepo.new.for_select_pucs(where: { farm_id: params[:changed_value] })
                   end
        actions << OpenStruct.new(type: :replace_select_options, dom_id: 'bin_load_product_puc_id', options_array: puc_list)
        json_actions(actions)
      end

      r.on 'puc_changed' do
        actions = []
        if params[:changed_value].nil_or_empty?
          show_hide_element = :hide_element
          orchard_list = []
        else
          show_hide_element = :show_element
          orchard_list = MasterfilesApp::FarmRepo.new.for_select_orchards(where: { puc_id: params[:changed_value] })
        end
        actions << OpenStruct.new(type: show_hide_element, dom_id: 'bin_load_product_orchard_id_field_wrapper')
        actions << OpenStruct.new(type: :replace_select_options, dom_id: 'bin_load_product_orchard_id', options_array: orchard_list)
        json_actions(actions)
      end
    end
  end
end
