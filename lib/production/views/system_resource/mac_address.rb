# frozen_string_literal: true

module Production
  module Resources
    module SystemResource
      class MacAddress
        def self.call(id)
          ui_rule = UiRules::Compiler.new(:system_resource, :deploy_config, id: id)
          rules   = ui_rule.compile

          Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form do |form|
              form.action "/production/resources/system_resources/#{id}/get_mac_address/loading"
              # form.submit_in_loading_page!
              form.remote!
              form.row do |row|
                row.column do |col|
                  col.add_field :plant_resource_code
                  col.add_field :system_resource_code
                  col.add_field :ip_address
                  col.add_field :network_ip
                  col.add_field :distro_type
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
