# frozen_string_literal: true

module MasterfilesApp
  class QualityRepo < BaseRepo
    # INSPECTION FAILURE TYPES
    # --------------------------------------------------------------------------
    build_for_select :inspection_failure_types,
                     label: :failure_type_code,
                     value: :id,
                     order_by: :failure_type_code
    build_inactive_select :inspection_failure_types,
                          label: :failure_type_code,
                          value: :id,
                          order_by: :failure_type_code
    crud_calls_for :inspection_failure_types, name: :inspection_failure_type, wrapper: InspectionFailureType

    # INSPECTION FAILURE REASONS
    # --------------------------------------------------------------------------
    build_for_select :inspection_failure_reasons,
                     label: :failure_reason,
                     value: :id,
                     order_by: :failure_reason
    build_inactive_select :inspection_failure_reasons,
                          label: :failure_reason,
                          value: :id,
                          order_by: :failure_reason
    crud_calls_for :inspection_failure_reasons, name: :inspection_failure_reason

    # PALLET VERIFICATION FAILURE REASONS
    # --------------------------------------------------------------------------
    build_for_select :pallet_verification_failure_reasons,
                     label: :reason,
                     value: :id,
                     order_by: :reason
    build_inactive_select :pallet_verification_failure_reasons,
                          label: :reason,
                          value: :id,
                          order_by: :reason
    crud_calls_for :pallet_verification_failure_reasons, name: :pallet_verification_failure_reason, wrapper: PalletVerificationFailureReason

    # SCRAP REASONS
    # --------------------------------------------------------------------------
    build_for_select :scrap_reasons,
                     label: :scrap_reason,
                     value: :id,
                     order_by: :scrap_reason
    build_inactive_select :scrap_reasons,
                          label: :scrap_reason,
                          value: :id,
                          order_by: :scrap_reason
    crud_calls_for :scrap_reasons, name: :scrap_reason, wrapper: ScrapReason

    # INSPECTION TYPES
    # --------------------------------------------------------------------------
    build_for_select :inspection_types,
                     label: :inspection_type_code,
                     value: :id,
                     order_by: :inspection_type_code
    build_inactive_select :inspection_types,
                          label: :inspection_type_code,
                          value: :id,
                          order_by: :inspection_type_code
    crud_calls_for :inspection_types, name: :inspection_type

    def find_inspection_type(id) # rubocop:disable Metrics/AbcSize
      hash = find_with_association(:inspection_types,
                                   id,
                                   parent_tables: [{ parent_table: :inspection_failure_types,
                                                     columns: [:failure_type_code],
                                                     foreign_key: :inspection_failure_type_id,
                                                     flatten_columns: { failure_type_code: :failure_type_code } }],
                                   lookup_functions: [{ function: :fn_current_status, args: ['inspection_types', :id],  col_name: :status }])
      return nil if hash.nil?

      role_id = get_id(:roles, name: AppConst::ROLE_TARGET_CUSTOMER)
      hash[:applicable_tm_customer_ids] = select_values(:party_roles, :id, role_id: role_id) if hash[:applies_to_all_tm_customers]
      hash[:applicable_tm_customers] = hash[:applicable_tm_customer_ids].to_a.map { |i| DB.get(Sequel.function(:fn_party_role_name, i)) }

      hash[:applicable_tm_ids] = select_values(:target_markets, :id) if hash[:applies_to_all_tms]
      hash[:applicable_tms] = select_values(:target_markets, :target_market_name, id: hash[:applicable_tm_ids].to_a)

      hash[:applicable_grade_ids] = select_values(:grades, :id) if hash[:applies_to_all_grades]
      hash[:applicable_grades] = select_values(:grades, :grade_code, id: hash[:applicable_grade_ids].to_a)

      InspectionType.new(hash)
    end

    def find_inspection_failure_reason(id)
      hash = find_with_association(:inspection_failure_reasons,
                                   id,
                                   parent_tables: [{ parent_table: :inspection_failure_types,
                                                     columns: [:failure_type_code],
                                                     foreign_key: :inspection_failure_type_id,
                                                     flatten_columns: { failure_type_code: :failure_type_code } }],
                                   lookup_functions: [{ function: :fn_current_status, args: ['inspection_failure_reasons', :id],  col_name: :status }])
      return nil if hash.nil?

      InspectionFailureReason.new(hash)
    end
  end
end
