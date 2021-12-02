# frozen_string_literal: true

module MasterfilesApp
  class AdvancedClassificationsRepo < BaseRepo
    build_for_select :ripeness_codes,
                     label: :ripeness_code,
                     value: :id,
                     no_active_check: true,
                     order_by: :ripeness_code

    build_for_select :rmt_handling_regimes,
                     label: :regime_code,
                     value: :id,
                     no_active_check: true,
                     order_by: :regime_code

    build_for_select :rmt_codes,
                     label: :rmt_code,
                     value: :id,
                     no_active_check: true,
                     order_by: :rmt_code

    crud_calls_for :rmt_codes, name: :rmt_code, wrapper: RmtCode
    crud_calls_for :rmt_handling_regimes, name: :rmt_handling_regime, wrapper: RmtHandlingRegime
    crud_calls_for :ripeness_codes, name: :ripeness_code, wrapper: RipenessCode

    def find_ripeness_code_flat(id)
      hash = find_with_association(
        :ripeness_codes, id,
        lookup_functions: [{ function: :fn_current_status, args: ['ripeness_codes', :id], col_name: :status }]
      )
      return nil if hash.nil?

      RipenessCodeFlat.new(hash)
    end

    def find_rmt_handling_regime_flat(id)
      hash = find_with_association(
        :rmt_handling_regimes, id,
        lookup_functions: [{ function: :fn_current_status, args: ['rmt_handling_regimes', :id], col_name: :status }]
      )
      return nil if hash.nil?

      RmtHandlingRegimeFlat.new(hash)
    end
  end
end
