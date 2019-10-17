# frozen_string_literal: true

class Nspack < Roda # rubocop:disable Metrics/ClassLength
  route 'packaging', 'masterfiles' do |r| # rubocop:disable Metrics/BlockLength
    # PALLET BASES
    # --------------------------------------------------------------------------
    r.on 'pallet_bases', Integer do |id| # rubocop:disable Metrics/BlockLength
      interactor = MasterfilesApp::PalletBaseInteractor.new(current_user, {}, { route_url: request.path }, {})

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
      interactor = MasterfilesApp::PalletBaseInteractor.new(current_user, {}, { route_url: request.path }, {})
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
      interactor = MasterfilesApp::PalletStackTypeInteractor.new(current_user, {}, { route_url: request.path }, {})

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
      interactor = MasterfilesApp::PalletStackTypeInteractor.new(current_user, {}, { route_url: request.path }, {})
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
      interactor = MasterfilesApp::PalletFormatInteractor.new(current_user, {}, { route_url: request.path }, {})

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
      interactor = MasterfilesApp::PalletFormatInteractor.new(current_user, {}, { route_url: request.path }, {})
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
      interactor = MasterfilesApp::CartonsPerPalletInteractor.new(current_user, {}, { route_url: request.path }, {})

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
      interactor = MasterfilesApp::CartonsPerPalletInteractor.new(current_user, {}, { route_url: request.path }, {})
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
      interactor = MasterfilesApp::PmTypeInteractor.new(current_user, {}, { route_url: request.path }, {})

      # Check for notfound:
      r.on !interactor.exists?(:pm_types, id) do
        handle_not_found(r)
      end

      r.on 'edit' do   # EDIT
        check_auth!('packaging', 'edit')
        interactor.assert_permission!(:edit, id)
        show_partial { Masterfiles::Packaging::PmType::Edit.call(id) }
      end

      r.is do
        r.get do       # SHOW
          check_auth!('packaging', 'read')
          show_partial { Masterfiles::Packaging::PmType::Show.call(id) }
        end
        r.patch do     # UPDATE
          res = interactor.update_pm_type(id, params[:pm_type])
          if res.success
            update_grid_row(id, changes: { pm_type_code: res.instance[:pm_type_code], description: res.instance[:description] },
                                notice: res.message)
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

    r.on 'pm_types' do
      interactor = MasterfilesApp::PmTypeInteractor.new(current_user, {}, { route_url: request.path }, {})
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
      interactor = MasterfilesApp::PmSubtypeInteractor.new(current_user, {}, { route_url: request.path }, {})

      # Check for notfound:
      r.on !interactor.exists?(:pm_subtypes, id) do
        handle_not_found(r)
      end

      r.on 'edit' do   # EDIT
        check_auth!('packaging', 'edit')
        interactor.assert_permission!(:edit, id)
        show_partial { Masterfiles::Packaging::PmSubtype::Edit.call(id) }
      end

      r.is do
        r.get do       # SHOW
          check_auth!('packaging', 'read')
          show_partial { Masterfiles::Packaging::PmSubtype::Show.call(id) }
        end
        r.patch do     # UPDATE
          res = interactor.update_pm_subtype(id, params[:pm_subtype])
          if res.success
            update_grid_row(id, changes: { pm_type_code: res.instance[:pm_type_code], subtype_code: res.instance[:subtype_code], description: res.instance[:description] },
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

    r.on 'pm_subtypes' do
      interactor = MasterfilesApp::PmSubtypeInteractor.new(current_user, {}, { route_url: request.path }, {})
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
      interactor = MasterfilesApp::PmProductInteractor.new(current_user, {}, { route_url: request.path }, {})

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
              subtype_code
              erp_code
              product_code
              description
              active
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
      interactor = MasterfilesApp::PmProductInteractor.new(current_user, {}, { route_url: request.path }, {})
      r.on 'new' do    # NEW
        check_auth!('packaging', 'new')
        show_partial_or_page(r) { Masterfiles::Packaging::PmProduct::New.call(remote: fetch?(r)) }
      end
      r.post do        # CREATE
        res = interactor.create_pm_product(params[:pm_product])
        if res.success
          row_keys = %i[
            id
            subtype_code
            erp_code
            product_code
            description
            active
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
      interactor = MasterfilesApp::PmBomInteractor.new(current_user, {}, { route_url: request.path }, {})

      # Check for notfound:
      r.on !interactor.exists?(:pm_boms, id) do
        handle_not_found(r)
      end

      r.on 'edit' do   # EDIT
        check_auth!('packaging', 'edit')
        interactor.assert_permission!(:edit, id)
        show_partial { Masterfiles::Packaging::PmBom::Edit.call(id) }
      end

      r.on 'pm_boms_products' do # rubocop:disable Metrics/BlockLength
        interactor = MasterfilesApp::PmBomsProductInteractor.new(current_user, {}, { route_url: request.path }, {})
        r.on 'new' do    # NEW
          check_auth!('packaging', 'new')
          show_partial_or_page(r) { Masterfiles::Packaging::PmBomsProduct::New.call(id, remote: fetch?(r)) }
        end
        r.post do        # CREATE
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
            json_actions([OpenStruct.new(type: :add_grid_row, attrs: select_attributes(res.instance, row_keys))],
                         res.message)
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

      r.is do
        r.get do       # SHOW
          check_auth!('packaging', 'read')
          show_partial { Masterfiles::Packaging::PmBom::Show.call(id) }
        end
        r.patch do     # UPDATE
          res = interactor.update_pm_bom(id, params[:pm_bom])
          if res.success
            update_grid_row(id, changes: { bom_code: res.instance[:bom_code], erp_bom_code: res.instance[:erp_bom_code], description: res.instance[:description] },
                                notice: res.message)
          else
            re_show_form(r, res) { Masterfiles::Packaging::PmBom::Edit.call(id, form_values: params[:pm_bom], form_errors: res.errors) }
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

    r.on 'pm_boms' do
      interactor = MasterfilesApp::PmBomInteractor.new(current_user, {}, { route_url: request.path }, {})
      r.on 'new' do    # NEW
        check_auth!('packaging', 'new')
        show_partial_or_page(r) { Masterfiles::Packaging::PmBom::New.call(remote: fetch?(r)) }
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
      interactor = MasterfilesApp::PmBomsProductInteractor.new(current_user, {}, { route_url: request.path }, {})

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
            update_grid_row(id, changes: select_attributes(res.instance, row_keys), notice: res.message)
          else
            re_show_form(r, res) { Masterfiles::Packaging::PmBomsProduct::Edit.call(id, form_values: params[:pm_boms_product], form_errors: res.errors) }
          end
        end
        r.delete do    # DELETE
          check_auth!('packaging', 'delete')
          interactor.assert_permission!(:delete, id)
          res = interactor.delete_pm_boms_product(id)
          if res.success
            delete_grid_row(id, notice: res.message)
          else
            show_json_error(res.message, status: 200)
          end
        end
      end
    end
  end
end
