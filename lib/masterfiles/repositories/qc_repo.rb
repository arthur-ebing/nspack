# frozen_string_literal: true

module MasterfilesApp
  class QcRepo < BaseRepo
    # QC MEASUREMENT TYPES
    # --------------------------------------------------------------------------
    build_for_select :qc_measurement_types,
                     label: :qc_measurement_type_name,
                     value: :id,
                     order_by: :qc_measurement_type_name
    build_inactive_select :qc_measurement_types,
                          label: :qc_measurement_type_name,
                          value: :id,
                          order_by: :qc_measurement_type_name

    # QC SAMPLE TYPES
    # --------------------------------------------------------------------------
    build_for_select :qc_sample_types,
                     label: :qc_sample_type_name,
                     value: :id,
                     order_by: :qc_sample_type_name
    build_inactive_select :qc_sample_types,
                          label: :qc_sample_type_name,
                          value: :id,
                          order_by: :qc_sample_type_name

    # QC TEST TYPES
    # --------------------------------------------------------------------------
    build_for_select :qc_test_types,
                     label: :qc_test_type_name,
                     value: :id,
                     order_by: :qc_test_type_name
    build_inactive_select :qc_test_types,
                          label: :qc_test_type_name,
                          value: :id,
                          order_by: :qc_test_type_name

    # FRUIT DEFECT CATEGORIES
    # --------------------------------------------------------------------------
    build_for_select :fruit_defect_categories,
                     label: :defect_category,
                     value: :id,
                     order_by: :defect_category
    build_inactive_select :fruit_defect_categories,
                          label: :defect_category,
                          value: :id,
                          order_by: :defect_category

    # FRUIT DEFECTS
    # --------------------------------------------------------------------------
    build_for_select :fruit_defects,
                     label: :fruit_defect_code,
                     value: :id,
                     no_active_check: true,
                     order_by: :fruit_defect_code

    crud_calls_for :qc_test_types, name: :qc_test_type, wrapper: QcTestType
    crud_calls_for :qc_sample_types, name: :qc_sample_type, wrapper: QcSampleType
    crud_calls_for :qc_measurement_types, name: :qc_measurement_type, wrapper: QcMeasurementType
    crud_calls_for :fruit_defect_categories, name: :fruit_defect_category, wrapper: FruitDefectCategory
    crud_calls_for :fruit_defect_types, name: :fruit_defect_type, wrapper: FruitDefectType
    crud_calls_for :fruit_defects, name: :fruit_defect, wrapper: FruitDefect

    def find_fruit_defect(id)
      find_with_association(:fruit_defects, id,
                            wrapper: FruitDefectFlat,
                            parent_tables: [{ parent_table: :fruit_defect_types,
                                              flatten_columns: { fruit_defect_type_name: :fruit_defect_type_name,
                                                                 fruit_defect_category_id: :fruit_defect_category_id } },
                                            { parent_table: :fruit_defect_categories,
                                              flatten_columns: { defect_category: :defect_category } }])
    end

    def find_fruit_defect_type_flat(id)
      find_with_association(:fruit_defect_types, id,
                            wrapper: FruitDefectTypeFlat,
                            parent_tables: [{ parent_table: :fruit_defect_categories,
                                              columns: [:defect_category],
                                              flatten_columns: { defect_category: :defect_category } }])
    end

    def for_select_fruit_defect_types(active: true) # rubocop:disable Metrics/AbcSize
      DB[:fruit_defect_types]
        .join(:fruit_defect_categories, id: :fruit_defect_category_id)
        .where(Sequel[:fruit_defect_types][:active] => active)
        .order(Sequel[:fruit_defect_categories][:defect_category], Sequel[:fruit_defect_types][:fruit_defect_type_name])
        .select(Sequel[:fruit_defect_categories][:defect_category], Sequel[:fruit_defect_types][:fruit_defect_type_name], Sequel[:fruit_defect_types][:id])
        .map { |r| ["#{r[:defect_category]} - #{r[:fruit_defect_type_name]}", r[:id]] }
    end

    def for_select_inactive_fruit_defect_types
      for_select_fruit_defect_types(active: false)
    end
  end
end
