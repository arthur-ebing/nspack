# frozen_string_literal: true

module ProductionApp
  class ImportResources < BaseService
    attr_reader :repo, :modules, :printers, :site_code

    PLANT_RES_TYPES = {
      'PRN' => 'PRINTER',
      'CLM' => 'CLM_ROBOT',                # on DROP
      'PMM' => 'PALLET_FORKLIFT_ROBOT',    # on PALLET_FORKLIFT
      'BTM' => 'BINTIPPING_ROBOT',         # on BIN_TIPPING_STATION
      'CVM' => 'CARTON_VERIFICATION_ROBOT' # on CARTON_VERIFICATION_STATION
    }.freeze

    def initialize(site_code, modules_file, printers_file)
      @site_code = site_code
      @repo = ResourceRepo.new
      @modules = Nokogiri::XML(File.read(modules_file))
      @printers = Nokogiri::XML(File.read(printers_file))
    end

    def call # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      line1 = DB[:plant_resources].where(plant_resource_code: 'LINE1').get(:id)
      line2 = DB[:plant_resources].where(plant_resource_code: 'LINE2').get(:id)
      line3 = DB[:plant_resources].where(plant_resource_code: 'LINE3').get(:id)
      line4 = DB[:plant_resources].where(plant_resource_code: 'LINE4').get(:id)
      clm_type = DB[:plant_resource_types].where(plant_resource_type_code: 'CLM_ROBOT').get(:id)
      btn_type = DB[:plant_resource_types].where(plant_resource_type_code: 'ROBOT_BUTTON').get(:id)
      prn_type = DB[:plant_resource_types].where(plant_resource_type_code: 'PRINTER').get(:id)
      raise 'Missing data' if [line1, line2, line3, line4, clm_type, btn_type, prn_type].any?(&:nil?)

      # Ignore: PWM-
      # Ignore: CLM-0001
      # - do these per-hand (find out where in ph...
      # plant_res_type

      # Create ph1 - 4, each with a line.
      # loop through robots and add to relevant line
      # - check if printer added and add to same line if not there.
      # printer_hash = printers.xpath('.//Printer').map {|p| { name: p.attributes['Name'].value, alias: p.attributes['Alias'].value } }
      printer_list = printers.xpath('.//Printer').each_with_object({}) { |p, h| h[p.attributes['Name'].value] = { alias: p.attributes['Alias'].value, in_db: false } }
      robot_list = modules.xpath('.//Module').each_with_object({}) { |p, h| h[p.attributes['Name'].value] = { alias: p.attributes['Alias'].value, printer: p.attributes['Printer'].value, ph: p.attributes['Alias'].value[2..2] } }.select { |k, v| k.start_with?('CLM-') && v[:alias] != 'UFAdmin' }

      printer_list.each do |k, v|
        hs = repo.where_hash(:plant_resources, plant_resource_code: k)
        next unless hs

        v[:id] = hs[:id]
        v[:sys_id] = hs[:system_resource_id]
        v[:in_db] = true
      end

      robot_list.each do |clm, attrs|
        next if repo.exists?(:plant_resources, plant_resource_code: attrs[:alias])

        robo = { plant_resource_type_id: clm_type, plant_resource_code: attrs[:alias], description: attrs[:alias] }
        res = PlantResourceSchema.call(robo)
        parent_id = case attrs[:ph]
                    when '1'
                      line1
                    when '2'
                      line2
                    when '3'
                      line3
                    when '4'
                      line4
                    else
                      raise "Unknown ph/line number - #{attrs[:ph]}"
                    end
        repo.transaction do
          id = repo.create_child_plant_resource(parent_id, res, sys_code: clm)
          repo.log_status('plant_resources', id, 'CREATED', user_name: 'Import')
          4.times do |btn_no|
            btn_dat = { plant_resource_type_id: btn_type, plant_resource_code: "#{attrs[:alias]}-#{btn_no + 1}", description: "#{attrs[:alias]}-#{btn_no + 1}" }
            res = PlantResourceSchema.call(btn_dat)
            b_id = repo.create_child_plant_resource(id, res)
            repo.log_status('plant_resources', b_id, 'CREATED', user_name: 'Import')
          end

          prn = attrs[:printer]
          if printer_list[prn]
            unless printer_list[prn][:in_db]
              # add printer
              prin = { plant_resource_type_id: prn_type, plant_resource_code: prn, description: printer_list[prn][:alias] }
              res = PlantResourceSchema.call(prin)
              p_id = repo.create_child_plant_resource(parent_id, res, sys_code: prn)
              repo.log_status('plant_resources', p_id, 'CREATED', user_name: 'Import')
              printer_list[prn][:id] = p_id
              printer_list[prn][:sys_id] = DB[:plant_resources].where(id: p_id).get(:system_resource_id)
              printer_list[prn][:in_db] = true
            end
            repo.link_peripherals(id, [printer_list[prn][:sys_id]])
          end
          repo.log_action(user_name: 'Import', context: 'import CLM & PRN resources via Rake')
        end
      end
      success_response('Import complete')
    end
  end
end
