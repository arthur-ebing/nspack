# frozen_string_literal: true

module Masterfiles
  module Quality
    module MrlRequirement
      class Complete
        def self.call(id)
          ui_rule = UiRules::Compiler.new(:mrl_requirement, :complete, id: id)
          rules   = ui_rule.compile

          Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form do |form|
              form.caption 'Complete Mrl Requirement'
              form.action "/masterfiles/quality/mrl_requirements/#{id}/complete"
              form.remote!
              form.submit_captions 'Complete'
              form.add_text 'Are you sure you want to complete this mrl_requirement?', wrapper: :h3
              form.add_field :to
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
              form.add_field :active
            end
          end
        end
      end
    end
  end
end
