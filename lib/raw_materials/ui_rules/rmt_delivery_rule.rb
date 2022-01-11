# frozen_string_literal: true

module UiRules
  class RmtDeliveryRule < Base
    def generate_rules # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      @repo = RawMaterialsApp::RmtDeliveryRepo.new
      @mrl_result_repo = QualityApp::MrlResultRepo.new

      make_form_object
      apply_form_values

      @rules[:mrl_result_notice] = check_mrl_result_status_for(@form_object.id) unless @form_object.id.nil?
      @rules[:create_tripsheet] = !@form_object.tripsheet_created && !@form_object.shipped && (@rules[:pending_mrl_result] || !@rules[:failed_mrl_result])
      @rules[:start_bins_trip] = @form_object.tripsheet_created && !@form_object.tripsheet_loaded
      @rules[:cancel_delivery_tripheet] = @form_object.tripsheet_created && !@form_object.tripsheet_offloaded
      @rules[:print_delivery_tripheet] = @form_object.tripsheet_created
      @rules[:vehicle_loaded] = @form_object.tripsheet_loaded
      @rules[:vehicle_job_id] = @repo.get_value(:vehicle_jobs, :id, rmt_delivery_id: @form_object.id) unless @form_object.id.nil?
      @rules[:refresh_tripsheet] = @form_object.tripsheet_created && !@form_object.tripsheet_offloaded && !@repo.delivery_tripsheet_discreps(@form_object.id).empty?
      @rules[:list_tripsheets] = !@form_object.tripsheet_offloaded && !@repo.delivery_tripsheets(@form_object.id).empty?
      rules[:tripsheet_button] = !@repo.delivery_tripsheets(@form_object.id).empty? || @rules[:create_tripsheet]
      rules[:do_qc] = do_qc?
      @qc_repo = QualityApp::QcRepo.new if rules[:do_qc]

      common_values_for_fields common_fields

      set_show_fields if %i[show reopen].include? @mode
      build_qc if %i[show edit].include?(@mode) && rules[:do_qc]
      add_behaviours if %i[new edit].include? @mode

      form_name 'rmt_delivery'
    end

    def set_show_fields # rubocop:disable Metrics/AbcSize
      header = @form_object.to_h
      header[:sample_bin_positions] = @form_object.sample_bins.join(',')
      cols = %i[id sample_bin_positions season_code farm_code puc_code orchard_code farm_section container_type_code rmt_owner
                container_material_type_code delivery_destination_code reference_number truck_registration_number qty_damaged_bins
                qty_empty_bins sample_bins_weighed quantity_bins_with_fruit bin_scan_mode current date_picked received date_delivered
                delivery_tipped tipping_complete_date_time keep_open active batch_number batch_number_updated_at sample_weights_extrapolated_at
                qty_partial_bins rmt_code rmt_variant_code regime_code]
      @form_object.rmt_classifications.to_a.each do |c|
        type = MasterfilesApp::AdvancedClassificationsRepo.new.find_rmt_classification_type_by_classification(c)
        label = type.to_sym
        cols << label
        header[label] = @repo.get_value(:rmt_classifications, :rmt_classification, id: c)
      end

      cols.delete(:farm_section) if @form_object.farm_section.nil_or_empty?
      unless AppConst::CR_RMT.all_delivery_bins_of_same_type?
        cols.delete(:container_type_code)
        cols.delete(:rmt_owner)
        cols.delete(:container_material_type_code)
      end
      cols.delete(:truck_registration_number) unless AppConst::DELIVERY_CAPTURE_TRUCK_AT_FRUIT_RECEPTION
      cols.delete(:qty_damaged_bins) unless AppConst::DELIVERY_CAPTURE_DAMAGED_BINS
      cols.delete(:qty_empty_bins) unless AppConst::DELIVERY_CAPTURE_EMPTY_BINS
      rules[:compact_header] = compact_header(columns: cols,
                                              display_columns: 3, with_object: header)
    end

    def common_fields # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity
      header = @form_object.to_h
      header[:sample_bin_positions] = @form_object.sample_bins.join(',')
      cols = %i[id sample_bin_positions sample_bins_weighed farm_section batch_number_updated_at delivery_tipped tipping_complete_date_time batch_number
                sample_weights_extrapolated_at rmt_code rmt_variant_code regime_code]
      @form_object.rmt_classifications.to_a.each do |c|
        type = MasterfilesApp::AdvancedClassificationsRepo.new.find_rmt_classification_type_by_classification(c)
        label = type.to_sym
        cols << label
        header[label] = @repo.get_value(:rmt_classifications, :rmt_classification, id: c)
      end

      cols.delete(:farm_section) if @form_object.farm_section.nil_or_empty?
      cols.delete(:batch_number_updated_at) if @form_object.batch_number_updated_at.nil?
      cols.delete(:batch_number) if @form_object.batch_number.nil_or_empty?
      cols.delete(:sample_weights_extrapolated_at) if @form_object.sample_weights_extrapolated_at.nil?
      cols.delete(:tipping_complete_date_time) if @form_object.tipping_complete_date_time.nil?
      rules[:compact_header] = compact_header(columns: cols,
                                              display_columns: 3, with_object: header)

      fields = {
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
        cultivar_id: { renderer: :select,
                       options: MasterfilesApp::CultivarRepo.new.for_select_cultivars(
                         where: { id: @repo.get(:orchards, :cultivar_ids, @form_object.orchard_id).to_a }
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
        quantity_bins_with_fruit: { renderer: :integer,
                                    caption: 'Qty Bins With Fruit',
                                    minvalue: 0 },
        qty_partial_bins: { renderer: :integer,
                            minvalue: 0 }
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

      @form_object = @repo.find_rmt_delivery_flat(@options[:id])
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

    def check_mrl_result_status_for(delivery_id)
      return nil unless AppConst::CR_RMT.enforce_mrl_check?

      res = QualityApp::FailedAndPendingMrlResults.call(delivery_id)
      @rules[:failed_mrl_result] = res[:errors][:failed]
      @rules[:pending_mrl_result] = res[:errors][:pending]
      res.success ? nil : res.message
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
      cultivars = if params[:changed_value].blank?
                    []
                  else
                    RawMaterialsApp::RmtDeliveryRepo.new.orchard_cultivars(params[:changed_value])
                  end
      json_actions([OpenStruct.new(type: :replace_select_options,
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

    def build_qc # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      first_delivery_rule = RawMaterialsApp::SeasonalDeliveryQcSamples.call(@options[:id])
      rules[:first_qc_sample_outstanding] = first_delivery_rule.first_test_outstanding?
      items_fruit = []
      sample_type_id, fruit_id = qc_sample_type_and_id(AppConst::QC_SAMPLE_100_FRUIT)
      if fruit_id
        items_fruit << { url: "/quality/qc/qc_samples/#{fruit_id}/edit", text: 'Edit', behaviour: :popup }
        # items_fruit << { url: '/', text: 'Complete', popup: true }
        items_fruit << { url: "/quality/qc/qc_samples/#{fruit_id}/print_barcode", text: 'Print', behaviour: :popup }
        items_fruit << { url: "/quality/qc/qc_samples/#{fruit_id}/qc_test/starch", text: 'Starch test', behaviour: :popup } # unless first_test_done(sample_type_id, test_type_name)
        items_fruit << { url: "/quality/qc/qc_samples/#{fruit_id}/qc_test/defects", text: 'Defects test', behaviour: :direct } # unless first_test_done(sample_type_id, test_type_name)
        items_fruit << { url: "/dataminer/reports/loading_report_with_params/oldmes_ftadf?instruments_fta_sessions.transaction_id=#{@form_object.reference_number}", text: 'FTA Diameter and Firmness', behaviour: :direct, loading_window: true }
        items_fruit << { url: "/dataminer/reports/loading_report_with_params/oldmes_fi_instrument?transaction_id=#{@form_object.reference_number}", text: 'Fruit Intake Intrumentation Averages', behaviour: :direct, loading_window: true }
      elsif first_delivery_rule.need_to_make_a_sample?(AppConst::QC_SAMPLE_100_FRUIT)
        items_fruit << { url: "/quality/qc/qc_samples/new_rmt_delivery_id_sample/#{sample_type_id}/#{@options[:id]}", text: 'Create', behaviour: :popup }
      end
      build_qc_summary(AppConst::QC_SAMPLE_100_FRUIT, fruit_id)

      items_prog = []
      sample_type_id, prog_id = qc_sample_type_and_id(AppConst::QC_SAMPLE_PROGRESSIVE)
      if prog_id
        items_prog << { url: "/quality/qc/qc_samples/#{prog_id}/edit", text: 'Edit', behaviour: :popup }
        items_prog << { url: "/quality/qc/qc_samples/#{prog_id}/print_barcode", text: 'Print', behaviour: :popup }
        items_prog << { url: "/quality/qc/qc_samples/#{prog_id}/qc_test/defects", text: 'Defects test', behaviour: :direct } # unless first_test_done(sample_type_id, test_type_name)
      elsif first_delivery_rule.need_to_make_a_sample?(AppConst::QC_SAMPLE_PROGRESSIVE)
        items_prog << { url: "/quality/qc/qc_samples/new_rmt_delivery_id_sample/#{sample_type_id}/#{@options[:id]}", text: 'Create', behaviour: :popup }
      end
      build_qc_summary(AppConst::QC_SAMPLE_PROGRESSIVE, prog_id)

      items_prod = []
      sample_type_id, prod_id = qc_sample_type_and_id(AppConst::QC_SAMPLE_PRODUCER)
      if prod_id
        items_prod << { url: "/quality/qc/qc_samples/#{prod_id}/edit", text: 'Edit', behaviour: :popup }
        items_prod << { url: "/quality/qc/qc_samples/#{prod_id}/print_barcode", text: 'Print', behaviour: :popup }
        items_prod << { url: "/quality/qc/qc_samples/#{prod_id}/qc_test/starch", text: 'Starch test', behaviour: :popup }
      elsif first_delivery_rule.need_to_make_a_sample?(AppConst::QC_SAMPLE_PRODUCER)
        items_prod << { url: "/quality/qc/qc_samples/new_rmt_delivery_id_sample/#{sample_type_id}/#{@options[:id]}", text: 'Create', behaviour: :popup }
      end
      build_qc_summary(AppConst::QC_SAMPLE_PRODUCER, prod_id)

      items_mrl = []
      mrl_result_id = mrl_result_id_for(@options[:id])
      if mrl_result_id
        rules[:mrl_test_result] = @mrl_result_repo.mrl_result_summary(mrl_result_id)
        items_mrl << { url: "/quality/mrl/mrl_results/#{mrl_result_id}/edit", text: 'Edit', behaviour: :popup }
        items_mrl << { url: "/quality/mrl/mrl_results/#{mrl_result_id}/capture_mrl_result", text: 'Capture Result', behaviour: :popup }
        items_mrl << { url: "/quality/mrl/mrl_results/#{mrl_result_id}", text: 'View', behaviour: :popup }
        items_mrl << { url: "/quality/mrl/mrl_results/#{mrl_result_id}/print_mrl_labels", text: 'Print MRL Label', behaviour: :popup }
      else
        rules[:mrl_test_result] = []
        items_mrl << { url: "/raw_materials/deliveries/rmt_deliveries/#{@options[:id]}/capture_delivery_mrl_result", text: 'Create', behaviour: :popup }
      end

      rules[:items_fruit] = items_fruit
      rules[:items_prog] = items_prog
      rules[:items_prod] = items_prod
      rules[:items_mrl] = items_mrl
    end

    def mrl_result_id_for(delivery_id)
      arr = %i[farm_id puc_id orchard_id cultivar_id season_id]
      args = @mrl_result_repo.mrl_result_attrs_for(delivery_id, arr)
      @mrl_result_repo.look_for_existing_mrl_result_id(args)
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
