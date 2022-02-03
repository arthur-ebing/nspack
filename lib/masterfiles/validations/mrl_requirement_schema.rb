# frozen_string_literal: true

module MasterfilesApp
  class MrlRequirementContract < Dry::Validation::Contract
    params do
      optional(:id).filled(:integer)
      required(:max_num_chemicals_allowed).filled(:integer)
      required(:require_orchard_level_results).maybe(:bool)
      required(:no_results_equal_failure).maybe(:bool)
      required(:season_id).filled(:integer)
      required(:cultivar_group_id).maybe(:integer)
      required(:cultivar_id).maybe(:integer)
      required(:qa_standard_id).maybe(:integer)
      required(:packed_tm_group_id).maybe(:integer)
      required(:target_market_id).maybe(:integer)
      required(:target_customer_id).maybe(:integer)
    end

    rule(:cultivar_group_id) do
      key.failure 'choose either Cultivar or Group' if (value && values[:cultivar_id]) || (value.nil? && values[:cultivar_id].nil?)
    end

    rule(:qa_standard_id) do
      nil_cnt = 0
      nil_cnt += value.nil? ? 1 : 0
      nil_cnt += values[:packed_tm_group_id].nil? ? 1 : 0
      nil_cnt += values[:target_market_id].nil? ? 1 : 0
      nil_cnt += values[:target_customer_id].nil? ? 1 : 0
      key.failure 'choose either QA Standard, Packed TM Group, Target Market or Target Customer' if nil_cnt != 3
    end
  end

  MrlRequirementSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:max_num_chemicals_allowed).filled(:integer)
    required(:require_orchard_level_results).maybe(:bool)
    required(:no_results_equal_failure).maybe(:bool)
  end
end
