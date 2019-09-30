# frozen_string_literal: true

module MasterfilesApp
  class PortTypeRepo < BaseRepo
    build_for_select :port_types,
                     label: :port_type_code,
                     value: :id,
                     order_by: :port_type_code
    build_inactive_select :port_types,
                          label: :port_type_code,
                          value: :id,
                          order_by: :port_type_code

    crud_calls_for :port_types, name: :port_type, wrapper: PortType
  end
end
