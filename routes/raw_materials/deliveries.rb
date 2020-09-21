# frozen_string_literal: true

class Nspack < Roda # rubocop:disable Metrics/ClassLength
  route 'deliveries', 'raw_materials' do |r| # rubocop:disable Metrics/BlockLength
    # --------------------------------------------------------------------------
    # RMT DELIVERIES
    # --------------------------------------------------------------------------
    r.on 'rmt_deliveries', Integer do |id| # rubocop:disable Metrics/BlockLength
      interactor = RawMaterialsApp::RmtDeliveryInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      # Check for notfound:
      r.on !interactor.exists?(:rmt_deliveries, id) do
        handle_not_found(r)
      end

      # --------------------------------------------------------------------------
      # BIN BARCODES SHEET
      # --------------------------------------------------------------------------
      r.on 'print_bin_barcodes' do
        res = CreateJasperReport.call(report_name: 'bin_tickets',
                                      user: current_user.login_name,
                                      file: 'bin_tickets',
                                      params: { delivery_id: id,
                                                keep_file: false })
        if res.success
          change_window_location_via_json(UtilityFunctions.cache_bust_url(res.instance), request.path)
        else
          show_error(res.message, fetch?(r))
        end
      end

      # --------------------------------------------------------------------------
      # DELIVERY SHEET
      # --------------------------------------------------------------------------
      r.on 'print_delivery' do
        res = CreateJasperReport.call(report_name: 'delivery',
                                      user: current_user.login_name,
                                      file: 'delivery',
                                      params: { delivery_id: id,
                                                keep_file: false })
        if res.success
          change_window_location_via_json(UtilityFunctions.cache_bust_url(res.instance), request.path)
        else
          show_error(res.message, fetch?(r))
        end
      end

      r.on 'recalc_nett_weight' do
        res = interactor.recalc_rmt_bin_nett_weight(id)
        if res.success
          flash[:notice] = res.message
        else
          flash[:error] = res.message
        end
        r.redirect(" /raw_materials/deliveries/rmt_deliveries/#{id}/edit")
      end

      r.on 'set_current_delivery' do
        res = interactor.delivery_set_current(id)
        if res.success
          flash[:notice] = "Delivery:#{id} Has Been Set As The Current Delivery"
        else
          flash[:error] = "Error: Could Not Set Delivery:#{id} As The Current Delivery"
        end
        r.redirect('/list/rmt_deliveries')
      end

      r.on 'open_delivery' do
        res = interactor.open_delivery(id)
        if res.success
          flash[:notice] = res.message
        else
          flash[:error] = unwrap_failed_response(res)
        end
        r.redirect("/list/rmt_deliveries/with_params?key=standard&id=#{id}")
      end

      r.on 'close_delivery' do
        res = interactor.close_delivery(id)
        if res.success
          flash[:notice] = res.message
        else
          flash[:error] = unwrap_failed_response(res)
        end
        r.redirect("/list/rmt_deliveries/with_params?key=standard&id=#{id}")
      end

      r.on 'edit_received_at' do
        r.get do
          show_partial_or_page(r) { RawMaterials::Deliveries::RmtDelivery::EditReceivedAt.call(id) }
        end

        r.post do
          res = interactor.update_received_at(id, params[:rmt_delivery])
          if res.success
            flash[:notice] = res.message
            redirect_to_last_grid(r)
          else
            re_show_form(r, res) { RawMaterials::Deliveries::RmtDelivery::EditReceivedAt.call(id, form_values: params[:rmt_delivery], form_errors: res.errors) }
          end
        end
      end

      r.on 'edit' do   # EDIT
        check_auth!('deliveries', 'edit')
        interactor.assert_permission!(:edit, id)
        show_partial_or_page(r) { RawMaterials::Deliveries::RmtDelivery::Edit.call(id) }
      end

      r.is do
        r.get do       # SHOW
          check_auth!('deliveries', 'read')
          show_partial_or_page(r) { RawMaterials::Deliveries::RmtDelivery::Show.call(id, back_url: back_button_url) }
        end

        r.patch do     # UPDATE
          res = interactor.update_rmt_delivery(id, params[:rmt_delivery])
          if res.success
            show_partial(notice: 'Delivery Updated') { RawMaterials::Deliveries::RmtDelivery::Edit.call(id, is_update: true) }
          else
            re_show_form(r, res) { RawMaterials::Deliveries::RmtDelivery::Edit.call(id, is_update: true, form_values: params[:rmt_delivery], form_errors: res.errors) }
          end
        end

        r.delete do    # DELETE
          check_auth!('deliveries', 'delete')
          interactor.assert_permission!(:delete, id)
          res = interactor.delete_rmt_delivery(id)
          if res.success
            delete_grid_row(id, notice: res.message)
          else
            show_json_error(res.message, status: 200)
          end
        end
      end

      r.on 'rmt_bins' do # rubocop:disable Metrics/BlockLength
        interactor = RawMaterialsApp::RmtBinInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})
        r.on 'new' do    # NEW
          check_auth!('deliveries', 'new')
          show_partial_or_page(r) { RawMaterials::Deliveries::RmtBin::New.call(id, remote: fetch?(r)) }
        end

        r.on 'create_bin_groups' do # rubocop:disable Metrics/BlockLength
          r.get do
            check_auth!('deliveries', 'new')
            show_partial_or_page(r) { RawMaterials::Deliveries::RmtBin::NewBinGroup.call(id, remote: fetch?(r)) }
          end

          r.post do # rubocop:disable Metrics/BlockLength
            params[:rmt_bin].merge!(qty_bins: 1)
            res = interactor.create_bin_groups(id, params[:rmt_bin])
            if res.success
              row_keys = %i[
                id
                rmt_delivery_id
                orchard_code
                farm_code
                puc_code
                cultivar_name
                season_code
                season_id
                cultivar_id
                orchard_id
                farm_id
                rmt_class_id
                rmt_material_owner_party_role_id
                container_type_code
                container_material_type_code
                cultivar_group_id
                location_long_code
                puc_id
                exit_ref
                qty_bins
                bin_asset_number
                tipped_asset_number
                rmt_inner_container_type_id
                rmt_inner_container_material_id
                qty_inner_bins
                production_run_rebin_id
                production_run_tipped_id
                bin_tipping_plant_resource_id
                bin_fullness
                nett_weight
                gross_weight
                bin_tipped
                bin_received_date_time
                bin_tipped_date_time
                exit_ref_date_time
                rebin_created_at
                scrapped
                scrapped_at
                status
                asset_number
              ]
              actions = []
              res.instance.each do |instance|
                actions << OpenStruct.new(type: :add_grid_row, attrs: select_attributes(instance, row_keys))
              end
              json_actions(actions, res.message)
            else
              re_show_form(r, res, url: "/raw_materials/deliveries/rmt_deliveries/#{id}/rmt_bins/create_bin_groups") do
                RawMaterials::Deliveries::RmtBin::NewBinGroup.call(id, form_values: params[:rmt_bin],
                                                                       form_errors: res.errors,
                                                                       remote: fetch?(r))
              end
            end
          end
        end

        r.on 'create_scanned_bin_groups' do # rubocop:disable Metrics/BlockLength
          r.get do
            check_auth!('deliveries', 'new')
            show_partial_or_page(r) { RawMaterials::Deliveries::RmtBin::ScanBinGroup.call(id, remote: fetch?(r)) }
          end

          r.post do # rubocop:disable Metrics/BlockLength
            res = interactor.create_scanned_bin_groups(id, params[:rmt_bin])
            if res.success
              row_keys = %i[
                id
                rmt_delivery_id
                orchard_code
                farm_code
                puc_code
                cultivar_name
                season_code
                season_id
                cultivar_id
                orchard_id
                farm_id
                rmt_class_id
                rmt_material_owner_party_role_id
                container_type_code
                container_material_type_code
                cultivar_group_id
                location_long_code
                puc_id
                exit_ref
                qty_bins
                bin_asset_number
                tipped_asset_number
                rmt_inner_container_type_id
                rmt_inner_container_material_id
                qty_inner_bins
                production_run_rebin_id
                production_run_tipped_id
                bin_tipping_plant_resource_id
                bin_fullness
                nett_weight
                gross_weight
                bin_tipped
                bin_received_date_time
                bin_tipped_date_time
                exit_ref_date_time
                rebin_created_at
                scrapped
                scrapped_at
                status
                asset_number
              ]
              actions = []
              res.instance.each do |instance|
                actions << OpenStruct.new(type: :add_grid_row, attrs: select_attributes(instance, row_keys))
              end
              json_actions(actions, res.message)
            else
              params[:rmt_bin][:scan_bin_numbers] = res.instance[:scan_bin_numbers] if res.instance[:scan_bin_numbers]
              re_show_form(r, res, url: "/raw_materials/deliveries/rmt_deliveries/#{id}/rmt_bins/create_scanned_bin_groups") do
                RawMaterials::Deliveries::RmtBin::ScanBinGroup.call(id, form_values: params[:rmt_bin],
                                                                        form_errors: res.errors,
                                                                        remote: fetch?(r))
              end
            end
          end
        end

        r.on 'direct_create' do
          r.post do
            id = interactor.find_current_delivery
            res = interactor.create_rmt_bin(id, params[:rmt_bin])
            if res.success
              r.redirect("/raw_materials/deliveries/rmt_deliveries/#{id}/edit")
            else
              re_show_form(r, res, url: "/raw_materials/deliveries/rmt_deliveries/#{id}/rmt_bins/new") do
                RawMaterials::Deliveries::RmtBin::New.call(id, is_direct_create: true, form_values: params[:rmt_bin],
                                                               form_errors: res.errors,
                                                               remote: fetch?(r))
              end
            end
          end
        end

        r.post do # rubocop:disable Metrics/BlockLength        # CREATE
          res = interactor.create_rmt_bin(id, params[:rmt_bin])
          if res.success
            row_keys = %i[
              id
              rmt_delivery_id
              orchard_code
              farm_code
              puc_code
              cultivar_name
              season_code
              season_id
              cultivar_id
              orchard_id
              farm_id
              rmt_class_id
              rmt_material_owner_party_role_id
              container_type_code
              container_material_type_code
              cultivar_group_id
              puc_id
              exit_ref
              qty_bins
              bin_asset_number
              tipped_asset_number
              rmt_inner_container_type_id
              rmt_inner_container_material_id
              qty_inner_bins
              production_run_rebin_id
              production_run_tipped_id
              bin_tipping_plant_resource_id
              bin_fullness
              nett_weight
              gross_weight
              bin_tipped
              bin_received_date_time
              bin_tipped_date_time
              exit_ref_date_time
              rebin_created_at
              scrapped
              scrapped_at
            ]
            add_grid_row(attrs: select_attributes(res.instance, row_keys),
                         notice: res.message)
          else
            re_show_form(r, res, url: "/raw_materials/deliveries/rmt_deliveries/#{id}/rmt_bins/new") do
              RawMaterials::Deliveries::RmtBin::New.call(id, form_values: params[:rmt_bin],
                                                             form_errors: res.errors,
                                                             remote: fetch?(r))
            end
          end
        end
      end
    end

    r.on 'rmt_deliveries' do # rubocop:disable Metrics/BlockLength
      interactor = RawMaterialsApp::RmtDeliveryInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})
      r.on 'new' do    # NEW
        check_auth!('deliveries', 'new')
        show_partial_or_page(r) { RawMaterials::Deliveries::RmtDelivery::New.call(remote: fetch?(r)) }
      end

      r.on 'current' do    # CURRENT
        id = RawMaterialsApp::RmtBinInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {}).find_current_delivery
        if id.nil?
          show_error('There is no delivery set up as current', fetch?(r))
        elsif interactor.delivery_tipped?(id)
          check_auth!('deliveries', 'read')
          show_partial_or_page(r) { RawMaterials::Deliveries::RmtDelivery::Show.call(id, back_url: back_button_url) }
        else
          check_auth!('deliveries', 'edit')
          interactor.assert_permission!(:edit, id)
          show_partial_or_page(r) { RawMaterials::Deliveries::RmtDelivery::Edit.call(id, back_url: back_button_url) }
        end
      end

      r.on 'farm_combo_changed' do
        if !params[:changed_value].to_s.empty?
          pucs = interactor.lookup_farms_pucs(params[:changed_value])
          json_actions([OpenStruct.new(type: :replace_select_options,
                                       dom_id: 'rmt_delivery_puc_id',
                                       options_array: pucs),
                        OpenStruct.new(type: :replace_select_options,
                                       dom_id: 'rmt_delivery_orchard_id',
                                       options_array: []),
                        OpenStruct.new(type: :replace_select_options,
                                       dom_id: 'rmt_delivery_cultivar_id',
                                       options_array: [])])
        else
          json_actions([OpenStruct.new(type: :replace_select_options,
                                       dom_id: 'rmt_delivery_puc_id',
                                       options_array: []),
                        OpenStruct.new(type: :replace_select_options,
                                       dom_id: 'rmt_delivery_orchard_id',
                                       options_array: []),
                        OpenStruct.new(type: :replace_select_options,
                                       dom_id: 'rmt_delivery_cultivar_id',
                                       options_array: [])])
        end
      end

      r.on 'puc_combo_changed' do
        if !params[:rmt_delivery_farm_id].to_s.empty? && !params[:rmt_delivery_puc_id].to_s.empty?
          orchards = interactor.lookup_orchards(params[:rmt_delivery_farm_id], params[:rmt_delivery_puc_id])
          json_actions([OpenStruct.new(type: :replace_select_options,
                                       dom_id: 'rmt_delivery_orchard_id',
                                       options_array: orchards),
                        OpenStruct.new(type: :replace_select_options,
                                       dom_id: 'rmt_delivery_cultivar_id',
                                       options_array: [])])
        else
          json_actions([OpenStruct.new(type: :replace_select_options,
                                       dom_id: 'rmt_delivery_orchard_id',
                                       options_array: []),
                        OpenStruct.new(type: :replace_select_options,
                                       dom_id: 'rmt_delivery_cultivar_id',
                                       options_array: [])])

        end
      end

      r.on 'orchard_combo_changed' do
        if !params[:rmt_delivery_orchard_id].to_s.empty?
          farm_section = MasterfilesApp::FarmRepo.new.find_orchard_farm_section(params[:rmt_delivery_orchard_id])
          cultivars = interactor.lookup_orchard_cultivars(params[:rmt_delivery_orchard_id])
          json_actions([OpenStruct.new(type: farm_section.nil_or_empty? ? :hide_element : :show_element,
                                       dom_id: 'rmt_delivery_farm_section_field_wrapper'),
                        OpenStruct.new(type: :replace_inner_html,
                                       dom_id: 'rmt_delivery_farm_section',
                                       value: farm_section),
                        OpenStruct.new(type: :replace_select_options,
                                       dom_id: 'rmt_delivery_cultivar_id',
                                       options_array: cultivars)])
        else
          json_actions([OpenStruct.new(type: :hide_element,
                                       dom_id: 'rmt_delivery_farm_section_field_wrapper'),
                        OpenStruct.new(type: :replace_inner_html,
                                       dom_id: 'rmt_delivery_farm_section',
                                       value: nil),
                        OpenStruct.new(type: :replace_select_options,
                                       dom_id: 'rmt_delivery_cultivar_id',
                                       options_array: [])])
        end
      end

      r.post do        # CREATE
        check_auth!('deliveries', 'new')
        res = interactor.create_rmt_delivery(params[:rmt_delivery])
        if res.success
          flash[:notice] = 'Delivery Created Successfully'
          r.redirect("/raw_materials/deliveries/rmt_deliveries/#{res[:instance][:id]}/edit")
        else
          re_show_form(r, res, url: '/raw_materials/deliveries/rmt_deliveries/new') do
            RawMaterials::Deliveries::RmtDelivery::New.call(form_values: params[:rmt_delivery],
                                                            form_errors: res.errors,
                                                            remote: fetch?(r))
          end
        end
      end
    end

    r.on 'rmt_delivery_costs', Integer do |rmt_delivery_id| # rubocop:disable Metrics/BlockLength
      interactor = RawMaterialsApp::RmtDeliveryInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      r.on 'edit', Integer do |cost_id|   # EDIT
        show_partial { RawMaterials::Deliveries::RmtDeliveryCost::Edit.call(rmt_delivery_id, cost_id) }
      end

      r.on 'show', Integer do |cost_id|      # SHOW
        show_partial { RawMaterials::Deliveries::RmtDeliveryCost::Show.call(rmt_delivery_id, cost_id) }
      end

      r.get do    # NEW
        show_partial_or_page(r) { RawMaterials::Deliveries::RmtDeliveryCost::New.call(rmt_delivery_id, remote: fetch?(r)) }
      end

      r.post do        # CREATE
        res = interactor.create_rmt_delivery_cost(rmt_delivery_id, params[:rmt_delivery_cost])
        if res.success
          res.instance[:id] = params[:rmt_delivery_cost][:cost_id]
          row_keys = %i[
            rmt_delivery_id
            id
            amount
            cost_code
            default_amount
            description
            cost_unit
            cost_type_code
          ]
          add_grid_row(attrs: select_attributes(res.instance, row_keys),
                       notice: res.message)
        else
          re_show_form(r, res, url: "/raw_materials/deliveries/rmt_delivery_costs/#{rmt_delivery_id}/new") do
            RawMaterials::Deliveries::RmtDeliveryCost::New.call(rmt_delivery_id,
                                                                form_values: params[:rmt_delivery_cost],
                                                                form_errors: res.errors,
                                                                remote: fetch?(r))
          end
        end
      end

      r.patch do     # UPDATE
        r.on 'update', Integer do |cost_id|
          res = interactor.update_rmt_delivery_cost(rmt_delivery_id, cost_id, params[:rmt_delivery_cost])
          if res.success
            update_grid_row(cost_id, changes: { rmt_delivery_id: res.instance[:rmt_delivery_id], id: res.instance[:cost_id], amount: res.instance[:amount] },
                                     notice: res.message)
          else
            re_show_form(r, res) { RawMaterials::Deliveries::RmtDeliveryCost::Edit.call(rmt_delivery_id, cost_id, form_values: params[:rmt_delivery_cost], form_errors: res.errors) }
          end
        end
      end

      r.delete do    # DELETE
        r.on 'delete', Integer do |cost_id|
          res = interactor.delete_rmt_delivery_cost(rmt_delivery_id, cost_id)
          if res.success
            delete_grid_row(cost_id, notice: res.message)
          else
            show_json_error(res.message, status: 200)
          end
        end
      end
    end

    r.on 'rmt_delivery_costs' do
      interactor = RawMaterialsApp::RmtDeliveryInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      r.on 'cost_changed' do
        type = :hide_element
        unless params[:changed_value].nil_or_empty?
          cost = interactor.cost(params[:changed_value])
          descr = cost.description
          amount = cost.default_amount.to_f
          type = :show_element
        end
        json_actions([OpenStruct.new(type: type, dom_id: 'rmt_delivery_cost_description_field_wrapper'),
                      OpenStruct.new(type: :replace_input_value,
                                     dom_id: 'rmt_delivery_cost_amount',
                                     value: amount.to_s),
                      OpenStruct.new(type: :replace_inner_html,
                                     dom_id: 'rmt_delivery_cost_description',
                                     value: descr.to_s)])
      end
    end

    # --------------------------------------------------------------------------
    # RMT BINS
    # --------------------------------------------------------------------------
    r.on 'rmt_bins', Integer do |id| # rubocop:disable Metrics/BlockLength
      interactor = RawMaterialsApp::RmtBinInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      # Check for notfound:
      r.on !interactor.exists?(:rmt_bins, id) do
        handle_not_found(r)
      end

      r.on 'edit' do   # EDIT
        check_auth!('deliveries', 'edit')
        interactor.assert_permission!(:edit, id)
        show_partial { RawMaterials::Deliveries::RmtBin::Edit.call(id) }
      end

      r.is do # rubocop:disable Metrics/BlockLength
        r.get do       # SHOW
          check_auth!('deliveries', 'read')
          show_partial { RawMaterials::Deliveries::RmtBin::Show.call(id) }
        end

        r.patch do # rubocop:disable Metrics/BlockLength     # UPDATE
          res = interactor.update_rmt_bin(id, params[:rmt_bin])
          if res.success
            row_keys = %i[
              id
              rmt_delivery_id
              orchard_code
              farm_code
              puc_code
              cultivar_name
              season_code
              season_id
              cultivar_id
              orchard_id
              farm_id
              rmt_class_id
              rmt_material_owner_party_role_id
              container_type_code
              container_material_type_code
              cultivar_group_id
              puc_id
              exit_ref
              qty_bins
              bin_asset_number
              tipped_asset_number
              rmt_inner_container_type_id
              rmt_inner_container_material_id
              qty_inner_bins
              production_run_rebin_id
              production_run_tipped_id
              bin_tipping_plant_resource_id
              bin_fullness
              nett_weight
              gross_weight
              bin_tipped
              bin_received_date_time
              bin_tipped_date_time
              exit_ref_date_time
              rebin_created_at
              scrapped
              scrapped_at
            ]
            update_grid_row(id, changes: select_attributes(res.instance, row_keys), notice: res.message)
          else
            re_show_form(r, res) { RawMaterials::Deliveries::RmtBin::Edit.call(id, form_values: params[:rmt_bin], form_errors: res.errors) }
          end
        end

        r.delete do    # DELETE
          check_auth!('deliveries', 'delete')
          interactor.assert_permission!(:delete, id)
          res = interactor.delete_rmt_bin(id)
          if res.success
            delete_grid_row(id, notice: res.message)
          else
            show_json_error(res.message, status: 200)
          end
        end
      end

      r.on 'print_barcode' do # BARCODE
        r.get do
          show_partial { RawMaterials::Deliveries::RmtBin::PrintBarcode.call(id) }
        end
        r.patch do
          res = interactor.print_bin_barcode(id, params[:rmt_bin])
          if res.success
            show_json_notice(res.message)
          else
            re_show_form(r, res) { RawMaterials::Deliveries::RmtBin::PrintBarcode.call(id, form_values: params[:rmt_bin], form_errors: res.errors) }
          end
        end
      end
    end

    r.on 'rmt_bins' do # rubocop:disable Metrics/BlockLength
      interactor = RawMaterialsApp::RmtBinInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      r.on 'new' do    # NEW
        check_auth!('deliveries', 'new')
        id = interactor.find_current_delivery
        if id.nil_or_empty?
          flash[:error] = 'Error: There Is No Current Delivery To Add Bins To'
          r.redirect('/list/rmt_deliveries')
        elsif RawMaterialsApp::RmtDeliveryInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {}).delivery_tipped?(id)
          flash[:error] = 'Cannot Add Bin To Current Delivery. Delivery Has Been Tipped'
          r.redirect("/raw_materials/deliveries/rmt_deliveries/#{id}")
        elsif AppConst::USE_PERMANENT_RMT_BIN_BARCODES
          r.redirect("/rmd/rmt_deliveries/rmt_bins/#{id}/new")
        else
          show_partial_or_page(r) { RawMaterials::Deliveries::RmtBin::New.call(id, is_direct_create: true, remote: fetch?(r)) }
        end
      end

      r.on 'rmt_container_type_combo_changed' do # rubocop:disable Metrics/BlockLength
        actions = []
        if !params[:changed_value].to_s.empty?
          rmt_container_material_type_ids = MasterfilesApp::RmtContainerMaterialTypeRepo.new.for_select_rmt_container_material_types(where: { rmt_container_type_id: params[:changed_value] })
          if AppConst::DELIVERY_CAPTURE_CONTAINER_MATERIAL
            actions << OpenStruct.new(type: :replace_select_options,
                                      dom_id: 'rmt_bin_rmt_container_material_type_id',
                                      options_array: rmt_container_material_type_ids)
          end
          if AppConst::DELIVERY_CAPTURE_CONTAINER_MATERIAL && AppConst::DELIVERY_CAPTURE_INNER_BINS
            actions << OpenStruct.new(type: MasterfilesApp::RmtContainerTypeRepo.new.find_container_type(params[:changed_value])&.rmt_inner_container_type_id ? :show_element : :hide_element,
                                      dom_id: 'rmt_bin_qty_inner_bins_field_wrapper')
          end
        else
          if AppConst::DELIVERY_CAPTURE_CONTAINER_MATERIAL
            actions << OpenStruct.new(type: :replace_select_options,
                                      dom_id: 'rmt_bin_rmt_container_material_type_id',
                                      options_array: [])
          end
          if AppConst::DELIVERY_CAPTURE_CONTAINER_MATERIAL && AppConst::DELIVERY_CAPTURE_INNER_BINS
            actions << OpenStruct.new(type: :hide_element,
                                      dom_id: 'rmt_bin_qty_inner_bins_field_wrapper')
          end
        end

        if AppConst::DELIVERY_CAPTURE_CONTAINER_MATERIAL && AppConst::DELIVERY_CAPTURE_CONTAINER_MATERIAL_OWNER
          actions << OpenStruct.new(type: :replace_select_options,
                                    dom_id: 'rmt_bin_rmt_material_owner_party_role_id',
                                    options_array: [])
        end

        json_actions(actions)
      end

      r.on 'container_material_type_combo_changed' do
        if !params[:rmt_bin_rmt_container_material_type_id].to_s.empty?
          filter_value = params[:rmt_bin_rmt_container_material_type_id]
        elsif !params[:changed_value].to_s.empty?
          filter_value = params[:changed_value]
        end

        if filter_value
          container_material_owners = interactor.find_container_material_owners_by_container_material_type(filter_value)
          json_replace_select_options('rmt_bin_rmt_material_owner_party_role_id', container_material_owners)
        else
          json_replace_select_options('rmt_bin_rmt_material_owner_party_role_id', [])
        end
      end
    end

    r.on 'pre_print_bin_labels' do
      r.get do
        show_partial_or_page(r) { RawMaterials::Deliveries::RmtBin::PrePrintBinLabels.call(remote: fetch?(r)) }
      end

      r.post do
        interactor = RawMaterialsApp::RmtBinInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

        res = interactor.pre_print_bin_labels(params[:rmt_delivery])
        if res.success
          show_partial_or_page(r) do
            params[:rmt_delivery][:bin_asset_numbers] = res.instance
            RawMaterials::Deliveries::RmtBin::LabelsPrintedConfirm.call(form_values: params[:rmt_delivery], notice: 'have labels printed out successfully?')
          end
        else
          re_show_form(r, res, url: '/raw_materials/deliveries/pre_print_bin_labels') do
            RawMaterials::Deliveries::RmtBin::PrePrintBinLabels.call(form_values: params[:rmt_delivery],
                                                                     form_errors: res.errors,
                                                                     remote: fetch?(r))
          end
        end
      end
    end

    r.on 'pre_printing_unsuccessful' do
      flash[:error] = 'Labels Printing Unsuccessful'
      r.redirect('/raw_materials/deliveries/pre_print_bin_labels')
    end

    r.on 'create_bin_labels' do
      interactor = RawMaterialsApp::RmtBinInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      res = interactor.create_bin_labels(params)
      if res.success
        flash[:notice] = 'Labels Printed Successfully'
        r.redirect('/raw_materials/deliveries/pre_print_bin_labels')
      else
        re_show_form(r, res, url: '/raw_materials/deliveries/pre_print_bin_labels') do
          RawMaterials::Deliveries::RmtBin::PrePrintBinLabels.call(form_values: params,
                                                                   form_errors: res.errors,
                                                                   remote: fetch?(r))
        end
      end
    end
    r.on 'preprint_orchard_combo_changed' do
      interactor = RawMaterialsApp::RmtDeliveryInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      if !params[:rmt_delivery_orchard_id].to_s.empty?
        cultivars = interactor.lookup_orchard_cultivars(params[:rmt_delivery_orchard_id])
        json_actions([OpenStruct.new(type: :replace_select_options,
                                     dom_id: 'rmt_delivery_cultivar_id',
                                     options_array: cultivars)])
      else
        json_actions([OpenStruct.new(type: :replace_select_options,
                                     dom_id: 'rmt_delivery_cultivar_id',
                                     options_array: [])])
      end
    end

    r.on 'delivery_batch' do
      interactor = RawMaterialsApp::RmtDeliveryInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      r.get do
        show_partial_or_page(r) { RawMaterials::Deliveries::RmtDelivery::Batch.call(remote: fetch?(r)) }
      end

      r.post do
        res = interactor.validate_batch_number(params[:rmt_delivery][:batch_number])
        if res.success
          store_locally(:batch_number, params[:rmt_delivery][:batch_number])
          load_via_json("/list/batch_deliveries/multi?key=standard&id=#{params[:rmt_delivery][:batch_number]}")
        else
          re_show_form(r, res) { RawMaterials::Deliveries::RmtDelivery::Batch.call(form_values: params[:rmt_delivery], form_errors: res.errors) }
        end
      end
    end

    r.on 'delivery_cost_invoice_report', Integer do |id|
      repo = RawMaterialsApp::RmtDeliveryRepo.new
      rep_delivery = repo.find_rmt_delivery(id)
      return show_error('<br>Could not print report. <br>Batch has more than one farm', fetch?(r)) unless repo.only_one_farm_batch?(rep_delivery.batch_number)

      res = CreateJasperReport.call(report_name: 'delivery_cost_invoice',
                                    user: current_user.login_name,
                                    file: 'delivery_cost_invoice',
                                    params: { batch_number: rep_delivery.batch_number,
                                              vat: AppConst::VAT,
                                              keep_file: false })
      if res.success
        change_window_location_via_json(UtilityFunctions.cache_bust_url(res.instance), request.path)
      else
        show_error(res.message, fetch?(r))
      end
    end

    r.on 'create_delivery_batch' do
      interactor = RawMaterialsApp::RmtDeliveryInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      res = interactor.create_delivery_batch(retrieve_from_local_store(:batch_number), params[:selection][:list].split(','))
      if res.success
        flash[:notice] = res.message
      else
        flash[:error] = unwrap_failed_response(res)
      end
      r.redirect('/list/delivery_batches')
    end

    r.on 'manage_delivery_batch', Integer do |id|
      interactor = RawMaterialsApp::RmtDeliveryInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      res = interactor.manage_delivery_batch(id, params[:selection][:list].split(',').map(&:to_i))
      if res.success
        flash[:notice] = res.message
      else
        flash[:error] = unwrap_failed_response(res)
      end
      r.redirect('/list/delivery_batches')
    end
  end
end
