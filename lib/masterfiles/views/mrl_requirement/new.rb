# frozen_string_literal: true

module Masterfiles
  module Quality
    module MrlRequirement
      class New
        def self.call(form_values: nil, form_errors: nil, remote: true)
          ui_rule = UiRules::Compiler.new(:mrl_requirement, :new, form_values: form_values)
          rules   = ui_rule.compile

          Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'New MRL Requirement'
              form.action '/masterfiles/quality/mrl_requirements'
              form.remote! if remote
              form.add_field :season_id
              form.add_field :qa_standard_id
              form.add_field :packed_tm_group_id
              form.add_field :target_market_id
              form.add_field :target_customer_id
              form.add_field :cultivar_group_id
              form.add_field :cultivar_id
              form.add_field :max_num_chemicals_allowed
              form.add_field :require_orchard_level_results
              form.add_field :no_results_equal_failure
            end
          end
        end
      end
    end
  end
end
