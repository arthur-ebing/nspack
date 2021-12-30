# frozen_string_literal: true

module QualityApp
  class QcRepo < BaseRepo
    build_for_select :qc_samples,
                     label: :presort_run_lot_number,
                     value: :id,
                     no_active_check: true,
                     order_by: :presort_run_lot_number

    crud_calls_for :qc_samples, name: :qc_sample, wrapper: QcSample

    build_for_select :qc_tests,
                     label: :id,
                     value: :id,
                     no_active_check: true,
                     order_by: :id

    crud_calls_for :qc_tests, name: :qc_test, wrapper: QcTest

    crud_calls_for :qc_starch_measurements, name: :qc_starch_measurement

    crud_calls_for :qc_defect_measurements, name: :qc_defect_measurement

    def existing_tests_for(qc_sample_id)
      all(:qc_tests, QcTest, qc_sample_id: qc_sample_id).map { |r| r.to_h.merge(test_type_code: 'starch') }
    end

    def find_qc_sample_label(id)
      DB[:vw_qc_sample_label].where(sample_id: id).first
    end

    def sample_context(res) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity
      ctx = res.to_h.select { |k, v| %i[rmt_delivery_id coldroom_location_id production_run_id orchard_id presort_run_lot_number].include?(k) && v }
      raise Crossbeams::FrameworkError, 'Sample has no context' if ctx.length.zero?
      raise Crossbeams::FrameworkError, 'Sample has more than one context' if ctx.length > 1

      case ctx.keys.first
      when :rmt_delivery_id
        ['Delivery', ctx.values.first]
      when :coldroom_location_id
        code = get(:locations, :location_long_code, ctx.values.first)
        ['Coldroom', code]
      when :production_run_id
        ['Production run', ctx.values.first]
      when :orchard_id
        ['Orchard', ctx.values.first]
      when :presort_run_lot_number
        ['Presort lot', ctx.values.first]
      end
    end

    def find_sample_test_of_type(sample_id, test_type_id)
      get_id(:qc_tests, qc_sample_id: sample_id, qc_test_type_id: test_type_id)
    end

    def starch_test_summary(qc_sample_id)
      test_type_id = get_id(:qc_test_types, qc_test_type_name: 'starch')
      test_id = find_sample_test_of_type(qc_sample_id, test_type_id)
      return nil if test_id.nil?

      DB.get(Sequel.function(:fn_starch_percentages, test_id))
    end

    def defects_test_summary(qc_sample_id)
      test_type_id = get_id(:qc_test_types, qc_test_type_name: 'defects')
      test_id = find_sample_test_of_type(qc_sample_id, test_type_id)
      return nil if test_id.nil?

      DB.get(Sequel.function(:fn_qc_defect_classes, test_id))
    end

    def sample_id_for_type_and_context(sample_type_id, context, context_key)
      DB[:qc_samples].where(qc_sample_type_id: sample_type_id, context => context_key).get(:id)
    end

    def sample_summary(qc_sample_id)
      query = <<~SQL
        SELECT s.id AS key, s.sample_size,
        CASE WHEN s.completed THEN
          'Complete'
        ELSE
          'Editing'
        END AS status,
        s.ref_number AS summary
        FROM qc_samples s
        WHERE s.id = ?
      SQL
      DB[query, qc_sample_id].first
    end

    def sample_test_summaries(qc_sample_id)
      query = <<~SQL
        SELECT y.qc_test_type_name AS key, t.sample_size,
        CASE WHEN t.completed THEN
          'Complete'
        ELSE
          'Editing'
        END AS status,
        CASE WHEN y.qc_test_type_name = 'starch' THEN
          fn_starch_percentages(t.id)
        WHEN y.qc_test_type_name = 'defects' THEN
          fn_qc_defect_classes(t.id)
        ELSE
          NULL
        END AS summary
        FROM qc_tests t
        JOIN qc_test_types y ON y.id = t.qc_test_type_id
        WHERE t.qc_sample_id = ?
        ORDER BY y.qc_test_type_name
      SQL
      DB[query, qc_sample_id].all
    end

    def rows_for_defects_test(qc_test_id)
      query = <<~SQL
        SELECT
          fruit_defects.id,
          fruit_defect_categories.defect_category,
          fruit_defect_types.fruit_defect_type_name,
          fruit_defects.fruit_defect_code,
          fruit_defects.short_description,
          internal,
          external,
          pre_harvest,
          post_harvest,
          severity,
          qc_class_2,
          qc_class_3,
          qc_defect_measurements.qty_class_2,
          qc_defect_measurements.qty_class_3
        FROM
          fruit_defects
          JOIN fruit_defect_types ON fruit_defect_types.id = fruit_defects.fruit_defect_type_id
          JOIN fruit_defect_categories ON fruit_defect_categories.id = fruit_defect_types.fruit_defect_category_id
          LEFT JOIN qc_defect_measurements ON qc_defect_measurements.fruit_defect_id = fruit_defects.id
            AND qc_defect_measurements.qc_test_id = ?
        WHERE
          fruit_defect_types.active
          AND fruit_defects.active
        ORDER BY
          fruit_defect_categories.defect_category,
          fruit_defect_types.fruit_defect_type_name,
          fruit_defects.fruit_defect_code
      SQL
      DB[query, qc_test_id].all
    end

    # Given a delivery, check if there is a sample of the given type
    # for the delivery's combination of season, cultivar and orchard.
    def rmt_delivery_has_first_sample?(rmt_delivery_id, sample_type)
      season_id, cultivar_id, orchard_id = get(:rmt_deliveries, %i[season_id cultivar_id orchard_id], rmt_delivery_id)
      query = <<~SQL
        SELECT s.id
        FROM qc_samples s
        JOIN qc_sample_types t ON t.id = s.qc_sample_type_id
        JOIN rmt_deliveries r ON r.id = s.rmt_delivery_id
        WHERE t.qc_sample_type_name = ?
          AND r.season_id = ?
          AND r.cultivar_id = ?
          AND r.orchard_id = ?
      SQL
      !DB[query, sample_type, season_id, cultivar_id, orchard_id].first.nil?
    end
  end
end
