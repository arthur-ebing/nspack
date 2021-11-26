# frozen_string_literal: true

module Production
  module Resources
    module SystemResource
      class ProvisionDevice
        def self.call(id)
          ui_rule = UiRules::Compiler.new(:system_resource, :deploy_config, id: id)
          rules   = ui_rule.compile

          Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form do |form|
              form.action "/production/resources/system_resources/#{id}/provision_device/loading"
              form.submit_in_loading_page!
              form.row do |row|
                row.column do |col|
                  col.add_field :plant_resource_code
                  col.add_field :system_resource_code
                  col.add_field :network_ip
                  col.add_field :use_network_ip
                  # webserver - host/port from BASE_IP as default
                  # MesServer: choose VLAN ip if required... (on MES SERVER, allow setting of VLAN ip addresses)
                end
                row.blank_column
              end
            end
          end
        end
      end
    end
  end
end
