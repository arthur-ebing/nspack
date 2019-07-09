# frozen_string_literal: true

module ProductionApp
  class ResourceRepo < BaseRepo
    build_for_select :resource_types,
                     label: :resource_type_code,
                     value: :id,
                     order_by: :resource_type_code
    build_inactive_select :resource_types,
                          label: :resource_type_code,
                          value: :id,
                          order_by: :resource_type_code
    build_for_select :resources,
                     label: :resource_code,
                     value: :id,
                     order_by: :resource_code
    build_inactive_select :resources,
                          label: :resource_code,
                          value: :id,
                          order_by: :resource_code

    crud_calls_for :resource_types, name: :resource_type, wrapper: ResourceType
    crud_calls_for :resources, name: :resource, wrapper: Resource

    def for_select_resource_types(resource_type_code)
      possible_codes = if resource_type_code.nil?
                         Crossbeams::Config::ResourceDefinitions::ROOT_PLANT_RESOURCE_TYPES
                       else
                         Crossbeams::Config::ResourceDefinitions::PLANT_RESOURCE_RULES[resource_type_code][:allowed_children]
                       end
      DB[:resource_types].where(resource_type_code: possible_codes).select_map(%i[resource_type_code id])
    end

    def create_resource_type(attrs)
      new_attrs = attrs.to_h
      new_attrs[:attribute_rules] = hash_for_jsonb_col(attrs[:attribute_rules])
      new_attrs[:behaviour_rules] = hash_for_jsonb_col(attrs[:behaviour_rules])
      create(:resource_types, new_attrs)
    end

    def create_root_resource(params)
      id = create_resource(params)
      DB[:tree_resources].insert(ancestor_resource_id: id,
                                 descendant_resource_id: id,
                                 path_length: 0)
      id
    end

    def create_child_resource(parent_id, res)
      id = create_resource(res)
      DB.execute(<<~SQL)
        INSERT INTO tree_resources (ancestor_resource_id, descendant_resource_id, path_length)
        SELECT t.ancestor_resource_id, #{id}, t.path_length + 1
        FROM tree_resources AS t
        WHERE t.descendant_resource_id = #{parent_id}
        UNION ALL
        SELECT #{id}, #{id}, 0;
      SQL
      id
    end

    def create_resource(attrs)
      new_attrs = attrs.to_h
      new_attrs[:resource_attributes] = hash_for_jsonb_col(attrs[:resource_attributes]) if attrs.to_h[:resource_attributes]
      create(:resources, new_attrs)
    end

    def delete_resource(id)
      DB[:tree_resources].where(ancestor_resource_id: id).or(descendant_resource_id: id).delete
      DB[:resources].where(id: id).delete
    end

    def resource_type_code_for(resource_id)
      DB[:resources].join(:resource_types, id: :resource_type_id).where(Sequel[:resources][:id] => resource_id).get(:resource_type_code)
    end
  end
end
