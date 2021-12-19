# frozen_string_literal: true

module UiRules
  class QcSampleRule < Base # rubocop:disable Metrics/ClassLength
    def generate_rules
      @repo = QualityApp::QcRepo.new
      @print_repo = LabelApp::PrinterRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields common_fields

      set_show_fields if %i[show reopen print_barcode select_test].include? @mode
      set_print_fields if @mode == :print_barcode
      fields[:id][:renderer] = :label if @mode == :edit
      rules[:existing_tests] = existing_tests

      form_name 'qc_sample'
    end

    def set_show_fields # rubocop:disable Metrics/AbcSize
      context, context_ref = @repo.sample_context(@repo.find_qc_sample(@options[:id]))
      starch_summary = @repo.starch_test_summary(@options[:id])
      fields[:id] = { renderer: :label, caption: 'Sample ID' }
      qc_sample_type_id_label = @repo.get(:qc_sample_types, @form_object.qc_sample_type_id, :qc_sample_type_name)
      rmt_delivery_id_label = @repo.get(:rmt_deliveries, @form_object.rmt_delivery_id, :truck_registration_number)
      coldroom_location_id_label = @repo.get(:locations, @form_object.coldroom_location_id, :location_long_code)
      production_run_id_label = @repo.get(:production_runs, @form_object.production_run_id, :active_run_stage)
      orchard_id_label = @repo.get(:orchards, @form_object.orchard_id, :orchard_code)
      fields[:qc_sample_type_id] = { renderer: :label, with_value: qc_sample_type_id_label, caption: 'Qc Sample Type' }
      fields[:rmt_delivery_id] = { renderer: :label, with_value: rmt_delivery_id_label, caption: 'Rmt Delivery' }
      fields[:coldroom_location_id] = { renderer: :label, with_value: coldroom_location_id_label, caption: 'Coldroom Location' }
      fields[:production_run_id] = { renderer: :label, with_value: production_run_id_label, caption: 'Production Run' }
      fields[:orchard_id] = { renderer: :label, with_value: orchard_id_label, caption: 'Orchard' }
      fields[:presort_run_lot_number] = { renderer: :label }
      fields[:ref_number] = { renderer: :label }
      fields[:short_description] = { renderer: :label }
      fields[:sample_size] = { renderer: :label }
      fields[:editing] = { renderer: :label, as_boolean: true }
      fields[:completed] = { renderer: :label, as_boolean: true }
      fields[:completed_at] = { renderer: :label, format: :without_timezone_or_seconds }
      fields[:rmt_bin_ids] = { renderer: :label }
      fields[:context] = { renderer: :label, caption: context, with_value: context_ref }
      fields[:starch_summary] = { renderer: :label, with_value: starch_summary, invisible: starch_summary.nil? }
    end

    def set_print_fields
      fields[:personnel_number] = { renderer: :label }
      fields[:label_name] = { renderer: :select,
                              options: MasterfilesApp::LabelTemplateRepo.new.for_select_label_templates(where: { application: AppConst::PRINT_APP_QC }).map(&:first),
                              required: true }
      fields[:printer] = { renderer: :select,
                           options: @print_repo.select_printers_for_application(AppConst::PRINT_APP_QC),
                           required: true }
      fields[:no_of_prints] = { renderer: :integer, required: true }
    end

    def common_fields
      {
        qc_test_type_id: { renderer: :select,
                           options: MasterfilesApp::QcRepo.new.for_select_qc_test_types,
                           disabled_options: MasterfilesApp::QcRepo.new.for_select_inactive_qc_test_types,
                           caption: 'QC Test Type',
                           required: true },
        qc_sample_type_id: { renderer: :label,
                             with_value: sample_type_label,
                             hidden_value: @options[:qc_sample_type_id] || @form_object.qc_sample_type_id,
                             caption: 'QC Sample Type',
                             include_hidden_field: true },
        rmt_delivery_id: { renderer: :hidden },
        coldroom_location_id: { renderer: :hidden },
        production_run_id: { renderer: :hidden },
        orchard_id: { renderer: :hidden },
        presort_run_lot_number: { renderer: :hidden },
        id: { renderer: :integer, caption: 'QC Sample id' },
        ref_number: { required: true },
        short_description: {},
        sample_size: { renderer: :integer, required: true },
        editing: { renderer: :checkbox },
        completed: { renderer: :checkbox },
        completed_at: {},
        drawn_at: { renderer: :datetime },
        rmt_bin_ids: {},
        context: { renderer: :hidden },
        context_key: { renderer: :hidden }
      }
    end

    def make_form_object
      if %i[new select].include?(@mode)
        make_new_form_object
        return
      end

      @form_object = OpenStruct.new(@repo.find_qc_sample(@options[:id]).to_h.merge(qc_test_type_id: nil, context: nil, starch_summary: nil))
      @form_object = OpenStruct.new(@form_object.to_h.merge(printer: @print_repo.default_printer_for_application(AppConst::PRINT_APP_QC), no_of_prints: 1)) if @mode == :print_barcode
    end

    def make_new_form_object
      hash = { @options[:context] => @options[:context_key],
               drawn_at: Time.now,
               sample_type_id: @options[:qc_sample_type_id],
               sample_size: @repo.get(:qc_sample_types, @options[:qc_sample_type_id], :default_sample_size),
               context: @options[:context],
               context_key: @options[:context_key] }
      # qc_sample_type = case @options[:context]
      #                  when :rmt_delivery_id
      #                    '100_fruit_sample'
      #                  when :coldroom_location_id
      #                    'coldroom'
      #                  end
      hash[:short_description] = send("desc_#{@options[:context]}".to_sym)
      # hash[:qc_sample_type_id] = @repo.get_id(:qc_sample_types, qc_sample_type_name: qc_sample_type) unless qc_sample_type.nil?
      @form_object = new_form_object_from_struct(QualityApp::QcSample, merge_hash: hash)
      # @form_object = new_form_object_from_struct(QualityApp::QcSample)
    end

    def desc_rmt_delivery_id
      instance = RawMaterialsApp::RmtDeliveryRepo.new.find_rmt_delivery(@options[:context_key])
      farm = @repo.get(:farms, instance.farm_id, :farm_code)
      orch = @repo.get(:orchards, instance.orchard_id, :orchard_code)
      cult, desc = @repo.get(:cultivars, instance.cultivar_id, %i[cultivar_code description])

      "Farm #{farm} Orch #{orch} #{cult} #{desc} #{instance.date_delivered.strftime('%Y-%m-%d %H:%M')}"
    end

    private

    def sample_type_label
      @repo.get(:qc_sample_types, @options[:qc_sample_type_id] || @form_object.qc_sample_type_id, :qc_sample_type_name)
    end

    def existing_tests
      return [] unless @options[:id]

      @repo.existing_tests_for(@options[:id]).map { |test| make_link_for_test(test) }
    end

    def make_link_for_test(test)
      { url: "/quality/qc/qc_tests/#{test[:id]}/#{test[:test_type_code]}", text: test[:test_type_code] }
    end
  end
end
