# frozen_string_literal: true

module FinishedGoodsApp
  class LoadContainerRepo < BaseRepo
    build_for_select :load_containers,
                     label: :container_code,
                     value: :id,
                     order_by: :container_code
    build_for_select :container_stack_types,
                     label: :stack_type_code,
                     value: :id,
                     order_by: :stack_type_code

    build_inactive_select :load_containers,
                          label: :container_code,
                          value: :id,
                          order_by: :container_code
    build_inactive_select :container_stack_types,
                          label: :stack_type_code,
                          value: :id,
                          order_by: :stack_type_code

    crud_calls_for :load_containers, name: :load_container, wrapper: LoadContainer

    def find_load_container_flat(id)
      find_with_association(:load_containers,
                            id,
                            parent_tables: [{ parent_table: :container_stack_types,
                                              columns: %i[stack_type_code description],
                                              foreign_key: :stack_type_id,
                                              flatten_columns: { stack_type_code: :stack_type_code, description: :stack_type_description } },
                                            { parent_table: :cargo_temperatures,
                                              columns: %i[temperature_code set_point_temperature],
                                              foreign_key: :cargo_temperature_id,
                                              flatten_columns: { temperature_code: :cargo_temperature_code, set_point_temperature: :set_point_temperature } }],
                            wrapper: LoadContainerFlat)
    end

    def for_select_container_stack_types
      query = "SELECT stack_type_code || ' - ' || description, id FROM container_stack_types"
      DB[query].select_map(%i[code id])
    end

    def find_stack_type_id(stack_type_code)
      DB[:container_stack_types].where(stack_type_code: stack_type_code).get(:id)
    end

    def find_load_container_from(load_id:)
      DB[:load_containers].where(load_id: load_id).get(:id)
    end

    def actual_payload_from(load_id:)
      DB[:pallets].where(load_id: load_id).select_map(:nett_weight).sum
    end

    def verified_gross_weight_from(load_id:)
      DB[:pallets].where(load_id: load_id).select_map(:gross_weight).sum
    end
  end
end
