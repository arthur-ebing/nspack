# frozen_string_literal: true

module ProductionApp
  class ProductSetupRepo < BaseRepo # rubocop:disable ClassLength
    build_for_select :product_setup_templates,
                     label: :template_name,
                     value: :id,
                     order_by: :template_name
    build_inactive_select :product_setup_templates,
                          label: :template_name,
                          value: :id,
                          order_by: :template_name

    build_for_select :product_setups,
                     label: :client_size_reference,
                     value: :id,
                     order_by: :client_size_reference
    build_inactive_select :product_setups,
                          label: :client_size_reference,
                          value: :id,
                          order_by: :client_size_reference

    crud_calls_for :product_setup_templates, name: :product_setup_template, wrapper: ProductSetupTemplate
    crud_calls_for :product_setups, name: :product_setup, wrapper: ProductSetup

    def find_product_setup_template(id)
      hash = DB['SELECT product_setup_templates.* , cultivar_groups.cultivar_group_code, cultivars.cultivar_name,
                 plant_resources.plant_resource_code AS packhouse_resource_code, plant_resources1.plant_resource_code AS production_line_resource_code,
                 season_groups.season_group_code, seasons.season_code
                 FROM product_setup_templates
                 JOIN cultivar_groups ON cultivar_groups.id = product_setup_templates.cultivar_group_id
                 LEFT JOIN cultivars ON cultivars.id = product_setup_templates.cultivar_id
                 LEFT JOIN plant_resources ON plant_resources.id = product_setup_templates.packhouse_resource_id
                 LEFT JOIN plant_resources plant_resources1 ON plant_resources1.id = product_setup_templates.production_line_resource_id
                 LEFT JOIN season_groups ON season_groups.id = product_setup_templates.season_group_id
                 LEFT JOIN seasons ON seasons.id = product_setup_templates.season_id
                 WHERE product_setup_templates.id = ?', id].first

      # hash = find_with_association(:product_setup_templates,
      #                              id,
      #                              parent_tables: [{ parent_table: :cultivar_groups,
      #                                                columns: [:cultivar_group_code],
      #                                                flatten_columns: { cultivar_group_code: :cultivar_group_code } },
      #                                              { parent_table: :cultivars,
      #                                                columns: [:cultivar_name],
      #                                                flatten_columns: { cultivar_name: :cultivar_name } },
      #                                              { parent_table: :plant_resources,
      #                                                columns: [:plant_resource_code],
      #                                                foreign_key: :packhouse_resource_id,
      #                                                flatten_columns: { plant_resource_code: :packhouse_resource_code } },
      #                                              { parent_table: :plant_resources,
      #                                                columns: [:plant_resource_code],
      #                                                foreign_key: :production_line_resource_id,
      #                                                flatten_columns: { plant_resource_code: :production_line_resource_code } },
      #                                              { parent_table: :season_groups,
      #                                                columns: [:season_group_code],
      #                                                flatten_columns: { season_group_code: :season_group_code } },
      #                                              { parent_table: :seasons,
      #                                                columns: [:season_code],
      #                                                flatten_columns: { season_code: :season_code } }])
      return nil if hash.nil?

      ProductSetupTemplate.new(hash)
    end

    def find_product_setup(id)
      hash = DB['SELECT product_setups.* , fn_party_role_name(?) AS product_setup_code, fn_product_setup_in_production(?) AS in_production
                 FROM product_setups WHERE product_setups.id = ?', id].first
      return nil if hash.nil?

      ProductSetup.new(hash)
    end

    def update_product_setup_template(id, attrs)
      update(:product_setup_templates, id, attrs)
      DB.execute(<<~SQL)
        UPDATE product_setups set active = #{attrs[:active]}
        WHERE product_setup_template_id = #{id};
      SQL
    end

    def for_select_plant_resources(plant_resource_type_code)
      DB[:plant_resources]
        .join(:plant_resource_types, id: :plant_resource_type_id)
        .where(plant_resource_type_code: plant_resource_type_code)
        .select(
          Sequel[:plant_resources][:id],
          :plant_resource_code
        ).map { |r| [r[:plant_resource_code], r[:id]] }
    end

    def for_select_packhouse_lines(packhouse_id)
      DB[:plant_resources]
        .join(:tree_plant_resources, descendant_plant_resource_id: :id)
        .where(ancestor_plant_resource_id: packhouse_id)
        .where { path_length.positive? }
        .select(
          :id,
          :plant_resource_code
        ).map { |r| [r[:plant_resource_code], r[:id]] }
    end

    def for_select_template_cultivar_commodities(cultivar_group_id)  # rubocop:disable Metrics/AbcSize
      DB[:commodities]
        .join(:cultivars, commodity_id: :id)
        .join(:cultivar_groups, id: :cultivar_group_id)
        .left_join(:product_setup_templates, cultivar_id: :id)
        .where(Sequel[:cultivars][:cultivar_group_id] => cultivar_group_id)
        .distinct(Sequel[:commodities][:id])
        .select(
          Sequel[:commodities][:id],
          Sequel[:commodities][:code]
        ).map { |r| [r[:code], r[:id]] }
    end

    def for_select_template_cultivar_marketing_varieties(cultivar_group_id)  # rubocop:disable Metrics/AbcSize
      DB[:marketing_varieties]
        .join(:marketing_varieties_for_cultivars, marketing_variety_id: :id)
        .join(:cultivars, id: :cultivar_id)
        .join(:cultivar_groups, id: :cultivar_group_id)
        .left_join(:product_setup_templates, cultivar_id: :id)
        .where(Sequel[:product_setup_templates][:cultivar_group_id] => cultivar_group_id)
        .distinct(Sequel[:marketing_varieties][:id])
        .select(
          Sequel[:marketing_varieties][:id],
          Sequel[:marketing_varieties][:marketing_variety_code]
        ).map { |r| [r[:marketing_variety_code], r[:id]] }
    end

    def for_select_template_commodity_marketing_varieties(product_setup_template_id, commodity_id)  # rubocop:disable Metrics/AbcSize
      DB[:marketing_varieties]
        .join(:marketing_varieties_for_cultivars, marketing_variety_id: :id)
        .join(:cultivars, id: :cultivar_id)
        .join(:cultivar_groups, id: :cultivar_group_id)
        .join(:product_setup_templates, cultivar_group_id: :id)
        .where(Sequel[:product_setup_templates][:id] => product_setup_template_id)
        .where(Sequel[:cultivars][:commodity_id] => commodity_id)
        .distinct(Sequel[:marketing_varieties][:id])
        .select(
          Sequel[:marketing_varieties][:id],
          Sequel[:marketing_varieties][:marketing_variety_code]
        ).map { |r| [r[:marketing_variety_code], r[:id]] }
    end

    def find_treatment_codes(id)
      query = <<~SQL
        SELECT treatments.treatment_code
        FROM product_setups
        JOIN treatments ON treatments.id = ANY (product_setups.treatment_ids)
        WHERE product_setups.id = #{id}
      SQL
      DB[query].order(:treatment_code).select_map(:treatment_code)
    end
  end
end
