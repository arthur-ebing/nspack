# frozen_string_literal: true

module Crossbeams
  module Config
    # Store rules for displaying header information for a record from a table.
    #
    # The Hash key is the table name as a Symbol.
    # query: is the query to run with a '?' placehoder for the id value.
    # headers: is a hash of column_name to String values for overriding the column name.
    # caption: is an optional caption for the record.
    class StatusHeaderDefinitions
      HEADER_DEF = {
        labels: {
          query: 'SELECT label_name, created_by FROM labels WHERE id = ?'
        },
        production_runs: {
          query: <<~SQL
            SELECT fn_production_run_code("production_runs"."id") AS production_run_code,
            "cultivar_groups"."cultivar_group_code" AS cultivar_group,
            "cultivars"."cultivar_name" AS cultivar, "farms"."farm_code" AS farm, "orchards"."orchard_code" AS orchard,
            "plant_resources"."plant_resource_code" AS packhouse, "plant_resources2"."plant_resource_code" AS line,
            "product_setup_templates"."template_name", "pucs"."puc_code" AS puc, "seasons"."season_code" AS season
            FROM production_runs
            LEFT JOIN "cultivar_groups" ON "cultivar_groups"."id" = "production_runs"."cultivar_group_id"
            LEFT JOIN "cultivars" ON "cultivars"."id" = "production_runs"."cultivar_id"
            JOIN "farms" ON "farms"."id" = "production_runs"."farm_id"
            LEFT JOIN "orchards" ON "orchards"."id" = "production_runs"."orchard_id"
            JOIN "plant_resources" ON "plant_resources"."id" = "production_runs"."packhouse_resource_id"
            LEFT JOIN "product_setup_templates" ON "product_setup_templates"."id" = "production_runs"."product_setup_template_id"
            JOIN "plant_resources" plant_resources2 ON "plant_resources2"."id" = "production_runs"."production_line_id"
            JOIN "pucs" ON "pucs"."id" = "production_runs"."puc_id"
            JOIN "seasons" ON "seasons"."id" = "production_runs"."season_id"
            WHERE production_runs.id = ?
          SQL
        },
        security_groups: {
          query: 'SELECT security_group_name FROM security_groups WHERE id = ?'
        }
      }.freeze
    end
  end
end
