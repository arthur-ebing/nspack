# frozen_string_literal: true

module Masterfiles
  module Quality
    module QaStandard
      class Edit
        def self.call(id, form_values: nil, form_errors: nil)
          ui_rule = UiRules::Compiler.new(:qa_standard, :edit, id: id, form_values: form_values)
          rules   = ui_rule.compile

          Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'Edit QA Standard'
              form.action "/masterfiles/qa/qa_standards/#{id}"
              form.remote!
              form.method :update
              form.add_field :qa_standard_name
              form.add_field :description
              form.add_field :season_id
              form.add_field :qa_standard_type_id
              form.add_field :packed_tm_group_ids
              form.add_field :target_market_ids
              form.add_field :internal_standard
              form.add_field :applies_to_all_markets
            end
          end
        end
      end
    end
  end
end
