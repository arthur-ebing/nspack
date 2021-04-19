# frozen_string_literal: true

module MasterfilesApp
  class FruitRepo < BaseRepo
    build_for_select :rmt_classes,
                     label: :rmt_class_code,
                     value: :id,
                     order_by: :rmt_class_code
    build_inactive_select :rmt_classes,
                          label: :rmt_class_code,
                          value: :id,
                          order_by: :rmt_class_code

    build_for_select :grades,
                     label: :grade_code,
                     value: :id,
                     order_by: :grade_code
    build_inactive_select :grades,
                          label: :grade_code,
                          value: :id,
                          order_by: :grade_code

    build_for_select :treatment_types,
                     label: :treatment_type_code,
                     value: :id,
                     order_by: :treatment_type_code
    build_inactive_select :treatment_types,
                          label: :treatment_type_code,
                          value: :id,
                          order_by: :treatment_type_code

    build_for_select :treatments,
                     label: :treatment_code,
                     value: :id,
                     order_by: :treatment_code
    build_inactive_select :treatments,
                          label: :treatment_code,
                          value: :id,
                          order_by: :treatment_code

    build_for_select :inventory_codes,
                     label: :inventory_code,
                     value: :id,
                     order_by: :inventory_code
    build_inactive_select :inventory_codes,
                          label: :inventory_code,
                          value: :id,
                          order_by: :inventory_code

    crud_calls_for :rmt_classes, name: :rmt_class, wrapper: RmtClass
    crud_calls_for :grades, name: :grade, wrapper: Grade
    crud_calls_for :treatment_types, name: :treatment_type, wrapper: TreatmentType
    crud_calls_for :treatments, name: :treatment, wrapper: Treatment
    crud_calls_for :inventory_codes, name: :inventory_code, wrapper: InventoryCode

    def find_treatment(id)
      hash = find_with_association(:treatments,
                                   id,
                                   parent_tables: [{ parent_table: :treatment_types,
                                                     columns: [:treatment_type_code],
                                                     flatten_columns: { treatment_type_code: :treatment_type_code } }])
      return nil if hash.nil?

      Treatment.new(hash)
    end

    def find_treatment_type_treatment_codes(id)
      DB[:treatments]
        .join(:treatment_types, id: :treatment_type_id)
        .where(treatment_type_id: id)
        .order(:treatment_code)
        .select_map(:treatment_code)
    end

    def for_select_treatments
      DB[:treatments]
        .join(:treatment_types, id: :treatment_type_id)
        .order(:treatment_code)
        .select(
          Sequel[:treatments][:id],
          :treatment_type_code,
          :treatment_code
        ).map { |r| ["#{r[:treatment_type_code]} - #{r[:treatment_code]}", r[:id]] }
    end

    def find_grade_by_rmt_class(rmt_class_id)
      DB[:grades]
        .join(:rmt_classes, rmt_class_code: :grade_code)
        .where(Sequel[:rmt_classes][:id] => rmt_class_id)
        .get(Sequel[:grades][:id])
    end
  end
end
