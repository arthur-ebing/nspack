# frozen_string_literal: true

module MasterfilesApp
  class ChemicalRepo < BaseRepo
    build_for_select :chemicals,
                     label: :chemical_name,
                     value: :id,
                     order_by: :chemical_name
    build_inactive_select :chemicals,
                          label: :chemical_name,
                          value: :id,
                          order_by: :chemical_name

    crud_calls_for :chemicals, name: :chemical, wrapper: Chemical
  end
end
