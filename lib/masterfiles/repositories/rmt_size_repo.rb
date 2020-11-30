# frozen_string_literal: true

module MasterfilesApp
  class RmtSizeRepo < BaseRepo
    build_for_select :rmt_sizes,
                     label: :size_code,
                     value: :id,
                     no_active_check: true,
                     order_by: :size_code

    crud_calls_for :rmt_sizes, name: :rmt_size, wrapper: RmtSize
  end
end
