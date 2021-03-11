# frozen_string_literal: true

module Masterfiles
  module General
    module MasterfileTransformation
      class Show
        def self.call(id) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:masterfile_transformation, :show, id: id)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form do |form|
              # form.caption 'Masterfile Transformation'
              form.view_only!
              form.add_field :transformation
              form.add_field :masterfile_table
              form.add_field :masterfile_column
              form.add_field :masterfile_id
              form.add_field :masterfile_code
              form.add_field :external_code
              form.add_field :external_system
              form.add_field :created_at
              form.add_field :updated_at
            end
          end

          layout
        end
      end
    end
  end
end
