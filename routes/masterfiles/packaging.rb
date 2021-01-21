# frozen_string_literal: true

class Nspack < Roda # rubocop:disable Metrics/ClassLength
  route 'packaging', 'masterfiles' do |r| # rubocop:disable Metrics/BlockLength
    # PALLET BASES
    # --------------------------------------------------------------------------
    r.on 'pallet_bases', Integer do |id| # rubocop:disable Metrics/BlockLength
      interactor = MasterfilesApp::PalletBaseInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      # Check for notfound:
      r.on !interactor.exists?(:pallet_bases, id) do
        handle_not_found(r)
      end

      r.on 'edit' do   # EDIT
        check_auth!('packaging', 'edit')
        interactor.assert_permission!(:edit, id)
        show_partial { Masterfiles::Packaging::PalletBase::Edit.call(id) }
      end

      r.is do # rubocop:disable Metrics/BlockLength
        r.get do       # SHOW
          check_auth!('packaging', 'read')
          show_partial { Masterfiles::Packaging::PalletBase::Show.call(id) }
        end
        r.patch do     # UPDATE
          res = interactor.update_pallet_base(id, params[:pallet_base])
          if res.success
            row_keys = %i[
              pallet_base_code
              description
              length
              width
              edi_in_pallet_base
              edi_out_pallet_base
              cartons_per_layer
              material_mass
              active
            ]
            update_grid_row(id, changes: select_attributes(res.instance, row_keys), notice: res.message)
          else
            re_show_form(r, res) { Masterfiles::Packaging::PalletBase::Edit.call(id, form_values: params[:pallet_base], form_errors: res.errors) }
          end
        end
        r.delete do    # DELETE
          check_auth!('packaging', 'delete')
          interactor.assert_permission!(:delete, id)
          res = interactor.delete_pallet_base(id)
          if res.success
            delete_grid_row(id, notice: res.message)
          else
            show_json_error(res.message, status: 200)
          end
        end
      end
    end

    r.on 'pallet_bases' do # rubocop:disable Metrics/BlockLength
      interactor = MasterfilesApp::PalletBaseInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})
      r.on 'new' do    # NEW
        check_auth!('packaging', 'new')
        show_partial_or_page(r) { Masterfiles::Packaging::PalletBase::New.call(remote: fetch?(r)) }
      end
      r.post do        # CREATE
        res = interactor.create_pallet_base(params[:pallet_base])
        if res.success
          row_keys = %i[
            id
            pallet_base_code
            description
            length
            width
            edi_in_pallet_base
            edi_out_pallet_base
            cartons_per_layer
            material_mass
            active
          ]
          add_grid_row(attrs: select_attributes(res.instance, row_keys),
                       notice: res.message)
        else
          re_show_form(r, res, url: '/masterfiles/packaging/pallet_bases/new') do
            Masterfiles::Packaging::PalletBase::New.call(form_values: params[:pallet_base],
                                                         form_errors: res.errors,
                                                         remote: fetch?(r))
          end
        end
      end
    end

    # PALLET STACK TYPES
    # --------------------------------------------------------------------------
    r.on 'pallet_stack_types', Integer do |id| # rubocop:disable Metrics/BlockLength
      interactor = MasterfilesApp::PalletStackTypeInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      # Check for notfound:
      r.on !interactor.exists?(:pallet_stack_types, id) do
        handle_not_found(r)
      end

      r.on 'edit' do   # EDIT
        check_auth!('packaging', 'edit')
        interactor.assert_permission!(:edit, id)
        show_partial { Masterfiles::Packaging::PalletStackType::Edit.call(id) }
      end

      r.is do
        r.get do       # SHOW
          check_auth!('packaging', 'read')
          show_partial { Masterfiles::Packaging::PalletStackType::Show.call(id) }
        end
        r.patch do     # UPDATE
          res = interactor.update_pallet_stack_type(id, params[:pallet_stack_type])
          if res.success
            update_grid_row(id, changes: { stack_type_code: res.instance[:stack_type_code], description: res.instance[:description], stack_height: res.instance[:stack_height] },
                                notice: res.message)
          else
            re_show_form(r, res) { Masterfiles::Packaging::PalletStackType::Edit.call(id, form_values: params[:pallet_stack_type], form_errors: res.errors) }
          end
        end
        r.delete do    # DELETE
          check_auth!('packaging', 'delete')
          interactor.assert_permission!(:delete, id)
          res = interactor.delete_pallet_stack_type(id)
          if res.success
            delete_grid_row(id, notice: res.message)
          else
            show_json_error(res.message, status: 200)
          end
        end
      end
    end

    r.on 'pallet_stack_types' do
      interactor = MasterfilesApp::PalletStackTypeInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})
      r.on 'new' do    # NEW
        check_auth!('packaging', 'new')
        show_partial_or_page(r) { Masterfiles::Packaging::PalletStackType::New.call(remote: fetch?(r)) }
      end
      r.post do        # CREATE
        res = interactor.create_pallet_stack_type(params[:pallet_stack_type])
        if res.success
          row_keys = %i[
            id
            stack_type_code
            description
            stack_height
            active
          ]
          add_grid_row(attrs: select_attributes(res.instance, row_keys),
                       notice: res.message)
        else
          re_show_form(r, res, url: '/masterfiles/packaging/pallet_stack_types/new') do
            Masterfiles::Packaging::PalletStackType::New.call(form_values: params[:pallet_stack_type],
                                                              form_errors: res.errors,
                                                              remote: fetch?(r))
          end
        end
      end
    end

    # PALLET FORMATS
    # --------------------------------------------------------------------------
    r.on 'pallet_formats', Integer do |id| # rubocop:disable Metrics/BlockLength
      interactor = MasterfilesApp::PalletFormatInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      # Check for notfound:
      r.on !interactor.exists?(:pallet_formats, id) do
        handle_not_found(r)
      end

      r.on 'edit' do   # EDIT
        check_auth!('packaging', 'edit')
        interactor.assert_permission!(:edit, id)
        show_partial { Masterfiles::Packaging::PalletFormat::Edit.call(id) }
      end

      r.is do # rubocop:disable Metrics/BlockLength
        r.get do       # SHOW
          check_auth!('packaging', 'read')
          show_partial { Masterfiles::Packaging::PalletFormat::Show.call(id) }
        end
        r.patch do     # UPDATE
          res = interactor.update_pallet_format(id, params[:pallet_format])
          if res.success
            row_keys = %i[
              description
              pallet_base_code
              stack_type_code
              active
            ]
            update_grid_row(id, changes: select_attributes(res.instance, row_keys), notice: res.message)
          else
            re_show_form(r, res) { Masterfiles::Packaging::PalletFormat::Edit.call(id, form_values: params[:pallet_format], form_errors: res.errors) }
          end
        end
        r.delete do    # DELETE
          check_auth!('packaging', 'delete')
          interactor.assert_permission!(:delete, id)
          res = interactor.delete_pallet_format(id)
          if res.success
            delete_grid_row(id, notice: res.message)
          else
            show_json_error(res.message, status: 200)
          end
        end
      end
    end

    r.on 'pallet_formats' do
      interactor = MasterfilesApp::PalletFormatInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})
      r.on 'new' do    # NEW
        check_auth!('packaging', 'new')
        show_partial_or_page(r) { Masterfiles::Packaging::PalletFormat::New.call(remote: fetch?(r)) }
      end
      r.post do        # CREATE
        res = interactor.create_pallet_format(params[:pallet_format])
        if res.success
          row_keys = %i[
            id
            description
            pallet_base_code
            stack_type_code
            active
          ]
          add_grid_row(attrs: select_attributes(res.instance, row_keys),
                       notice: res.message)
        else
          re_show_form(r, res, url: '/masterfiles/packaging/pallet_formats/new') do
            Masterfiles::Packaging::PalletFormat::New.call(form_values: params[:pallet_format],
                                                           form_errors: res.errors,
                                                           remote: fetch?(r))
          end
        end
      end
    end

    # CARTONS PER PALLET
    # --------------------------------------------------------------------------
    r.on 'cartons_per_pallet', Integer do |id| # rubocop:disable Metrics/BlockLength
      interactor = MasterfilesApp::CartonsPerPalletInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      # Check for notfound:
      r.on !interactor.exists?(:cartons_per_pallet, id) do
        handle_not_found(r)
      end

      r.on 'edit' do   # EDIT
        check_auth!('packaging', 'edit')
        interactor.assert_permission!(:edit, id)
        show_partial { Masterfiles::Packaging::CartonsPerPallet::Edit.call(id) }
      end

      r.is do # rubocop:disable Metrics/BlockLength
        r.get do       # SHOW
          check_auth!('packaging', 'read')
          show_partial { Masterfiles::Packaging::CartonsPerPallet::Show.call(id) }
        end
        r.patch do     # UPDATE
          res = interactor.update_cartons_per_pallet(id, params[:cartons_per_pallet])
          if res.success
            row_keys = %i[
              description
              pallet_format_id
              basic_pack_id
              cartons_per_pallet
              layers_per_pallet
              active
              basic_pack_code
              pallet_formats_description
              active
            ]
            update_grid_row(id, changes: select_attributes(res.instance, row_keys), notice: res.message)
          else
            re_show_form(r, res) { Masterfiles::Packaging::CartonsPerPallet::Edit.call(id, form_values: params[:cartons_per_pallet], form_errors: res.errors) }
          end
        end
        r.delete do    # DELETE
          check_auth!('packaging', 'delete')
          interactor.assert_permission!(:delete, id)
          res = interactor.delete_cartons_per_pallet(id)
          if res.success
            delete_grid_row(id, notice: res.message)
          else
            show_json_error(res.message, status: 200)
          end
        end
      end
    end

    r.on 'cartons_per_pallet' do # rubocop:disable Metrics/BlockLength
      interactor = MasterfilesApp::CartonsPerPalletInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})
      r.on 'new' do    # NEW
        check_auth!('packaging', 'new')
        show_partial_or_page(r) { Masterfiles::Packaging::CartonsPerPallet::New.call(remote: fetch?(r)) }
      end
      r.post do        # CREATE
        res = interactor.create_cartons_per_pallet(params[:cartons_per_pallet])
        if res.success
          row_keys = %i[
            id
            description
            pallet_format_id
            basic_pack_id
            cartons_per_pallet
            layers_per_pallet
            active
            basic_pack_code
            pallet_formats_description
            active
          ]
          add_grid_row(attrs: select_attributes(res.instance, row_keys),
                       notice: res.message)
        else
          re_show_form(r, res, url: '/masterfiles/packaging/cartons_per_pallet/new') do
            Masterfiles::Packaging::CartonsPerPallet::New.call(form_values: params[:cartons_per_pallet],
                                                               form_errors: res.errors,
                                                               remote: fetch?(r))
          end
        end
      end
    end

    # PM TYPES
    # --------------------------------------------------------------------------
    r.on 'pm_types', Integer do |id| # rubocop:disable Metrics/BlockLength
      interactor = MasterfilesApp::PmTypeInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      # Check for notfound:
      r.on !interactor.exists?(:pm_types, id) do
        handle_not_found(r)
      end

      r.on 'edit' do   # EDIT
        check_auth!('packaging', 'edit')
        interactor.assert_permission!(:edit, id)
        show_partial { Masterfiles::Packaging::PmType::Edit.call(id) }
      end

      r.is do # rubocop:disable Metrics/BlockLength
        r.get do       # SHOW
          check_auth!('packaging', 'read')
          show_partial { Masterfiles::Packaging::PmType::Show.call(id) }
        end
        r.patch do     # UPDATE
          res = interactor.update_pm_type(id, params[:pm_type])
          if res.success
            row_keys = %i[
              id
              pm_type_code
              description
              composition_level
              composition_level_description
              short_code
              active
            ]
            update_grid_row(id, changes: select_attributes(res.instance, row_keys), notice: res.message)
          else
            re_show_form(r, res) { Masterfiles::Packaging::PmType::Edit.call(id, form_values: params[:pm_type], form_errors: res.errors) }
          end
        end
        r.delete do    # DELETE
          check_auth!('packaging', 'delete')
          interactor.assert_permission!(:delete, id)
          res = interactor.delete_pm_type(id)
          if res.success
            delete_grid_row(id, notice: res.message)
          else
            show_json_error(res.message, status: 200)
          end
        end
      end
    end

    r.on 'pm_types' do # rubocop:disable Metrics/BlockLength
      interactor = MasterfilesApp::PmTypeInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})
      r.on 'new' do    # NEW
        check_auth!('packaging', 'new')
        show_partial_or_page(r) { Masterfiles::Packaging::PmType::New.call(remote: fetch?(r)) }
      end
      r.post do        # CREATE
        res = interactor.create_pm_type(params[:pm_type])
        if res.success
          row_keys = %i[
            id
            pm_type_code
            description
            composition_level
            composition_level_description
            short_code
            active
          ]
          add_grid_row(attrs: select_attributes(res.instance, row_keys),
                       notice: res.message)
        else
          re_show_form(r, res, url: '/masterfiles/packaging/pm_types/new') do
            Masterfiles::Packaging::PmType::New.call(form_values: params[:pm_type],
                                                     form_errors: res.errors,
                                                     remote: fetch?(r))
          end
        end
      end
    end

    # PM SUBTYPES
    # --------------------------------------------------------------------------
    r.on 'pm_subtypes', Integer do |id| # rubocop:disable Metrics/BlockLength
      interactor = MasterfilesApp::PmSubtypeInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      # Check for notfound:
      r.on !interactor.exists?(:pm_subtypes, id) do
        handle_not_found(r)
      end

      r.on 'edit' do   # EDIT
        check_auth!('packaging', 'edit')
        interactor.assert_permission!(:edit, id)
        show_partial { Masterfiles::Packaging::PmSubtype::Edit.call(id) }
      end

      r.is do # rubocop:disable Metrics/BlockLength
        r.get do       # SHOW
          check_auth!('packaging', 'read')
          show_partial { Masterfiles::Packaging::PmSubtype::Show.call(id) }
        end
        r.patch do     # UPDATE
          res = interactor.update_pm_subtype(id, params[:pm_subtype])
          if res.success
            update_grid_row(id, changes: { short_code: res.instance[:short_code],
                                           pm_type_code: res.instance[:pm_type_code],
                                           subtype_code: res.instance[:subtype_code],
                                           description: res.instance[:description] },
                                notice: res.message)
          else
            re_show_form(r, res) { Masterfiles::Packaging::PmSubtype::Edit.call(id, form_values: params[:pm_subtype], form_errors: res.errors) }
          end
        end
        r.delete do    # DELETE
          check_auth!('packaging', 'delete')
          interactor.assert_permission!(:delete, id)
          res = interactor.delete_pm_subtype(id)
          if res.success
            delete_grid_row(id, notice: res.message)
          else
            show_json_error(res.message, status: 200)
          end
        end
      end
    end

    r.on 'pm_subtypes' do # rubocop:disable Metrics/BlockLength
      interactor = MasterfilesApp::PmSubtypeInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})
      r.on 'new' do    # NEW
        check_auth!('packaging', 'new')
        show_partial_or_page(r) { Masterfiles::Packaging::PmSubtype::New.call(remote: fetch?(r)) }
      end
      r.post do        # CREATE
        res = interactor.create_pm_subtype(params[:pm_subtype])
        if res.success
          row_keys = %i[
            id
            pm_type_code
            subtype_code
            description
            active
            short_code
          ]
          add_grid_row(attrs: select_attributes(res.instance, row_keys),
                       notice: res.message)
        else
          re_show_form(r, res, url: '/masterfiles/packaging/pm_subtypes/new') do
            Masterfiles::Packaging::PmSubtype::New.call(form_values: params[:pm_subtype],
                                                        form_errors: res.errors,
                                                        remote: fetch?(r))
          end
        end
      end
    end

    # PM PRODUCTS
    # --------------------------------------------------------------------------
    r.on 'pm_products', Integer do |id| # rubocop:disable Metrics/BlockLength
      interactor = MasterfilesApp::PmProductInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      # Check for notfound:
      r.on !interactor.exists?(:pm_products, id) do
        handle_not_found(r)
      end

      r.on 'edit' do   # EDIT
        check_auth!('packaging', 'edit')
        interactor.assert_permission!(:edit, id)
        show_partial { Masterfiles::Packaging::PmProduct::Edit.call(id) }
      end

      r.is do # rubocop:disable Metrics/BlockLength
        r.get do       # SHOW
          check_auth!('packaging', 'read')
          show_partial { Masterfiles::Packaging::PmProduct::Show.call(id) }
        end
        r.patch do     # UPDATE
          res = interactor.update_pm_product(id, params[:pm_product])
          if res.success
            row_keys = %i[
              pm_type_code
              subtype_code
              erp_code
              product_code
              description
              active
              material_mass
              basic_pack_code
              height_mm
              composition_level
              gross_weight_per_unit
              items_per_unit
              items_per_unit_client_description
            ]
            update_grid_row(id, changes: select_attributes(res.instance, row_keys), notice: res.message)
          else
            re_show_form(r, res) { Masterfiles::Packaging::PmProduct::Edit.call(id, form_values: params[:pm_product], form_errors: res.errors) }
          end
        end
        r.delete do    # DELETE
          check_auth!('packaging', 'delete')
          interactor.assert_permission!(:delete, id)
          res = interactor.delete_pm_product(id)
          if res.success
            delete_grid_row(id, notice: res.message)
          else
            show_json_error(res.message, status: 200)
          end
        end
      end
    end

    r.on 'pm_products' do # rubocop:disable Metrics/BlockLength
      interactor = MasterfilesApp::PmProductInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})
      r.on 'new' do    # NEW
        check_auth!('packaging', 'new')
        show_partial_or_page(r) { Masterfiles::Packaging::PmProduct::New.call(remote: fetch?(r)) }
      end

      r.on 'pm_subtype_changed' do
        actions = []
        unless params[:changed_value].nil_or_empty?
          pm_subtype_id = params[:changed_value]
          repo = MasterfilesApp::BomRepo.new
          show_product_extra_fields = repo.fruit_composition_level?(pm_subtype_id)
          show_one_level_up_fields = repo.one_level_up_fruit_composition?(pm_subtype_id)
          actions = [OpenStruct.new(type: :replace_inner_html,
                                    dom_id: 'pm_product_composition_level',
                                    value: repo.find_pm_subtype(pm_subtype_id).composition_level),
                     OpenStruct.new(type: repo.can_edit_product_code?(pm_subtype_id) ? :show_element : :hide_element,
                                    dom_id: 'pm_product_product_code_field_wrapper'),
                     OpenStruct.new(type: repo.minimum_composition_level?(pm_subtype_id) ? :show_element : :hide_element,
                                    dom_id: 'pm_product_basic_pack_id_field_wrapper'),
                     OpenStruct.new(type: show_product_extra_fields ? :hide_element : :show_element,
                                    dom_id: 'pm_product_material_mass_field_wrapper'),
                     OpenStruct.new(type: show_product_extra_fields ? :hide_element : :show_element,
                                    dom_id: 'pm_product_height_mm_field_wrapper'),
                     OpenStruct.new(type: show_one_level_up_fields ? :show_element : :hide_element,
                                    dom_id: 'pm_product_gross_weight_per_unit_field_wrapper'),
                     OpenStruct.new(type: show_one_level_up_fields ? :show_element : :hide_element,
                                    dom_id: 'pm_product_items_per_unit_field_wrapper'),
                     OpenStruct.new(type: show_one_level_up_fields ? :show_element : :hide_element,
                                    dom_id: 'pm_product_items_per_unit_client_description_field_wrapper')]
        end
        json_actions(actions)
      end

      r.post do # rubocop:disable Metrics/BlockLength     # CREATE
        res = interactor.create_pm_product(params[:pm_product])
        if res.success
          row_keys = %i[
            id
            pm_type_code
            subtype_code
            erp_code
            product_code
            description
            active
            material_mass
            basic_pack_code
            height_mm
            composition_level
            gross_weight_per_unit
            items_per_unit
            items_per_unit_client_description
          ]
          add_grid_row(attrs: select_attributes(res.instance, row_keys),
                       notice: res.message)
        else
          re_show_form(r, res, url: '/masterfiles/packaging/pm_products/new') do
            Masterfiles::Packaging::PmProduct::New.call(form_values: params[:pm_product],
                                                        form_errors: res.errors,
                                                        remote: fetch?(r))
          end
        end
      end
    end

    # PM BOMS
    # --------------------------------------------------------------------------
    r.on 'pm_boms', Integer do |id| # rubocop:disable Metrics/BlockLength
      interactor = MasterfilesApp::PmBomInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      # Check for notfound:
      r.on !interactor.exists?(:pm_boms, id) do
        handle_not_found(r)
      end

      r.on 'edit' do   # EDIT
        check_auth!('packaging', 'edit')
        interactor.assert_permission!(:edit, id)
        show_partial_or_page(r) do
          Masterfiles::Packaging::PmBom::Edit.call(id)
        end
      end

      r.on 'calculate_bom_weights' do
        res = interactor.calculate_bom_weights(id)
        flash[:notice] = res.message
        if res.success
          r.redirect("/masterfiles/packaging/pm_boms/#{id}/edit")
        else
          re_show_form(r, res) do
            Masterfiles::Packaging::PmBom::Edit.call(id,
                                                     is_update: true,
                                                     form_values: params[:pm_bom],
                                                     form_errors: res.errors)
          end
        end
      end

      r.on 'pm_boms_products' do # rubocop:disable Metrics/BlockLength
        interactor = MasterfilesApp::PmBomsProductInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})
        r.on 'new' do    # NEW
          check_auth!('packaging', 'new')
          show_partial_or_page(r) { Masterfiles::Packaging::PmBomsProduct::New.call(id, remote: fetch?(r)) }
        end
        r.post do # rubocop:disable Metrics/BlockLength       # CREATE
          res = interactor.create_pm_boms_product(params[:pm_boms_product])
          if res.success
            row_keys = %i[
              id
              product_code
              bom_code
              uom_code
              quantity
              active
            ]
            acts = [OpenStruct.new(type: :add_grid_row,
                                   attrs: select_attributes(res.instance, row_keys)),
                    OpenStruct.new(type: :replace_input_value,
                                   dom_id: 'pm_bom_bom_code',
                                   value: res.instance[:bom_code]),
                    OpenStruct.new(type: :replace_inner_html,
                                   dom_id: 'pm_bom_system_code',
                                   value: res.instance[:bom_code])]

            json_actions(acts, res.message, keep_dialog_open: false)
          else
            re_show_form(r, res, url: "/masterfiles/packaging/pm_boms/#{id}/pm_boms_products/new") do
              Masterfiles::Packaging::PmBomsProduct::New.call(id,
                                                              form_values: params[:pm_boms_product],
                                                              form_errors: res.errors,
                                                              remote: fetch?(r))
            end
          end
        end
      end

      r.is do # rubocop:disable Metrics/BlockLength
        r.get do       # SHOW
          check_auth!('packaging', 'read')
          show_partial { Masterfiles::Packaging::PmBom::Show.call(id) }
        end
        r.patch do     # UPDATE
          res = interactor.update_pm_bom(id, params[:pm_bom])
          if res.success
            show_partial(notice: 'BOM Updated') do
              Masterfiles::Packaging::PmBom::Edit.call(id,
                                                       is_update: true)
            end
          else
            re_show_form(r, res) do
              Masterfiles::Packaging::PmBom::Edit.call(id,
                                                       is_update: true,
                                                       form_values: params[:pm_bom],
                                                       form_errors: res.errors)
            end
          end
        end
        r.delete do    # DELETE
          check_auth!('packaging', 'delete')
          interactor.assert_permission!(:delete, id)
          res = interactor.delete_pm_bom(id)
          if res.success
            delete_grid_row(id, notice: res.message)
          else
            show_json_error(res.message, status: 200)
          end
        end
      end
    end

    r.on 'pm_boms' do # rubocop:disable Metrics/BlockLength
      interactor = MasterfilesApp::PmBomInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})
      r.on 'new' do    # NEW
        check_auth!('packaging', 'new')
        show_partial_or_page(r) { Masterfiles::Packaging::PmBom::New.call(remote: fetch?(r)) }
      end

      r.on 'select_subtypes' do
        r.get do
          show_partial_or_page(r) do
            Masterfiles::Packaging::PmBom::SelectSubtypes.call(remote: fetch?(r))
          end
        end
        r.post do
          res = interactor.select_subtypes(params[:pm_bom])
          if res.success
            store_locally(:pm_subtype_ids, params[:pm_bom][:pm_subtype_ids].map(&:to_i))
            show_partial_or_page(r) do
              Masterfiles::Packaging::PmBom::AddProducts.call({ pm_subtype_ids: params[:pm_bom][:pm_subtype_ids].map(&:to_i), selected_product_ids: [] },
                                                              back_url: back_button_url)
            end
          else
            re_show_form(r, res, url: '/masterfiles/packaging/pm_boms/select_subtypes') do
              Masterfiles::Packaging::PmBom::SelectSubtypes.call(form_values: params[:pm_bom],
                                                                 form_errors: res.errors,
                                                                 remote: fetch?(r))
            end
          end
        end
      end

      r.on 'multiselect_pm_products' do
        pm_subtype_ids = retrieve_from_local_store(:pm_subtype_ids)
        store_locally(:pm_bom_params, { pm_subtype_ids: pm_subtype_ids, selected_product_ids: multiselect_grid_choices(params) })
        res = interactor.multiselect_pm_products(multiselect_grid_choices(params))
        if res.success
          flash[:notice] = res.message
          show_partial_or_page(r) do
            Masterfiles::Packaging::PmBom::Edit.call(res.instance[:id])
          end
        else
          re_show_form(r, res, url: '/masterfiles/packaging/pm_boms/add_pm_bom_products') do
            Masterfiles::Packaging::PmBom::AddProducts.call({ pm_subtype_ids: pm_subtype_ids, selected_product_ids: multiselect_grid_choices(params) },
                                                            back_url: back_button_url,
                                                            form_values: params[:pm_bom],
                                                            form_errors: res.errors,
                                                            remote: fetch?(r))
          end
        end
      end

      r.on 'add_pm_bom_products' do
        pm_bom_params = retrieve_from_local_store(:pm_bom_params)
        store_locally(:pm_bom_params, pm_bom_params)
        show_partial_or_page(r) do
          Masterfiles::Packaging::PmBom::AddProducts.call(pm_bom_params,
                                                          back_url: back_button_url)
        end
      end

      r.on 'refresh_system_codes' do
        check_auth!('fruit', 'new')
        res = interactor.refresh_system_codes
        flash[:notice] = res.message
        redirect_to_last_grid(r)
      end

      r.post do        # CREATE
        res = interactor.create_pm_bom(params[:pm_bom])
        if res.success
          row_keys = %i[
            id
            bom_code
            erp_bom_code
            description
            active
            gross_weight
            nett_weight
          ]
          add_grid_row(attrs: select_attributes(res.instance, row_keys),
                       notice: res.message)
        else
          re_show_form(r, res, url: '/masterfiles/packaging/pm_boms/new') do
            Masterfiles::Packaging::PmBom::New.call(form_values: params[:pm_bom],
                                                    form_errors: res.errors,
                                                    remote: fetch?(r))
          end
        end
      end
    end

    # PM BOMS PRODUCTS
    # --------------------------------------------------------------------------
    r.on 'pm_boms_products', Integer do |id| # rubocop:disable Metrics/BlockLength
      interactor = MasterfilesApp::PmBomsProductInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      # Check for notfound:
      r.on !interactor.exists?(:pm_boms_products, id) do
        handle_not_found(r)
      end

      r.on 'edit' do   # EDIT
        check_auth!('packaging', 'edit')
        interactor.assert_permission!(:edit, id)
        show_partial { Masterfiles::Packaging::PmBomsProduct::Edit.call(id) }
      end

      r.is do # rubocop:disable Metrics/BlockLength
        r.get do       # SHOW
          check_auth!('packaging', 'read')
          show_partial { Masterfiles::Packaging::PmBomsProduct::Show.call(id) }
        end
        r.patch do     # UPDATE
          res = interactor.update_pm_boms_product(id, params[:pm_boms_product])
          if res.success
            row_keys = %i[
              product_code
              bom_code
              uom_code
              quantity
              active
            ]
            acts = [OpenStruct.new(type: :update_grid_row,
                                   id: id,
                                   changes: select_attributes(res.instance, row_keys)),
                    OpenStruct.new(type: :replace_input_value,
                                   dom_id: 'pm_bom_bom_code',
                                   value: res.instance[:bom_code]),
                    OpenStruct.new(type: :replace_inner_html,
                                   dom_id: 'pm_bom_system_code',
                                   value: res.instance[:bom_code])]
            json_actions(acts, res.message, keep_dialog_open: true)
          else
            re_show_form(r, res) { Masterfiles::Packaging::PmBomsProduct::Edit.call(id, form_values: params[:pm_boms_product], form_errors: res.errors) }
          end
        end
        r.delete do    # DELETE
          check_auth!('packaging', 'delete')
          interactor.assert_permission!(:delete, id)
          res = interactor.delete_pm_boms_product(id)
          if res.success
            acts = [OpenStruct.new(type: :delete_grid_row,
                                   id: id),
                    OpenStruct.new(type: :replace_input_value,
                                   dom_id: 'pm_bom_bom_code',
                                   value: res.instance[:bom_code]),
                    OpenStruct.new(type: :replace_inner_html,
                                   dom_id: 'pm_bom_system_code',
                                   value: res.instance[:system_code])]

            json_actions(acts, res.message, keep_dialog_open: false)
          else
            show_json_error(res.message, status: 200)
          end
        end
      end
    end

    r.on 'pm_boms_products' do # rubocop:disable Metrics/BlockLength
      interactor = MasterfilesApp::PmBomsProductInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      r.on 'pm_subtype_changed' do
        pm_products = if params[:changed_value].blank?
                        []
                      else
                        interactor.for_select_subtype_products(params[:changed_value])
                      end
        json_actions([OpenStruct.new(type: :replace_select_options,
                                     dom_id: 'pm_boms_product_pm_product_id',
                                     options_array: pm_products)])
      end

      r.on 'inline_edit_bom_product', Integer do |bom_product_id|
        res = interactor.inline_edit_bom_product(bom_product_id, params)
        if res.success
          acts = [OpenStruct.new(type: :update_grid_row,
                                 id: bom_product_id,
                                 changes: res.instance[:changes])]
          if res.instance[:refresh_bom_code]
            acts << OpenStruct.new(type: :replace_input_value,
                                   dom_id: 'pm_bom_bom_code',
                                   value: res.instance[:bom_code])
            acts << OpenStruct.new(type: :replace_inner_html,
                                   dom_id: 'pm_bom_system_code',
                                   value: res.instance[:system_code])
          end

          json_actions(acts, res.message, keep_dialog_open: false)
        else
          undo_grid_inline_edit(message: res.message, message_type: :warning)
        end
      end
    end

    # PACKING METHODS
    # --------------------------------------------------------------------------
    r.on 'packing_methods', Integer do |id| # rubocop:disable Metrics/BlockLength
      interactor = MasterfilesApp::PackingMethodInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      # Check for notfound:
      r.on !interactor.exists?(:packing_methods, id) do
        handle_not_found(r)
      end

      r.on 'edit' do   # EDIT
        check_auth!('packaging', 'edit')
        interactor.assert_permission!(:edit, id)
        show_partial { Masterfiles::Packaging::PackingMethod::Edit.call(id) }
      end

      r.is do
        r.get do       # SHOW
          check_auth!('packaging', 'read')
          show_partial { Masterfiles::Packaging::PackingMethod::Show.call(id) }
        end
        r.patch do     # UPDATE
          res = interactor.update_packing_method(id, params[:packing_method])
          if res.success
            update_grid_row(id, changes: { packing_method_code: res.instance[:packing_method_code], description: res.instance[:description], actual_count_reduction_factor: res.instance[:actual_count_reduction_factor] },
                                notice: res.message)
          else
            re_show_form(r, res) { Masterfiles::Packaging::PackingMethod::Edit.call(id, form_values: params[:packing_method], form_errors: res.errors) }
          end
        end
        r.delete do    # DELETE
          check_auth!('packaging', 'delete')
          interactor.assert_permission!(:delete, id)
          res = interactor.delete_packing_method(id)
          if res.success
            delete_grid_row(id, notice: res.message)
          else
            show_json_error(res.message, status: 200)
          end
        end
      end
    end

    r.on 'packing_methods' do
      interactor = MasterfilesApp::PackingMethodInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})
      r.on 'new' do    # NEW
        check_auth!('packaging', 'new')
        show_partial_or_page(r) { Masterfiles::Packaging::PackingMethod::New.call(remote: fetch?(r)) }
      end
      r.post do        # CREATE
        res = interactor.create_packing_method(params[:packing_method])
        if res.success
          row_keys = %i[
            id
            packing_method_code
            description
            actual_count_reduction_factor
            active
          ]
          add_grid_row(attrs: select_attributes(res.instance, row_keys),
                       notice: res.message)
        else
          re_show_form(r, res, url: '/masterfiles/packaging/packing_methods/new') do
            Masterfiles::Packaging::PackingMethod::New.call(form_values: params[:packing_method],
                                                            form_errors: res.errors,
                                                            remote: fetch?(r))
          end
        end
      end
    end

    # PM COMPOSITION LEVELS
    # --------------------------------------------------------------------------
    r.on 'pm_composition_levels', Integer do |id| # rubocop:disable Metrics/BlockLength
      interactor = MasterfilesApp::PmCompositionLevelInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      # Check for notfound:
      r.on !interactor.exists?(:pm_composition_levels, id) do
        handle_not_found(r)
      end

      r.on 'edit' do   # EDIT
        check_auth!('packaging', 'edit')
        interactor.assert_permission!(:edit, id)
        show_partial { Masterfiles::Packaging::PmCompositionLevel::Edit.call(id) }
      end

      r.is do
        r.get do       # SHOW
          check_auth!('packaging', 'read')
          show_partial { Masterfiles::Packaging::PmCompositionLevel::Show.call(id) }
        end
        r.patch do     # UPDATE
          res = interactor.update_pm_composition_level(id, params[:pm_composition_level])
          if res.success
            update_grid_row(id, changes: { composition_level: res.instance[:composition_level], description: res.instance[:description] },
                                notice: res.message)
          else
            re_show_form(r, res) { Masterfiles::Packaging::PmCompositionLevel::Edit.call(id, form_values: params[:pm_composition_level], form_errors: res.errors) }
          end
        end
        r.delete do    # DELETE
          check_auth!('packaging', 'delete')
          interactor.assert_permission!(:delete, id)
          res = interactor.delete_pm_composition_level(id)
          if res.success
            delete_grid_row(id, notice: res.message)
          else
            show_json_error(res.message, status: 200)
          end
        end
      end
    end

    r.on 'pm_composition_levels' do # rubocop:disable Metrics/BlockLength
      interactor = MasterfilesApp::PmCompositionLevelInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})
      r.on 'new' do    # NEW
        check_auth!('packaging', 'new')
        show_partial_or_page(r) { Masterfiles::Packaging::PmCompositionLevel::New.call(remote: fetch?(r)) }
      end

      r.on 'reorder' do
        show_partial_or_page(r) { Masterfiles::Packaging::PmCompositionLevel::Reorder.call }
      end

      r.on 'save_reorder' do
        res = interactor.reorder_composition_levels(params[:p_sorted_ids])
        flash[:notice] = res.message
        redirect_to_last_grid(r)
      end

      r.post do        # CREATE
        res = interactor.create_pm_composition_level(params[:pm_composition_level])
        if res.success
          row_keys = %i[
            id
            composition_level
            description
            active
          ]
          add_grid_row(attrs: select_attributes(res.instance, row_keys),
                       notice: res.message)
        else
          re_show_form(r, res, url: '/masterfiles/packaging/pm_composition_levels/new') do
            Masterfiles::Packaging::PmCompositionLevel::New.call(form_values: params[:pm_composition_level],
                                                                 form_errors: res.errors,
                                                                 remote: fetch?(r))
          end
        end
      end
    end

    # PM MARKS
    # --------------------------------------------------------------------------
    r.on 'pm_marks', Integer do |id| # rubocop:disable Metrics/BlockLength
      interactor = MasterfilesApp::PmMarkInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      # Check for notfound:
      r.on !interactor.exists?(:pm_marks, id) do
        handle_not_found(r)
      end

      r.on 'edit' do   # EDIT
        check_auth!('packaging', 'edit')
        interactor.assert_permission!(:edit, id)
        show_partial { Masterfiles::Packaging::PmMark::Edit.call(id) }
      end

      r.is do
        r.get do       # SHOW
          check_auth!('packaging', 'read')
          show_partial { Masterfiles::Packaging::PmMark::Show.call(id) }
        end
        r.patch do     # UPDATE
          res = interactor.update_pm_mark(id, params[:pm_mark])
          if res.success
            update_grid_row(id, changes: { mark_code: res.instance[:mark_code], packaging_marks: res.instance[:packaging_marks], description: res.instance[:description] },
                                notice: res.message)
          else
            re_show_form(r, res) { Masterfiles::Packaging::PmMark::Edit.call(id, form_values: params[:pm_mark], form_errors: res.errors) }
          end
        end
        r.delete do    # DELETE
          check_auth!('packaging', 'delete')
          interactor.assert_permission!(:delete, id)
          res = interactor.delete_pm_mark(id)
          if res.success
            delete_grid_row(id, notice: res.message)
          else
            show_json_error(res.message, status: 200)
          end
        end
      end
    end

    r.on 'pm_marks' do # rubocop:disable Metrics/BlockLength
      interactor = MasterfilesApp::PmMarkInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})
      r.on 'new' do    # NEW
        check_auth!('packaging', 'new')
        show_partial_or_page(r) { Masterfiles::Packaging::PmMark::New.call(remote: fetch?(r)) }
      end
      r.post do        # CREATE
        res = interactor.create_pm_mark(params[:pm_mark])
        if res.success
          row_keys = %i[
            id
            mark_id
            mark_code
            packaging_marks
            description
            active
          ]
          add_grid_row(attrs: select_attributes(res.instance, row_keys),
                       notice: res.message)
        else
          re_show_form(r, res, url: '/masterfiles/packaging/pm_marks/new') do
            Masterfiles::Packaging::PmMark::New.call(form_values: params[:pm_mark],
                                                     form_errors: res.errors,
                                                     remote: fetch?(r))
          end
        end
      end
    end
  end
end
