# frozen_string_literal: true

module FinishedGoodsApp
  OrderSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:order_type_id).filled(:integer)
    required(:sales_person_party_role_id).filled(:integer)
    required(:customer_party_role_id).filled(:integer)
    required(:contact_party_role_id).filled(:integer)
    required(:currency_id).filled(:integer)
    required(:deal_type_id).filled(:integer)
    required(:incoterm_id).filled(:integer)
    required(:customer_payment_term_set_id).filled(:integer)
    required(:target_customer_party_role_id).maybe(:integer)
    required(:exporter_party_role_id).filled(:integer)
    required(:packed_tm_group_id).maybe(:integer)
    required(:final_receiver_party_role_id).filled(:integer)
    required(:marketing_org_party_role_id).filled(:integer)
    optional(:allocated).filled(:bool)
    optional(:shipped).filled(:bool)
    optional(:completed).filled(:bool)
    optional(:completed_at).maybe(:time)
    required(:customer_order_number).maybe(Types::StrippedString)
    required(:internal_order_number).maybe(Types::StrippedString)
    required(:remarks).maybe(Types::StrippedString)
    required(:pricing_per_kg).maybe(:bool)
    optional(:load_id).maybe(:integer)
  end

  class OrderItemContract < Dry::Validation::Contract
    params do
      optional(:id).filled(:integer)
      required(:order_id).filled(:integer)
      required(:commodity_id).filled(:integer)
      required(:basic_pack_id).filled(:integer)
      required(:standard_pack_id).filled(:integer)
      required(:actual_count_id).maybe(:integer)
      required(:size_reference_id).maybe(:integer)
      required(:grade_id).filled(:integer)
      required(:mark_id).filled(:integer)
      required(:marketing_variety_id).filled(:integer)
      required(:inventory_id).maybe(:integer)
      required(:carton_quantity).filled(:integer)
      required(:price_per_carton).maybe(:decimal)
      required(:price_per_kg).maybe(:decimal)
      required(:sell_by_code).maybe(Types::StrippedString)
      required(:pallet_format_id).maybe(:integer)
      required(:pm_mark_id).maybe(:integer)
      required(:pm_bom_id).maybe(:integer)
      required(:rmt_class_id).maybe(:integer)
      # required(:treatment_id).maybe(:integer)
    end

    rule(:actual_count_id) do
      key.failure('must be filled or size reference must be filled') if values[:actual_count_id].nil_or_empty? && values[:size_reference_id].nil_or_empty?
    end
  end

  OrdersLoadsSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:load_id).filled(:integer)
    required(:order_id).filled(:integer)
  end
end
