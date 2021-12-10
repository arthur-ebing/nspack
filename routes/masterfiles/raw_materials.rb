# frozen_string_literal: true

class Nspack < Roda
  route 'raw_materials', 'masterfiles' do |r|
    # RMT DELIVERY DESTINATIONS
    # --------------------------------------------------------------------------
    r.on 'rmt_delivery_destinations', Integer do |id|
      interactor = MasterfilesApp::RmtDeliveryDestinationInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      # Check for notfound:
      r.on !interactor.exists?(:rmt_delivery_destinations, id) do
        handle_not_found(r)
      end

      r.on 'edit' do   # EDIT
        check_auth!('raw materials', 'edit')
        interactor.assert_permission!(:edit, id)
        show_partial { Masterfiles::RawMaterials::RmtDeliveryDestination::Edit.call(id) }
      end

      r.is do
        r.get do       # SHOW
          check_auth!('raw materials', 'read')
          show_partial { Masterfiles::RawMaterials::RmtDeliveryDestination::Show.call(id) }
        end
        r.patch do     # UPDATE
          res = interactor.update_rmt_delivery_destination(id, params[:rmt_delivery_destination])
          if res.success
            update_grid_row(id, changes: { delivery_destination_code: res.instance[:delivery_destination_code], description: res.instance[:description] },
                                notice: res.message)
          else
            re_show_form(r, res) { Masterfiles::RawMaterials::RmtDeliveryDestination::Edit.call(id, form_values: params[:rmt_delivery_destination], form_errors: res.errors) }
          end
        end
        r.delete do    # DELETE
          check_auth!('raw materials', 'delete')
          interactor.assert_permission!(:delete, id)
          res = interactor.delete_rmt_delivery_destination(id)
          if res.success
            delete_grid_row(id, notice: res.message)
          else
            show_json_error(res.message, status: 200)
          end
        end
      end
    end

    r.on 'rmt_delivery_destinations' do
      interactor = MasterfilesApp::RmtDeliveryDestinationInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})
      r.on 'new' do    # NEW
        check_auth!('raw materials', 'new')
        show_partial_or_page(r) { Masterfiles::RawMaterials::RmtDeliveryDestination::New.call(remote: fetch?(r)) }
      end
      r.post do        # CREATE
        res = interactor.create_rmt_delivery_destination(params[:rmt_delivery_destination])
        if res.success
          row_keys = %i[
            id
            delivery_destination_code
            description
          ]
          add_grid_row(attrs: select_attributes(res.instance, row_keys),
                       notice: res.message)
        else
          re_show_form(r, res, url: '/masterfiles/raw_materials/rmt_delivery_destinations/new') do
            Masterfiles::RawMaterials::RmtDeliveryDestination::New.call(form_values: params[:rmt_delivery_destination],
                                                                        form_errors: res.errors,
                                                                        remote: fetch?(r))
          end
        end
      end
    end
    # ASSET TRANSACTION TYPES
    # --------------------------------------------------------------------------
    r.on 'asset_transaction_types', Integer do |id|
      interactor = MasterfilesApp::AssetTransactionTypeInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      # Check for notfound:
      r.on !interactor.exists?(:asset_transaction_types, id) do
        handle_not_found(r)
      end

      r.on 'edit' do   # EDIT
        check_auth!('raw materials', 'edit')
        interactor.assert_permission!(:edit, id)
        show_partial { Masterfiles::RawMaterials::AssetTransactionType::Edit.call(id) }
      end

      r.is do
        r.get do       # SHOW
          check_auth!('raw materials', 'read')
          show_partial { Masterfiles::RawMaterials::AssetTransactionType::Show.call(id) }
        end
        r.patch do     # UPDATE
          res = interactor.update_asset_transaction_type(id, params[:asset_transaction_type])
          if res.success
            row_keys = %i[
              id
              transaction_type_code
              description
              status
            ]
            update_grid_row(id, changes: select_attributes(res.instance, row_keys), notice: res.message)
          else
            re_show_form(r, res) { Masterfiles::RawMaterials::AssetTransactionType::Edit.call(id, form_values: params[:asset_transaction_type], form_errors: res.errors) }
          end
        end
        r.delete do    # DELETE
          check_auth!('raw materials', 'delete')
          interactor.assert_permission!(:delete, id)
          res = interactor.delete_asset_transaction_type(id)
          if res.success
            delete_grid_row(id, notice: res.message)
          else
            show_json_error(res.message, status: 200)
          end
        end
      end
    end

    r.on 'asset_transaction_types' do
      interactor = MasterfilesApp::AssetTransactionTypeInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})
      r.on 'new' do    # NEW
        check_auth!('raw materials', 'new')
        show_partial_or_page(r) { Masterfiles::RawMaterials::AssetTransactionType::New.call(remote: fetch?(r)) }
      end
      r.post do        # CREATE
        res = interactor.create_asset_transaction_type(params[:asset_transaction_type])
        if res.success
          row_keys = %i[
            id
            transaction_type_code
            description
            status
          ]
          add_grid_row(attrs: select_attributes(res.instance, row_keys),
                       notice: res.message)
        else
          re_show_form(r, res, url: '/masterfiles/raw_materials/asset_transaction_types/new') do
            Masterfiles::RawMaterials::AssetTransactionType::New.call(form_values: params[:asset_transaction_type],
                                                                      form_errors: res.errors,
                                                                      remote: fetch?(r))
          end
        end
      end
    end

    # RMT SIZES
    # --------------------------------------------------------------------------
    r.on 'rmt_sizes', Integer do |id|
      interactor = MasterfilesApp::RmtSizeInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      # Check for notfound:
      r.on !interactor.exists?(:rmt_sizes, id) do
        handle_not_found(r)
      end

      r.on 'edit' do   # EDIT
        check_auth!('raw materials', 'edit')
        interactor.assert_permission!(:edit, id)
        show_partial { Masterfiles::RawMaterials::RmtSize::Edit.call(id) }
      end

      r.is do
        r.get do       # SHOW
          check_auth!('raw materials', 'read')
          show_partial { Masterfiles::RawMaterials::RmtSize::Show.call(id) }
        end
        r.patch do     # UPDATE
          res = interactor.update_rmt_size(id, params[:rmt_size])
          if res.success
            update_grid_row(id, changes: { size_code: res.instance[:size_code], description: res.instance[:description] },
                                notice: res.message)
          else
            re_show_form(r, res) { Masterfiles::RawMaterials::RmtSize::Edit.call(id, form_values: params[:rmt_size], form_errors: res.errors) }
          end
        end
        r.delete do    # DELETE
          check_auth!('raw materials', 'delete')
          interactor.assert_permission!(:delete, id)
          res = interactor.delete_rmt_size(id)
          if res.success
            delete_grid_row(id, notice: res.message)
          else
            show_json_error(res.message, status: 200)
          end
        end
      end
    end

    r.on 'rmt_sizes' do
      interactor = MasterfilesApp::RmtSizeInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})
      r.on 'new' do    # NEW
        check_auth!('raw materials', 'new')
        show_partial_or_page(r) { Masterfiles::RawMaterials::RmtSize::New.call(remote: fetch?(r)) }
      end
      r.post do        # CREATE
        res = interactor.create_rmt_size(params[:rmt_size])
        if res.success
          row_keys = %i[
            id
            size_code
            description
          ]
          add_grid_row(attrs: select_attributes(res.instance, row_keys),
                       notice: res.message)
        else
          re_show_form(r, res, url: '/masterfiles/raw_materials/rmt_sizes/new') do
            Masterfiles::RawMaterials::RmtSize::New.call(form_values: params[:rmt_size],
                                                         form_errors: res.errors,
                                                         remote: fetch?(r))
          end
        end
      end
    end

    # RIPENESS CODES
    # --------------------------------------------------------------------------
    r.on 'ripeness_codes', Integer do |id|
      interactor = MasterfilesApp::AdvancedClassificationsInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      # Check for notfound:
      r.on !interactor.exists?(:ripeness_codes, id) do
        handle_not_found(r)
      end

      r.on 'edit' do   # EDIT
        check_auth!('raw materials', 'edit')
        interactor.assert_ripeness_code_permission!(:edit, id)
        show_partial { Masterfiles::RawMaterials::RipenessCode::Edit.call(id) }
      end

      r.is do
        r.get do       # SHOW
          check_auth!('raw materials', 'read')
          show_partial { Masterfiles::RawMaterials::RipenessCode::Show.call(id) }
        end
        r.patch do     # UPDATE
          res = interactor.update_ripeness_code(id, params[:ripeness_code])
          if res.success
            update_grid_row(id, changes: { ripeness_code: res.instance[:ripeness_code], description: res.instance[:description], legacy_code: res.instance[:legacy_code] },
                                notice: res.message)
          else
            re_show_form(r, res) { Masterfiles::RawMaterials::RipenessCode::Edit.call(id, form_values: params[:ripeness_code], form_errors: res.errors) }
          end
        end
        r.delete do    # DELETE
          check_auth!('raw materials', 'delete')
          interactor.assert_ripeness_code_permission!(:delete, id)
          res = interactor.delete_ripeness_code(id)
          if res.success
            delete_grid_row(id, notice: res.message)
          else
            show_json_error(res.message, status: 200)
          end
        end
      end
    end

    r.on 'ripeness_codes' do
      interactor = MasterfilesApp::AdvancedClassificationsInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})
      # r.on 'ui_change', String do |change_type| # Handle UI behaviours
      #   handle_ui_change(:ripeness_code, change_type.to_sym, params)
      # end
      r.on 'new' do    # NEW
        check_auth!('raw materials', 'new')
        show_partial_or_page(r) { Masterfiles::RawMaterials::RipenessCode::New.call(remote: fetch?(r)) }
      end
      r.post do        # CREATE
        res = interactor.create_ripeness_code(params[:ripeness_code])
        if res.success
          row_keys = %i[
            id
            ripeness_code
            description
            legacy_code
            status
          ]
          add_grid_row(attrs: select_attributes(res.instance, row_keys),
                       notice: res.message)
        else
          re_show_form(r, res, url: '/masterfiles/raw_materials/ripeness_codes/new') do
            Masterfiles::RawMaterials::RipenessCode::New.call(form_values: params[:ripeness_code],
                                                              form_errors: res.errors,
                                                              remote: fetch?(r))
          end
        end
      end
    end

    # RMT HANDLING REGIMES
    # --------------------------------------------------------------------------
    r.on 'rmt_handling_regimes', Integer do |id|
      interactor = MasterfilesApp::AdvancedClassificationsInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      # Check for notfound:
      r.on !interactor.exists?(:rmt_handling_regimes, id) do
        handle_not_found(r)
      end

      r.on 'edit' do   # EDIT
        check_auth!('raw materials', 'edit')
        interactor.assert_handling_regime_permission!(:edit, id)
        show_partial { Masterfiles::RawMaterials::RmtHandlingRegime::Edit.call(id) }
      end

      r.is do
        r.get do       # SHOW
          check_auth!('raw materials', 'read')
          show_partial { Masterfiles::RawMaterials::RmtHandlingRegime::Show.call(id) }
        end
        r.patch do     # UPDATE
          res = interactor.update_rmt_handling_regime(id, params[:rmt_handling_regime])
          if res.success
            update_grid_row(id, changes: { regime_code: res.instance[:regime_code], description: res.instance[:description], for_packing: res.instance[:for_packing] },
                                notice: res.message)
          else
            re_show_form(r, res) { Masterfiles::RawMaterials::RmtHandlingRegime::Edit.call(id, form_values: params[:rmt_handling_regime], form_errors: res.errors) }
          end
        end
        r.delete do    # DELETE
          check_auth!('raw materials', 'delete')
          interactor.assert_handling_regime_permission!(:delete, id)
          res = interactor.delete_rmt_handling_regime(id)
          if res.success
            delete_grid_row(id, notice: res.message)
          else
            show_json_error(res.message, status: 200)
          end
        end
      end
    end

    r.on 'rmt_handling_regimes' do
      interactor = MasterfilesApp::AdvancedClassificationsInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})
      # r.on 'ui_change', String do |change_type| # Handle UI behaviours
      #   handle_ui_change(:rmt_handling_regime, change_type.to_sym, params)
      # end
      r.on 'new' do    # NEW
        check_auth!('raw materials', 'new')
        show_partial_or_page(r) { Masterfiles::RawMaterials::RmtHandlingRegime::New.call(remote: fetch?(r)) }
      end
      r.post do        # CREATE
        res = interactor.create_rmt_handling_regime(params[:rmt_handling_regime])
        if res.success
          row_keys = %i[
            id
            regime_code
            description
            for_packing
            status
          ]
          add_grid_row(attrs: select_attributes(res.instance, row_keys),
                       notice: res.message)
        else
          re_show_form(r, res, url: '/masterfiles/raw_materials/rmt_handling_regimes/new') do
            Masterfiles::RawMaterials::RmtHandlingRegime::New.call(form_values: params[:rmt_handling_regime],
                                                                   form_errors: res.errors,
                                                                   remote: fetch?(r))
          end
        end
      end
    end

    # RMT CODES
    # --------------------------------------------------------------------------
    r.on 'rmt_codes', Integer do |id|
      interactor = MasterfilesApp::AdvancedClassificationsInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      # Check for notfound:
      r.on !interactor.exists?(:rmt_codes, id) do
        handle_not_found(r)
      end

      r.on 'edit' do   # EDIT
        check_auth!('raw materials', 'edit')
        interactor.assert_rmt_code_permission!(:edit, id)
        show_partial { Masterfiles::RawMaterials::RmtCode::Edit.call(id) }
      end

      r.is do
        r.get do       # SHOW
          check_auth!('raw materials', 'read')
          show_partial { Masterfiles::RawMaterials::RmtCode::Show.call(id) }
        end
        r.patch do     # UPDATE
          res = interactor.update_rmt_code(id, params[:rmt_code])
          if res.success
            row_keys = %i[
              id
              code
              cultivar_group_code
              cultivar_name
              cultivar_id
              rmt_variant_code
              rmt_code
              description
              regime_code
              for_packing
              marketing_variety_code
              rmt_variant_id
            ]
            update_grid_row(id, changes: select_attributes(res.instance, row_keys), notice: res.message)
          else
            re_show_form(r, res) { Masterfiles::RawMaterials::RmtCode::Edit.call(id, form_values: params[:rmt_code], form_errors: res.errors) }
          end
        end
        r.delete do    # DELETE
          check_auth!('raw materials', 'delete')
          interactor.assert_rmt_code_permission!(:delete, id)
          res = interactor.delete_rmt_code(id)
          if res.success
            delete_grid_row(id, notice: res.message)
          else
            show_json_error(res.message, status: 200)
          end
        end
      end
    end

    # RMT VARIANTS
    # --------------------------------------------------------------------------
    r.on 'rmt_variants', Integer do |id|
      interactor = MasterfilesApp::AdvancedClassificationsInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      # Check for notfound:
      r.on !interactor.exists?(:rmt_variants, id) do
        handle_not_found(r)
      end

      r.on 'edit' do   # EDIT
        check_auth!('raw materials', 'edit')
        interactor.assert_rmt_variant_permission!(:edit, id)
        show_partial { Masterfiles::RawMaterials::RmtVariant::Edit.call(id) }
      end

      r.is do
        r.get do       # SHOW
          check_auth!('raw materials', 'read')
          show_partial { Masterfiles::RawMaterials::RmtVariant::Show.call(id) }
        end
        r.patch do     # UPDATE
          res = interactor.update_rmt_variant(id, params[:rmt_variant])
          if res.success
            flash[:notice] = res.message
            redirect_to_last_grid(r)
          else
            re_show_form(r, res) { Masterfiles::RawMaterials::RmtVariant::Edit.call(id, form_values: params[:rmt_variant], form_errors: res.errors) }
          end
        end
        r.delete do    # DELETE
          check_auth!('raw materials', 'delete')
          interactor.assert_rmt_variant_permission!(:delete, id)
          res = interactor.delete_rmt_variant(id)
          if res.success
            flash[:notice] = res.message
            redirect_to_last_grid(r)
          else
            show_json_error(res.message, status: 200)
          end
        end
      end

      r.on 'rmt_codes' do     # NEW
        r.get do # NEW
          check_auth!('raw materials', 'new')
          show_partial_or_page(r) { Masterfiles::RawMaterials::RmtCode::New.call(id, remote: fetch?(r)) }
        end

        r.post do        # CREATE
          res = interactor.create_rmt_code(id, params[:rmt_code])
          if res.success
            if res.instance[:add_grid_row]
              row_keys = %i[
                id
                code
                cultivar_group_code
                cultivar_name
                cultivar_id
                rmt_variant_code
                rmt_code
                description
                regime_code
                for_packing
                marketing_variety_code
                rmt_variant_id
              ]
              add_grid_row(attrs: select_attributes(res.instance[:rmt_code], row_keys),
                           notice: res.message)
            else
              flash[:notice] = res.message
              redirect_to_last_grid(r)
            end
          else
            re_show_form(r, res, url: "/masterfiles/raw_materials/rmt_variants/#{id}/rmt_codes") do
              Masterfiles::RawMaterials::RmtCode::New.call(form_values: params[:rmt_code],
                                                           form_errors: res.errors,
                                                           remote: fetch?(r))
            end
          end
        end
      end
    end

    r.on 'rmt_variants' do
      interactor = MasterfilesApp::AdvancedClassificationsInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      r.on 'new', Integer do |id|   # NEW
        r.get do
          check_auth!('raw materials', 'new')
          show_partial_or_page(r) { Masterfiles::RawMaterials::RmtVariant::New.call(id, remote: fetch?(r)) }
        end

        r.post do        # CREATE
          res = interactor.create_rmt_variant(id, params[:rmt_variant])
          if res.success
            if res.instance[:add_grid_row]
              row_keys = %i[
                id
                code
                cultivar_group_code
                cultivar_name
                cultivar_id
                rmt_variant_code
                rmt_code
                description
                regime_code
                for_packing
                marketing_variety_code
                rmt_variant_id
              ]
              add_grid_row(attrs: select_attributes(res.instance[:rmt_variant], row_keys),
                           notice: res.message)
            else
              flash[:notice] = res.message
              redirect_to_last_grid(r)
            end
          else
            re_show_form(r, res, url: "/masterfiles/raw_materials/rmt_variants/new/#{id}") do
              Masterfiles::RawMaterials::RmtVariant::New.call(id,
                                                              form_values: params[:rmt_variant],
                                                              form_errors: res.errors,
                                                              remote: fetch?(r))
            end
          end
        end
      end
    end

    # RMT CLASSIFICATION TYPES
    # --------------------------------------------------------------------------
    r.on 'rmt_classification_types', Integer do |id|
      interactor = MasterfilesApp::AdvancedClassificationsInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      # Check for notfound:
      r.on !interactor.exists?(:rmt_classification_types, id) do
        handle_not_found(r)
      end

      r.on 'edit' do   # EDIT
        check_auth!('raw materials', 'edit')
        interactor.assert_rmt_classification_type_permission!(:edit, id)
        show_partial { Masterfiles::RawMaterials::RmtClassificationType::Edit.call(id) }
      end

      r.on 'rmt_classifications' do    # NEW
        r.get do
          check_auth!('raw materials', 'new')
          show_partial_or_page(r) { Masterfiles::RawMaterials::RmtClassification::New.call(id, remote: fetch?(r)) }
        end

        r.post do        # CREATE
          res = interactor.create_rmt_classification(id, params[:rmt_classification])
          if res.success
            if res.instance[:add_grid_row]
              row_keys = %i[
                id
                rmt_classification_type_id
                rmt_classification_type_code
                rmt_classification
                description
                status
              ]
              add_grid_row(attrs: select_attributes(res.instance[:rmt_classification], row_keys),
                           notice: res.message)
            else
              flash[:notice] = res.message
              redirect_to_last_grid(r)
            end
          else
            re_show_form(r, res, url: "/masterfiles/raw_materials/rmt_classification_types/#{id}/rmt_classifications") do
              Masterfiles::RawMaterials::RmtClassification::New.call(id, form_values: params[:rmt_classification],
                                                                         form_errors: res.errors,
                                                                         remote: fetch?(r))
            end
          end
        end
      end

      r.is do
        r.get do       # SHOW
          check_auth!('raw materials', 'read')
          show_partial { Masterfiles::RawMaterials::RmtClassificationType::Show.call(id) }
        end
        r.patch do     # UPDATE
          res = interactor.update_rmt_classification_type(id, params[:rmt_classification_type])
          if res.success
            flash[:notice] = res.message
            redirect_to_last_grid(r)
          else
            re_show_form(r, res) { Masterfiles::RawMaterials::RmtClassificationType::Edit.call(id, form_values: params[:rmt_classification_type], form_errors: res.errors) }
          end
        end
        r.delete do    # DELETE
          check_auth!('raw materials', 'delete')
          interactor.assert_rmt_classification_type_permission!(:delete, id)
          res = interactor.delete_rmt_classification_type(id)
          if res.success
            flash[:notice] = res.message
            redirect_to_last_grid(r)
          else
            show_json_error(res.message, status: 200)
          end
        end
      end
    end

    r.on 'rmt_classification_types' do
      interactor = MasterfilesApp::AdvancedClassificationsInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})
      # r.on 'ui_change', String do |change_type| # Handle UI behaviours
      #   handle_ui_change(:rmt_classification_type, change_type.to_sym, params)
      # end
      r.on 'new' do    # NEW
        check_auth!('raw materials', 'new')
        show_partial_or_page(r) { Masterfiles::RawMaterials::RmtClassificationType::New.call(remote: fetch?(r)) }
      end
      r.post do        # CREATE
        res = interactor.create_rmt_classification_type(params[:rmt_classification_type])
        if res.success
          row_keys = %i[
            rmt_classification_type_id
            rmt_classification_type_code
            description
          ]
          add_grid_row(attrs: select_attributes(res.instance, row_keys),
                       notice: res.message)
        else
          re_show_form(r, res, url: '/masterfiles/raw_materials/rmt_classification_types/new') do
            Masterfiles::RawMaterials::RmtClassificationType::New.call(form_values: params[:rmt_classification_type],
                                                                       form_errors: res.errors,
                                                                       remote: fetch?(r))
          end
        end
      end
    end

    # RMT CLASSIFICATIONS
    # --------------------------------------------------------------------------
    r.on 'rmt_classifications', Integer do |id|
      interactor = MasterfilesApp::AdvancedClassificationsInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      # Check for notfound:
      r.on !interactor.exists?(:rmt_classifications, id) do
        handle_not_found(r)
      end

      r.on 'edit' do   # EDIT
        check_auth!('raw materials', 'edit')
        interactor.assert_rmt_classification_permission!(:edit, id)
        show_partial { Masterfiles::RawMaterials::RmtClassification::Edit.call(id) }
      end

      r.is do
        r.get do       # SHOW
          check_auth!('raw materials', 'read')
          show_partial { Masterfiles::RawMaterials::RmtClassification::Show.call(id) }
        end
        r.patch do     # UPDATE
          res = interactor.update_rmt_classification(id, params[:rmt_classification])
          if res.success
            update_grid_row(id, changes: { rmt_classification_type_id: res.instance[:rmt_classification_type_id], rmt_classification: res.instance[:rmt_classification] },
                                notice: res.message)
          else
            re_show_form(r, res) { Masterfiles::RawMaterials::RmtClassification::Edit.call(id, form_values: params[:rmt_classification], form_errors: res.errors) }
          end
        end
        r.delete do    # DELETE
          check_auth!('raw materials', 'delete')
          interactor.assert_rmt_classification_permission!(:delete, id)
          res = interactor.delete_rmt_classification(id)
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
