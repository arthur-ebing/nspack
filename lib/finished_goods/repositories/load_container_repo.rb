# frozen_string_literal: true

module FinishedGoodsApp
  class LoadContainerRepo < BaseRepo
    build_for_select :load_containers, label: :container_code, value: :id, order_by: :container_code
    build_for_select :container_stack_types, label: :stack_type_code, value: :id, order_by: :stack_type_code
    build_inactive_select :load_containers, label: :container_code, value: :id, order_by: :container_code
    build_inactive_select :container_stack_types, label: :stack_type_code, value: :id, order_by: :stack_type_code
    crud_calls_for :load_containers, name: :load_container, wrapper: LoadContainer

    def find_load_container_flat(id)
      hash = find_with_association(:load_containers,
                                   id,
                                   parent_tables: [{ parent_table: :container_stack_types,
                                                     columns: %i[stack_type_code description],
                                                     foreign_key: :stack_type_id,
                                                     flatten_columns: { stack_type_code: :stack_type_code, description: :stack_type_description } },
                                                   { parent_table: :cargo_temperatures,
                                                     columns: %i[temperature_code set_point_temperature],
                                                     foreign_key: :cargo_temperature_id,
                                                     flatten_columns: { temperature_code: :cargo_temperature_code, set_point_temperature: :set_point_temperature } }])
      return nil if hash.nil?

      hash[:load_container_id] = id
      hash[:container] = true
      hash[:stack_type_id] ||= repo.get_id(:container_stack_types, stack_type_code: 'S')
      hash[:cargo_temperature_id] ||= get_id(:cargo_temperatures, temperature_code: AppConst::DEFAULT_CARGO_TEMP_ON_ARRIVAL)
      %i[max_gross_weight tare_weight max_payload actual_payload set_point_temperature verified_gross_weight].each do |k|
        hash[k] = UtilityFunctions.delimited_number(hash[k])
      end
      LoadContainerFlat.new(hash)
    end

    def for_select_container_stack_types
      query = <<~SQL
        SELECT stack_type_code||' ('||description||')' AS code, id FROM container_stack_types
      SQL
      DB[query].select_map(%i[code id])
    end

    def calculate_calculate_actual_payload(load_id)
      DB[:pallets].where(load_id: load_id).select_map(:nett_weight).map { |w| w.nil? ? AppConst::BIG_ZERO : w }.sum
    end

    def calculate_verified_gross_weight(id)
      load_id = get(:load_containers, id, :load_id)
      pallets_gross_weight = DB[:pallets].where(load_id: load_id).select_map(:gross_weight).map { |w| w.nil? ? AppConst::BIG_ZERO : w }.sum
      container_tare_weight = get(:load_containers, id, :tare_weight) || 0
      pallets_gross_weight + container_tare_weight
    end
  end
end
