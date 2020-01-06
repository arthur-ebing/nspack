# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
class Nspack < Roda # rubocop:disable Metrics/ClassLength
  route 'dispatch', 'finished_goods' do |r|
    # VOYAGES_PORTS
    # --------------------------------------------------------------------------
    r.on 'voyage_ports', Integer do |id|
      interactor = FinishedGoodsApp::VoyagePortInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      # Check for notfound:
      r.on !interactor.exists?(:voyage_ports, id) do
        handle_not_found(r)
      end

      r.on 'edit' do   # EDIT
        check_auth!('dispatch', 'edit')
        interactor.assert_permission!(:edit, id)
        show_partial { FinishedGoods::Dispatch::VoyagePort::Edit.call(id) }
      end

      r.is do
        r.get do       # SHOW
          check_auth!('dispatch', 'read')
          show_partial { FinishedGoods::Dispatch::VoyagePort::Show.call(id) }
        end
        r.patch do     # UPDATE
          res = interactor.update_voyage_port(id, params[:voyage_port])
          if res.success
            row_keys = %i[
              id
              voyage_id
              port_id
              trans_shipment_vessel_id
              ata
              atd
              eta
              etd
              active
              port_code
              trans_shipment_vessel
              port_type_code
            ]
            update_grid_row(id, changes: select_attributes(res.instance, row_keys), notice: res.message)
          else
            re_show_form(r, res) { FinishedGoods::Dispatch::VoyagePort::Edit.call(id, form_values: params[:voyage_port], form_errors: res.errors) }
          end
        end
        r.delete do    # DELETE
          check_auth!('dispatch', 'delete')
          interactor.assert_permission!(:delete, id)
          res = interactor.delete_voyage_port(id)
          if res.success
            delete_grid_row(id, notice: res.message)
          else
            show_json_error(res.message, status: 200)
          end
        end
      end
    end

    r.on 'voyage_ports' do
      r.on 'port_type_changed' do
        if params[:changed_value].nil_or_empty?
          blank_json_response
        else
          actions = []
          voyage_type_id = FinishedGoodsApp::VoyageRepo.new.find_voyage_flat(params[:voyage_id])&.voyage_type_id
          port_list = MasterfilesApp::PortRepo.new.for_select_ports(port_type_id: params[:changed_value], voyage_type_id: voyage_type_id)
          actions << OpenStruct.new(type: :replace_select_options, dom_id: 'voyage_port_port_id', options_array: port_list)
          port_type_code = MasterfilesApp::PortTypeRepo.new.find_port_type(params[:changed_value])&.port_type_code
          port_type_code = port_type_code.nil? ? 'stub' : port_type_code
          dom_id_hash = { 'voyage_port_trans_shipment_vessel_id_field_wrapper': %([TRANSSHIP]),
                          'voyage_port_atd_field_wrapper': %([TRANSSHIP POD]),
                          'voyage_port_etd_field_wrapper': %([TRANSSHIP POD]),
                          'voyage_port_ata_field_wrapper': %([TRANSSHIP POL]),
                          'voyage_port_eta_field_wrapper': %([TRANSSHIP POL]),
                          'voyage_port_port_id_field_wrapper': %([TRANSSHIP POL POD]) }
          dom_id_hash.each do |dom_id, port_type|
            actions << OpenStruct.new(type: port_type.include?(port_type_code) ? :show_element : :hide_element, dom_id: dom_id.to_s)
          end
          json_actions(actions)
        end
      end
    end

    # VOYAGES
    # --------------------------------------------------------------------------
    r.on 'voyages', Integer do |id|
      interactor = FinishedGoodsApp::VoyageInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      # Check for notfound:
      r.on !interactor.exists?(:voyages, id) do
        handle_not_found(r)
      end

      r.on 'edit' do   # EDIT
        check_auth!('dispatch', 'edit')
        interactor.assert_permission!(:edit, id)
        show_page { FinishedGoods::Dispatch::Voyage::Edit.call(id, back_url: request.referer) }
      end

      r.on 'voyage_ports' do
        interactor = FinishedGoodsApp::VoyagePortInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})
        r.on 'new' do    # NEW
          check_auth!('dispatch', 'new')
          show_partial_or_page(r) { FinishedGoods::Dispatch::VoyagePort::New.call(id, remote: fetch?(r)) }
        end
        r.post do        # CREATE
          res = interactor.create_voyage_port(id, params[:voyage_port])
          if res.success
            row_keys = %i[
              id
              voyage_id
              port_id
              trans_shipment_vessel_id
              ata
              atd
              eta
              etd
              active
              port_code
              trans_shipment_vessel
              port_type_code
            ]
            add_grid_row(attrs: select_attributes(res.instance, row_keys),
                         notice: res.message)
          else
            re_show_form(r, res, url: "/finished_goods/dispatch/voyages#{id}/voyage_ports/new") do
              FinishedGoods::Dispatch::VoyagePort::New.call(id,
                                                            form_values: params[:voyage_port],
                                                            form_errors: res.errors,
                                                            remote: fetch?(r))
            end
          end
        end
      end

      r.on 'complete' do
        r.get do
          check_auth!('dispatch', 'edit')
          interactor.assert_permission!(:complete, id)
          show_partial { FinishedGoods::Dispatch::Voyage::Complete.call(id) }
        end

        r.post do
          res = interactor.complete_a_voyage(id)
          if res.success
            flash[:notice] = res.message
            redirect_to_last_grid(r)
          else
            re_show_form(r, res) { FinishedGoods::Dispatch::Voyage::Complete.call(id) }
          end
        end
      end

      r.is do
        r.get do       # SHOW
          check_auth!('dispatch', 'read')
          show_page { FinishedGoods::Dispatch::Voyage::Show.call(id, back_url: request.referer) }
        end
        r.patch do     # UPDATE
          res = interactor.update_voyage(id, params[:voyage])
          if res.success
            flash[:notice] = res.message
            redirect_to_last_grid(r)
          else
            re_show_form(r, res) { FinishedGoods::Dispatch::Voyage::Edit.call(id, form_values: params[:voyage], form_errors: res.errors, back_url: request.referer) }
          end
        end
        r.delete do    # DELETE
          check_auth!('dispatch', 'delete')
          interactor.assert_permission!(:delete, id)
          res = interactor.delete_voyage(id)
          if res.success
            delete_grid_row(id, notice: res.message)
          else
            show_json_error(res.message, status: 200)
          end
        end
      end
    end

    r.on 'voyages' do
      interactor = FinishedGoodsApp::VoyageInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      r.on 'voyage_type_changed' do
        if params[:changed_value].nil_or_empty?
          blank_json_response
        else
          vessel_list = MasterfilesApp::VesselRepo.new.for_select_vessels(voyage_type_id: params[:changed_value])
          json_replace_select_options('voyage_vessel_id', vessel_list)
        end
      end

      r.on 'new' do    # NEW
        check_auth!('dispatch', 'new')
        show_partial_or_page(r) { FinishedGoods::Dispatch::Voyage::New.call(remote: fetch?(r)) }
      end
      r.post do        # CREATE
        res = interactor.create_voyage(params[:voyage])
        if res.success
          row_keys = %i[
            id
            vessel_id
            voyage_type_id
            voyage_number
            voyage_code
            year
            completed
            completed_at
            active
            vessel_code
            voyage_type_code
          ]
          add_grid_row(attrs: select_attributes(res.instance, row_keys),
                       notice: res.message)
        else
          re_show_form(r, res, url: '/finished_goods/dispatch/voyages/new') do
            FinishedGoods::Dispatch::Voyage::New.call(form_values: params[:voyage],
                                                      form_errors: res.errors,
                                                      remote: fetch?(r))
          end
        end
      end
    end

    # LOADS
    # --------------------------------------------------------------------------
    r.on 'loads', Integer do |id|
      interactor = FinishedGoodsApp::LoadInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      # Check for notfound:
      r.on !interactor.exists?(:loads, id) do
        handle_not_found(r)
      end

      # Unship only pallet
      r.on 'unship', String do |pallet_number|
        check_auth!('dispatch', 'edit')
        interactor.assert_permission!(:unship, id)
        res = interactor.unship_load(id, pallet_number)
        flash[:notice] = res.message
        r.redirect "/finished_goods/dispatch/loads/#{id}"
      end

      r.on 'unship' do
        check_auth!('dispatch', 'edit')
        res = interactor.unship_load(id)
        if res.success
          flash[:notice] = res.message
          r.redirect "/finished_goods/dispatch/loads/#{id}/edit"
        else
          flash[:error] = res.message
          r.redirect "/finished_goods/dispatch/loads/#{id}"
        end
      end

      r.on 'ship' do
        check_auth!('dispatch', 'edit')
        res = interactor.ship_load(id)

        if res.success
          flash[:notice] = res.message
          r.redirect '/list/loads'
        else
          flash[:error] = res.message
          r.redirect "/finished_goods/dispatch/loads/#{id}"
        end
      end

      r.on 're_send_po_edi' do
        check_auth!('dispatch', 'edit')
        res = interactor.send_po_edi(id)

        error = if res.success
                  nil
                else
                  res.message
                end
        update_dialog_content(content: wrap_content_in_style(res.message, error.nil? ? :success : :error, caption: ''))
      end

      r.on 'allocate_multiselect' do
        check_auth!('dispatch', 'edit')
        interactor.assert_permission!(:edit, id)
        res = interactor.allocate_multiselect(id, pallet_sequence_id: multiselect_grid_choices(params))
        flash[:notice] = res.message
        r.redirect request.referer
      end

      r.on 'allocate' do
        r.get do       # SHOW
          check_auth!('dispatch', 'edit')
          interactor.assert_permission!(:edit, id)
          show_partial_or_page(r) { FinishedGoods::Dispatch::Load::Allocate.call(id, back_url: session[:last_grid_url]) }
        end

        r.patch do # UPDATE
          res = interactor.allocate(id, params[:load][:pallet_list])
          if res.success
            flash[:notice] = res.message
            r.redirect "/finished_goods/dispatch/loads/#{id}/allocate"
          else
            re_show_form(r, res, url: request.fullpath) { FinishedGoods::Dispatch::Load::Allocate.call(id, form_values: params[:load], form_errors: res.errors) }
          end
        end
      end

      r.on 'copy' do    # COPY
        check_auth!('dispatch', 'new')
        show_partial_or_page(r) { FinishedGoods::Dispatch::Load::New.call(id: id, back_url: request.referer) }
      end

      r.on 'edit' do   # EDIT
        check_auth!('dispatch', 'edit')
        interactor.assert_permission!(:edit, id)
        show_partial_or_page(r) { FinishedGoods::Dispatch::Load::Edit.call(id, user: current_user, back_url: request.referer) }
      end

      r.is do
        r.get do       # SHOW
          check_auth!('dispatch', 'read')
          show_partial_or_page(r) { FinishedGoods::Dispatch::Load::Show.call(id, user: current_user, back_url: request.referer) }
        end

        r.patch do     # UPDATE
          res = interactor.update_load(id, params[:load])
          if res.success
            flash[:notice] = res.message
            redirect_to_last_grid(r)
          else
            url = "/finished_goods/dispatch/loads/#{id}"
            re_show_form(r, res, url: url) { FinishedGoods::Dispatch::Load::Edit.call(id, form_values: params[:load], form_errors: res.errors) }
          end
        end

        r.delete do    # DELETE
          check_auth!('dispatch', 'delete')
          interactor.assert_permission!(:delete, id)
          res = interactor.delete_load(id)
          if res.success
            delete_grid_row(id, notice: res.message)
          else
            show_json_error(res.message, status: 200)
          end
        end
      end
    end

    r.on 'loads' do
      interactor = FinishedGoodsApp::LoadInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})
      r.on 'last', String do |mode|
        if mode == 'view'
          id = FinishedGoodsApp::LoadRepo.new.last_load
          r.redirect "/finished_goods/dispatch/loads/#{id}" unless id.nil?
        else
          id = FinishedGoodsApp::LoadRepo.new.last_load(exclude_shipped: true)
          r.redirect "/finished_goods/dispatch/loads/#{id}/#{mode}" unless id.nil?
        end
      end

      r.on 'voyage_type_changed' do
        if params[:changed_value].nil_or_empty?
          blank_json_response
        else
          actions = []

          vessel_list = MasterfilesApp::VesselRepo.new.for_select_vessels(voyage_type_id: params[:changed_value])
          pol_port_list = MasterfilesApp::PortRepo.new.for_select_ports(voyage_type_id: params[:changed_value], port_type_code: AppConst::PORT_TYPE_POL)
          pod_port_list = MasterfilesApp::PortRepo.new.for_select_ports(voyage_type_id: params[:changed_value], port_type_code: AppConst::PORT_TYPE_POD)

          actions << OpenStruct.new(type: :replace_select_options, dom_id: 'load_vessel_id', options_array: vessel_list)
          actions << OpenStruct.new(type: :replace_select_options, dom_id: 'load_pol_port_id', options_array: pol_port_list)
          actions << OpenStruct.new(type: :replace_select_options, dom_id: 'load_pod_port_id', options_array: pod_port_list)
          json_actions(actions)
        end
      end

      r.on 'pod_port_changed' do
        if params[:changed_value].nil_or_empty?
          blank_json_response
        else
          value = MasterfilesApp::PortRepo.new.find_port_flat(params[:changed_value])&.city_id
          json_change_select_value('load_final_destination_id', value)
        end
      end

      r.on 'customer_changed' do
        if params[:changed_value].nil_or_empty?
          blank_json_response
        else
          actions = []
          party_id = MasterfilesApp::PartyRepo.new.find_party_role(params[:changed_value])&.party_id
          consignee_value = MasterfilesApp::PartyRepo.new.party_role_id_from_role_and_party_id(AppConst::ROLE_CONSIGNEE, party_id)
          receiver_value = MasterfilesApp::PartyRepo.new.party_role_id_from_role_and_party_id(AppConst::ROLE_FINAL_RECEIVER, party_id)

          actions << OpenStruct.new(type: :change_select_value, dom_id: 'load_consignee_party_role_id', value: consignee_value)
          actions << OpenStruct.new(type: :change_select_value, dom_id: 'load_final_receiver_party_role_id', value: receiver_value)
          json_actions(actions)
        end
      end

      r.on 'exporter_changed' do
        if params[:changed_value].nil_or_empty?
          blank_json_response
        else
          party_id = MasterfilesApp::PartyRepo.new.find_party_role(params[:changed_value])&.party_id
          value = MasterfilesApp::PartyRepo.new.party_role_id_from_role_and_party_id(AppConst::ROLE_BILLING_CLIENT, party_id)
          json_change_select_value('load_billing_client_party_role_id', value)
        end
      end

      r.on 'unship' do
        attrs = params[:unship]
        check_auth!('dispatch', 'edit')
        if attrs.nil_or_empty?
          show_partial_or_page(r) { FinishedGoods::Dispatch::Load::Unship.call(back_url: request.referer) }
        else
          show_partial_or_page(r) { FinishedGoods::Dispatch::Load::Show.call(attrs[:id], back_url: request.referer) }
        end
      end

      r.on 'search_load_by_pallet' do # SEARCH
        r.get do
          show_partial_or_page(r) { FinishedGoods::Dispatch::Load::Search.call(back_url: request.referer) }
        end

        r.post do # FIND
          res = interactor.find_load_with(params[:load][:pallet_number])
          if res.success
            r.redirect "/finished_goods/dispatch/loads/#{res.instance}"
          else
            re_show_form(r, res, url: '/finished_goods/dispatch/loads/search_load_by_pallet') do
              FinishedGoods::Dispatch::Load::Search.call(back_url: request.referer, form_values: params[:load], form_errors: res.errors)
            end
          end
        end
      end

      r.on 'new' do    # NEW
        check_auth!('dispatch', 'new')
        show_partial_or_page(r) { FinishedGoods::Dispatch::Load::New.call(back_url: request.referer) }
      end

      r.post do        # CREATE
        res = interactor.create_load(params[:load])
        if res.success
          flash[:notice] = res.message
          redirect_to_last_grid(r)
        else
          re_show_form(r, res, url: '/finished_goods/dispatch/loads/new') do
            FinishedGoods::Dispatch::Load::New.call(back_url: request.referer,
                                                    form_values: params[:load],
                                                    form_errors: res.errors)
          end
        end
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
