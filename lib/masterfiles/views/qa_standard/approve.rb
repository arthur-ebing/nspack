# frozen_string_literal: true

module Masterfiles
  module Quality
    module QaStandard
      class Approve
        def self.call(id)
          ui_rule = UiRules::Compiler.new(:qa_standard, :approve, id: id)
          rules   = ui_rule.compile

          Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form do |form|
              form.caption 'Approve or Reject QA Standard'
              form.action "/masterfiles/quality/qa_standards/#{id}/approve"
              form.remote!
              form.submit_captions 'Approve or Reject'
              form.add_field :approve_action
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
