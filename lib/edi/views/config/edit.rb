# frozen_string_literal: true

module Edi
  module Config
    module EdiOutRule
      class Edit
      def self.call(id, form_values: nil, form_errors: nil, mode: :edit) # rubocop:disable Metrics/AbcSize, Layout/IndentationWidth
        ui_rule = UiRules::Compiler.new(:edi_out, mode, id: id, form_values: form_values)
        rules   = ui_rule.compile

        layout = Crossbeams::Layout::Page.build(rules) do |page| # rubocop:disable Metrics/BlockLength
          page.form_object ui_rule.form_object
          page.form_values form_values
          page.form_errors form_errors
          page.form do |form|
            form.caption 'Edit Edi Out Rule'
            form.action "/edi/config/edi_out_rules/#{id}"
            form.remote!
            form.method :update
            form.row do |row|
              row.column do |col|
                col.add_field :flow_type
                col.add_field :role_id
                col.add_field :party_role_id
                col.add_field :hub_address
              end
              row.column do |col|
                col.add_field :destination_type
                col.add_field :depot_id
              end
            end

            form.row do |row|
              row.column do |col|
                col.add_field :directory_keys
              end
            end
          end
        end

        layout
      end
      end
    end
  end
end
