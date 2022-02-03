# frozen_string_literal: true

module Masterfiles
  module Quality
    module QaStandardType
      class Complete
        def self.call(id)
          ui_rule = UiRules::Compiler.new(:qa_standard_type, :complete, id: id)
          rules   = ui_rule.compile

          Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form do |form|
              form.caption 'Complete QA Standard Type'
              form.action "/masterfiles/quality/qa_standard_types/#{id}/complete"
              form.remote!
              form.submit_captions 'Complete'
              form.add_text 'Are you sure you want to complete this qa_standard_type?', wrapper: :h3
              form.add_field :to
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
