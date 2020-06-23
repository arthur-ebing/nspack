# frozen_string_literal: true

module Production
  module Resources
    module SystemResource
      class SetPeripheral
        def self.call(id, form_values: nil, form_errors: nil) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:system_resource, :set_peripheral, id: id, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page| # rubocop:disable Metrics/BlockLength
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form| # rubocop:disable Metrics/BlockLength
              form.caption 'Edit System Resource'
              form.action "/production/resources/system_resources/#{id}/set_peripheral"
              form.remote!
              form.row do |row|
                row.column do |col|
                  col.add_field :plant_resource_type_id
                  col.add_field :system_resource_code
                  col.add_field :description
                end
              end
              form.row do |row|
                row.column do |col|
                  col.add_field :equipment_type
                  col.add_field :peripheral_model
                  col.add_field :ip_address
                  col.add_field :port
                  col.add_field :ttl
                  col.add_field :cycle_time
                end
                row.column do |col|
                  col.add_field :module_function
                  col.add_field :connection_type
                  col.add_field :printer_language
                  col.add_field :print_username
                  col.add_field :print_password
                  col.add_field :pixels_mm
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
