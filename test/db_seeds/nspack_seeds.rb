module MiniTestSeeds
  # def db_create_roles
  #   # roles
  #   mar_id = DB[:roles].insert(name: 'MARKETER')
  #   ret_id = DB[:roles].insert(name: 'RETAILER')
  #   @fixed_table_set[:roles] = {marketer: { id: mar_id },
  #                                retailer: { id: ret_id }
  #   }
  # end
  #
  # def db_create_locations
  #   assignment_id = DB[:location_assignments].insert(assignment_code: 'Assignment Code')
  #   storage_type_id = DB[:location_storage_types].insert(storage_type_code: 'Storage')
  #   location_type_id = DB[:location_types].insert(location_type_code: 'RECEIVING BAY', short_code: 'RB')
  #   default_id = DB[:locations].insert(
  #     primary_storage_type_id: storage_type_id,
  #     location_type_id: location_type_id,
  #     primary_assignment_id: assignment_id,
  #     location_description: 'Default Receiving Bay',
  #     location_long_code: 'RECEIVING BAY',
  #     location_short_code: 'RBY',
  #     can_store_stock: true
  #   )
  #   @fixed_table_set[:locations] = {
  #     assignment_id: assignment_id,
  #     storage_type_id: storage_type_id,
  #     type_id: location_type_id,
  #     default_id: default_id
  #   }
  # end
end
