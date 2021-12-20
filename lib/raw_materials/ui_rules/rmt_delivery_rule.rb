# frozen_string_literal: true

module UiRules
  class RmtDeliveryRule < Base # rubocop:disable Metrics/ClassLength
    def generate_rules # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      @repo = RawMaterialsApp::RmtDeliveryRepo.new
      make_form_object
      apply_form_values

      @rules[:create_tripsheet] = !@form_object.tripsheet_created && !@form_object.shipped
      @rules[:start_bins_trip] = @form_object.tripsheet_created && !@form_object.tripsheet_loaded
      @rules[:cancel_delivery_tripheet] = @form_object.tripsheet_created && !@form_object.tripsheet_offloaded
      @rules[:print_delivery_tripheet] = @rules[:cancel_delivery_tripheet]
      @rules[:vehicle_loaded] = @form_object.tripsheet_loaded
      @rules[:vehicle_job_id] = @repo.get_value(:vehicle_jobs, :id, rmt_delivery_id: @form_object.id) unless @form_object.id.nil?
      @rules[:refresh_tripsheet] = @form_object.tripsheet_created && !@form_object.tripsheet_offloaded && !@repo.delivery_tripsheet_discreps(@form_object.id).empty?
      @rules[:list_tripsheets] = !@form_object.tripsheet_offloaded && !@repo.delivery_tripsheets(@form_object.id).empty?
      rules[:do_qc] = do_qc?
      @qc_repo = QualityApp::QcRepo.new if rules[:do_qc]

      common_values_for_fields common_fields

      set_show_fields if %i[show reopen].include? @mode
      build_qc if %i[show edit].include?(@mode) && rules[:do_qc]
      add_behaviours if %i[new edit].include? @mode

      form_name 'rmt_delivery'
    end

    def set_show_fields # rubocop:disable Metrics/AbcSize
      @options ||= {}
      fields[:id] = { renderer: :label, caption: 'Delivery Id' }
      fields[:orchard_id] = { renderer: :label,
                              with_value: MasterfilesApp::FarmRepo.new.find_orchard(@form_object.orchard_id)&.orchard_code,
                              caption: 'Orchard' }
      fields[:farm_section] = { renderer: :label,
                                with_value: @options[:farm_section].to_s,
                                hide_on_load: @options[:farm_section].nil_or_empty?,
                                caption: 'Farm Section' }
      fields[:cultivar_id] = { renderer: :label,
                               with_value: MasterfilesApp::CultivarRepo.new.find_cultivar(@form_object.cultivar_id)&.cultivar_name,
                               caption: 'Cultivar' }
      fields[:rmt_delivery_destination_id] = { renderer: :label,
                                               with_value: MasterfilesApp::RmtDeliveryDestinationRepo.new.find_rmt_delivery_destination(@form_object.rmt_delivery_destination_id)&.delivery_destination_code,
                                               caption: 'Destination',
                                               hide_on_load: !AppConst::CR_RMT.include_destination_in_delivery? }
      fields[:season_id] = { renderer: :label,
                             with_value: MasterfilesApp::CalendarRepo.new.find_season(@form_object.season_id)&.season_code,
                             caption: 'Season' }
      fields[:farm_id] = { renderer: :label,
                           with_value: MasterfilesApp::FarmRepo.new.find_farm(@form_object.farm_id)&.farm_code,
                           caption: 'Farm' }
      fields[:puc_id] = { renderer: :label,
                          with_value: MasterfilesApp::FarmRepo.new.find_puc(@form_object.puc_id)&.puc_code,
                          caption: 'PUC' }
      fields[:truck_registration_number] = { renderer: :label,
                                             hide_on_load: !AppConst::DELIVERY_CAPTURE_TRUCK_AT_FRUIT_RECEPTION }
      fields[:reference_number] = { renderer: :label }
      fields[:qty_damaged_bins] = { renderer: :label,
                                    hide_on_load: !AppConst::DELIVERY_CAPTURE_DAMAGED_BINS }
      fields[:qty_empty_bins] = { renderer: :label,
                                  hide_on_load: !AppConst::DELIVERY_CAPTURE_EMPTY_BINS }
      fields[:date_picked] = { renderer: :label,
                               caption: 'Picked at' }
      fields[:received] = { renderer: :label,
                            as_boolean: true }
      fields[:date_delivered] = { renderer: :label,
                                  caption: 'Received at',
                                  format: :without_timezone_or_seconds }
      fields[:tipping_complete_date_time] = { renderer: :label,
                                              caption: 'Tipped at' }
      fields[:quantity_bins_with_fruit] = { renderer: :label }
      fields[:current] = { renderer: :label,
                           as_boolean: true }
      fields[:delivery_tipped] = { renderer: :label,
                                   caption: 'Tipped',
                                   as_boolean: true }
      fields[:keep_open] = { renderer: :label,
                             as_boolean: true }
      fields[:bin_scan_mode] = { renderer: :label,
                                 with_value: @form_object.bin_scan_mode }
      fields[:active] = { renderer: :label,
                          as_boolean: true }
      fields[:batch_number] = { renderer: :label }
      fields[:batch_number_updated_at] = { renderer: :label }
    end

    def common_fields # rubocop:disable Metrics/AbcSize
      fields = {
        id: { renderer: :label, caption: 'Delivery Id' },
        farm_id: { renderer: :select,
                   options: MasterfilesApp::FarmRepo.new.for_select_farms,
                   disabled_options: MasterfilesApp::FarmRepo.new.for_select_inactive_farms,
                   caption: 'Farm',
                   required: true,
                   prompt: true },
        puc_id: { renderer: :select,
                  options: MasterfilesApp::FarmRepo.new.for_select_pucs(where: { farm_id: @form_object.farm_id }),
                  disabled_options: MasterfilesApp::FarmRepo.new.for_select_inactive_pucs,
                  caption: 'PUC',
                  required: true,
                  prompt: true },
        orchard_id: { renderer: :select,
                      options: MasterfilesApp::FarmRepo.new.for_select_orchards(where: { puc_id: @form_object.puc_id }),
                      disabled_options: MasterfilesApp::FarmRepo.new.for_select_inactive_orchards,
                      caption: 'Orchard',
                      required: true,
                      prompt: true  },
        farm_section: { renderer: :label,
                        with_value: @options[:farm_section].to_s,
                        hide_on_load: @options[:farm_section].nil_or_empty? },
        cultivar_id: { renderer: :select,
                       options: MasterfilesApp::CultivarRepo.new.for_select_cultivars(
                         where: { id: @repo.get(:orchards, @form_object.orchard_id, :cultivar_ids).to_a }
                       ),
                       disabled_options: MasterfilesApp::CultivarRepo.new.for_select_inactive_cultivars,
                       caption: 'Cultivar',
                       required: true,
                       prompt: true },
        rmt_delivery_destination_id: { renderer: :select,
                                       options: MasterfilesApp::RmtDeliveryDestinationRepo.new.for_select_rmt_delivery_destinations,
                                       disabled_options: MasterfilesApp::RmtDeliveryDestinationRepo.new.for_select_inactive_rmt_delivery_destinations,
                                       caption: 'Destination',
                                       required: AppConst::CR_RMT.include_destination_in_delivery?,
                                       hide_on_load: !AppConst::CR_RMT.include_destination_in_delivery?,
                                       prompt: true },
        truck_registration_number: { pattern: :alphanumeric,
                                     hide_on_load: !AppConst::DELIVERY_CAPTURE_TRUCK_AT_FRUIT_RECEPTION },
        reference_number: {},
        qty_damaged_bins: { renderer: :integer,
                            hide_on_load: !AppConst::DELIVERY_CAPTURE_DAMAGED_BINS,
                            minvalue: 0 },
        qty_empty_bins: { renderer: :integer,
                          hide_on_load: !AppConst::DELIVERY_CAPTURE_EMPTY_BINS,
                          minvalue: 0 },
        date_picked: { renderer: :date,
                       caption: 'Picked at' },
        received: { renderer: :checkbox,
                    hide_on_load: true },
        date_delivered: { renderer: :datetime,
                          caption: 'Received at' },
        current_date_delivered: { renderer: :label,
                                  with_value: @form_object.date_delivered,
                                  caption: 'Current Received date' },
        bin_scan_mode: { renderer: :select,
                         options: AppConst::BIN_SCAN_MODE_OPTIONS,
                         caption: 'Web Bin Scan Mode',
                         prompt: true },
        current: { renderer: :checkbox,
                   caption: 'Set As Current' },
        delivery_tipped: { renderer: :label,
                           caption: 'Tipped',
                           as_boolean: true },
        tipping_complete_date_time: { renderer: :label,
                                      caption: 'Tipped at' },
        keep_open: { renderer: :label,
                     as_boolean: true },
        quantity_bins_with_fruit: { renderer: :integer,
                                    caption: 'Qty Bins With Fruit',
                                    minvalue: 0 },
        batch_number: { renderer: :label },
        batch_number_updated_at: { renderer: :label }
      }
      if AppConst::CR_RMT.all_delivery_bins_of_same_type?
        fields[:rmt_container_type_id] = { renderer: :select, options: MasterfilesApp::RmtContainerTypeRepo.new.for_select_rmt_container_types, required: true, prompt: true }
        fields[:rmt_material_owner_party_role_id] = { renderer: :select, options: @repo.for_select_container_material_owners, caption: 'Container Material Owner', required: true, prompt: true }
        fields[:rmt_container_material_type_id] = { renderer: :select,
                                                    options: MasterfilesApp::RmtContainerMaterialTypeRepo.new.for_select_rmt_container_material_types(where: { rmt_container_type_id: @form_object.rmt_container_type_id }),
                                                    disabled_options: MasterfilesApp::RmtContainerMaterialTypeRepo.new.for_select_inactive_rmt_container_material_types,
                                                    caption: 'Rmt Container Material Type',
                                                    required: true,
                                                    prompt: true }
      end

      fields
    end

    def make_form_object
      if @mode == :new
        make_new_form_object
        return
      end

      @form_object = @repo.find_rmt_delivery(@options[:id])
      @options[:farm_section] = MasterfilesApp::FarmRepo.new.find_orchard_farm_section(@form_object.orchard_id)
    end

    def make_new_form_object
      res = @repo.default_farm_puc
      @form_object = OpenStruct.new(orchard_id: nil,
                                    cultivar_id: nil,
                                    rmt_delivery_destination_id: nil,
                                    season_id: nil,
                                    farm_id: res[:farm_id],
                                    puc_id: res[:puc_id],
                                    truck_registration_number: nil,
                                    qty_damaged_bins: nil,
                                    qty_empty_bins: nil,
                                    delivery_tipped: false,
                                    date_picked: Time.now,
                                    date_delivered: Time.now,
                                    received: true,
                                    tipping_complete_date_time: nil,
                                    bin_scan_mode: nil)
    end

    def handle_behaviour
      case @mode
      when :farm
        farm_change
      when :puc
        puc_change
      when :orchard
        orchard_change
      when :rmt_container_type
        rmt_container_type_change
      when :rmt_container_material_type
        rmt_container_material_type_change
      else
        unhandled_behaviour!
      end
    end

    private

    def add_behaviours
      behaviours do |behaviour|
        behaviour.dropdown_change :farm_id,
                                  notify: [{ url: '/raw_materials/deliveries/rmt_deliveries/ui_change/farm' }]
        behaviour.dropdown_change :puc_id,
                                  notify: [{ url: '/raw_materials/deliveries/rmt_deliveries/ui_change/puc',
                                             param_keys: %i[rmt_delivery_farm_id] }]
        behaviour.dropdown_change :orchard_id,
                                  notify: [{ url: '/raw_materials/deliveries/rmt_deliveries/ui_change/orchard' }]
        behaviour.dropdown_change :rmt_container_type_id,
                                  notify: [{ url: '/raw_materials/deliveries/rmt_deliveries/ui_change/rmt_container_type' }]
        behaviour.dropdown_change :rmt_container_material_type_id,
                                  notify: [{ url: '/raw_materials/deliveries/rmt_deliveries/ui_change/rmt_container_material_type' }]
      end
    end

    def farm_change
      pucs = if params[:changed_value].blank?
               []
             else
               RawMaterialsApp::RmtDeliveryRepo.new.farm_pucs(params[:changed_value])
             end
      json_actions([OpenStruct.new(type: :replace_select_options,
                                   dom_id: 'rmt_delivery_puc_id',
                                   options_array: pucs),
                    OpenStruct.new(type: :replace_select_options,
                                   dom_id: 'rmt_delivery_orchard_id',
                                   options_array: []),
                    OpenStruct.new(type: :replace_select_options,
                                   dom_id: 'rmt_delivery_cultivar_id',
                                   options_array: [])])
    end

    def puc_change
      farm_id = params[:rmt_delivery_farm_id]
      orchards = if params[:changed_value].blank? || farm_id.blank?
                   []
                 else
                   RawMaterialsApp::RmtDeliveryRepo.new.orchards(farm_id, params[:changed_value])
                 end
      json_actions([OpenStruct.new(type: :replace_select_options,
                                   dom_id: 'rmt_delivery_orchard_id',
                                   options_array: orchards),
                    OpenStruct.new(type: :replace_select_options,
                                   dom_id: 'rmt_delivery_cultivar_id',
                                   options_array: [])])
    end

    def orchard_change
      if params[:changed_value].blank?
        farm_section = nil
        cultivars = []
      else
        farm_section = MasterfilesApp::FarmRepo.new.find_orchard_farm_section(params[:changed_value])
        cultivars = RawMaterialsApp::RmtDeliveryRepo.new.orchard_cultivars(params[:changed_value])
      end
      json_actions([OpenStruct.new(type: farm_section.nil_or_empty? ? :hide_element : :show_element,
                                   dom_id: 'rmt_delivery_farm_section_field_wrapper'),
                    OpenStruct.new(type: :replace_inner_html,
                                   dom_id: 'rmt_delivery_farm_section',
                                   value: farm_section),
                    OpenStruct.new(type: :replace_select_options,
                                   dom_id: 'rmt_delivery_cultivar_id',
                                   options_array: cultivars)])
    end

    def rmt_container_type_change
      actions = []
      rmt_container_material_types = if params[:changed_value].blank?
                                       []
                                     else
                                       MasterfilesApp::RmtContainerMaterialTypeRepo.new.for_select_rmt_container_material_types(
                                         where: { rmt_container_type_id: params[:changed_value] }
                                       )
                                     end
      if AppConst::DELIVERY_CAPTURE_CONTAINER_MATERIAL
        actions << OpenStruct.new(type: :replace_select_options,
                                  dom_id: 'rmt_delivery_rmt_container_material_type_id',
                                  options_array: rmt_container_material_types)
      end
      if AppConst::DELIVERY_CAPTURE_CONTAINER_MATERIAL && AppConst::DELIVERY_CAPTURE_CONTAINER_MATERIAL_OWNER
        actions << OpenStruct.new(type: :replace_select_options,
                                  dom_id: 'rmt_delivery_rmt_material_owner_party_role_id',
                                  options_array: [])
      end
      json_actions(actions)
    end

    def rmt_container_material_type_change
      container_material_owners = if params[:changed_value].blank?
                                    []
                                  else
                                    RawMaterialsApp::RmtDeliveryRepo.new.find_container_material_owners_by_container_material_type(params[:changed_value])
                                  end
      json_replace_select_options('rmt_delivery_rmt_material_owner_party_role_id', container_material_owners)
    end

    def do_qc?
      @repo.exists?(:qc_sample_types, active: true)
    end

    def qc_sample_type_and_id(sample_type)
      sample_type_id = @qc_repo.get_id(:qc_sample_types, qc_sample_type_name: sample_type)
      sample_id = @qc_repo.sample_id_for_type_and_context(sample_type_id, :rmt_delivery_id, @options[:id])
      [sample_type_id, sample_id]
    end

    def build_qc # rubocop:disable Metrics/AbcSize
      items_fruit = []
      sample_type_id, fruit_id = qc_sample_type_and_id('100_fruit_sample')
      if fruit_id
        items_fruit << { url: "/quality/qc/qc_samples/#{fruit_id}/edit", text: 'Edit', behaviour: :popup }
        items_fruit << { url: '/', text: 'Complete', popup: true }
        items_fruit << { url: "/quality/qc/qc_samples/#{fruit_id}/print_barcode", text: 'Print', behaviour: :popup }
        items_fruit << { url: "/quality/qc/qc_samples/#{fruit_id}/qc_test/starch", text: 'Starch test', behaviour: :popup }
        items_fruit << { url: "/quality/qc/qc_samples/#{fruit_id}/qc_test/defects", text: 'Defects test', behaviour: :direct }
      else
        items_fruit << { url: "/quality/qc/qc_samples/new_rmt_delivery_id_sample/#{sample_type_id}/#{@options[:id]}", text: 'Create', behaviour: :popup }
      end
      build_qc_summary('100_fruit_sample', fruit_id)
      items_prog = []
      sample_type_id, prog_id = qc_sample_type_and_id('delivery_progressive_tests')
      if prog_id
        items_prog << { url: "/quality/qc/qc_samples/#{prog_id}/edit", text: 'Edit', behaviour: :popup }
        items_prog << { url: "/quality/qc/qc_samples/#{prog_id}/print_barcode", text: 'Print', behaviour: :popup }
        items_prog << { url: "/quality/qc/qc_samples/#{prog_id}/qc_test/defects", text: 'Defects test', behaviour: :direct }
      else
        items_prog << { url: "/quality/qc/qc_samples/new_rmt_delivery_id_sample/#{sample_type_id}/#{@options[:id]}", text: 'Create', behaviour: :popup }
      end
      rules[:items_fruit] = items_fruit
      rules[:items_prog] = items_prog
      build_qc_summary('delivery_progressive_tests', prog_id)
    end

    def build_qc_summary(sample_type, sample_id)
      items = []
      unless sample_id.nil?
        items << @qc_repo.sample_summary(sample_id)
        @qc_repo.sample_test_summaries(sample_id).each { |s| items << s }
      end
      rules["qc_summary_#{sample_type}".to_sym] = items
    end
  end
end
