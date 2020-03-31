# frozen_string_literal: true

module FinishedGoodsApp
  class EcertRepo < BaseRepo
    build_for_select :ecert_agreements,
                     label: %i[code name],
                     value: :id,
                     order_by: :code
    build_inactive_select :ecert_agreements,
                          label: %i[code name],
                          value: :id,
                          order_by: :code

    crud_calls_for :ecert_agreements, name: :ecert_agreement, wrapper: EcertAgreement
    crud_calls_for :ecert_tracking_units, name: :ecert_tracking_unit, wrapper: EcertTrackingUnit
  end
end
