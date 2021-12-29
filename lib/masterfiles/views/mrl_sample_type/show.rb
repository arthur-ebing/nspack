# frozen_string_literal: true

module Masterfiles
  module Quality
    module MrlSampleType
      class Show
        def self.call(id)
          ui_rule = UiRules::Compiler.new(:mrl_sample_type, :show, id: id)
          rules   = ui_rule.compile

          Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form do |form|
              # form.caption 'Mrl Sample Type'
              form.view_only!
              form.add_field :sample_type_code
              form.add_field :description
              form.add_field :active
            end
          end
        end
      end
    end
  end
end
