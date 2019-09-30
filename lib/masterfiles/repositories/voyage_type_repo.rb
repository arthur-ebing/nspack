# frozen_string_literal: true

module MasterfilesApp
  class VoyageTypeRepo < BaseRepo
    build_for_select :voyage_types,
                     label: :voyage_type_code,
                     value: :id,
                     order_by: :voyage_type_code
    build_inactive_select :voyage_types,
                          label: :voyage_type_code,
                          value: :id,
                          order_by: :voyage_type_code

    crud_calls_for :voyage_types, name: :voyage_type, wrapper: VoyageType
  end
end
