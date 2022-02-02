# frozen_string_literal: true

class Nspack < Roda
  route 'bin_assets', 'raw_materials' do |r|
    interactor = RawMaterialsApp::BinAssetTransactionInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})
    # BIN ASSET TRANSACTIONS
    # --------------------------------------------------------------------------
    r.on 'bin_asset_transactions', Integer do |id|
      # Check for notfound:
      r.on !interactor.exists?(:bin_asset_transactions, id) do
        handle_not_found(r)
      end

      r.on 'preview_bin_asset_report' do
        jasper_params = JasperParams.new('bin_assets',
                                         current_user.login_name,
                                         bin_asset_transaction_id: id)
        res = CreateJasperReport.call(jasper_params)

        if res.success
          change_window_location_via_json(UtilityFunctions.cache_bust_url(res.instance), request.path)
        else
          show_error(res.message, fetch?(r))
        end
      end

      r.is do
        r.get do       # SHOW
          check_auth!('Bin Assets', 'read')
          show_partial { RawMaterials::BinAssets::BinAssetTransaction::Show.call(id) }
        end
      end
    end

    r.on 'bin_asset_transactions' do
      stepper = interactor.stepper
      r.on 'bin_asset_transaction_items' do
        r.on 'owner_changed' do
          rmt_container_material_types = params[:changed_value].blank? ? [] : interactor.rmt_container_material_types(params[:changed_value])
          json_actions([OpenStruct.new(type: :replace_select_options,
                                       dom_id: 'bin_asset_transaction_item_rmt_container_material_type_id',
                                       options_array: rmt_container_material_types)])
        end
        r.on 'new' do    # NEW
          check_auth!('Bin Assets', 'new')
          show_partial_or_page(r) { RawMaterials::BinAssets::BinAssetTransactionItem::New.call(remote: fetch?(r), interactor: interactor) }
        end
        r.on 'add' do
          res = stepper.add_bin_set(params[:bin_asset_transaction_item])
          if res.success
            bin_asset_types = stepper.for_select_bin_sets
            json_actions([OpenStruct.new(type: :replace_list_items,
                                         dom_id: 'bin_asset_transaction_item_bin_sets',
                                         items: bin_asset_types),
                          OpenStruct.new(type: :clear_form_validation,
                                         dom_id: 'bin_asset_transaction_item')],
                         'Bin Type Added',
                         keep_dialog_open: true)
          else
            re_show_form(r, res, url: '/raw_materials/bin_assets/bin_asset_transactions/bin_asset_transaction_items/new') do
              RawMaterials::BinAssets::BinAssetTransactionItem::New.call(form_values: {},
                                                                         form_errors: res.errors,
                                                                         remote: true,
                                                                         interactor: interactor)
            end
          end
        end
        r.on 'remove', String do |combined_ids|
          stepper.remove_bin_set(combined_ids)
          bin_asset_types = stepper.for_select_bin_sets
          json_actions([OpenStruct.new(type: :replace_list_items,
                                       dom_id: 'bin_asset_transaction_item_bin_sets',
                                       items: bin_asset_types),
                        OpenStruct.new(type: :clear_form_validation,
                                       dom_id: 'bin_asset_transaction_item')],
                       'Bin Type Removed',
                       keep_dialog_open: true)
        end
        r.on 'done' do
          res = interactor.validate_stepper
          if res.success
            res = interactor.create_bin_asset_transaction
            if res.success
              flash[:notice] = res.message
            else
              flash[:error] = res.message
            end
            redirect_via_json('/list/bin_asset_transaction_items')
          else
            re_show_form(r, res, url: '/raw_materials/bin_assets/bin_asset_transactions/bin_asset_transaction_items/new') do
              RawMaterials::BinAssets::BinAssetTransactionItem::New.call(form_values: {},
                                                                         form_errors: res.errors,
                                                                         remote: true,
                                                                         interactor: interactor)
            end
          end
        end
      end
      r.on 'delivery_id_changed' do
        truck_registration_number = interactor.truck_registration_number_for_delivery(params[:changed_value])
        json_actions([OpenStruct.new(type: :replace_input_value,
                                     dom_id: 'bin_asset_transaction_truck_registration_number',
                                     value: truck_registration_number)])
      end
      r.on 'issue_bin_assets' do
        r.on 'new' do
          check_auth!('Bin Assets', 'new')
          stepper.reset
          show_partial_or_page(r) { RawMaterials::BinAssets::BinAssetTransaction::IssueBinAssets.call(remote: fetch?(r)) }
        end
        r.post do        # CREATE
          res = interactor.validate_issue_params(params[:bin_asset_transaction])
          if res.success
            stepper.merge(params[:bin_asset_transaction])
            r.redirect '/raw_materials/bin_assets/bin_asset_transactions/bin_asset_transaction_items/new'
          else
            re_show_form(r, res, url: '/raw_materials/bin_assets/bin_asset_transactions/issue_bin_assets/new') do
              RawMaterials::BinAssets::BinAssetTransaction::IssueBinAssets.call(form_values: params[:bin_asset_transaction],
                                                                                form_errors: res.errors,
                                                                                remote: fetch?(r))
            end
          end
        end
      end
      r.on 'receive_bin_assets' do
        r.on 'new' do
          check_auth!('Bin Assets', 'new')
          stepper.reset
          show_partial_or_page(r) { RawMaterials::BinAssets::BinAssetTransaction::ReceiveBinAssets.call(remote: fetch?(r)) }
        end
        r.post do        # CREATE
          res = interactor.validate_receive_params(params[:bin_asset_transaction])
          if res.success
            stepper.merge(params[:bin_asset_transaction])
            r.redirect '/raw_materials/bin_assets/bin_asset_transactions/bin_asset_transaction_items/new'
          else
            re_show_form(r, res, url: '/raw_materials/bin_assets/bin_asset_transactions/receive_bin_assets/new') do
              RawMaterials::BinAssets::BinAssetTransaction::ReceiveBinAssets.call(form_values: params[:bin_asset_transaction],
                                                                                  form_errors: res.errors,
                                                                                  remote: fetch?(r))
            end
          end
        end
      end
      r.on 'adhoc_transaction' do
        r.on 'new' do
          check_auth!('Bin Assets', 'new')
          stepper.reset
          show_partial_or_page(r) { RawMaterials::BinAssets::BinAssetTransaction::AdhocMove.call(remote: fetch?(r)) }
        end
        r.post do        # CREATE
          res = interactor.validate_adhoc_params(params[:bin_asset_transaction])
          if res.success
            stepper.merge(params[:bin_asset_transaction])
            r.redirect '/raw_materials/bin_assets/bin_asset_transactions/bin_asset_transaction_items/new'
          else
            re_show_form(r, res, url: '/raw_materials/bin_assets/bin_asset_transactions/adhoc_transaction/new') do
              RawMaterials::BinAssets::BinAssetTransaction::AdhocMove.call(form_values: params[:bin_asset_transaction],
                                                                           form_errors: res.errors,
                                                                           remote: fetch?(r))
            end
          end
        end
      end
      r.on 'adhoc_create' do
        r.on 'new' do
          check_auth!('Bin Assets', 'new')
          stepper.reset
          show_partial_or_page(r) { RawMaterials::BinAssets::BinAssetTransaction::AdhocCreate.call(remote: fetch?(r)) }
        end
        r.post do        # CREATE
          res = interactor.validate_adhoc_create_params(params[:bin_asset_transaction])
          if res.success
            stepper.merge(params[:bin_asset_transaction])
            r.redirect '/raw_materials/bin_assets/bin_asset_transactions/bin_asset_transaction_items/new'
          else
            re_show_form(r, res, url: '/raw_materials/bin_assets/bin_asset_transactions/adhoc_create/new') do
              RawMaterials::BinAssets::BinAssetTransaction::AdhocCreate.call(form_values: params[:bin_asset_transaction],
                                                                             form_errors: res.errors,
                                                                             remote: fetch?(r))
            end
          end
        end
      end
      r.on 'adhoc_destroy' do
        r.on 'new' do
          check_auth!('Bin Assets', 'new')
          stepper.reset
          show_partial_or_page(r) { RawMaterials::BinAssets::BinAssetTransaction::AdhocDestroy.call(remote: fetch?(r)) }
        end
        r.post do        # CREATE
          res = interactor.validate_adhoc_destroy_params(params[:bin_asset_transaction])
          if res.success
            stepper.merge(params[:bin_asset_transaction])
            r.redirect '/raw_materials/bin_assets/bin_asset_transactions/bin_asset_transaction_items/new'
          else
            re_show_form(r, res, url: '/raw_materials/bin_assets/bin_asset_transactions/adhoc_destroy/new') do
              RawMaterials::BinAssets::BinAssetTransaction::AdhocDestroy.call(form_values: params[:bin_asset_transaction],
                                                                              form_errors: res.errors,
                                                                              remote: fetch?(r))
            end
          end
        end
      end
    end

    # bin asset TRANSACTION ITEMS
    # --------------------------------------------------------------------------
    r.on 'bin_asset_transaction_items', Integer do |id|
      # Check for notfound:
      r.on !interactor.exists?(:bin_asset_transaction_items, id) do
        handle_not_found(r)
      end

      r.on 'edit' do   # EDIT
        check_auth!('Bin Assets', 'edit')
        interactor.assert_permission!(:edit, id)
        show_partial { RawMaterials::BinAssets::BinAssetTransactionItem::Edit.call(id) }
      end

      r.is do
        r.get do       # SHOW
          check_auth!('Bin Assets', 'read')
          show_partial { RawMaterials::BinAssets::BinAssetTransactionItem::Show.call(id) }
        end
        r.patch do     # UPDATE
          res = interactor.update_bin_asset_transaction_item(id, params[:bin_asset_transaction_item])
          if res.success
            row_keys = %i[
              bin_asset_transaction_id
              rmt_container_material_owner_id
              bin_asset_from_location_id
              bin_asset_to_location_id
              quantity_bins
            ]
            update_grid_row(id, changes: select_attributes(res.instance, row_keys), notice: res.message)
          else
            re_show_form(r, res) { RawMaterials::BinAssets::BinAssetTransactionItem::Edit.call(id, form_values: params[:bin_asset_transaction_item], form_errors: res.errors) }
          end
        end
        r.delete do    # DELETE
          check_auth!('Bin Assets', 'delete')
          interactor.assert_permission!(:delete, id)
          res = interactor.delete_bin_asset_transaction_item(id)
          if res.success
            delete_grid_row(id, notice: res.message)
          else
            show_json_error(res.message, status: 200)
          end
        end
      end
    end

    # BIN ASSET LOCATION TRANSACTION HISTORY
    r.on 'location_transaction_history', Integer do |id|
      res = interactor.get_applicable_transaction_item_ids(id)
      history_ids = res.instance.join(',')
      r.redirect "/list/transaction_history_items/with_params?key=history&history_ids=#{history_ids}"
    end

    # RESOLVE BIN ASSET MOVE ERROR
    r.on 'bin_asset_move_error_logs', Integer do |id|
      r.on 'resolve_transaction_error' do
        res = interactor.resolve_transaction_error(id)
        if res.success
          flash[:notice] = res.message
        else
          flash[:error] = res.message
        end
        redirect_to_last_grid(r)
      end
    end
  end
end
