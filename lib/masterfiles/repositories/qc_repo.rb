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

    # FRUIT DEFECT TYPES
    # --------------------------------------------------------------------------
    build_for_select :fruit_defect_types,
                     label: :fruit_defect_type_name,
                     value: :id,
                     order_by: :fruit_defect_type_name
    build_inactive_select :fruit_defect_types,
                          label: :fruit_defect_type_name,
                          value: :id,
                          order_by: :fruit_defect_type_name

    # FRUIT DEFECTS
    # --------------------------------------------------------------------------
    build_for_select :fruit_defects,
                     label: :fruit_defect_code,
                     value: :id,
                     no_active_check: true,
                     order_by: :fruit_defect_code

    crud_calls_for :fruit_defect_types, name: :fruit_defect_type, wrapper: FruitDefectType
    crud_calls_for :qc_test_types, name: :qc_test_type, wrapper: QcTestType
    crud_calls_for :qc_sample_types, name: :qc_sample_type, wrapper: QcSampleType
    crud_calls_for :qc_measurement_types, name: :qc_measurement_type, wrapper: QcMeasurementType
    crud_calls_for :fruit_defects, name: :fruit_defect, wrapper: FruitDefect

    def find_fruit_defect(id)
      find_with_association(:fruit_defects, id,
                            wrapper: FruitDefectFlat,
                            parent_tables: [{ parent_table: :rmt_classes,
                                              columns: [:rmt_class_code],
                                              flatten_columns: { rmt_class_code: :rmt_class_code } },
                                            { parent_table: :fruit_defect_types,
                                              columns: [:fruit_defect_type_name],
                                              flatten_columns: { fruit_defect_type_name: :fruit_defect_type_name } }])
    end
  end
end
