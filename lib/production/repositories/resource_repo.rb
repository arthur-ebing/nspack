# frozen_string_literal: true

module ProductionApp
  class ResourceRepo < BaseRepo # rubocop:disable Metrics/ClassLength
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

    def create_child_plant_resource(parent_id, res)
      sys_id = create_twin_system_resource(parent_id, res)
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

    def system_resource_type_id_from_code(system_resource_type)
      DB[:system_resource_types].where(system_resource_type_code: system_resource_type).get(:id)
    end

    def plant_resource_definition(id)
      plant_resource_type = find_plant_resource_type(id).plant_resource_type_code
      Crossbeams::Config::ResourceDefinitions::PLANT_RESOURCE_RULES[plant_resource_type]
    end

    def create_plant_resource(attrs)
      new_attrs = attrs.to_h
      new_attrs[:plant_resource_attributes] = hash_for_jsonb_col(attrs[:plant_resource_attributes]) if attrs.to_h[:plant_resource_attributes]
      create(:plant_resources, new_attrs)
    end

    def delete_plant_resource(id)
      DB[:tree_plant_resources].where(ancestor_plant_resource_id: id).or(descendant_plant_resource_id: id).delete
      system_resource_id = find_plant_resource(id)&.system_resource_id
      DB[:plant_resources].where(id: id).delete
      DB[:system_resources].where(id: system_resource_id).delete if system_resource_id
    end

    def plant_resource_type_code_for(plant_resource_id)
      DB[:plant_resources].join(:plant_resource_types, id: :plant_resource_type_id).where(Sequel[:plant_resources][:id] => plant_resource_id).get(:plant_resource_type_code)
    end

    def next_peripheral_code(plant_resource_type_id)
      rules = plant_resource_definition(plant_resource_type_id)
      return '' unless rules[:non_editable_code]

      system_resource_type = rules[:create_with_system_resource]
      raise Crossbeams::FrameworkError, 'Plant peripheral resource type must link to system peripheral type' unless system_resource_type

      resolve_system_code(nil, rules[:code_prefix], plant_resource_type_id)
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

    private

    def create_twin_system_resource(parent_id, res)
      rules = plant_resource_definition(res[:plant_resource_type_id])
      system_resource_type = rules[:create_with_system_resource]
      return unless system_resource_type

      system_rules = Crossbeams::Config::ResourceDefinitions::SYSTEM_RESOURCE_RULES[system_resource_type]
      system_resource_type_id = system_resource_type_id_from_code(system_resource_type)
      code = resolve_system_code(parent_id, rules[:code_prefix], res[:plant_resource_type_id])
      attrs = { system_resource_type_id: system_resource_type_id,
                plant_resource_type_id: res[:plant_resource_type_id],
                system_resource_code: code,
                description: "#{system_rules[:description]}: #{code}" }
      create_system_resource(attrs)
    end

    def resolve_system_code(parent_id, rule, plant_resource_type_id)
      return system_code_via_parent(parent_id, rule) if rule.include?('${CODE}')

      # CLM- ..what about gaps? CLM-02, CLM-03, CLM-07 --> next should be CLM-04...
      max = DB[:system_resources].where(plant_resource_type_id: plant_resource_type_id).max(:system_resource_code)
      if max
        max.succ
      else
        "#{rule}01"
      end
    end

    def system_code_via_parent(parent_id, rule)
      plant = find_plant_resource(parent_id)
      sys = find_system_resource(plant.system_resource_id)
      base = rule.sub('${CODE}', sys.system_resource_code)
      max = DB[:system_resources].where(Sequel.like(:system_resource_code, "#{base}%")).max(:system_resource_code)
      if max
        max.succ
      else
        "#{base}01"
      end
    end
  end
end
