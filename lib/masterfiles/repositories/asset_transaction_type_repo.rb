# frozen_string_literal: true

module MasterfilesApp
  class AssetTransactionTypeRepo < BaseRepo
    build_for_select :asset_transaction_types,
                     label: :transaction_type_code,
                     value: :id,
                     no_active_check: true,
                     order_by: :transaction_type_code

    crud_calls_for :asset_transaction_types, name: :asset_transaction_type, wrapper: AssetTransactionType

    def find_asset_transaction_type(id)
      find_with_association(:asset_transaction_types, id,
                            lookup_functions: [{ function: :fn_current_status,
                                                 args: ['asset_transaction_types', id],
                                                 col_name: :status }],
                            wrapper: AssetTransactionType)
    end
  end
end
