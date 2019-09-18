# frozen_string_literal: true

class Nspack < Roda
  # --------------------------------------------------------------------------
  # DELIVERIES
  # --------------------------------------------------------------------------
  route 'rmt_deliveries', 'rmd' do |r| # rubocop:disable Metrics/BlockLength
    # --------------------------------------------------------------------------
    # BINS
    # --------------------------------------------------------------------------
    r.on 'rmt_bins', Integer do |id| # rubocop:disable Metrics/BlockLength
      interactor = RawMaterialsApp::RmtBinInteractor.new(current_user, {}, { route_url: request.path }, {})

      r.on 'new' do # rubocop:disable Metrics/BlockLength    # NEW
        delivery = RawMaterialsApp::RmtDeliveryRepo.new.find_rmt_delivery(id)
        default_rmt_container_type = RawMaterialsApp::RmtDeliveryRepo.new.rmt_container_type_by_container_type_code(AppConst::DELIVERY_DEFAULT_RMT_CONTAINER_TYPE)
        details = { cultivar_id: delivery.cultivar_id, qty_bins: 1, bin_fullness: :Full }

        capture_inner_bins = AppConst::DELIVERY_CAPTURE_INNER_BINS == 'true' && !default_rmt_container_type[:id].nil?
        capture_nett_weight = AppConst::DELIVERY_CAPTURE_BIN_WEIGHT_AT_FRUIT_RECEPTION == 'true'
        capture_container_material = AppConst::DELIVERY_CAPTURE_CONTAINER_MATERIAL == 'true'
        capture_container_material_owner = AppConst::DELIVERY_CAPTURE_CONTAINER_MATERIAL_OWNER == 'true'

        form = Crossbeams::RMDForm.new(details,
                                       form_name: :rmt_bin,
                                       scan_with_camera: @rmd_scan_with_camera,
                                       caption: 'New Bin',
                                       action: "/rmd/rmt_deliveries/rmt_bins/#{id}/rmt_bins",
                                       button_caption: 'Submit')

        form.behaviours do |behaviour|
          behaviour.dropdown_change :rmt_container_type_id, notify: [{ url: '/rmd/rmt_deliveries/rmt_bins/rmt_container_type_combo_changed' }]
          behaviour.dropdown_change :rmt_container_material_type_id, notify: [{ url: '/rmd/rmt_deliveries/rmt_bins/container_material_type_combo_changed' }]
        end

        form.add_select(:cultivar_id, 'Cultivar', items: RawMaterialsApp::RmtDeliveryRepo.new.orchard_cultivars(delivery.orchard_id), required: true, prompt: true)
        form.add_select(:rmt_container_type_id, 'Container Type', items: MasterfilesApp::RmtContainerTypeRepo.new.for_select_rmt_container_types, value: default_rmt_container_type[:id],
                                                                  required: true, prompt: true)
        # TO DO: Are these qtys neccessary for option B or they default=1?
        form.add_field(:qty_bins, 'Qty Bins', data_type: :number)
        form.add_field(:qty_inner_bins, 'Qty Inner Bins', data_type: :number, required: false, hide_on_load: capture_inner_bins ? false : true)
        form.add_select(:bin_fullness, 'Bin Fullness', items: %w[Quarter Half Three Quarters Full], prompt: true)
        form.add_field(:nett_weight, 'Nett Weight', required: false, prompt: true) if capture_nett_weight
        if capture_container_material
          form.add_select(:rmt_container_material_type_id, 'Container Material Type',
                          items: MasterfilesApp::RmtContainerMaterialTypeRepo.new.for_select_rmt_container_material_types(where: { rmt_container_type_id: default_rmt_container_type[:id] }),
                          required: true, prompt: true)
        end
        form.add_select(:rmt_container_material_owner_id, 'Container Material Owner', items: [], required: true, prompt: true) if capture_container_material && capture_container_material_owner
        form.add_field(:bin_asset_number, 'Asset Number', data_type: :number, required: true)
        form.add_csrf_tag csrf_tag
        view(inline: form.render, layout: :layout_rmd)
      end

      r.post do # CREATE
        res = interactor.create_rmt_bin(id, params[:rmt_bin])
        if res.success
          flash[:notice] = 'Bin Created Successfully'
        else
          # TO DO: How to show an error rmd form
          # r.redirect("/rmd/rmt_deliveries/rmt_bins/#{id}/new")
          flash[:error] = "Error: #{res.message}"
        end
        r.redirect("/raw_materials/deliveries/rmt_deliveries/#{id}/edit")
      end
    end

    r.on 'rmt_bins' do # rubocop:disable Metrics/BlockLength
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
                                       dom_id: 'rmt_bin_qty_inner_bins_row')],
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
        if !params[:changed_value].to_s.empty?
          container_material_owners = RawMaterialsApp::RmtDeliveryRepo.new.find_container_material_owners_by_container_material_type(params[:changed_value])
          json_replace_select_options('rmt_bin_rmt_container_material_owner_id', container_material_owners)
        else
          json_replace_select_options('rmt_bin_rmt_container_material_owner_id', [])
        end
      end
    end
  end
end
