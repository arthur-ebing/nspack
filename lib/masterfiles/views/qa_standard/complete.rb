# frozen_string_literal: true

module Masterfiles
  module Quality
    module QaStandard
      class Complete
        def self.call(id)
          ui_rule = UiRules::Compiler.new(:qa_standard, :complete, id: id)
          rules   = ui_rule.compile

          Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form do |form|
              form.caption 'Complete QA Standard'
              form.action "/masterfiles/qa/qa_standards/#{id}/complete"
              form.remote!
              form.submit_captions 'Complete'
              form.add_text 'Are you sure you want to complete this qa_standard?', wrapper: :h3
              form.add_field :to
              form.add_field :qa_standard_name
              form.add_field :description
              form.add_field :season_id
              form.add_field :qa_standard_type_id
              form.add_field :target_market_ids
              form.add_field :packed_tm_group_ids
              form.add_field :internal_standard
              form.add_field :applies_to_all_markets
              form.add_field :active
            end
          end
        end
      end
    end
  end
end
