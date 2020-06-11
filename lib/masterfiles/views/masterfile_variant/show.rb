# frozen_string_literal: true

module Masterfiles
  module General
    module MasterfileVariant
      class Show
        def self.call(id)
          ui_rule = UiRules::Compiler.new(:masterfile_variant, :show, id: id)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form do |form|
              # form.caption 'Masterfile Variant'
              form.view_only!
              form.add_field :masterfile_table
              form.add_field :masterfile_code
              form.add_field :variant_code
            end
          end

          layout
        end
      end
    end
  end
end
