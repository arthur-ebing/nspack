# frozen_string_literal: true

module ProductionApp
  class ResourceRepo < BaseRepo
    build_for_select :plant_resource_types,
                     label: :plant_resource_type_code,
                     value: :id,
                     order_by: :plant_resource_type_code
    build_inactive_select :plant_resource_types,
                          label: :plant_resource_type_code,
                          value: :id,
                          order_by: :plant_resource_type_code
    build_for_select :plant_resources,
                     label: :plant_resource_code,
                     value: :id,
                     order_by: :plant_resource_code
    build_inactive_select :plant_resources,
                          label: :plant_resource_code,
                          value: :id,
                          order_by: :plant_resource_code
    build_for_select :system_resource_types,
                     label: :system_resource_type_code,
                     value: :id,
                     order_by: :system_resource_type_code
    build_inactive_select :system_resource_types,
                          label: :system_resource_type_code,
                          value: :id,
                          order_by: :system_resource_type_code

    crud_calls_for :plant_resource_types, name: :plant_resource_type, wrapper: PlantResourceType
    crud_calls_for :plant_resources, name: :plant_resource, wrapper: PlantResource
    crud_calls_for :system_resource_types, name: :system_resource_type, wrapper: SystemResourceType
    crud_calls_for :system_resources, name: :system_resource, wrapper: SystemResource

    def for_select_plant_resources_of_type(plant_resource_type_code, active: true)
      type = where_hash(:plant_resource_types, plant_resource_type_code: plant_resource_type_code, active: active)
      return [] if type.nil?

      for_select_plant_resources(where: { plant_resource_type_id: type[:id] })
    end

    def get_bin_production_line(bin_asset_number)
      DB[:production_runs]
        .join(:rmt_bins, production_run_rebin_id: :id)
        .where(bin_asset_number: bin_asset_number)
        .get(:production_line_id)
    end

    def for_select_plant_resource_codes(plant_resource_type_code)
      type = where_hash(:plant_resource_types, plant_resource_type_code: plant_resource_type_code, active: true)
      return [] if type.nil?

      opts = DB[:plant_resources]
             .left_join(:system_resources, id: :system_resource_id)
             .where(Sequel[:plant_resources][:plant_resource_type_id] => type[:id])
             .select_map(%i[plant_resource_code system_resource_code])
      opts.map { |o| [o.first, o.last.nil? ? o.first : o.last] }
    end

    def packhouse_lines(packhouse_id, active: true) # rubocop:disable Metrics/AbcSize
      DB[:plant_resources]
        .join(:tree_plant_resources, descendant_plant_resource_id: Sequel[:plant_resources][:id])
        .join(:plant_resource_types, id: Sequel[:plant_resources][:plant_resource_type_id])
        .where(Sequel[:tree_plant_resources][:ancestor_plant_resource_id] => packhouse_id)
        .where(Sequel[:plant_resource_types][:plant_resource_type_code] => Crossbeams::Config::ResourceDefinitions::LINE)
        .where(Sequel[:plant_resources][:active] => active)
        .select_map([:plant_resource_code, Sequel[:plant_resources][:id]])
    end

    def for_select_plant_resource_types(plant_resource_type_code)
      possible_codes = if plant_resource_type_code.nil?
                         Crossbeams::Config::ResourceDefinitions::ROOT_PLANT_RESOURCE_TYPES
                       else
                         Crossbeams::Config::ResourceDefinitions::PLANT_RESOURCE_RULES[plant_resource_type_code][:allowed_children]
                       end
      DB[:plant_resource_types].where(plant_resource_type_code: possible_codes).select_map(%i[plant_resource_type_code id])
    end

    def for_select_peripheral_types
      possible_codes = Crossbeams::Config::ResourceDefinitions.peripheral_type_codes
      DB[:plant_resource_types].where(plant_resource_type_code: possible_codes).select_map(%i[plant_resource_type_code id])
    end

    def find_plant_resource_flat(id)
      find_with_association(:plant_resources,
                            id,
                            parent_tables: [{ parent_table: :system_resources,
                                              columns: [:system_resource_code],
                                              flatten_columns: { system_resource_code: :system_resource_code } },
                                            { parent_table: :plant_resource_types,
                                              columns: %i[plant_resource_type_code packpoint],
                                              flatten_columns: { plant_resource_type_code: :plant_resource_type_code,
                                                                 packpoint: :packpoint } },
                                            { parent_table: :plant_resources,
                                              foreign_key: :represents_plant_resource_id,
                                              columns: %i[plant_resource_code],
                                              flatten_columns: { plant_resource_code: :represents_plant_resource_code } },
                                            { parent_table: :locations,
                                              columns: [:location_long_code],
                                              flatten_columns: { location_long_code: :location_long_code } }],
                            wrapper: PlantResourceFlat)
    end

    def find_plant_resource_flat_for_grid(id)
      query = <<~SQL
        SELECT plant_resources.id, plant_resources.plant_resource_type_id,
        plant_resource_types.icon,
        CASE WHEN representing_plant.plant_resource_code IS NULL THEN
          plant_resources.plant_resource_code
        ELSE
          plant_resources.plant_resource_code || ' (' || representing_plant.plant_resource_code || ')'
        END AS plant_resource_code,
        plant_resources.description,
        system_resources.system_resource_code,
        plant_resources.resource_properties ->> 'phc' AS phc,
        plant_resources.resource_properties ->> 'packhouse_no' AS ph_no,
        plant_resources.resource_properties ->> 'gln' AS gln,
        plant_resources.resource_properties ->> 'edi_out_value' AS edi_out_value,
        (SELECT string_agg(system_resource_code, '; ') FROM (SELECT pr.system_resource_code
          FROM plant_resources_system_resources prs
          JOIN system_resources pr ON pr.id = prs.system_resource_id
          WHERE prs.plant_resource_id = plant_resources.id) sub) AS linked_resources,
        plant_resources.active,
        plant_resource_types.plant_resource_type_code,
        plant_resource_types.description AS type_description,
        (SELECT array_agg(cc.plant_resource_code) as path
          FROM (SELECT c.plant_resource_code
                 FROM plant_resources AS c
                JOIN tree_plant_resources AS t1 ON t1.ancestor_plant_resource_id = c.id
               WHERE t1.descendant_plant_resource_id = plant_resources.id
               ORDER BY t1.path_length DESC) AS cc) AS path_array,
        (SELECT MAX(path_length)
           FROM tree_plant_resources
           WHERE descendant_plant_resource_id = plant_resources.id) + 1 AS level,
        plant_resources.system_resource_id,
        system_resource_types.peripheral,
        plant_resource_types.packpoint
        FROM plant_resources
        JOIN plant_resource_types ON plant_resource_types.id = plant_resources.plant_resource_type_id
        LEFT OUTER JOIN system_resources ON system_resources.id = plant_resources.system_resource_id
        LEFT OUTER JOIN system_resource_types ON system_resource_types.id = system_resources.system_resource_type_id
        LEFT OUTER JOIN plant_resources representing_plant ON representing_plant.id = plant_resources.represents_plant_resource_id
        WHERE plant_resources.id = ?
      SQL
      hash = DB[query, id].first
      return nil if hash.nil?

      PlantResourceFlatForGrid.new(hash)
    end

    def find_system_resource_flat(id)
      find_with_association(:system_resources,
                            id,
                            parent_tables: [{ parent_table: :plant_resource_types,
                                              columns: [:plant_resource_type_code],
                                              flatten_columns: { plant_resource_type_code: :plant_resource_type_code } },
                                            { parent_table: :system_resource_types,
                                              columns: [:system_resource_type_code],
                                              flatten_columns: { system_resource_type_code: :system_resource_type_code } }],
                            sub_tables: [{ sub_table: :plant_resources, one_to_one: { plant_resource_code: :plant_resource_code,
                                                                                      id: :plant_resource_id } }],
                            wrapper: SystemResourceFlat)
    end

    def find_mes_server
      type_id = get_id(:plant_resource_types, plant_resource_type_code: Crossbeams::Config::ResourceDefinitions::MES_SERVER)
      id = get_value(:plant_resources, :system_resource_id, plant_resource_type_id: type_id)

      find_system_resource_flat(id)
    end

    def create_plant_resource_type(attrs)
      new_attrs = attrs.to_h
      new_attrs[:attribute_rules] = hash_for_jsonb_col(attrs[:attribute_rules])
      new_attrs[:behaviour_rules] = hash_for_jsonb_col(attrs[:behaviour_rules])
      create(:plant_resource_types, new_attrs)
    end

    def create_root_plant_resource(params)
      id = create_plant_resource(params)
      DB[:tree_plant_resources].insert(ancestor_plant_resource_id: id,
                                       descendant_plant_resource_id: id,
                                       path_length: 0)
      id
    end

    def create_child_plant_resource(parent_id, res, sys_code: nil)
      sys_id = create_twin_system_resource(parent_id, res, sys_code)
      attrs = if sys_id
                res.to_h.merge(system_resource_id: sys_id)
              else
                res
              end
      id = create_plant_resource(attrs)

      DB.execute(<<~SQL)
        INSERT INTO tree_plant_resources (ancestor_plant_resource_id, descendant_plant_resource_id, path_length)
        SELECT t.ancestor_plant_resource_id, #{id}, t.path_length + 1
        FROM tree_plant_resources AS t
        WHERE t.descendant_plant_resource_id = #{parent_id}
        UNION ALL
        SELECT #{id}, #{id}, 0;
      SQL
      id
    end

    def plant_resource_type_code_for(plant_resource_id)
      DB[:plant_resources].join(:plant_resource_types, id: :plant_resource_type_id).where(Sequel[:plant_resources][:id] => plant_resource_id).get(:plant_resource_type_code)
    end

    def plant_resource_type_id_from_code(plant_resource_type_code)
      get_value(:plant_resource_types, :id, plant_resource_type_code: plant_resource_type_code)
    end

    def plant_resource_type_id_for_resource(plant_resource_id)
      DB[:plant_resource_types].where(id: get_value(:plant_resources, :plant_resource_type_id, id: plant_resource_id)).get(:id)
    end

    def system_resource_type_id_from_code(system_resource_type)
      DB[:system_resource_types].where(system_resource_type_code: system_resource_type).get(:id)
    end

    def system_resource_type_from_resource(system_resource_id)
      DB[:system_resource_types].where(id: DB[:system_resources].where(id: system_resource_id).get(:system_resource_type_id)).get(:system_resource_type_code)
    end

    def plant_resource_id_for_system_code(system_code)
      DB[:plant_resources].where(system_resource_id: DB[:system_resources].where(system_resource_code: system_code).get(:id)).get(:id)
    end

    def plant_resource_code_for_system_code(system_code)
      DB[:plant_resources].where(system_resource_id: DB[:system_resources].where(system_resource_code: system_code).get(:id)).get(:plant_resource_code)
    end

    def plant_resource_definition(id)
      plant_resource_type = find_plant_resource_type(id).plant_resource_type_code
      Crossbeams::Config::ResourceDefinitions::PLANT_RESOURCE_RULES[plant_resource_type]
    end

    def plant_resource_type_code_for_system_resource(system_resource_id)
      DB[:plant_resource_types].where(id: DB[:plant_resources].where(system_resource_id: system_resource_id).get(:plant_resource_type_id)).get(:plant_resource_type_code)
    end

    def create_plant_resource(attrs)
      new_attrs = attrs.to_h
      new_attrs[:resource_properties] = hash_for_jsonb_col(attrs[:resource_properties]) if attrs.to_h[:resource_properties]
      create(:plant_resources, new_attrs)
    end

    def update_plant_resource(id, attrs, name_changed = false)
      new_attrs = attrs.to_h
      properties_present = new_attrs.keys.include?(:resource_properties)
      check_or_create_gln_sequence(new_attrs[:resource_properties][:gln]) if properties_present && new_attrs[:resource_properties][:gln]
      new_attrs[:resource_properties] = hash_for_jsonb_col(attrs[:resource_properties]) if properties_present
      update(:plant_resources, id, new_attrs)
      update_button_names(id, attrs) if name_changed
    end

    def update_button_names(plant_resource_id, attrs)
      # has button children?
      ids = select_values(:tree_plant_resources, :descendant_plant_resource_id, ancestor_plant_resource_id: plant_resource_id, path_length: 1)
      ids.each do |id|
        next unless plant_resource_type_code_for(id) == Crossbeams::Config::ResourceDefinitions::ROBOT_BUTTON

        old_code = get_value(:plant_resources, :plant_resource_code, id: id)
        new_code = old_code.sub(/.+(B\d+)$/, "#{attrs[:plant_resource_code]} \\1")
        DB[:plant_resources].where(id: id).update(plant_resource_code: new_code, description: new_code)
      end
    end

    def check_for_duplicate_gln(id, gln)
      return ok_response if gln.empty?

      query = <<~SQL
        SELECT id FROM plant_resources
        WHERE resource_properties ->> 'gln' = ?
        AND id <> ?
      SQL
      rec = DB[query, gln, id].first
      return ok_response if rec.nil?

      failed_response("GLN #{gln} has already been used")
    end

    def delete_plant_resource(id)
      DB[:tree_plant_resources].where(ancestor_plant_resource_id: id).or(descendant_plant_resource_id: id).delete
      system_resource_id = find_plant_resource(id)&.system_resource_id
      DB[:palletizing_bay_states].where(palletizing_bay_resource_id: id).delete
      DB[:plant_resources].where(id: id).delete
      DB[:system_resources].where(id: system_resource_id).delete if system_resource_id
    end

    def enable_disable_plant_resource(id, enable: true)
      DB[:plant_resources].where(id: id).update(active: enable)
      DB[:system_resources].where(id: DB[:plant_resources].where(id: id).get(:system_resource_id)).update(active: enable)
    end

    def next_peripheral_code(plant_resource_type_id)
      rules = plant_resource_definition(plant_resource_type_id)
      return '' unless rules[:non_editable_code]

      system_resource_type = rules[:create_with_system_resource]
      raise Crossbeams::FrameworkError, 'Plant peripheral resource type must link to system peripheral type' unless system_resource_type

      resolve_system_code(nil, rules[:code_prefix], plant_resource_type_id, rules[:sequence_without_zero_padding])
    end

    def link_a_peripheral(plant_resource_id, peripheral_id)
      DB[:plant_resources_system_resources].insert(plant_resource_id: plant_resource_id, system_resource_id: peripheral_id)
    end

    def link_peripherals(plant_resource_id, peripheral_ids)
      existing_ids = existing_system_resource_ids_for_plant_resource(plant_resource_id)
      old_ids = existing_ids - peripheral_ids
      new_ids = peripheral_ids - existing_ids

      DB[:plant_resources_system_resources].where(plant_resource_id: plant_resource_id).where(system_resource_id: old_ids).delete
      new_ids.each do |new_id|
        DB[:plant_resources_system_resources].insert(plant_resource_id: plant_resource_id, system_resource_id: new_id)
      end

      linked_peripheral_codes_for(plant_resource_id)
    end

    def linked_peripheral_codes_for(plant_resource_id)
      DB[:plant_resources_system_resources]
        .join(:system_resources, id: :system_resource_id)
        .where(plant_resource_id: plant_resource_id)
        .select(Sequel[:system_resources][:system_resource_code])
        .map { |r| r[:system_resource_code] }
        .join('; ')
    end

    def existing_system_resource_ids_for_plant_resource(plant_resource_id)
      DB[:plant_resources_system_resources].where(plant_resource_id: plant_resource_id).select_map(:system_resource_id)
    end

    def plant_resource_level(id)
      DB[:tree_plant_resources].where(descendant_plant_resource_id: id).max(:path_length)
    end

    # Given a device name (system resource code), return a list
    # of printer codes linked to it.
    def linked_printer_for_device(system_resource_code)
      plant_resource_id = plant_resource_id_for_system_code(system_resource_code)
      system_resource_ids = existing_system_resource_ids_for_plant_resource(plant_resource_id)

      query = <<~SQL
        SELECT s.id, s.system_resource_code
        FROM plant_resources p
        JOIN system_resources s ON s.id = p.system_resource_id
        JOIN plant_resource_types t ON t.id = p.plant_resource_type_id
        WHERE p.system_resource_id IN ?
          AND t.plant_resource_type_code = 'PRINTER'
      SQL
      DB[query, system_resource_ids].all
    end

    # Given a system resource, find its parent of a particular plant type.
    def plant_resource_parent_of_system_resource(plant_resource_type, system_resource_code)
      query = <<~SQL
        SELECT p.id
        FROM system_resources sys
        JOIN plant_resources bintip ON bintip.system_resource_id = sys.id
        JOIN tree_plant_resources t ON t.descendant_plant_resource_id = bintip.id
        JOIN plant_resources p ON p.id = t.ancestor_plant_resource_id AND p.plant_resource_type_id = (SELECT id from plant_resource_types WHERE plant_resource_type_code = ?)
        WHERE sys.system_resource_code = ?
      SQL
      id = DB[query, plant_resource_type, system_resource_code].get(:id)
      return failed_response(%(No "#{plant_resource_type}" found for system resource "#{system_resource_code}")) if id.nil?

      success_response('ok', id)
    end

    # List the target nodes a plant resource can be moved to.
    def move_targets_for(plant_resource_id)
      type = plant_resource_type_code_for(plant_resource_id)
      allowed_types = Crossbeams::Config::ResourceDefinitions.allowed_parent_types(type)
      type_ids = select_values(:plant_resource_types, :id, plant_resource_type_code: allowed_types)
      parent_id = DB[:tree_plant_resources].where(descendant_plant_resource_id: plant_resource_id, path_length: 1).get(:ancestor_plant_resource_id)
      DB[:plant_resources].where(plant_resource_type_id: type_ids).exclude(id: parent_id).select_map { %i[plant_resource_code id] }
    end

    def system_servers
      query = <<~SQL
        SELECT s.system_resource_code as name,
        s.equipment_type as module_type,
        s.module_function as function, -- Could add to resource_types
        p.plant_resource_code as alias,
        s.ip_address as network_interface,
        s.port as port,
        s.mac_address as mac_address,
        s.ttl as ttl,
        -- s.cycle_time as cycle_time,
        s.publishing as publishing, -- true/false..
        (SELECT string_agg("equipment_type", ',')
        FROM (SELECT DISTINCT "sr"."equipment_type"
        FROM "plant_resources_system_resources" prs
        JOIN "system_resources" sr ON "sr"."id" = "prs"."system_resource_id"
        WHERE sr.plant_resource_type_id = (SELECT id FROM plant_resource_types WHERE plant_resource_type_code = 'PRINTER')) sub) AS printer_types,

        s.id, s.plant_resource_type_id, s.system_resource_type_id,
               s.description, s.active,
               t.system_resource_type_code, t.peripheral,
               e.plant_resource_type_code
        FROM public.system_resources s
        JOIN system_resource_types t ON t.id = s.system_resource_type_id
        LEFT OUTER JOIN plant_resource_types e ON e.id = s.plant_resource_type_id
        LEFT OUTER JOIN plant_resources p ON p.system_resource_id = s.id
        WHERE t.system_resource_type_code = 'SERVER'
          AND s.active
        ORDER BY s.system_resource_code
      SQL
      DB[query].all
    end

    def system_modules
      query = <<~SQL
        SELECT (SELECT c.plant_resource_code
                FROM plant_resources c
                JOIN tree_plant_resources t1 ON t1.ancestor_plant_resource_id = c.id
                WHERE t1.descendant_plant_resource_id = p.id
                  AND c.plant_resource_type_id = (SELECT id FROM plant_resource_types WHERE plant_resource_type_code = 'PACKHOUSE')
                ) AS packhouse,
        s.system_resource_code as name,
        s.equipment_type as module_type,
        s.module_function as function, -- Could add to resource_types
        p.plant_resource_code as alias,
        s.ip_address as network_interface,
        s.port as port,
        s.mac_address as mac_address,
        s.ttl as ttl,
        s.cycle_time as cycle_time,
        s.publishing as publishing, -- true/false..
        s.login as login,
        s.logoff as logoff,
        s.module_action,
        'TODO: URL' as url,
        'TODO: Par1' as par1,
        'TODO: Par2' as par2,
        'TODO: Par3' as par3,
        'TODO: Par4' as par4,
        'TODO: Par5' as par5,
        'TODO: ReaderID' as readerid,
        'TODO: ContainerType' as container_type,
        'TODO: WeightUnits' as weight_units,
        (SELECT string_agg("system_resource_code", ',')
        FROM (SELECT "pr"."system_resource_code"
        FROM "plant_resources_system_resources" prs
        JOIN "system_resources" pr ON "pr"."id" = "prs"."system_resource_id"
        WHERE "prs"."plant_resource_id" = p.id
          AND pr.plant_resource_type_id = (SELECT id FROM plant_resource_types WHERE plant_resource_type_code = 'PRINTER')) sub) AS printer,
        (SELECT string_agg("equipment_type", ',')
        FROM (SELECT DISTINCT "sr"."equipment_type"
        FROM "plant_resources_system_resources" prs
        JOIN "system_resources" sr ON "sr"."id" = "prs"."system_resource_id"
        WHERE "prs"."plant_resource_id" = p.id
          AND sr.plant_resource_type_id = (SELECT id FROM plant_resource_types WHERE plant_resource_type_code = 'PRINTER')) sub) AS printer_types,

        s.id, s.plant_resource_type_id, s.system_resource_type_id,
               s.description, s.active,
               t.system_resource_type_code, t.peripheral,
               e.plant_resource_type_code
        FROM public.system_resources s
        JOIN system_resource_types t ON t.id = s.system_resource_type_id
        LEFT OUTER JOIN plant_resource_types e ON e.id = s.plant_resource_type_id
        LEFT OUTER JOIN plant_resources p ON p.system_resource_id = s.id
        WHERE t.system_resource_type_code = 'MODULE'
          AND s.active
        ORDER BY 1, s.system_resource_code
      SQL
      # DB[query].to_hash_groups(:packhouse)
      DB[query].all.group_by { |rec| rec[:packhouse] }
    end

    def usb_printer_ip(sys_peripheral_id)
      DB[:plant_resources_system_resources]
        .join(:plant_resources, id: :plant_resource_id)
        .join(:system_resources, id: Sequel[:plant_resources][:system_resource_id])
        .where(Sequel[:plant_resources_system_resources][:system_resource_id] => sys_peripheral_id)
        .get(:ip_address)
    end

    def system_peripheral_printers
      query = <<~SQL
        SELECT (SELECT c.plant_resource_code
                FROM plant_resources c
                JOIN tree_plant_resources t1 ON t1.ancestor_plant_resource_id = c.id
                WHERE t1.descendant_plant_resource_id = p.id
                  AND c.plant_resource_type_id = (SELECT id FROM plant_resource_types WHERE plant_resource_type_code = 'PACKHOUSE')
                ) AS packhouse,
        s.system_resource_code as name,
        s.module_function as function,
        p.plant_resource_code as alias,
        s.equipment_type as type,
        s.peripheral_model as model,
        s.connection_type AS connection_type,
        s.ip_address as network_interface,
        s.port as port,
        s.ttl as ttl,
        s.cycle_time as cycle_time,
        s.printer_language as language,
        s.print_username as username,
        s.print_password as password,
        s.pixels_mm as pixels_mm
        ,
         s.id, s.plant_resource_type_id, s.system_resource_type_id,
               s.description, s.active,
               t.system_resource_type_code, t.peripheral,
               e.plant_resource_type_code
          FROM public.system_resources s
          JOIN system_resource_types t ON t.id = s.system_resource_type_id
          LEFT OUTER JOIN plant_resource_types e ON e.id = s.plant_resource_type_id
          LEFT OUTER JOIN plant_resources p ON p.system_resource_id = s.id
        WHERE t.system_resource_type_code = 'PERIPHERAL'
          AND e.plant_resource_type_code = 'PRINTER'
          AND s.active
        ORDER BY 1, s.system_resource_code
      SQL
      DB[query].all.group_by { |rec| rec[:packhouse] }
    end

    def no_of_direct_descendants(plant_resource_id)
      DB[:tree_plant_resources].where(ancestor_plant_resource_id: plant_resource_id, path_length: 1).count
    end

    def max_plant_resource_code_for_type(plant_resource_type_id)
      DB[:plant_resources].where(plant_resource_type_id: plant_resource_type_id).max(:plant_resource_code)
    end

    def max_sys_resource_code_for_plant_type(plant_resource_type_code)
      type_id = plant_resource_type_id_from_code(plant_resource_type_code)
      DB[:system_resources].where(plant_resource_type_id: type_id).max(:system_resource_code)
    end

    def find_robot_by_mac_addr(mac_addr)
      query = <<~SQL
        SELECT system_resources.id,
          plant_resources.plant_resource_code,
          plant_resources.description,
          --system_resources.plant_resource_type_id,
          --system_resources.system_resource_type_id,
          system_resources.system_resource_code,
          system_resources.description AS system_resource_description,
          system_resources.active,
          system_resources.equipment_type,
          system_resources.module_function,
          system_resources.mac_address,
          -- system_resources.ip_address,
          -- system_resources.port,
          -- system_resources.ttl,
          -- system_resources.cycle_time,
          -- system_resources.publishing,
          -- system_resources.login,
          -- system_resources.logoff,
          system_resources.module_action,
          -- system_resources.peripheral_model,
          -- system_resources.connection_type,
          -- system_resources.printer_language,
          -- system_resources.print_username,
          -- system_resources.print_password,
          -- system_resources.pixels_mm,
          system_resources.robot_function,
          COALESCE(mes_modules.bulk_registration_mode, false) AS bulk_registration_mode
        FROM system_resources
        JOIN plant_resources ON plant_resources.system_resource_id = system_resources.id
        LEFT JOIN mes_modules ON mes_modules.module_code = system_resources.system_resource_code
        WHERE system_resources.mac_address = ?
      SQL
      hash = DB[query, mac_addr].first
      return nil if hash.nil?

      Robot.new(hash)
    end

    def system_resource_incentive_settings(device, packpoint, button, card_reader)
      hash = DB[:system_resources]
             .select(:id, :system_resource_code, :login, :logoff, :group_incentive)
             .where(system_resource_code: device)
             .first
      return nil if hash.nil?

      button_system_resource_id = get_id(:system_resources, system_resource_code: button)
      cache_key = if button_system_resource_id && !button_points_to_packpoint?(button_system_resource_id)
                    button
                  else
                    packpoint
                  end
      SystemResourceIncentiveSettings.new(hash.merge(packpoint: packpoint, cache_key: cache_key, card_reader: card_reader || '1'))
    end

    def active_group_incentive_id_for(system_resource_id)
      DB[:group_incentives].where(system_resource_id: system_resource_id, active: true).get(:id)
    end

    def active_individual_incentive_id_for(system_resource_id)
      DB[:system_resource_logins].where(system_resource_id: system_resource_id, active: true).get(:id)
    end

    def packpoint_for_button(system_resource_code)
      system_resource_id = get_id(:system_resources, system_resource_code: system_resource_code)
      return nil if system_resource_id.nil?

      plant_resource_code, represented_id = get_value(:plant_resources, %i[plant_resource_code represents_plant_resource_id], system_resource_id: system_resource_id)
      return plant_resource_code if represented_id.nil?

      get(:plant_resources, :plant_resource_code, represented_id)
    end

    def robot_buttons(robot_id) # rubocop:disable Metrics/AbcSize
      return [] if robot_id.nil?

      DB[:plant_resources]
        .join(:tree_plant_resources, descendant_plant_resource_id: Sequel[:plant_resources][:id])
        .join(:plant_resource_types, id: Sequel[:plant_resources][:plant_resource_type_id])
        .where(Sequel[:tree_plant_resources][:ancestor_plant_resource_id] => robot_id)
        .where(Sequel[:plant_resource_types][:plant_resource_type_code] => Crossbeams::Config::ResourceDefinitions::ROBOT_BUTTON)
        .select_map(Sequel[:plant_resources][:id])
    end

    # All buttons of a robot plant resource
    # - SystemResources
    # - Order by button code
    #
    # @param robot_id [integer] the robot's plant resource id
    # @return [array of SystemResource] - buttons in system_resource_code order
    def robot_button_system_resources(robot_id)
      plant_ids = robot_buttons(robot_id)
      sys_ids = select_values(:plant_resources, :system_resource_id, id: plant_ids)
      all(:system_resources, SystemResource, id: sys_ids).sort_by(&:system_resource_code)
    end

    def update_bin_filler_role(plant_resource_id, label_to_print)
      attrs = resolve_resource_carton_equals_pallet(label_to_print)
      bin_filler = plant_resource_type_is_bin_filler?(plant_resource_id)
      bin_filler ? update_bin_filler_robot_button_roles(plant_resource_id, attrs) : update_plant_resource(plant_resource_id, attrs)

      success_response("Applied #{label_to_print}", label_to_print: label_to_print)
    end

    def for_select_robots_for_rmd(rmd_id)
      query = <<~SQL
        SELECT CONCAT_WS(' - ', sr.system_resource_code, CASE pbs.scanner_code when '1' THEN 'Left' WHEN '2' THEN 'Right' ELSE null END) AS key_name,
          sr.id::text || '_' || coalesce(pbs.scanner_code, '1') AS id
        FROM plant_resources pr
        JOIN system_resources sr ON sr.id = pr.system_resource_id
        LEFT JOIN palletizing_bay_states pbs ON pbs.palletizing_robot_code = sr.system_resource_code
        WHERE pr.resource_properties ->> 'rmd_mode' = 't'
        AND NOT EXISTS(SELECT id FROM registered_mobile_devices
                WHERE act_as_system_resource_id = sr.id
                  AND act_as_reader_id = COALESCE(pbs.scanner_code, '1')
                  AND id <> ?)
        ORDER BY sr.system_resource_code, coalesce(pbs.scanner_code, '1')
      SQL
      DB[query, rmd_id].select_map(%i[key_name id])
    end

    def remove_rmd_mode(plant_resource_id)
      sysres_id = DB[:plant_resources].where(id: plant_resource_id).get(:system_resource_id)
      DB[:registered_mobile_devices].where(act_as_system_resource_id: sysres_id).update(act_as_system_resource_id: nil, act_as_reader_id: nil)
    end

    def device_code_from_ip_address(ip_address)
      DB[:system_resources].where(ip_address: ip_address).get(:system_resource_code)
    end

    def device_handled_by_rmd?(device)
      prop = DB[:plant_resources].where(system_resource_id: DB[:system_resources].where(system_resource_code: device).get(:id)).get(:resource_properties)
      prop && prop['rmd_mode'] == 't'
    end

    def rmd_device_settings_for_ip(ip_address)
      system_resource_id, reader_id = get_value(:registered_mobile_devices, %i[act_as_system_resource_id act_as_reader_id], ip_address: ip_address)
      return failed_response("This device (ip #{ip_address}) is not acting as a robot device") if system_resource_id.nil?

      device = get_value(:system_resources, :system_resource_code, id: system_resource_id)
      instance = OpenStruct.new(device: device, reader_id: reader_id)
      success_response('ok', instance)
    end

    private

    def button_points_to_packpoint?(button_system_resource_id)
      represented_id = get_value(:plant_resources, :represents_plant_resource_id, system_resource_id: button_system_resource_id)
      !represented_id.nil?
    end

    def create_twin_system_resource(parent_id, res, sys_code)
      rules = plant_resource_definition(res[:plant_resource_type_id])
      system_resource_type = rules[:create_with_system_resource]
      return unless system_resource_type

      system_rules = Crossbeams::Config::ResourceDefinitions::SYSTEM_RESOURCE_RULES[system_resource_type]
      system_resource_type_id = system_resource_type_id_from_code(system_resource_type)
      code = sys_code || resolve_system_code(parent_id, rules[:code_prefix], res[:plant_resource_type_id], rules[:sequence_without_zero_padding])
      attrs = { system_resource_type_id: system_resource_type_id,
                plant_resource_type_id: res[:plant_resource_type_id],
                system_resource_code: code,
                description: "#{system_rules[:description]}: #{code}" }
      create_system_resource(attrs)
    end

    def resolve_system_code(parent_id, rule, plant_resource_type_id, without_padding)
      return system_code_via_parent(parent_id, rule, without_padding) if rule.include?('${CODE}')

      # CLM- ..what about gaps? CLM-02, CLM-03, CLM-07 --> next should be CLM-04...
      max = DB[:system_resources].where(plant_resource_type_id: plant_resource_type_id).max(:system_resource_code)
      if max
        max.succ
      elsif without_padding
        "#{rule}1"
      else
        "#{rule}01"
      end
    end

    def system_code_via_parent(parent_id, rule, without_padding)
      plant = find_plant_resource(parent_id)
      sys = find_system_resource(plant.system_resource_id)
      base = rule.sub('${CODE}', sys.system_resource_code)
      max = DB[:system_resources].where(Sequel.like(:system_resource_code, "#{base}%")).max(:system_resource_code)
      if max
        max.succ
      elsif without_padding
        "#{base}1"
      else
        "#{base}01"
      end
    end

    def check_or_create_gln_sequence(gln)
      return if gln.nil? || gln.empty?

      seq_name = "gln_seq_for_#{gln}"
      query = "SELECT EXISTS(SELECT 0 FROM pg_class where relname = '#{seq_name}')"
      return if DB[query].single_value

      DB.run("CREATE SEQUENCE #{seq_name}")
    end

    def resolve_resource_carton_equals_pallet(label_to_print)
      opts = { 'Carton' => 'f', 'Pallet' => 't' }
      { resource_properties: { carton_equals_pallet: opts[label_to_print] } }
    end

    def plant_resource_type_is_bin_filler?(plant_resource_id)
      type_code = plant_resource_type_code_for(plant_resource_id)
      type_code == Crossbeams::Config::ResourceDefinitions::BIN_FILLER_ROBOT
    end

    def update_bin_filler_robot_button_roles(robot_id, attrs)
      robot_buttons(robot_id).each do |id|
        update_plant_resource(id, attrs)
      end
    end
  end
end
