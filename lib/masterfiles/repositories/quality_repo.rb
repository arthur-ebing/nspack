# frozen_string_literal: true

module MasterfilesApp
  class QualityRepo < BaseRepo
    build_for_select :pallet_verification_failure_reasons,
                     label: :reason,
                     value: :id,
                     order_by: :reason
    build_inactive_select :pallet_verification_failure_reasons,
                          label: :reason,
                          value: :id,
                          order_by: :reason

    build_for_select :scrap_reasons,
                     label: :scrap_reason,
                     value: :id,
                     order_by: :scrap_reason
    build_inactive_select :scrap_reasons,
                          label: :scrap_reason,
                          value: :id,
                          order_by: :scrap_reason

    crud_calls_for :pallet_verification_failure_reasons, name: :pallet_verification_failure_reason, wrapper: PalletVerificationFailureReason
    crud_calls_for :scrap_reasons, name: :scrap_reason, wrapper: ScrapReason

    build_for_select :inspection_types, label: :inspection_type_code, value: :id, order_by: :inspection_type_code
    build_inactive_select :inspection_types, label: :inspection_type_code, value: :id, order_by: :inspection_type_code
    crud_calls_for :inspection_types, name: :inspection_type, wrapper: InspectionType

    build_for_select :inspection_failure_types, label: :failure_type_code, value: :id, order_by: :failure_type_code
    build_inactive_select :inspection_failure_types, label: :failure_type_code, value: :id, order_by: :failure_type_code
    crud_calls_for :inspection_failure_types, name: :inspection_failure_type, wrapper: InspectionFailureType

    build_for_select :inspection_failure_reasons, label: :failure_reason, value: :id, order_by: :failure_reason
    build_inactive_select :inspection_failure_reasons, label: :failure_reason, value: :id, order_by: :failure_reason
    crud_calls_for :inspection_failure_reasons, name: :inspection_failure_reason, wrapper: InspectionFailureReason

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

    def find_inspection_type_flat(id) # rubocop:disable Metrics/AbcSize
      hash = find_with_association(:inspection_types,
                                   id,
                                   parent_tables: [{ parent_table: :inspection_failure_types,
                                                     columns: [:failure_type_code],
                                                     foreign_key: :inspection_failure_type_id,
                                                     flatten_columns: { failure_type_code: :failure_type_code } }],
                                   lookup_functions: [{ function: :fn_current_status, args: ['inspection_types', :id],  col_name: :status }])
      return nil if hash.nil?

      hash[:applicable_tm_group_ids] ||= select_values(:target_market_groups, :id)
      hash[:applicable_tm_groups] = select_values(:target_market_groups, :target_market_group_name, id: hash[:applicable_tm_group_ids].to_a)
      hash[:applicable_cultivar_ids] ||= select_values(:cultivars, :id)
      hash[:applicable_cultivars] = select_values(:cultivars, :cultivar_name, id: hash[:applicable_cultivar_ids].to_a)
      hash[:applicable_orchard_ids] ||= select_values(:orchards, :id)
      hash[:applicable_orchards] = select_values(:orchards, :orchard_code, id: hash[:applicable_orchard_ids].to_a)

      InspectionTypeFlat.new(hash)
    end

    def create_inspection_type(res)
      hash = res.to_h
      hash[:applicable_tm_group_ids] = nil if hash[:applies_to_all_tm_groups]
      hash[:applicable_cultivar_ids] = nil if hash[:applies_to_all_cultivars]
      hash[:applicable_orchard_ids] = nil if hash[:applies_to_all_orchards]
      create(:inspection_types, hash)
    end

    def update_inspection_type(id, res)
      hash = res.to_h
      hash[:applicable_tm_group_ids] = nil if hash[:applies_to_all_tm_groups]
      hash[:applicable_cultivar_ids] = nil if hash[:applies_to_all_cultivars]
      hash[:applicable_orchard_ids] = nil if hash[:applies_to_all_orchards]
      update(:inspection_types, id, hash)
    end
  end
end
