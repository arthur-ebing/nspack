# frozen_string_literal: true

module MasterfilesApp
  class FarmRepo < BaseRepo # rubocop:disable Metrics/ClassLength
    build_for_select :production_regions,
                     label: :production_region_code,
                     value: :id,
                     order_by: :production_region_code
    build_inactive_select :production_regions,
                          label: :production_region_code,
                          value: :id,
                          order_by: :production_region_code

    build_for_select :farm_groups,
                     label: :farm_group_code,
                     value: :id,
                     order_by: :farm_group_code
    build_inactive_select :farm_groups,
                          label: :farm_group_code,
                          value: :id,
                          order_by: :farm_group_code

    build_for_select :farms,
                     label: :farm_code,
                     value: :id,
                     order_by: :farm_code
    build_inactive_select :farms,
                          label: :farm_code,
                          value: :id,
                          order_by: :farm_code

    build_for_select :orchards,
                     label: :orchard_code,
                     value: :id,
                     order_by: :orchard_code
    build_inactive_select :orchards,
                          label: :orchard_code,
                          value: :id,
                          order_by: :orchard_code

    build_for_select :farm_sections,
                     label: :farm_section_name,
                     value: :id,
                     no_active_check: true,
                     order_by: :farm_section_name

    crud_calls_for :farm_sections, name: :farm_section, wrapper: FarmSection

    def for_select_pucs(opts = {})
      dataset = DB[:pucs].join(:farms_pucs, puc_id: :id).where(active: true).order(:puc_code)
      if opts[:where]
        raise Crossbeams::FrameworkError, 'WHERE clause in "for_select" must be a hash' unless opts[:where].is_a?(Hash)

        dataset = dataset.where(opts[:where].transform_values { |v| v == '' ? nil : v })
      end
      dataset.select_map(%i[puc_code id])
    end

    build_inactive_select :pucs,
                          label: :puc_code,
                          value: :id,
                          order_by: :puc_code

    crud_calls_for :production_regions, name: :production_region, wrapper: ProductionRegion
    crud_calls_for :farm_groups, name: :farm_group, wrapper: FarmGroup
    crud_calls_for :farms, name: :farm, wrapper: Farm
    crud_calls_for :orchards, name: :orchard, wrapper: Orchard
    crud_calls_for :pucs, name: :puc, wrapper: Puc

    def find_farm(id)
      hash = find_with_association(:farms,
                                   id,
                                   parent_tables: [{ parent_table: :farm_groups,
                                                     columns: [:farm_group_code],
                                                     flatten_columns: { farm_group_code: :farm_group_code } },
                                                   { parent_table: :production_regions,
                                                     columns: [:production_region_code],
                                                     foreign_key: :pdn_region_id,
                                                     flatten_columns: { production_region_code: :pdn_region_production_region_code } }],
                                   lookup_functions: [{ function: :fn_party_role_name,
                                                        args: [:owner_party_role_id],
                                                        col_name: :owner_party_role }])
      return nil if hash.nil?

      hash[:puc_id] = farm_primary_puc_id(id)
      Farm.new(hash)
    end

    def find_orchard(id)
      hash = find_with_association(:orchards,
                                   id,
                                   parent_tables: [{ parent_table: :farms,
                                                     columns: [:farm_code],
                                                     flatten_columns: { farm_code: :farm } },
                                                   { parent_table: :farm_sections,
                                                     columns: %i[farm_section_name farm_manager_party_role_id],
                                                     flatten_columns: { farm_section_name: :farm_section_name, farm_manager_party_role_id: :farm_manager_party_role_id } },
                                                   { parent_table: :pucs,
                                                     columns: [:puc_code],
                                                     flatten_columns: { puc_code: :puc_code } }],
                                   sub_tables: [{ sub_table: :cultivars,
                                                  id_keys_column: :cultivar_ids,
                                                  columns: %i[id cultivar_name] }])
      return nil if hash.nil?

      hash[:cultivar_names] = hash[:cultivars].map { |r| r[:cultivar_name] }.sort.join(',')
      Orchard.new(hash)
    end

    def create_farm(attrs)
      params = attrs.to_h
      farms_pucs_ids = Array(params.to_h.delete(:puc_id))
      farm_id = DB[:farms].insert(params)
      farms_pucs_ids.each do |puc_id|
        DB[:farms_pucs].insert(farm_id: farm_id,
                               puc_id: puc_id)
      end
      farm_id
    end

    def associate_farms_pucs(id, farms_pucs_ids)
      return { error: 'Choose at least one puc' } if farms_pucs_ids.empty?

      existing_farms_pucs_ids = DB[:farms_pucs].where(farm_id: id).select_map(:puc_id)
      removed_farms_pucs_ids = existing_farms_pucs_ids - farms_pucs_ids
      new_farms_pucs_ids = farms_pucs_ids - existing_farms_pucs_ids
      DB[:farms_pucs].where(farm_id: id).where(puc_id: removed_farms_pucs_ids).delete
      new_farms_pucs_ids.each do |puc_id|
        DB[:farms_pucs].insert(farm_id: id,
                               puc_id: puc_id)
      end
    end

    def delete_farm(id)
      DB[:farms_pucs].where(farm_id: id).delete
      DB[:farms].where(id: id).delete
      { success: true }
    end

    def delete_farms_pucs(puc_id)
      DB[:farms_pucs].where(puc_id: puc_id).delete
    end

    def find_puc_farm_codes(id)
      DB[:farms].join(:farms_pucs, farm_id: :id).where(puc_id: id).order(:farm_code).select_map(:farm_code)
    end

    def find_farm_puc_codes(id)
      DB[:pucs].join(:farms_pucs, puc_id: :id).where(farm_id: id).order(:puc_code).select_map(:puc_code)
    end

    def find_farm_orchard_codes(id)
      DB[:orchards].join(:farms, id: :farm_id).where(farm_id: id).order(:orchard_code).select_map(:orchard_code)
    end

    def find_orchard_farm_section(id)
      query = <<~SQL
        SELECT f.farm_section_name || ' - ' || fn_party_role_name(f.farm_manager_party_role_id) AS farm_section
        FROM farm_sections f
        JOIN orchards o on o.farm_section_id=f.id
        WHERE o.id= ?
      SQL
      hash = DB[query, id].first
      hash.nil? ? nil : hash[:farm_section]
    end

    def selected_farm_orchard_codes(farm_id, puc_id)
      DB[:orchards]
        .where(farm_id: farm_id)
        .where(puc_id: puc_id)
        .order(:orchard_code)
        .select_map(%i[orchard_code id])
    end

    def selected_puc_orchard_codes(puc_id)
      DB[:orchards]
        .where(farm_id: DB[:farms_pucs].where(puc_id: puc_id).select(:farm_id))
        .where(puc_id: puc_id)
        .order(:orchard_code)
        .select_map(%i[orchard_code id])
    end

    def selected_farm_pucs(farm_id)
      DB[:pucs].join(:farms_pucs, puc_id: :id).where(farm_id: farm_id).order(:puc_code).select_map(%i[puc_code puc_id])
    end

    def farm_primary_puc_id(farm_id)
      DB[:pucs].join(:farms_pucs, puc_id: :id).where(farm_id: farm_id).select_map(:puc_id).first
    end

    def select_unallocated_pucs
      query = <<~SQL
        SELECT puc_code,id
        FROM pucs
        WHERE active AND id NOT IN (SELECT distinct puc_id from farms_pucs)
      SQL
      DB[query].order(:puc_code).select_map(%i[puc_code id])
    end

    def find_cultivar_names(id)
      query = <<~SQL
        SELECT cultivars.cultivar_name
        FROM orchards
        JOIN cultivars ON cultivars.id = ANY (orchards.cultivar_ids)
        WHERE orchards.id = #{id}
      SQL
      DB[query].order(:cultivar_name).select_map(:cultivar_name)
    end

    def find_farm_orchards
      query = <<~SQL
        SELECT DISTINCT o.id, f.farm_code || '_' || o.orchard_code AS farm_orchard_code
        FROM orchards o
        JOIN farms f ON f.id=o.farm_id
      SQL
      DB[query].map { |s| [s[:farm_orchard_code], s[:id]] }
    end

    def find_farm_orchard_by_orchard_id(orchard_id)
      query = <<~SQL
        SELECT DISTINCT f.farm_code || '_' || o.orchard_code AS farm_orchard_code
        FROM orchards o
        JOIN farms f ON f.id=o.farm_id
        WHERE o.id=#{orchard_id}
      SQL
      DB[query].map { |s| s[:farm_orchard_code] }.first
    end

    def find_farm_group_farm_codes(id)
      DB[:farms].join(:farm_groups, id: :farm_group_id).where(farm_group_id: id).order(:farm_code).select_map(:farm_code)
    end

    def create_farm_section(params)
      orchard_ids = params.delete(:orchard_ids).to_a
      farm_section_id = DB[:farm_sections].insert(params)
      DB[:orchards].where(id: orchard_ids).update(farm_section_id: farm_section_id)
      farm_section_id
    end

    def find_farm_section(id)
      query = <<~SQL
        SELECT DISTINCT farm_sections.id, farm_sections.farm_manager_party_role_id, farm_sections.farm_section_name, farm_sections.description
        , string_agg(orchard_code::text, ', '::text)AS orchards, orchards.farm_id
        , fn_party_role_name(farm_sections.farm_manager_party_role_id) AS farm_manager_party_role, fn_current_status('farm_sections', farm_sections.id) AS status
        FROM farm_sections
        JOIN orchards ON orchards.farm_section_id = farm_sections.id
        WHERE farm_sections.id = ?
        GROUP BY farm_sections.id, farm_sections.farm_manager_party_role_id, farm_sections.farm_section_name, farm_sections.description, orchards.farm_id
      SQL
      hash = DB[query, id].first
      return nil if hash.nil?

      hash[:orchard_ids] = orchard_ids(hash[:id])
      FarmSectionFlat.new(hash)
    end

    def orchard_ids(id)
      DB[:orchards].where(farm_section_id: id).select_map(:id)
    end

    def update_farm_section(id, params) # rubocop:disable Metrics/AbcSize
      orchard_ids = params.delete(:orchard_ids).map(&:to_i)
      current_orchards = DB[:orchards].where(farm_section_id: id).select_map(:id)
      new_orchards = orchard_ids - current_orchards
      removed_orchards = current_orchards - orchard_ids

      DB[:orchards].where(id: new_orchards).update(farm_section_id: id)
      DB[:orchards].where(id: removed_orchards).update(farm_section_id: nil)
      DB[:farm_sections].where(id: id).update(params)
    end

    def delete_farm_section(id)
      DB[:orchards].where(farm_section_id: id).update(farm_section_id: nil)
      DB[:farm_sections].where(id: id).delete
    end
  end
end
