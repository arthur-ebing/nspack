# frozen_string_literal: true

module QualityApp
  class OrchardTestRepo < BaseRepo # rubocop:disable Metrics/ClassLength
    build_for_select :orchard_test_types,
                     label: :test_type_code,
                     value: :id,
                     order_by: :test_type_code
    build_inactive_select :orchard_test_types,
                          label: :test_type_code,
                          value: :id,
                          order_by: :test_type_code

    crud_calls_for :orchard_test_types, name: :orchard_test_type, wrapper: OrchardTestType
    crud_calls_for :orchard_test_results, name: :orchard_test_result, wrapper: OrchardTestResult

    build_for_select :cultivars,
                     alias: :cultivar_codes,
                     label: %i[cultivar_name cultivar_code],
                     value: :id,
                     order_by: :cultivar_code
    build_inactive_select :cultivars,
                          alias: :cultivar_codes,
                          label: %i[cultivar_name cultivar_code],
                          value: :id,
                          order_by: :cultivar_code

    build_for_select :orchards,
                     label: :orchard_code,
                     value: :id,
                     order_by: :orchard_code
    build_inactive_select :orchards,
                          label: :orchard_code,
                          value: :id,
                          order_by: :orchard_code

    def for_select_orchard_test_results(orchard_test_type_id)
      query = <<~SQL
        SELECT
            concat(pucs.puc_code, ' - ',orchards.orchard_code, ' - ',cultivars.cultivar_code) as code,
            orchard_test_results.id
        FROM orchard_test_results
        JOIN pucs ON pucs.id = orchard_test_results.puc_id
        JOIN orchards ON orchards.id = orchard_test_results.orchard_id
        JOIN cultivars ON cultivars.id = orchard_test_results.cultivar_id
        WHERE orchard_test_type_id = #{orchard_test_type_id}
      SQL
      DB[query].select_map(%i[code id])
    end

    def find_orchard_test_type_flat(id)
      query = <<~SQL
        SELECT
            orchard_test_types.*,
            string_agg(DISTINCT target_market_groups.target_market_group_name, ', ') AS applicable_tm_groups,
            string_agg(DISTINCT cultivars.cultivar_name, ', ') AS applicable_cultivars,
            string_agg(DISTINCT commodity_groups.code, ', ') AS applicable_commodity_groups
        FROM orchard_test_types
        LEFT JOIN target_market_groups ON target_market_groups.id = ANY (orchard_test_types.applicable_tm_group_ids)
        LEFT JOIN cultivars ON cultivars.id = ANY (orchard_test_types.applicable_cultivar_ids)
        LEFT JOIN commodity_groups ON commodity_groups.id = ANY (orchard_test_types.applicable_commodity_group_ids)
        WHERE orchard_test_types.id = #{id}
        GROUP BY orchard_test_types.id
      SQL
      OrchardTestTypeFlat.new(DB[query].first)
    end

    def find_orchard_test_result_flat(id)
      query = <<~SQL
        SELECT
            orchard_test_results.*,
            orchard_test_types.test_type_code AS orchard_test_type_code,
            orchards.orchard_code,
            pucs.puc_code,
            cultivars.cultivar_name AS cultivar_code
        FROM orchard_test_results
        JOIN orchard_test_types ON orchard_test_types.id = orchard_test_results.orchard_test_type_id
        LEFT JOIN cultivars ON cultivars.id = orchard_test_results.cultivar_id
        LEFT JOIN orchards ON orchards.id = orchard_test_results.orchard_id
        LEFT JOIN pucs ON pucs.id = orchard_test_results.puc_id
        WHERE orchard_test_results.id = #{id}

      SQL
      hash = DB[query].first
      return nil if hash.nil?

      hash[:api_result] = nil if hash[:api_result].nil_or_empty?
      OrchardTestResultFlat.new(hash)
    end

    def create_orchard_test_type(params)
      DB[:orchard_test_types].insert(prepare_array_values_for_db(params))
    end

    def update_orchard_test_type(id, params)
      attrs = params.to_h
      attrs[:applicable_tm_group_ids] = nil if attrs[:applies_to_all_markets]

      if attrs[:applies_to_all_cultivars]
        attrs[:applicable_cultivar_ids] = nil
        attrs[:applicable_commodity_group_ids] = nil
      end

      DB[:orchard_test_types].where(id: id).update(prepare_array_values_for_db(attrs))
    end

    def update_orchard_test_result(id, params)
      attrs = params.to_h
      attrs.delete(:api_response) if attrs[:api_response].nil_or_empty?
      attrs[:api_response] = hash_for_jsonb_col(attrs[:api_response]) if attrs.key?(:api_response)

      DB[:orchard_test_results].where(id: id).update(attrs)
    end

    def delete_orchard_test_result(id)
      instance = find_orchard_test_result_flat(id)

      # update_orchard_otmc_results
      otmc_results = get(:orchards, instance.orchard_id, :otmc_results) || {}
      otmc_results.delete(instance.orchard_test_type_code.to_sym)
      result = otmc_results.empty? ? nil : Sequel.hstore(otmc_results)
      update(:orchards, instance.orchard_id, otmc_results: result)

      DB[:orchard_test_results].where(id: id).delete
    end

    def puc_orchard_cultivar
      hash = {}
      select_values(:orchards, %i[puc_id id cultivar_ids]).each do |puc_id, orchard_id, cultivar_ids|
        puc = get(:pucs, puc_id, :puc_code)
        orchard = get(:orchards, orchard_id, :orchard_code)
        cultivar_ids.each do |cultivar_id|
          cultivar = get(:cultivars, cultivar_id, :cultivar_code)
          hash["Puc #{puc} - Orchard #{orchard}"] = "Cultivar #{cultivar}   "
        end
      end
      Hash[hash.sort]
    end
  end
end
