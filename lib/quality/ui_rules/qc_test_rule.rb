# frozen_string_literal: true

module UiRules
  class QcTestRule < Base
    def generate_rules
      @repo = QualityApp::QcRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields common_fields

      header
      set_show_fields if %i[show reopen].include? @mode

      form_name 'qc_test'
    end

    def header
      context, context_ref = @repo.sample_context(@repo.find_qc_sample(@form_object.qc_sample_id))
      query = <<~SQL
        SELECT qc_samples.id AS sample_id, qc_sample_type_name AS sample_type,
        ref_number, short_description,
        '#{context_ref}' AS #{context}, sample_size
        FROM qc_samples
        JOIN qc_sample_types ON qc_sample_types.id = qc_samples.qc_sample_type_id
        WHERE qc_samples.id = ?
      SQL
      rec = DB[query, @form_object.qc_sample_id].first

      rules[:compact_header] = compact_header(columns: rec.keys, with_object: rec)
    end

    def set_show_fields
      fields[:qc_measurement_type_id] = { renderer: :label, with_value: qc_measurement_type_id_label, caption: 'Qc Measurement Type' }
      fields[:qc_sample_id] = { renderer: :label, with_value: qc_sample_id_label, caption: 'Qc Sample' }
      fields[:qc_test_type_id] = { renderer: :label, with_value: qc_test_type_id_label, caption: 'Qc Test Type' }
      fields[:instrument_plant_resource_id] = { renderer: :label, with_value: instrument_plant_resource_id_label, caption: 'Instrument Plant Resource' }
      fields[:sample_size] = { renderer: :label }
      fields[:editing] = { renderer: :label, as_boolean: true }
      fields[:completed] = { renderer: :label, as_boolean: true }
      fields[:completed_at] = { renderer: :label, format: :without_timezone_or_seconds }
    end

    def common_fields
      {
        qc_measurement_type_id: { renderer: :label },
        qc_sample_id: { renderer: :label },
        qc_test_type_id: { renderer: :label },
        instrument_plant_resource_id: { renderer: :label },
        sample_size: { required: true },
        editing: { renderer: :checkbox },
        completed: { renderer: :checkbox },
        percentage5: { caption: '5%' },
        percentage10: { caption: '10%' },
        percentage20: { caption: '20%' },
        percentage25: { caption: '25%' },
        percentage30: { caption: '30%' },
        percentage40: { caption: '40%' },
        percentage60: { caption: '60%' },
        percentage70: { caption: '70%' },
        percentage80: { caption: '80%' },
        completed_at: {}
      }
    end

    def make_form_object
      if @mode == :new
        make_new_form_object
        return
      end

      @form_object = @repo.find_qc_test(@options[:id])
      @form_object = OpenStruct.new(@form_object.to_h.merge(percentages))
    end

    def percentages
      current_set = Hash[@repo.select_values(:qc_starch_measurements, %i[starch_percentage qty_fruit_with_percentage], qc_test_id: @options[:id])]
      percs = [5, 10, 20, 25, 30, 40, 60, 70, 80]
      Hash[percs.map { |p| "percentage#{p}".to_sym }.zip(percs.map { |p| current_set[p]&.zero? ? nil : current_set[p] })]
    end

    def make_new_form_object
      @form_object = new_form_object_from_struct(QualityApp::QcTest)
    end
  end
end
