# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
# rubocop:disable Metrics/ClassLength

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
  end
end
# rubocop:enable Metrics/BlockLength
# rubocop:enable Metrics/ClassLength
