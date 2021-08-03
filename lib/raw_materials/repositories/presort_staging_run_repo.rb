# frozen_string_literal: true

module RawMaterialsApp
  class PresortStagingRunRepo < BaseRepo
    build_for_select :presort_staging_runs,
                     label: :id,
                     value: :id,
                     order_by: :id
    build_for_select :presort_staging_run_children,
                     label: :id,
                     value: :id,
                     order_by: :id
    build_inactive_select :presort_staging_runs,
                          label: :id,
                          value: :id,
                          order_by: :id
    build_inactive_select :presort_staging_run_children,
                          label: :id,
                          value: :id,
                          order_by: :id

    crud_calls_for :presort_staging_runs, name: :presort_staging_run, wrapper: PresortStagingRun
    crud_calls_for :presort_staging_run_children, name: :presort_staging_run_child, wrapper: PresortStagingRunChild

    def find_presort_staging_run_flat(id)
      hash = find_with_association(
        :presort_staging_runs, id,
        parent_tables: [{ parent_table: :plant_resources,
                          columns: [:plant_resource_code],
                          foreign_key: :presort_unit_plant_resource_id,
                          flatten_columns: { plant_resource_code: :plant_resource_code } },
                        { parent_table: :cultivars,
                          columns: [:cultivar_name],
                          flatten_columns: { cultivar_name: :cultivar_name } },
                        { parent_table: :rmt_classes,
                          foreign_key: :rmt_class_id,
                          flatten_columns: { rmt_class_code: :rmt_class_code } },
                        { parent_table: :rmt_sizes,
                          flatten_columns: { size_code: :size_code } },
                        { parent_table: :seasons,
                          flatten_columns: { season_code: :season_code } },
                        { parent_table: :suppliers,
                          flatten_columns: { supplier_party_role_id: :supplier_party_role_id } }],
        lookup_functions: [{ function: :fn_current_status,
                             args: ['presort_staging_runs', :id],
                             col_name: :status }]
      )
      return nil if hash.nil?

      hash[:supplier] = DB.get(Sequel.function(:fn_party_role_name, hash[:supplier_party_role_id]))
      PresortStagingRunFlat.new(hash)
    end

    def find_presort_staging_run_child_flat(id)
      hash = find_with_association(
        :presort_staging_run_children, id,
        parent_tables: [{ parent_table: :farms,
                          columns: [:farm_code],
                          foreign_key: :farm_id,
                          flatten_columns: { farm_code: :farm_code } }],
        lookup_functions: [{ function: :fn_current_status,
                             args: ['presort_staging_run_children', :id],
                             col_name: :status }]
      )
      return nil if hash.nil?

      PresortStagingRunChildFlat.new(hash)
    end

    def active_or_staged_children?(presort_staging_run_id)
      !DB[:presort_staging_run_children]
        .where(staged: true)
        .or(active: true)
        .where(presort_staging_run_id: presort_staging_run_id)
        .all
        .empty?
    end

    def child_run_parent_id_and_plant_resource_id(child_run_id)
      DB[:presort_staging_run_children]
        .join(:presort_staging_runs, id: :presort_staging_run_id)
        .where(Sequel[:presort_staging_run_children][:id] => child_run_id)
        .select(:presort_staging_run_id, :presort_unit_plant_resource_id)
        .get(%i[presort_staging_run_id presort_unit_plant_resource_id])
    end

    def active_child_run_for_plant_resource_id?(plant_resource_id)
      !DB[:presort_staging_run_children]
        .join(:presort_staging_runs, id: :presort_staging_run_id)
        .where(Sequel[:presort_staging_run_children][:active] => true, presort_unit_plant_resource_id: plant_resource_id)
        .first
        .nil?
    end
  end
end
