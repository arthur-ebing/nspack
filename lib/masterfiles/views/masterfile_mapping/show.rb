# frozen_string_literal: true

module Masterfiles
  module General
    module ExternalMasterfileMapping
      class Show
        def self.call(id)
          ui_rule = UiRules::Compiler.new(:external_masterfile_mapping, :show, id: id)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form do |form|
              # form.caption 'External Masterfile Mapping'
              form.view_only!
              form.add_field :external_system
              form.add_field :masterfile_table
              form.add_field :masterfile_id
              form.add_field :external_code
            end
          end

          layout
        end
      end
    end
  end
end
