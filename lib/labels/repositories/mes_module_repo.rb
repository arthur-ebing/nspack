# frozen_string_literal: true

module LabelsApp
  class MesModuleRepo < BaseRepo
    build_for_select :mes_modules,
                     label: :module_code,
                     value: :id,
                     order_by: :module_code
    build_inactive_select :mes_modules,
                          label: :module_code,
                          value: :id,
                          order_by: :module_code

    crud_calls_for :mes_modules, name: :mes_module, wrapper: MesModule

    def refresh_and_add_mes_modules(ip_or_address, module_list) # rubocop:disable Metrics/AbcSize
      server_ip = UtilityFunctions.ip_from_uri(ip_or_address)
      module_codes = module_list.map { |a| a['Code'] }
      qry = <<~SQL
        UPDATE mes_modules
        SET active = false
        WHERE server_ip = '#{server_ip}'
          AND module_code NOT IN ('#{module_codes.join("', '")}');
      SQL
      DB.transaction do
        DB.execute(qry)
        module_list.each do |mes_module|
          rec = {
            module_code: mes_module['Code'],
            module_type: mes_module['Function'],
            ip_address: mes_module['NetworkInterface'],
            port: mes_module['Port'].to_i,
            alias: mes_module['Alias']
          }
          DB[:mes_modules].insert_conflict(target: %i[server_ip module_code],
                                           update: {
                                             alias: Sequel[:excluded][:alias],
                                             module_type: Sequel[:excluded][:module_type],
                                             ip_address: Sequel[:excluded][:ip_address],
                                             port: Sequel[:excluded][:port],
                                             server_ip: server_ip,
                                             active: true
                                           }).insert(module_code: rec[:module_code],
                                                     alias: rec[:alias],
                                                     module_type: rec[:module_type],
                                                     ip_address: rec[:ip_address],
                                                     port: rec[:port],
                                                     server_ip: server_ip)
        end
      end
    end
  end
end
