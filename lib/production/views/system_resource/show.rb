# frozen_string_literal: true

module Production
  module Resources
    module SystemResource
      class Show
        def self.call(id) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:system_resource, :show, id: id)
          rules   = ui_rule.compile

          Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form do |form|
              form.view_only!
              form.row do |row|
                row.column do |col|
                  col.add_field :plant_resource_code
                  col.add_field :system_resource_code
                  col.add_field :active
                end
                row.column do |col|
                  col.add_field :plant_resource_type_id
                  col.add_field :system_resource_type_code
                  col.add_field :represents_plant_resource_code
                end
              end
              form.row do |row|
                row.column do |col|
                  col.add_field :description
                end
              end
              if ui_rule.form_object.system_resource_type_code == Crossbeams::Config::ResourceDefinitions::PERIPHERAL
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
              else
                form.row do |row|
                  row.column do |col|
                    col.add_field :module_function
                    col.add_field :robot_function
                    col.add_field :mac_address
                    col.add_field :ip_address
                    col.add_field :port
                    col.add_field :publishing
                  end
                  row.column do |col|
                    col.add_field :ttl
                    col.add_field :cycle_time
                    col.add_field :login
                    col.add_field :logoff
                    col.add_field :group_incentive
                    col.add_field :legacy_messcada
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
