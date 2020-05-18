# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
# rubocop:disable Metrics/ClassLength

class Nspack < Roda
  route 'empty_bins', 'raw_materials' do |r|
    @interactor ||= RawMaterialsApp::EmptyBinTransactionInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})
    # EMPTY BIN TRANSACTIONS
    # --------------------------------------------------------------------------
    r.on 'empty_bin_transactions', Integer do |id|
      # Check for notfound:
      r.on !@interactor.exists?(:empty_bin_transactions, id) do
        handle_not_found(r)
      end

      r.is do
        r.get do       # SHOW
          check_auth!('empty bins', 'read')
          show_partial { RawMaterials::EmptyBins::EmptyBinTransaction::Show.call(id) }
        end
      end
    end

    r.on 'empty_bin_transactions' do # rubocop:disable Metrics/BlockLength
      stepper = @interactor.stepper
      r.on 'empty_bin_transaction_items' do
        r.on 'owner_changed' do
          rmt_container_material_types = params[:changed_value].blank? ? [] : @interactor.rmt_container_material_types(params[:changed_value])
          json_actions([OpenStruct.new(type: :replace_select_options,
                                       dom_id: 'empty_bin_transaction_item_rmt_container_material_type_id',
                                       options_array: rmt_container_material_types)])
        end
        r.on 'new' do    # NEW
          check_auth!('empty bins', 'new')
          show_partial_or_page(r) { RawMaterials::EmptyBins::EmptyBinTransactionItem::New.call(remote: fetch?(r), interactor: @interactor) }
        end
        r.on 'add' do
          stepper.add_bin_set(params[:empty_bin_transaction_item])
          empty_bin_types = stepper.for_select_bin_sets
          json_actions([OpenStruct.new(type: :replace_list_items,
                                       dom_id: 'bin_set_list',
                                       items: empty_bin_types),
                        OpenStruct.new(type: :clear_form_validation,
                                       dom_id: 'empty_bin_transaction_item')],
                       'Bin Type Added',
                       keep_dialog_open: true)
        end
        r.on 'remove', Integer do |id|
          stepper.remove_bin_set(id)
          empty_bin_types = stepper.for_select_bin_sets
          json_actions([OpenStruct.new(type: :replace_list_items,
                                       dom_id: 'bin_set_list',
                                       items: empty_bin_types),
                        OpenStruct.new(type: :clear_form_validation,
                                       dom_id: 'empty_bin_transaction_item')],
                       'Bin Type Removed',
                       keep_dialog_open: true)
        end
        r.on 'done' do
          res = @interactor.validate_stepper
          if res.success
            res = @interactor.create_empty_bin_transaction
            if res.success
              flash[:notice] = res.message
            else
              flash[:error] = res.message
            end
            redirect_via_json('/list/empty_bin_transaction_items')
          else
            re_show_form(r, res, url: '/raw_materials/empty_bins/empty_bin_transactions/empty_bin_transaction_items/new') do
              RawMaterials::EmptyBins::EmptyBinTransactionItem::New.call(form_values: {},
                                                                         form_errors: res.errors,
                                                                         remote: true,
                                                                         interactor: @interactor)
            end
          end
        end
      end
      r.on 'delivery_id_changed' do
        truck_registration_number = if params[:changed_value].blank?
                                      nil
                                    else
                                      @interactor.truck_registration_number(params[:changed_value])
                                    end
        json_actions([OpenStruct.new(type: :replace_input_value,
                                     dom_id: 'empty_bin_transaction_truck_registration_number',
                                     value: truck_registration_number)])
      end
      r.on 'issue_empty_bins' do
        r.on 'new' do
          check_auth!('empty bins', 'new')
          stepper.reset
          show_partial_or_page(r) { RawMaterials::EmptyBins::EmptyBinTransaction::IssueEmptyBins.call(remote: fetch?(r)) }
        end
        r.post do        # CREATE
          res = @interactor.validate_issue_params(params[:empty_bin_transaction])
          if res.success
            stepper.merge(params[:empty_bin_transaction])
            r.redirect '/raw_materials/empty_bins/empty_bin_transactions/empty_bin_transaction_items/new'
          else
            re_show_form(r, res, url: '/raw_materials/empty_bins/empty_bin_transactions/issue_empty_bins/new') do
              RawMaterials::EmptyBins::EmptyBinTransaction::IssueEmptyBins.call(form_values: params[:empty_bin_transaction],
                                                                                form_errors: res.errors,
                                                                                remote: fetch?(r))
            end
          end
        end
      end
      r.on 'receive_empty_bins' do
        r.on 'new' do
          check_auth!('empty bins', 'new')
          stepper.reset
          show_partial_or_page(r) { RawMaterials::EmptyBins::EmptyBinTransaction::ReceiveEmptyBins.call(remote: fetch?(r)) }
        end
        r.post do        # CREATE
          res = @interactor.validate_receive_params(params[:empty_bin_transaction])
          if res.success
            stepper.merge(params[:empty_bin_transaction])
            r.redirect '/raw_materials/empty_bins/empty_bin_transactions/empty_bin_transaction_items/new'
          else
            re_show_form(r, res, url: '/raw_materials/empty_bins/empty_bin_transactions/receive_empty_bins/new') do
              RawMaterials::EmptyBins::EmptyBinTransaction::ReceiveEmptyBins.call(form_values: params[:empty_bin_transaction],
                                                                                  form_errors: res.errors,
                                                                                  remote: fetch?(r))
            end
          end
        end
      end
      r.on 'adhoc_transaction' do
        r.on 'new' do
          check_auth!('empty bins', 'new')
          stepper.reset
          show_partial_or_page(r) { RawMaterials::EmptyBins::EmptyBinTransaction::AdhocMove.call(remote: fetch?(r)) }
        end
        r.post do        # CREATE
          res = @interactor.validate_adhoc_params(params[:empty_bin_transaction])
          if res.success
            stepper.merge(params[:empty_bin_transaction])
            r.redirect '/raw_materials/empty_bins/empty_bin_transactions/empty_bin_transaction_items/new'
          else
            re_show_form(r, res, url: '/raw_materials/empty_bins/empty_bin_transactions/adhoc_transaction/new') do
              RawMaterials::EmptyBins::EmptyBinTransaction::AdhocMove.call(form_values: params[:empty_bin_transaction],
                                                                           form_errors: res.errors,
                                                                           remote: fetch?(r))
            end
          end
        end
      end
      r.on 'adhoc_create' do
        r.on 'new' do
          check_auth!('empty bins', 'new')
          stepper.reset
          show_partial_or_page(r) { RawMaterials::EmptyBins::EmptyBinTransaction::AdhocCreate.call(remote: fetch?(r)) }
        end
        r.post do        # CREATE
          res = @interactor.validate_adhoc_create_params(params[:empty_bin_transaction])
          if res.success
            stepper.merge(params[:empty_bin_transaction])
            r.redirect '/raw_materials/empty_bins/empty_bin_transactions/empty_bin_transaction_items/new'
          else
            re_show_form(r, res, url: '/raw_materials/empty_bins/empty_bin_transactions/adhoc_create/new') do
              RawMaterials::EmptyBins::EmptyBinTransaction::AdhocCreate.call(form_values: params[:empty_bin_transaction],
                                                                             form_errors: res.errors,
                                                                             remote: fetch?(r))
            end
          end
        end
      end
      r.on 'adhoc_destroy' do
        r.on 'new' do
          check_auth!('empty bins', 'new')
          stepper.reset
          show_partial_or_page(r) { RawMaterials::EmptyBins::EmptyBinTransaction::AdhocDestroy.call(remote: fetch?(r)) }
        end
        r.post do        # CREATE
          res = @interactor.validate_adhoc_destroy_params(params[:empty_bin_transaction])
          if res.success
            stepper.merge(params[:empty_bin_transaction])
            r.redirect '/raw_materials/empty_bins/empty_bin_transactions/empty_bin_transaction_items/new'
          else
            re_show_form(r, res, url: '/raw_materials/empty_bins/empty_bin_transactions/adhoc_destroy/new') do
              RawMaterials::EmptyBins::EmptyBinTransaction::AdhocDestroy.call(form_values: params[:empty_bin_transaction],
                                                                              form_errors: res.errors,
                                                                              remote: fetch?(r))
            end
          end
        end
      end
    end

    # EMPTY BIN TRANSACTION ITEMS
    # --------------------------------------------------------------------------
    r.on 'empty_bin_transaction_items', Integer do |id|
      interactor = RawMaterialsApp::EmptyBinTransactionItemInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      # Check for notfound:
      r.on !interactor.exists?(:empty_bin_transaction_items, id) do
        handle_not_found(r)
      end

      r.on 'edit' do   # EDIT
        check_auth!('empty bins', 'edit')
        interactor.assert_permission!(:edit, id)
        show_partial { RawMaterials::EmptyBins::EmptyBinTransactionItem::Edit.call(id) }
      end

      r.is do
        r.get do       # SHOW
          check_auth!('empty bins', 'read')
          show_partial { RawMaterials::EmptyBins::EmptyBinTransactionItem::Show.call(id) }
        end
        r.patch do     # UPDATE
          res = interactor.update_empty_bin_transaction_item(id, params[:empty_bin_transaction_item])
          if res.success
            row_keys = %i[
              empty_bin_transaction_id
              rmt_container_material_owner_id
              empty_bin_from_location_id
              empty_bin_to_location_id
              quantity_bins
            ]
            update_grid_row(id, changes: select_attributes(res.instance, row_keys), notice: res.message)
          else
            re_show_form(r, res) { RawMaterials::EmptyBins::EmptyBinTransactionItem::Edit.call(id, form_values: params[:empty_bin_transaction_item], form_errors: res.errors) }
          end
        end
        r.delete do    # DELETE
          check_auth!('empty bins', 'delete')
          interactor.assert_permission!(:delete, id)
          res = interactor.delete_empty_bin_transaction_item(id)
          if res.success
            delete_grid_row(id, notice: res.message)
          else
            show_json_error(res.message, status: 200)
          end
        end
      end
    end

    # EMPTY BIN LOCATION TRANSACTION HISTORY
    r.on 'location_transaction_history', Integer do |id|
      res = @interactor.get_applicable_transaction_item_ids(id)
      history_ids = res.instance.join(',')
      r.redirect "/list/transaction_history_items/with_params?key=history&history_ids=#{history_ids}"
    end
  end
end
# rubocop:enable Metrics/BlockLength
# rubocop:enable Metrics/ClassLength
