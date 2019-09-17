# frozen_string_literal: true

class Nspack < Roda # rubocop:disable ClassLength
  route 'deliveries', 'raw_materials' do |r| # rubocop:disable Metrics/BlockLength
    # --------------------------------------------------------------------------
    # RMT DELIVERIES
    # --------------------------------------------------------------------------
    r.on 'rmt_deliveries', Integer do |id| # rubocop:disable Metrics/BlockLength
      interactor = RawMaterialsApp::RmtDeliveryInteractor.new(current_user, {}, { route_url: request.path }, {})

      # Check for notfound:
      r.on !interactor.exists?(:rmt_deliveries, id) do
        handle_not_found(r)
      end

      r.on 'edit' do   # EDIT
        check_auth!('deliveries', 'edit')
        interactor.assert_permission!(:edit, id)
        show_partial_or_page(r) { RawMaterials::Deliveries::RmtDelivery::Edit.call(id) }
      end

      r.is do
        r.get do       # SHOW
          check_auth!('deliveries', 'read')
          show_partial_or_page(r) { RawMaterials::Deliveries::RmtDelivery::Show.call(id) }
        end

        r.patch do     # UPDATE
          res = interactor.update_rmt_delivery(id, params[:rmt_delivery])
          if res.success
            show_partial_or_page(r) { RawMaterials::Deliveries::RmtDelivery::Edit.call(id, is_update: true) }
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
        interactor = RawMaterialsApp::RmtBinInteractor.new(current_user, {}, { route_url: request.path }, {})
        r.on 'new' do    # NEW
          check_auth!('deliveries', 'new')
          show_partial_or_page(r) { RawMaterials::Deliveries::RmtBin::New.call(id, remote: fetch?(r)) }
        end

        r.post do # rubocop:disable Metrics/BlockLength        # CREATE
          res = interactor.create_rmt_bin(id, params[:rmt_bin])
          if res.success
            row_keys = %i[
              id
              rmt_delivery_id
              season_id
              cultivar_id
              orchard_id
              farm_id
              rmt_class_id
              rmt_container_material_owner_id
              rmt_container_type_id
              rmt_container_material_type_id
              cultivar_group_id
              puc_id
              status
              exit_ref
              qty_bins
              bin_asset_number
              tipped_asset_number
              rmt_inner_container_type_id
              rmt_inner_container_material_id
              qty_inner_bins
              production_run_rebin_id
              production_run_tipped_id
              production_run_tipping_id
              bin_tipping_plant_resource_id
              bin_fullness
              nett_weight
              gross_weight
              bin_tipped
              tipping
              bin_received_date_time
              bin_tipped_date_time
              exit_ref_date_time
              bin_tipping_started_date_time
              rebin_created_at
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
      interactor = RawMaterialsApp::RmtDeliveryInteractor.new(current_user, {}, { route_url: request.path }, {})
      r.on 'new' do    # NEW
        check_auth!('deliveries', 'new')
        show_partial_or_page(r) { RawMaterials::Deliveries::RmtDelivery::New.call(remote: fetch?(r)) }
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
                                       options_array: [])],
                       'Farm has changed')
        else
          json_actions([OpenStruct.new(type: :replace_select_options,
                                       dom_id: 'rmt_delivery_puc_id',
                                       options_array: []),
                        OpenStruct.new(type: :replace_select_options,
                                       dom_id: 'rmt_delivery_orchard_id',
                                       options_array: []),
                        OpenStruct.new(type: :replace_select_options,
                                       dom_id: 'rmt_delivery_cultivar_id',
                                       options_array: [])],
                       'Farm has changed')
        end
      end

      r.on 'puc_combo_changed' do
        p params
        if !params[:rmt_delivery_farm_id].to_s.empty? && !params[:rmt_delivery_puc_id].to_s.empty?
          orchards = interactor.lookup_orchards(params[:rmt_delivery_farm_id], params[:rmt_delivery_puc_id])
          json_actions([OpenStruct.new(type: :replace_select_options,
                                       dom_id: 'rmt_delivery_orchard_id',
                                       options_array: orchards),
                        OpenStruct.new(type: :replace_select_options,
                                       dom_id: 'rmt_delivery_cultivar_id',
                                       options_array: [])],
                       'PUCs have changed')
        else
          json_actions([OpenStruct.new(type: :replace_select_options,
                                       dom_id: 'rmt_delivery_orchard_id',
                                       options_array: []),
                        OpenStruct.new(type: :replace_select_options,
                                       dom_id: 'rmt_delivery_cultivar_id',
                                       options_array: [])],
                       'PUCs have changed')

        end
      end

      r.on 'orchard_combo_changed' do
        if !params[:rmt_delivery_orchard_id].to_s.empty?
          cultivars = interactor.lookup_orchard_cultivars(params[:rmt_delivery_orchard_id])
          json_replace_select_options('rmt_delivery_cultivar_id', cultivars)
        else
          json_replace_select_options('rmt_delivery_cultivar_id', [])
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

    # --------------------------------------------------------------------------
    # RMT BINS
    # --------------------------------------------------------------------------
    r.on 'rmt_bins', Integer do |id| # rubocop:disable Metrics/BlockLength
      interactor = RawMaterialsApp::RmtBinInteractor.new(current_user, {}, { route_url: request.path }, {})

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
              rmt_delivery_id
              season_id
              cultivar_id
              orchard_id
              farm_id
              rmt_class_id
              rmt_container_material_owner_id
              rmt_container_type_id
              rmt_container_material_type_id
              cultivar_group_id
              puc_id
              status
              exit_ref
              qty_bins
              bin_asset_number
              tipped_asset_number
              rmt_inner_container_type_id
              rmt_inner_container_material_id
              qty_inner_bins
              production_run_rebin_id
              production_run_tipped_id
              production_run_tipping_id
              bin_tipping_plant_resource_id
              bin_fullness
              nett_weight
              gross_weight
              bin_tipped
              tipping
              bin_received_date_time
              bin_tipped_date_time
              exit_ref_date_time
              bin_tipping_started_date_time
              rebin_created_at
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
    end

    r.on 'rmt_bins' do # rubocop:disable Metrics/BlockLength
      interactor = RawMaterialsApp::RmtBinInteractor.new(current_user, {}, { route_url: request.path }, {})

      r.on 'rmt_container_type_combo_changed' do
        if !params[:changed_value].to_s.empty?
          rmt_container_material_type_ids = MasterfilesApp::RmtContainerMaterialTypeRepo.new.for_select_rmt_container_material_types(where: { rmt_container_type_id: params[:changed_value] })
          json_actions([OpenStruct.new(type: :replace_select_options,
                                       dom_id: 'rmt_bin_rmt_container_material_type_id',
                                       options_array: rmt_container_material_type_ids),
                        OpenStruct.new(type: :replace_select_options,
                                       dom_id: 'rmt_bin_rmt_container_material_owner_id',
                                       options_array: []),
                        OpenStruct.new(type: MasterfilesApp::RmtContainerTypeRepo.new.find_container_type(params[:changed_value])&.rmt_inner_container_type_id && AppConst::DELIVERY_CAPTURE_INNER_BINS == 'true' ? :show_element : :hide_element,
                                       dom_id: 'rmt_bin_qty_inner_bins_field_wrapper')],
                       'Container Type has changed')
        else
          json_actions([OpenStruct.new(type: :replace_select_options,
                                       dom_id: 'rmt_bin_rmt_container_material_type_id',
                                       options_array: []),
                        OpenStruct.new(type: :replace_select_options,
                                       dom_id: 'rmt_bin_rmt_container_material_owner_id',
                                       options_array: [])],
                       'Container Type has changed')
        end
      end

      r.on 'container_material_type_combo_changed' do
        if !params[:rmt_bin_rmt_container_material_type_id].to_s.empty?
          filter_value = params[:rmt_bin_rmt_container_material_type_id]
        elsif !params[:changed_value].to_s.empty?
          filter_value = params[:changed_value]
        end

        if filter_value
          container_material_owners = interactor.find_container_material_owners_by_container_material_type(filter_value)
          json_replace_select_options('rmt_bin_rmt_container_material_owner_id', container_material_owners)
        else
          json_replace_select_options('rmt_bin_rmt_container_material_owner_id', [])
        end
      end
    end
  end
end
