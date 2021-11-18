# frozen_string_literal: true

class Nspack < Roda
  route 'fruit', 'masterfiles' do |r|
    # COMMODITY GROUPS
    # --------------------------------------------------------------------------
    r.on 'commodity_groups', Integer do |id|
      interactor = MasterfilesApp::CommodityInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      # Check for notfound:
      r.on !interactor.exists?(:commodity_groups, id) do
        handle_not_found(r)
      end

      r.on 'edit' do   # EDIT
        check_auth!('fruit', 'edit')
        show_partial { Masterfiles::Fruit::CommodityGroup::Edit.call(id) }
      end
      r.is do
        r.get do       # SHOW
          check_auth!('fruit', 'read')
          show_partial { Masterfiles::Fruit::CommodityGroup::Show.call(id) }
        end
        r.patch do     # UPDATE
          res = interactor.update_commodity_group(id, params[:commodity_group])
          if res.success
            update_grid_row(id,
                            changes: { code: res.instance[:code],
                                       description: res.instance[:description] },
                            notice: res.message)
          else
            re_show_form(r, res) { Masterfiles::Fruit::CommodityGroup::Edit.call(id, params[:commodity_group], res.errors) }
          end
        end
        r.delete do    # DELETE
          check_auth!('fruit', 'delete')
          res = interactor.delete_commodity_group(id)
          if res.success
            delete_grid_row(id, notice: res.message)
          else
            show_json_error(res.message)
          end
        end
      end
    end

    r.on 'commodity_groups' do
      interactor = MasterfilesApp::CommodityInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})
      r.on 'new' do    # NEW
        check_auth!('fruit', 'new')
        show_partial_or_page(r) { Masterfiles::Fruit::CommodityGroup::New.call(remote: fetch?(r)) }
      end
      r.post do        # CREATE
        res = interactor.create_commodity_group(params[:commodity_group])
        if res.success
          flash[:notice] = res.message
          redirect_to_last_grid(r)
        else
          re_show_form(r, res, url: '/masterfiles/fruit/commodity_groups/new') do
            Masterfiles::Fruit::CommodityGroup::New.call(form_values: params[:commodity_group],
                                                         form_errors: res.errors,
                                                         remote: fetch?(r))
          end
        end
      end
    end

    # COMMODITIES
    # --------------------------------------------------------------------------
    r.on 'commodities', Integer do |id|
      interactor = MasterfilesApp::CommodityInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      # Check for notfound:
      r.on !interactor.exists?(:commodities, id) do
        handle_not_found(r)
      end

      r.on 'edit' do   # EDIT
        check_auth!('fruit', 'edit')
        show_partial { Masterfiles::Fruit::Commodity::Edit.call(id) }
      end

      r.on 'colour_percentages' do
        interactor = MasterfilesApp::ColourPercentageInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

        r.on 'new' do    # NEW
          check_auth!('fruit', 'new')
          show_partial_or_page(r) { Masterfiles::Fruit::ColourPercentage::New.call(id, remote: fetch?(r)) }
        end
        r.post do        # CREATE
          res = interactor.create_colour_percentage(params[:colour_percentage])
          if res.success
            row_keys = %i[
              id
              commodity_id
              commodity_code
              colour_percentage
              description
              active
            ]
            json_actions([OpenStruct.new(type: :replace_input_value,
                                         dom_id: 'colour_percentage_colour_percentage',
                                         value: ''),
                          OpenStruct.new(type: :replace_input_value,
                                         dom_id: 'colour_percentage_description',
                                         value: ''),
                          OpenStruct.new(type: :clear_form_validation,
                                         dom_id: 'colour_percentage_form'),
                          OpenStruct.new(type: :add_grid_row,
                                         attrs: select_attributes(res.instance, row_keys))],
                         res.message,
                         keep_dialog_open: true)
          else
            re_show_form(r, res, url: "/masterfiles/fruit/commodities/#{id}/colour_percentages/new") do
              Masterfiles::Fruit::ColourPercentage::New.call(id,
                                                             form_values: params[:colour_percentage],
                                                             form_errors: res.errors,
                                                             remote: fetch?(r))
            end
          end
        end
      end

      r.is do
        r.get do       # SHOW
          check_auth!('fruit', 'read')
          show_partial { Masterfiles::Fruit::Commodity::Show.call(id) }
        end
        r.patch do     # UPDATE
          res = interactor.update_commodity(id, params[:commodity])
          if res.success
            row_keys = %i[
              id
              commodity_group_code
              code
              description
              hs_code
              requires_standard_counts
              use_size_ref_for_edi
              active
              colour_applies
            ]
            update_grid_row(id, changes: select_attributes(res.instance, row_keys), notice: res.message)
          else
            re_show_form(r, res) { Masterfiles::Fruit::Commodity::Edit.call(id, params[:commodity], res.errors) }
          end
        end
        r.delete do    # DELETE
          check_auth!('fruit', 'delete')
          res = interactor.delete_commodity(id)
          if res.success
            delete_grid_row(id, notice: res.message)
          else
            show_json_error(res.message)
          end
        end
      end
    end

    r.on 'commodities' do
      interactor = MasterfilesApp::CommodityInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})
      r.on 'new' do    # NEW
        check_auth!('fruit', 'new')
        show_partial_or_page(r) { Masterfiles::Fruit::Commodity::New.call(remote: fetch?(r)) }
      end
      r.post do        # CREATE
        res = interactor.create_commodity(params[:commodity])
        if res.success
          row_keys = %i[
            id
            commodity_group_code
            code
            description
            hs_code
            requires_standard_counts
            use_size_ref_for_edi
            active
            colour_applies
          ]
          add_grid_row(attrs: select_attributes(res.instance, row_keys),
                       notice: res.message)
        else
          re_show_form(r, res, url: '/masterfiles/fruit/commodities/new') do
            Masterfiles::Fruit::Commodity::New.call(form_values: params[:commodity],
                                                    form_errors: res.errors,
                                                    remote: fetch?(r))
          end
        end
      end
    end

    # CULTIVAR GROUPS
    # --------------------------------------------------------------------------
    r.on 'cultivar_groups', Integer do |id|
      interactor = MasterfilesApp::CultivarGroupInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      # Check for notfound:
      r.on !interactor.exists?(:cultivar_groups, id) do
        handle_not_found(r)
      end

      r.on 'edit' do   # EDIT
        check_auth!('fruit', 'edit')
        show_partial { Masterfiles::Fruit::CultivarGroup::Edit.call(id) }
      end
      r.is do
        r.get do       # SHOW
          check_auth!('fruit', 'read')
          show_partial { Masterfiles::Fruit::CultivarGroup::Show.call(id) }
        end
        r.patch do     # UPDATE
          res = interactor.update_cultivar_group(id, params[:cultivar_group])
          if res.success
            update_grid_row(id,
                            changes: { cultivar_group_code: res.instance[:cultivar_group_code],
                                       commodity_code: res.instance[:commodity_code],
                                       description: res.instance[:description] },
                            notice: res.message)
          else
            re_show_form(r, res) { Masterfiles::Fruit::CultivarGroup::Edit.call(id, params[:cultivar_group], res.errors) }
          end
        end
        r.delete do    # DELETE
          check_auth!('fruit', 'delete')
          # interactor.assert_permission!(:delete, id)
          res = interactor.delete_cultivar_group(id)
          if res.success
            delete_grid_row(id, notice: res.message)
          else
            show_json_error(res.message, status: 200)
          end
        end
      end
    end

    r.on 'cultivar_groups' do
      interactor = MasterfilesApp::CultivarGroupInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})
      r.on 'new' do    # NEW
        check_auth!('fruit', 'new')
        show_partial_or_page(r) { Masterfiles::Fruit::CultivarGroup::New.call(remote: fetch?(r)) }
      end
      r.post do        # CREATE
        res = interactor.create_cultivar_group(params[:cultivar_group])
        if res.success
          if fetch?(r)
            row_keys = %i[
              id
              cultivar_group_code
              description
              active
              commodity_code
            ]
            add_grid_row(attrs: select_attributes(res.instance, row_keys),
                         notice: res.message)
          else
            flash[:notice] = res.message
            redirect_to_last_grid(r)
          end
        else
          re_show_form(r, res, url: '/masterfiles/fruit/cultivar_groups/new') do
            Masterfiles::Fruit::CultivarGroup::New.call(form_values: params[:cultivar_group],
                                                        form_errors: res.errors,
                                                        remote: fetch?(r))
          end
        end
      end
    end

    # CULTIVARS
    # --------------------------------------------------------------------------
    r.on 'cultivars', Integer do |id|
      interactor = MasterfilesApp::CultivarInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      # Check for notfound:
      r.on !interactor.exists?(:cultivars, id) do
        handle_not_found(r)
      end

      r.on 'edit' do   # EDIT
        check_auth!('fruit', 'edit')
        show_partial { Masterfiles::Fruit::Cultivar::Edit.call(id) }
      end

      # MARKETING VARIETIES
      # --------------------------------------------------------------------------
      r.on 'link_marketing_varieties' do
        r.post do
          interactor = MasterfilesApp::CultivarInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})
          res = interactor.link_marketing_varieties(id, multiselect_grid_choices(params))

          if res.success
            flash[:notice] = res.message
          else
            flash[:error] = res.message
          end
          redirect_to_last_grid(r)
        end
      end
      r.on 'marketing_varieties' do
        interactor = MasterfilesApp::CultivarInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})
        r.on 'new' do    # NEW
          check_auth!('fruit', 'new')
          show_partial_or_page(r) { Masterfiles::Fruit::MarketingVariety::New.call(id, remote: fetch?(r)) }
        end
        r.post do        # CREATE
          res = interactor.create_marketing_variety(id, params[:marketing_variety])
          if res.success
            flash[:notice] = res.message
            redirect_to_last_grid(r)
          else
            re_show_form(r, res, url: "/masterfiles/fruit/cultivars/#{id}/marketing_varieties/new") do
              Masterfiles::Fruit::MarketingVariety::New.call(id,
                                                             form_values: params[:marketing_variety],
                                                             form_errors: res.errors,
                                                             remote: fetch?(r))
            end
          end
        end
      end
      r.is do
        r.get do       # SHOW
          check_auth!('fruit', 'read')
          show_partial { Masterfiles::Fruit::Cultivar::Show.call(id) }
        end
        r.patch do     # UPDATE
          res = interactor.update_cultivar(id, params[:cultivar])
          if res.success
            row_keys = %i[
              cultivar_group_id
              cultivar_group_code
              cultivar_name
              cultivar_code
              description
            ]
            update_grid_row(id, changes: select_attributes(res.instance, row_keys), notice: res.message)
          else
            re_show_form(r, res) { Masterfiles::Fruit::Cultivar::Edit.call(id, params[:cultivar], res.errors) }
          end
        end
        r.delete do    # DELETE
          check_auth!('fruit', 'delete')
          # interactor.assert_permission!(:delete, id)
          res = interactor.delete_cultivar(id)
          if res.success
            delete_grid_row(id, notice: res.message)
          else
            show_json_error(res.message, status: 200)
          end
        end
      end
    end

    r.on 'cultivars' do
      interactor = MasterfilesApp::CultivarInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})
      r.on 'new' do    # NEW
        check_auth!('fruit', 'new')
        show_partial_or_page(r) { Masterfiles::Fruit::Cultivar::New.call(remote: fetch?(r)) }
      end
      r.post do        # CREATE
        res = interactor.create_cultivar(params[:cultivar])
        if res.success
          flash[:notice] = res.message
          redirect_to_last_grid(r)
        else
          re_show_form(r, res, url: '/masterfiles/fruit/cultivars/new') do
            Masterfiles::Fruit::Cultivar::New.call(form_values: params[:cultivar],
                                                   form_errors: res.errors,
                                                   remote: fetch?(r))
          end
        end
      end
    end

    r.on 'marketing_varieties', Integer do |id|
      interactor = MasterfilesApp::CultivarInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      # Check for notfound:
      r.on !interactor.exists?(:marketing_varieties, id) do
        handle_not_found(r)
      end

      r.on 'edit' do   # EDIT
        check_auth!('fruit', 'edit')
        show_partial { Masterfiles::Fruit::MarketingVariety::Edit.call(id) }
      end
      r.is do
        r.get do       # SHOW
          check_auth!('fruit', 'read')
          show_partial { Masterfiles::Fruit::MarketingVariety::Show.call(id) }
        end
        r.patch do     # UPDATE
          res = interactor.update_marketing_variety(id, params[:marketing_variety])
          if res.success
            row_keys = %i[
              marketing_variety_code
              description
              inspection_variety
            ]
            update_grid_row(id, changes: select_attributes(res.instance, row_keys), notice: res.message)
          else
            re_show_form(r, res) { Masterfiles::Fruit::MarketingVariety::Edit.call(id, params[:marketing_variety], res.errors) }
          end
        end

        r.delete do    # DELETE
          check_auth!('fruit', 'delete')
          # interactor.assert_permission!(:delete, id)
          res = interactor.delete_marketing_variety(id)
          if res.success
            delete_grid_row(id, notice: res.message)
          else
            show_json_error(res.message, status: 200)
          end
        end
      end
    end

    # BASIC PACK CODES
    # --------------------------------------------------------------------------
    r.on 'basic_pack_codes', Integer do |id|
      interactor = MasterfilesApp::BasicPackInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      # Check for notfound:
      r.on !interactor.exists?(:basic_pack_codes, id) do
        handle_not_found(r)
      end

      r.on 'edit' do   # EDIT
        check_auth!('fruit', 'edit')
        show_partial { Masterfiles::Fruit::BasicPack::Edit.call(id) }
      end
      r.is do
        r.get do       # SHOW
          check_auth!('fruit', 'read')
          show_partial { Masterfiles::Fruit::BasicPack::Show.call(id) }
        end
        r.patch do     # UPDATE
          res = interactor.update_basic_pack(id, params[:basic_pack])
          if res.success
            row_keys = %i[
              basic_pack_code
              description
              length_mm
              width_mm
              height_mm
              footprint_code
              standard_pack_codes
              bin
            ]
            update_grid_row(id, changes: select_attributes(res.instance, row_keys), notice: res.message)
          else
            re_show_form(r, res) { Masterfiles::Fruit::BasicPack::Edit.call(id, params[:basic_pack], res.errors) }
          end
        end
        r.delete do    # DELETE
          check_auth!('fruit', 'delete')
          res = interactor.delete_basic_pack(id)
          if res.success
            delete_grid_row(id, notice: res.message)
          else
            show_json_error(res.message)
          end
        end
      end
    end

    r.on 'basic_pack_codes' do
      interactor = MasterfilesApp::BasicPackInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      r.on 'height_changed' do
        footprint_code = params[:basic_pack_footprint_code]
        basic_pack_code = if footprint_code.blank? || params[:changed_value].blank?
                            params[:basic_pack_basic_pack_code]
                          else
                            footprint_code + params[:changed_value]
                          end
        json_replace_input_value('basic_pack_basic_pack_code', basic_pack_code)
      end

      r.on 'footprint_code_changed' do
        height_mm = params[:basic_pack_height_mm]
        basic_pack_code = if height_mm.blank? || params[:changed_value].blank?
                            params[:basic_pack_basic_pack_code]
                          else
                            params[:changed_value] + height_mm
                          end
        json_replace_input_value('basic_pack_basic_pack_code', basic_pack_code)
      end

      r.on 'new' do    # NEW
        check_auth!('fruit', 'new')
        interactor.assert_permission!(:create)
        show_partial_or_page(r) { Masterfiles::Fruit::BasicPack::New.call(remote: fetch?(r)) }
      end
      r.post do        # CREATE
        res = interactor.create_basic_pack(params[:basic_pack])
        if res.success
          row_keys = %i[
            id
            basic_pack_code
            description
            length_mm
            width_mm
            height_mm
            active
            footprint_code
            standard_pack_codes
            bin
          ]
          add_grid_row(attrs: select_attributes(res.instance, row_keys),
                       notice: res.message)
        else
          re_show_form(r, res, url: '/masterfiles/fruit/basic_pack_codes/new') do
            Masterfiles::Fruit::BasicPack::New.call(form_values: params[:basic_pack],
                                                    form_errors: res.errors,
                                                    remote: fetch?(r))
          end
        end
      end
    end

    # STANDARD PACK CODES
    # --------------------------------------------------------------------------
    r.on 'standard_pack_codes', Integer do |id|
      interactor = MasterfilesApp::StandardPackInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      # Check for notfound:
      r.on !interactor.exists?(:standard_pack_codes, id) do
        handle_not_found(r)
      end

      r.on 'edit' do   # EDIT
        check_auth!('fruit', 'edit')
        show_partial { Masterfiles::Fruit::StandardPack::Edit.call(id) }
      end
      r.is do
        r.get do       # SHOW
          check_auth!('fruit', 'read')
          show_partial { Masterfiles::Fruit::StandardPack::Show.call(id) }
        end
        r.patch do     # UPDATE
          res = interactor.update_standard_pack(id, params[:standard_pack])
          if res.success
            row_keys = %i[
              standard_pack_code
              material_mass
              plant_resource_button_indicator
              description
              std_pack_label_code
              use_size_ref_for_edi
              palletizer_incentive_rate
              bin
              rmt_container_material_owner
              basic_pack_codes
              active
            ]
            update_grid_row(id, changes: select_attributes(res.instance, row_keys), notice: res.message)
          else
            re_show_form(r, res) { Masterfiles::Fruit::StandardPack::Edit.call(id, params[:standard_pack], res.errors) }
          end
        end
        r.delete do    # DELETE
          check_auth!('fruit', 'delete')
          res = interactor.delete_standard_pack(id)
          if res.success
            delete_grid_row(id, notice: res.message)
          else
            show_json_error(res.message)
          end
        end
      end
    end

    r.on 'standard_pack_codes' do
      interactor = MasterfilesApp::StandardPackInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      r.on 'bin_changed' do
        handle_ui_change(:standard_pack, :bin, params)
      end

      r.on 'new' do    # NEW
        check_auth!('fruit', 'new')
        show_partial_or_page(r) { Masterfiles::Fruit::StandardPack::New.call(remote: fetch?(r)) }
      end
      r.post do        # CREATE
        res = interactor.create_standard_pack(params[:standard_pack])
        if res.success
          row_keys = %i[
            id
            standard_pack_code
            active
            material_mass
            plant_resource_button_indicator
            description
            std_pack_label_code
            use_size_ref_for_edi
            bin
            palletizer_incentive_rate
            rmt_container_material_owner_id
            rmt_container_material_owner
            basic_pack_codes
          ]
          add_grid_row(attrs: select_attributes(res.instance, row_keys),
                       notice: res.message)
        else
          re_show_form(r, res, url: '/masterfiles/fruit/standard_pack_codes/new') do
            Masterfiles::Fruit::StandardPack::New.call(form_values: params[:standard_pack],
                                                       form_errors: res.errors,
                                                       remote: fetch?(r))
          end
        end
      end
    end

    # STANDARD PRODUCT WEIGHTS
    # --------------------------------------------------------------------------
    r.on 'standard_product_weights', Integer do |id|
      interactor = MasterfilesApp::StandardProductWeightInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      # Check for notfound:
      r.on !interactor.exists?(:standard_product_weights, id) do
        handle_not_found(r)
      end

      r.on 'edit' do   # EDIT
        check_auth!('fruit', 'edit')
        interactor.assert_permission!(:edit, id)
        show_partial { Masterfiles::Fruit::StandardProductWeight::Edit.call(id) }
      end

      r.on 'derive_ratios' do
        res = interactor.derive_ratios(id)
        if res.success
          flash[:notice] = res.message
        else
          flash[:error] = res.message
        end
        redirect_to_last_grid(r)
      end

      r.is do
        r.get do       # SHOW
          check_auth!('fruit', 'read')
          show_partial { Masterfiles::Fruit::StandardProductWeight::Show.call(id) }
        end
        r.patch do     # UPDATE
          res = interactor.update_standard_product_weight(id, params[:standard_product_weight])
          if res.success
            row_keys = %i[
              commodity_id
              commodity_code
              standard_pack_id
              standard_pack_code
              gross_weight
              nett_weight
              standard_carton_nett_weight
              ratio_to_standard_carton
              is_standard_carton
              min_gross_weight
              max_gross_weight
            ]
            update_grid_row(id, changes: select_attributes(res.instance, row_keys), notice: res.message)
          else
            re_show_form(r, res) { Masterfiles::Fruit::StandardProductWeight::Edit.call(id, form_values: params[:standard_product_weight], form_errors: res.errors) }
          end
        end
        r.delete do    # DELETE
          check_auth!('fruit', 'delete')
          interactor.assert_permission!(:delete, id)
          res = interactor.delete_standard_product_weight(id)
          if res.success
            delete_grid_row(id, notice: res.message)
          else
            show_json_error(res.message, status: 200)
          end
        end
      end
    end

    r.on 'standard_product_weights' do
      interactor = MasterfilesApp::StandardProductWeightInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      r.on 'derive_all_ratios' do
        res = interactor.derive_all_ratios
        if res.success
          flash[:notice] = res.message
        else
          flash[:error] = res.message
        end
        redirect_to_last_grid(r)
      end

      r.on 'new' do    # NEW
        check_auth!('fruit', 'new')
        show_partial_or_page(r) { Masterfiles::Fruit::StandardProductWeight::New.call(remote: fetch?(r)) }
      end
      r.post do        # CREATE
        res = interactor.create_standard_product_weight(params[:standard_product_weight])
        if res.success
          row_keys = %i[
            id
            commodity_id
            commodity_code
            standard_pack_id
            standard_pack_code
            gross_weight
            nett_weight
            active
            standard_carton_nett_weight
            ratio_to_standard_carton
            is_standard_carton
            min_gross_weight
            max_gross_weight
          ]
          add_grid_row(attrs: select_attributes(res.instance, row_keys),
                       notice: res.message)
        else
          re_show_form(r, res, url: '/masterfiles/fruit/standard_product_weights/new') do
            Masterfiles::Fruit::StandardProductWeight::New.call(form_values: params[:standard_product_weight],
                                                                form_errors: res.errors,
                                                                remote: fetch?(r))
          end
        end
      end
    end

    # STD FRUIT SIZE COUNTS
    # --------------------------------------------------------------------------
    r.on 'std_fruit_size_counts', Integer do |id|
      interactor = MasterfilesApp::FruitSizeInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})
      # Check for notfound:
      r.on !interactor.exists?(:std_fruit_size_counts, id) do
        handle_not_found(r)
      end

      r.on 'edit' do   # EDIT
        check_auth!('fruit', 'edit')
        show_partial { Masterfiles::Fruit::StdFruitSizeCount::Edit.call(id) }
      end
      r.on 'fruit_actual_counts_for_packs' do
        r.on 'new' do    # NEW
          check_auth!('fruit', 'new')
          show_partial_or_page(r) { Masterfiles::Fruit::FruitActualCountsForPack::New.call(id, remote: fetch?(r)) }
        end
        r.post do        # CREATE
          res = interactor.create_fruit_actual_counts_for_pack(id, params[:fruit_actual_counts_for_pack])
          if res.success
            flash[:notice] = res.message
            redirect_to_last_grid(r)
          else
            re_show_form(r, res, url: "/masterfiles/fruit/std_fruit_size_counts/#{id}/fruit_actual_counts_for_packs/new") do
              Masterfiles::Fruit::FruitActualCountsForPack::New.call(id,
                                                                     form_values: params[:fruit_actual_counts_for_pack],
                                                                     form_errors: res.errors,
                                                                     remote: fetch?(r))
            end
          end
        end
      end
      r.is do
        r.get do       # SHOW
          check_auth!('fruit', 'read')
          show_partial { Masterfiles::Fruit::StdFruitSizeCount::Show.call(id) }
        end
        r.patch do     # UPDATE
          res = interactor.update_std_fruit_size_count(id, params[:std_fruit_size_count])
          if res.success
            update_grid_row(id,
                            changes: { commodity_id: res.instance[:commodity_id],
                                       uom_id: res.instance[:uom_id],
                                       size_count_description: res.instance[:size_count_description],
                                       marketing_size_range_mm: res.instance[:marketing_size_range_mm],
                                       marketing_weight_range: res.instance[:marketing_weight_range],
                                       size_count_interval_group: res.instance[:size_count_interval_group],
                                       size_count_value: res.instance[:size_count_value],
                                       minimum_size_mm: res.instance[:minimum_size_mm],
                                       maximum_size_mm: res.instance[:maximum_size_mm],
                                       average_size_mm: res.instance[:average_size_mm],
                                       minimum_weight_gm: res.instance[:minimum_weight_gm],
                                       maximum_weight_gm: res.instance[:maximum_weight_gm],
                                       average_weight_gm: res.instance[:average_weight_gm] },
                            notice: res.message)
          else
            re_show_form(r, res) { Masterfiles::Fruit::StdFruitSizeCount::Edit.call(id, params[:std_fruit_size_count], res.errors) }
          end
        end
        r.delete do    # DELETE
          check_auth!('fruit', 'delete')
          # interactor.assert_permission!(:delete, id)
          res = interactor.delete_std_fruit_size_count(id)
          if res.success
            delete_grid_row(id, notice: res.message)
          else
            show_json_error(res.message, status: 200)
          end
        end
      end
    end

    r.on 'std_fruit_size_counts' do
      interactor = MasterfilesApp::FruitSizeInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      r.on 'basic_pack_changed' do
        standard_packs = interactor.for_select_standard_packs(where: { basic_pack_id: params[:changed_value] })
        json_replace_multi_options('fruit_actual_counts_for_pack_standard_pack_code_ids', standard_packs)
      end

      r.on 'sync_pm_boms' do
        check_auth!('fruit', 'new')
        res = interactor.sync_pm_boms
        flash[:notice] = res.message
        redirect_to_last_grid(r)
      end

      r.on 'new' do    # NEW
        check_auth!('fruit', 'new')
        show_partial_or_page(r) { Masterfiles::Fruit::StdFruitSizeCount::New.call(remote: fetch?(r)) }
      end

      r.post do        # CREATE
        res = interactor.create_std_fruit_size_count(params[:std_fruit_size_count])
        if res.success
          flash[:notice] = res.message
          redirect_to_last_grid(r)
        else
          re_show_form(r, res, url: '/masterfiles/fruit/std_fruit_size_counts/new') do
            Masterfiles::Fruit::StdFruitSizeCount::New.call(form_values: params[:std_fruit_size_count],
                                                            form_errors: res.errors,
                                                            remote: fetch?(r))
          end
        end
      end
    end

    r.on 'fruit_actual_counts_for_packs', Integer do |id|
      interactor = MasterfilesApp::FruitSizeInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      # Check for notfound:
      r.on !interactor.exists?(:fruit_actual_counts_for_packs, id) do
        handle_not_found(r)
      end

      r.on 'edit' do   # EDIT
        check_auth!('fruit', 'edit')
        show_partial { Masterfiles::Fruit::FruitActualCountsForPack::Edit.call(id) }
      end

      r.is do
        r.get do       # SHOW
          check_auth!('fruit', 'read')
          show_partial { Masterfiles::Fruit::FruitActualCountsForPack::Show.call(id) }
        end
        r.patch do     # UPDATE
          res = interactor.update_fruit_actual_counts_for_pack(id, params[:fruit_actual_counts_for_pack])
          if res.success
            row_keys = %i[
              std_fruit_size_count
              basic_pack_code
              actual_count_for_pack
              standard_packs
              size_references
              active
            ]
            update_grid_row(id, changes: select_attributes(res.instance, row_keys), notice: res.message)
          else
            re_show_form(r, res) { Masterfiles::Fruit::FruitActualCountsForPack::Edit.call(id, params[:fruit_actual_counts_for_pack], res.errors) }
          end
        end
        r.delete do    # DELETE
          check_auth!('fruit', 'delete')
          # interactor.assert_permission!(:delete, id)
          res = interactor.delete_fruit_actual_counts_for_pack(id)
          if res.success
            delete_grid_row(id, notice: res.message)
          else
            show_json_error(res.message, status: 200)
          end
        end
      end
    end

    r.on 'back', Integer do |id|
      r.on 'fruit_actual_counts_for_packs' do
        # NOTE: Working on the principle that your views are allowed access to your repositories
        # Create interactor method to return parent. - return success/failure & not_found if fail...
        repo = MasterfilesApp::FruitSizeRepo.new
        actual_count = repo.find_fruit_actual_counts_for_pack(id)
        handle_not_found(r) unless actual_count
        check_auth!('fruit', 'read')
        parent_id = actual_count.std_fruit_size_count_id
        r.redirect "/list/fruit_actual_counts_for_packs/with_params?key=standard&fruit_actual_counts_for_packs.std_fruit_size_count_id=#{parent_id}"
      end
    end

    # FRUIT SIZE REFERENCES
    # --------------------------------------------------------------------------
    r.on 'fruit_size_references', Integer do |id|
      interactor = MasterfilesApp::FruitSizeReferenceInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      # Check for notfound:
      r.on !interactor.exists?(:fruit_size_references, id) do
        handle_not_found(r)
      end

      r.on 'edit' do   # EDIT
        check_auth!('fruit', 'edit')
        interactor.assert_permission!(:edit, id)
        show_partial { Masterfiles::Fruit::FruitSizeReference::Edit.call(id) }
      end

      r.is do
        r.get do       # SHOW
          check_auth!('fruit', 'read')
          show_partial { Masterfiles::Fruit::FruitSizeReference::Show.call(id) }
        end
        r.patch do     # UPDATE
          res = interactor.update_fruit_size_reference(id, params[:fruit_size_reference])
          if res.success
            update_grid_row(id, changes: { size_reference: res.instance[:size_reference], edi_out_code: res.instance[:edi_out_code] },
                                notice: res.message)
          else
            re_show_form(r, res) { Masterfiles::Fruit::FruitSizeReference::Edit.call(id, form_values: params[:fruit_size_reference], form_errors: res.errors) }
          end
        end
        r.delete do    # DELETE
          check_auth!('fruit', 'delete')
          interactor.assert_permission!(:delete, id)
          res = interactor.delete_fruit_size_reference(id)
          if res.success
            delete_grid_row(id, notice: res.message)
          else
            show_json_error(res.message, status: 200)
          end
        end
      end
    end

    r.on 'fruit_size_references' do
      interactor = MasterfilesApp::FruitSizeReferenceInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})
      r.on 'new' do    # NEW
        check_auth!('fruit', 'new')
        show_partial_or_page(r) { Masterfiles::Fruit::FruitSizeReference::New.call(remote: fetch?(r)) }
      end
      r.post do        # CREATE
        res = interactor.create_fruit_size_reference(params[:fruit_size_reference])
        if res.success
          row_keys = %i[
            id
            size_reference
            edi_out_code
            active
          ]
          add_grid_row(attrs: select_attributes(res.instance, row_keys),
                       notice: res.message)
        else
          re_show_form(r, res, url: '/masterfiles/fruit/fruit_size_references/new') do
            Masterfiles::Fruit::FruitSizeReference::New.call(form_values: params[:fruit_size_reference],
                                                             form_errors: res.errors,
                                                             remote: fetch?(r))
          end
        end
      end
    end

    # RMT CLASSES
    # --------------------------------------------------------------------------
    r.on 'rmt_classes', Integer do |id|
      interactor = MasterfilesApp::RmtClassInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      # Check for notfound:
      r.on !interactor.exists?(:rmt_classes, id) do
        handle_not_found(r)
      end

      r.on 'edit' do   # EDIT
        check_auth!('fruit', 'edit')
        interactor.assert_permission!(:edit, id)
        show_partial { Masterfiles::Fruit::RmtClass::Edit.call(id) }
      end

      r.is do
        r.get do       # SHOW
          check_auth!('fruit', 'read')
          show_partial { Masterfiles::Fruit::RmtClass::Show.call(id) }
        end
        r.patch do     # UPDATE
          res = interactor.update_rmt_class(id, params[:rmt_class])
          if res.success
            update_grid_row(id, changes: { rmt_class_code: res.instance[:rmt_class_code], description: res.instance[:description] },
                                notice: res.message)
          else
            re_show_form(r, res) { Masterfiles::Fruit::RmtClass::Edit.call(id, form_values: params[:rmt_class], form_errors: res.errors) }
          end
        end
        r.delete do    # DELETE
          check_auth!('fruit', 'delete')
          interactor.assert_permission!(:delete, id)
          res = interactor.delete_rmt_class(id)
          if res.success
            delete_grid_row(id, notice: res.message)
          else
            show_json_error(res.message, status: 200)
          end
        end
      end
    end

    r.on 'rmt_classes' do
      interactor = MasterfilesApp::RmtClassInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})
      r.on 'new' do    # NEW
        check_auth!('fruit', 'new')
        show_partial_or_page(r) { Masterfiles::Fruit::RmtClass::New.call(remote: fetch?(r)) }
      end
      r.post do        # CREATE
        res = interactor.create_rmt_class(params[:rmt_class])
        if res.success
          row_keys = %i[
            id
            rmt_class_code
            description
            active
          ]
          add_grid_row(attrs: select_attributes(res.instance, row_keys),
                       notice: res.message)
        else
          re_show_form(r, res, url: '/masterfiles/fruit/rmt_classes/new') do
            Masterfiles::Fruit::RmtClass::New.call(form_values: params[:rmt_class],
                                                   form_errors: res.errors,
                                                   remote: fetch?(r))
          end
        end
      end
    end

    # GRADES
    r.on 'grades', Integer do |id|
      interactor = MasterfilesApp::GradeInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      # Check for notfound:
      r.on !interactor.exists?(:grades, id) do
        handle_not_found(r)
      end

      r.on 'edit' do   # EDIT
        check_auth!('fruit', 'edit')
        interactor.assert_permission!(:edit, id)
        show_partial { Masterfiles::Fruit::Grade::Edit.call(id) }
      end

      r.is do
        r.get do       # SHOW
          check_auth!('fruit', 'read')
          show_partial { Masterfiles::Fruit::Grade::Show.call(id) }
        end
        r.patch do     # UPDATE
          res = interactor.update_grade(id, params[:grade])
          if res.success
            row_keys = %i[
              grade_code
              description
              rmt_grade
              qa_level
              inspection_class
            ]
            update_grid_row(id, changes: select_attributes(res.instance, row_keys), notice: res.message)
          else
            re_show_form(r, res) { Masterfiles::Fruit::Grade::Edit.call(id, form_values: params[:grade], form_errors: res.errors) }
          end
        end
        r.delete do    # DELETE
          check_auth!('fruit', 'delete')
          interactor.assert_permission!(:delete, id)
          res = interactor.delete_grade(id)
          if res.success
            delete_grid_row(id, notice: res.message)
          else
            show_json_error(res.message, status: 200)
          end
        end
      end
    end

    r.on 'grades' do
      interactor = MasterfilesApp::GradeInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})
      r.on 'new' do    # NEW
        check_auth!('fruit', 'new')
        show_partial_or_page(r) { Masterfiles::Fruit::Grade::New.call(remote: fetch?(r)) }
      end
      r.post do        # CREATE
        res = interactor.create_grade(params[:grade])
        if res.success
          row_keys = %i[
            id
            grade_code
            description
            rmt_grade
            active
            qa_level
            inspection_class
          ]
          add_grid_row(attrs: select_attributes(res.instance, row_keys),
                       notice: res.message)
        else
          re_show_form(r, res, url: '/masterfiles/fruit/grades/new') do
            Masterfiles::Fruit::Grade::New.call(form_values: params[:grade],
                                                form_errors: res.errors,
                                                remote: fetch?(r))
          end
        end
      end
    end

    # TREATMENT TYPES
    # --------------------------------------------------------------------------
    r.on 'treatment_types', Integer do |id|
      interactor = MasterfilesApp::TreatmentTypeInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      # Check for notfound:
      r.on !interactor.exists?(:treatment_types, id) do
        handle_not_found(r)
      end

      r.on 'edit' do   # EDIT
        check_auth!('fruit', 'edit')
        interactor.assert_permission!(:edit, id)
        show_partial { Masterfiles::Fruit::TreatmentType::Edit.call(id) }
      end

      r.is do
        r.get do       # SHOW
          check_auth!('fruit', 'read')
          show_partial { Masterfiles::Fruit::TreatmentType::Show.call(id) }
        end
        r.patch do     # UPDATE
          res = interactor.update_treatment_type(id, params[:treatment_type])
          if res.success
            update_grid_row(id, changes: { treatment_type_code: res.instance[:treatment_type_code], description: res.instance[:description] }, notice: res.message)
          else
            re_show_form(r, res) { Masterfiles::Fruit::TreatmentType::Edit.call(id, form_values: params[:treatment_type], form_errors: res.errors) }
          end
        end
        r.delete do    # DELETE
          check_auth!('fruit', 'delete')
          interactor.assert_permission!(:delete, id)
          res = interactor.delete_treatment_type(id)
          if res.success
            delete_grid_row(id, notice: res.message)
          else
            show_json_error(res.message, status: 200)
          end
        end
      end
    end

    r.on 'treatment_types' do
      interactor = MasterfilesApp::TreatmentTypeInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})
      r.on 'new' do    # NEW
        check_auth!('fruit', 'new')
        show_partial_or_page(r) { Masterfiles::Fruit::TreatmentType::New.call(remote: fetch?(r)) }
      end
      r.post do        # CREATE
        res = interactor.create_treatment_type(params[:treatment_type])
        if res.success
          row_keys = %i[
            id
            treatment_type_code
            description
            active
          ]
          add_grid_row(attrs: select_attributes(res.instance, row_keys),
                       notice: res.message)
        else
          re_show_form(r, res, url: '/masterfiles/fruit/treatment_types/new') do
            Masterfiles::Fruit::TreatmentType::New.call(form_values: params[:treatment_type],
                                                        form_errors: res.errors,
                                                        remote: fetch?(r))
          end
        end
      end
    end

    # TREATMENTS
    # --------------------------------------------------------------------------
    r.on 'treatments', Integer do |id|
      interactor = MasterfilesApp::TreatmentInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      # Check for notfound:
      r.on !interactor.exists?(:treatments, id) do
        handle_not_found(r)
      end

      r.on 'edit' do   # EDIT
        check_auth!('fruit', 'edit')
        interactor.assert_permission!(:edit, id)
        show_partial { Masterfiles::Fruit::Treatment::Edit.call(id) }
      end

      r.is do
        r.get do       # SHOW
          check_auth!('fruit', 'read')
          show_partial { Masterfiles::Fruit::Treatment::Show.call(id) }
        end
        r.patch do     # UPDATE
          res = interactor.update_treatment(id, params[:treatment])
          if res.success
            update_grid_row(id, changes: { treatment_type_id: res.instance[:treatment_type_id],
                                           treatment_code: res.instance[:treatment_code],
                                           description: res.instance[:description] },
                                notice: res.message)
          else
            re_show_form(r, res) { Masterfiles::Fruit::Treatment::Edit.call(id, form_values: params[:treatment], form_errors: res.errors) }
          end
        end
        r.delete do    # DELETE
          check_auth!('fruit', 'delete')
          interactor.assert_permission!(:delete, id)
          res = interactor.delete_treatment(id)
          if res.success
            delete_grid_row(id, notice: res.message)
          else
            show_json_error(res.message, status: 200)
          end
        end
      end
    end

    r.on 'treatments' do
      interactor = MasterfilesApp::TreatmentInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})
      r.on 'new' do    # NEW
        check_auth!('fruit', 'new')
        show_partial_or_page(r) { Masterfiles::Fruit::Treatment::New.call(remote: fetch?(r)) }
      end
      r.post do        # CREATE
        res = interactor.create_treatment(params[:treatment])
        if res.success
          row_keys = %i[
            id
            treatment_type_code
            treatment_code
            description
            active
          ]
          add_grid_row(attrs: select_attributes(res.instance, row_keys),
                       notice: res.message)
        else
          re_show_form(r, res, url: '/masterfiles/fruit/treatments/new') do
            Masterfiles::Fruit::Treatment::New.call(form_values: params[:treatment],
                                                    form_errors: res.errors,
                                                    remote: fetch?(r))
          end
        end
      end
    end

    # INVENTORY CODES
    # --------------------------------------------------------------------------
    r.on 'inventory_codes', Integer do |id|
      interactor = MasterfilesApp::InventoryCodeInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      # Check for notfound:
      r.on !interactor.exists?(:inventory_codes, id) do
        handle_not_found(r)
      end

      r.on 'edit' do   # EDIT
        check_auth!('fruit', 'edit')
        interactor.assert_permission!(:edit, id)
        show_partial { Masterfiles::Fruit::InventoryCode::Edit.call(id) }
      end

      r.is do
        r.get do       # SHOW
          check_auth!('fruit', 'read')
          show_partial { Masterfiles::Fruit::InventoryCode::Show.call(id) }
        end
        r.patch do     # UPDATE
          res = interactor.update_inventory_code(id, params[:inventory_code])
          if res.success
            update_grid_row(id, changes: { inventory_code: res.instance[:inventory_code],
                                           description: res.instance[:description],
                                           fruit_item_incentive_rate: res.instance[:fruit_item_incentive_rate],
                                           edi_out_inventory_code: res.instance[:edi_out_inventory_code] },
                                notice: res.message)
          else
            re_show_form(r, res) { Masterfiles::Fruit::InventoryCode::Edit.call(id, form_values: params[:inventory_code], form_errors: res.errors) }
          end
        end
        r.delete do    # DELETE
          check_auth!('fruit', 'delete')
          interactor.assert_permission!(:delete, id)
          res = interactor.delete_inventory_code(id)
          if res.success
            delete_grid_row(id, notice: res.message)
          else
            show_json_error(res.message, status: 200)
          end
        end
      end
    end

    r.on 'inventory_codes' do
      interactor = MasterfilesApp::InventoryCodeInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})
      r.on 'new' do    # NEW
        check_auth!('fruit', 'new')
        show_partial_or_page(r) { Masterfiles::Fruit::InventoryCode::New.call(remote: fetch?(r)) }
      end
      r.post do        # CREATE
        res = interactor.create_inventory_code(params[:inventory_code])
        if res.success
          row_keys = %i[
            id
            inventory_code
            description
            edi_out_inventory_code
            fruit_item_incentive_rate
            active
          ]
          add_grid_row(attrs: select_attributes(res.instance, row_keys),
                       notice: res.message)
        else
          re_show_form(r, res, url: '/masterfiles/fruit/inventory_codes/new') do
            Masterfiles::Fruit::InventoryCode::New.call(form_values: params[:inventory_code],
                                                        form_errors: res.errors,
                                                        remote: fetch?(r))
          end
        end
      end
    end

    # INVENTORY CODES PACKING COSTS
    # --------------------------------------------------------------------------
    r.on 'inventory_codes_packing_costs', Integer do |id|
      interactor = MasterfilesApp::InventoryCodeInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      r.on 'sync_inventory_packing_costs' do
        check_auth!('fruit', 'new')
        res = interactor.sync_inventory_packing_costs(id)
        flash[:notice] = res.message
        show_partial { Masterfiles::Fruit::InventoryCode::Edit.call(id) }
      end

      r.on 'inline_edit_packing_cost' do
        res = interactor.inline_update_packing_cost(id, params)
        if res.success
          row_keys = %i[
            commodity_code
            commodity_description
            inventory_code
            inventory_description
            packing_cost
          ]
          update_grid_row(id, changes: select_attributes(res.instance, row_keys), notice: res.message)
        else
          undo_grid_inline_edit(message: res.message, message_type: :error)
        end
      end
    end

    # COLOUR PERCENTAGES
    # --------------------------------------------------------------------------
    r.on 'colour_percentages', Integer do |id|
      interactor = MasterfilesApp::ColourPercentageInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      # Check for notfound:
      r.on !interactor.exists?(:colour_percentages, id) do
        handle_not_found(r)
      end

      r.on 'inline_edit_colour_percentage' do
        res = interactor.inline_update_colour_percentage(id, params)
        if res.success
          row_keys = %i[
            commodity_code
            colour_percentage
            description
          ]
          update_grid_row(id, changes: select_attributes(res.instance, row_keys), notice: res.message)
        else
          undo_grid_inline_edit(message: unwrap_failed_response(res), message_type: :error)
        end
      end

      r.on 'edit' do   # EDIT
        check_auth!('fruit', 'edit')
        interactor.assert_permission!(:edit, id)
        show_partial { Masterfiles::Fruit::ColourPercentage::Edit.call(id) }
      end

      r.is do
        r.get do       # SHOW
          check_auth!('fruit', 'read')
          show_partial { Masterfiles::Fruit::ColourPercentage::Show.call(id) }
        end

        r.patch do     # UPDATE
          res = interactor.update_colour_percentage(id, params[:colour_percentage])
          if res.success
            row_keys = %i[
              commodity_code
              colour_percentage
              description
            ]
            update_grid_row(id, changes: select_attributes(res.instance, row_keys), notice: res.message)
          else
            re_show_form(r, res) do
              Masterfiles::Fruit::ColourPercentage::Edit.call(id,
                                                              form_values: params[:colour_percentage],
                                                              form_errors: res.errors)
            end
          end
        end

        r.delete do    # DELETE
          check_auth!('fruit', 'delete')
          interactor.assert_permission!(:delete, id)
          res = interactor.delete_colour_percentage(id)
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
