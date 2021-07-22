# frozen_string_literal: true

module MasterfilesApp
  class FruitRepo < BaseRepo # rubocop:disable Metrics/ClassLength
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

    def find_rmt_class_by_grade(grade_id)
      DB[:rmt_classes]
        .join(:grades, grade_code: :rmt_class_code)
        .where(Sequel[:grades][:id] => grade_id)
        .get(Sequel[:rmt_classes][:id])
    end

    def sync_inventory_packing_costs(inventory_code_id)
      query = <<~SQL
        INSERT INTO inventory_codes_packing_costs (inventory_code_id, commodity_id)
        SELECT ?, commodities.id
        FROM commodities
        WHERE NOT EXISTS (SELECT id
          FROM inventory_codes_packing_costs
          WHERE inventory_code_id = ?
          AND commodity_id = commodities.id)
      SQL
      DB[query, inventory_code_id, inventory_code_id].insert
    end

    def update_inventory_codes_packing_cost(id, attrs)
      update(:inventory_codes_packing_costs, id, attrs)
    end

    def find_inventory_codes_packing_cost(id)
      hash = find_with_association(:inventory_codes_packing_costs,
                                   id,
                                   parent_tables: [{ parent_table: :commodities,
                                                     columns: %i[code description],
                                                     foreign_key: :commodity_id,
                                                     flatten_columns: { code: :commodity_code, description: :commodity_description  } },
                                                   { parent_table: :inventory_codes,
                                                     columns: %i[inventory_code description],
                                                     foreign_key: :inventory_code_id,
                                                     flatten_columns: { inventory_code: :inventory_code, description: :inventory_description  } }])
      return nil if hash.nil?

      InventoryCodesPackingCostFlat.new(hash)
    end

    def delete_inventory_code(id)
      DB[:inventory_codes_packing_costs].where(inventory_code_id: id).delete
      DB[:inventory_codes].where(id: id).delete
    end
  end
end
