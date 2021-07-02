# frozen_string_literal: true

module Production
  module Resources
    module SystemResource
      class SetModule
        def self.call(id, form_values: nil, form_errors: nil) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:system_resource, :set_module, id: id, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'Edit System Resource'
              form.action "/production/resources/system_resources/#{id}/set_module"
              form.remote!
              form.row do |row|
                row.column do |col|
                  col.add_field :plant_resource_type_id
                  col.add_field :system_resource_code
                  col.add_field :description
                  col.add_field :equipment_type
                  col.add_field :module_action
                end
              end
              form.row do |row|
                row.column do |col|
                  col.add_field :module_function
                  col.add_field :robot_function
                  col.add_field :mac_address
                  col.add_field :ip_address
                  col.add_field :port
                end
                row.column do |col|
                  col.add_field :ttl
                  col.add_field :cycle_time
                  col.add_field :publishing
                  col.add_field :login
                  col.add_field :logoff
                  col.add_field :group_incentive
                  col.add_field :legacy_messcada
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
