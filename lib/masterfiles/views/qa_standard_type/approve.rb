# frozen_string_literal: true

module Masterfiles
  module Quality
    module QaStandardType
      class Approve
        def self.call(id)
          ui_rule = UiRules::Compiler.new(:qa_standard_type, :approve, id: id)
          rules   = ui_rule.compile

          Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form do |form|
              form.caption 'Approve or Reject QA Standard Type'
              form.action "/masterfiles/quality/qa_standard_types/#{id}/approve"
              form.remote!
              form.submit_captions 'Approve or Reject'
              form.add_field :approve_action
              form.add_field :qa_standard_type_code
              form.add_field :description
              form.add_field :active
            end
          end
        end
      end
    end
  end
end
