# frozen_string_literal: true

module MasterfilesApp
  class MrlRequirementRepo < BaseRepo
    build_for_select :mrl_requirements,
                     label: :id,
                     value: :id,
                     order_by: :id
    build_inactive_select :mrl_requirements,
                          label: :id,
                          value: :id,
                          order_by: :id

    crud_calls_for :mrl_requirements, name: :mrl_requirement, wrapper: MrlRequirement
  end
end
