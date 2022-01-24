# frozen_string_literal: true

module Masterfiles
  module Quality
    module QaStandardType
      class Show
        def self.call(id)
          ui_rule = UiRules::Compiler.new(:qa_standard_type, :show, id: id)
          rules   = ui_rule.compile

          Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form do |form|
              # form.caption 'QA Standard Type'
              form.view_only!
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
