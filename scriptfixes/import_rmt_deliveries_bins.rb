# frozen_string_literal: true

# What this script does:
# ----------------------
# Implement a script to import rmt_deliveries and rmt_bins from the attached csv file
#
# The following columns are relevant:
# BINNUMBER, bin_type,orchard,PUC, intake_date,pick_date
#
# 1] first create a set of deliveries by using the IN_NUMBER.
# 1) create a new rmt_delivery record:
# -- puc = <provided>
# -- farm = <find farm associated with PUC in farm_pucs: there should only be one record>
# -- cultivar = <find single cultivar in orchard.cultivars column>
# -- date_picked = <provided pick_date- use any time>
# -- date_delivered = < provided intake_date>
# -- status = IMPORTED_FOR_GO_LIVE
# 2) create the individual rmt_bins records that belongs to the rmt_delivery (i.e. to the combination item) see the existing code to create rmt_bins- i.e. it inherits most info from the delivery
# -- orchard_id (inherited from header record)
# -- season_id (inherited from header record)
# -- cultivar_id (defaulted from selection on header, but more than one value possible from orchards master file for qty_bins (defaults to 1)
# -- bin_fullness = 'full'
# -- rmt_container_type_id = 'BIN'
# -- rmt_container_material_type_id = <lookup the record via provided 'bin_type'>
# -- rmt_container_material_owner_id = 'Sitrusrand'
# -- bin_received_date_time (inherited from headers date_delivered)
#
# Reason for this script:
# -----------------------
# For deployment at Sitrusrand
# Import legacy data.
#
class ImportRmtDeliveriesBins < BaseScript # rubocop:disable Metrics/ClassLength
  attr_reader :filename, :status, :data, :debug_mode
  def initialize(filename, debug_mode: false)
    @filename = filename.first
    @debug_mode = debug_mode
    @status = 'IMPORTED_FOR_GO_LIVE'
  end

  def run
    if debug_mode
      parse_csv
      puts 'Dry run complete'
      success_response('Dry run complete')
    else
      DB.transaction do
        parse_csv
      end
      infodump = <<~STR
        Script: ImportRmtDeliveriesBins

        What this script does:
        ----------------------
        Implement a script to import rmt_deliveries and rmt_bins from the attached csv file

        The following columns are relevant:
        BINNUMBER, bin_type,orchard,PUC, intake_date,pick_date

        # 1] first create a set of deliveries by using the IN_NUMBER.
        1) create a new rmt_delivery record:
        -- puc = <provided>
        -- farm = <find farm associated with PUC in farm_pucs: there should only be one record>
        -- cultivar = <find single cultivar in orchard.cultivars column>
        -- date_picked = <provided pick_date- use any time>
        -- date_delivered = < provided intake_date>
        -- status = IMPORTED_FOR_GO_LIVE
        2) create the individual rmt_bins records that belongs to the rmt_delivery (i.e. to the combination item) see the existing code to create rmt_bins- i.e. it inherits most info from the delivery
        -- orchard_id (inherited from header record)
        -- season_id (inherited from header record)
        -- cultivar_id (defaulted from selection on header, but more than one value possible from orchards master file for qty_bins (defaults to 1)
        -- bin_fullness = 'full'
        -- rmt_container_type_id = 'BIN'
        -- rmt_container_material_type_id = <lookup the record via provided 'bin_type'>
        -- rmt_container_material_owner_id = 'Sitrusrand'
        -- bin_received_date_time (inherited from header’s date_delivered)

        Reason for this script:
        -----------------------
        For deployment at Sitrusrand
        Import legacy data.

        Results:
        --------
        Updated something

        data: #{data}
      STR
      log_infodump(:data_import,
                   :rmt_bins_import,
                   :change_description,
                   infodump)

      puts 'Import Completed'
      success_response('Import Completed')
    end
  end

  def parse_csv # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    @data = []
    table = CSV::Table.new(CSV.parse(File.read(@filename), headers: true).sort_by { |row| row['IN_NUMBER'] })
    in_numbers = table['IN_NUMBER'].uniq

    in_numbers.each do |in_number| # rubocop:disable Metrics/BlockLength
      delivery_rows = table.select { |row| row['IN_NUMBER'] == in_number }
      row = delivery_rows.first

      puc_id = DB[:pucs].where(puc_code: row['FARM'].strip).get(:id)
      farm_id = DB[:farms_pucs].where(puc_id: puc_id).get(:farm_id)
      orchard_id = DB[:orchards].where(puc_id: puc_id, farm_id: farm_id, orchard_code: row['ORCHARD'].strip).get(:id)
      if orchard_id.nil?
        p "cultivar not linked to orchard - cultivar_name: #{row['VARIETY'].strip}, orchard_code: #{row['ORCHARD'].strip}, puc_code: #{row['FARM'].strip}"
        next
      end

      cultivar_id = DB[:cultivars].where(cultivar_name: row['VARIETY']).get(:id)
      cultivar_ids = DB[:orchards].where(id: orchard_id).get(:cultivar_ids)

      unless cultivar_ids.include?(cultivar_id)
        p "cultivar not linked to orchard - cultivar_name: #{row['VARIETY'].strip}, orchard_code: #{row['ORCHARD'].strip}, puc_code: #{row['FARM'].strip}"
        next
      end

      cultivar_group_id = DB[:cultivars].where(id: cultivar_id).get(:cultivar_group_id)
      commodity_id = DB[:cultivar_groups].where(id: cultivar_group_id).get(:commodity_id)
      commodity_id = DB[:commodities].where(id: commodity_id, code: row['COMMODITY']).get(:id)
      if commodity_id.nil?
        p 'Check COMMODITY setup'
        p row
        next
      end

      date_picked = Date.parse(row['PICK_DATE']).to_s
      date_delivered = Date.parse(row['IN_DATE_TIME']).to_s
      season_id = DB["SELECT id FROM seasons WHERE commodity_id = #{commodity_id} AND start_date <= '#{date_picked}'::date AND end_date >= '#{date_picked}'::date"].get(:id)

      # create a new rmt_delivery
      rmt_delivery_attrs = {
        orchard_id: orchard_id,
        cultivar_id: cultivar_id,
        season_id: season_id,
        farm_id: farm_id,
        puc_id: puc_id,
        delivery_tipped: true,
        date_picked: date_picked,
        date_delivered: date_delivered
      }

      rmt_delivery_id = DB[:rmt_deliveries].where(rmt_delivery_attrs).get(:id)
      if rmt_delivery_id.nil? && !debug_mode
        rmt_delivery_id = DB[:rmt_deliveries].insert(rmt_delivery_attrs)
        log_status(:rmt_deliveries, rmt_delivery_id, status)
      end

      # create rmt_bins
      delivery_rows.each do |delivery_row| # rubocop:disable Metrics/BlockLength
        tipped_asset_number = delivery_row['BINNUMBER'].strip
        if tipped_asset_number.gsub('BJV', '').gsub('BVJ', '').gsub('BJ', '').gsub('SR', '').gsub('BV', '').gsub('JB', '').length != 8
          puts "check BINNUMBER: #{tipped_asset_number}"
          next
        end
        rmt_container_type_id = DB[:rmt_container_types].where(container_type_code: 'BIN').get(:id)
        party_id = DB[:organizations].where(medium_description: 'Sitrusrand').get(:party_id)
        role_id = DB[:roles].where(name: 'RMT_BIN_OWNER').get(:id)
        rmt_material_owner_party_role_id = DB[:party_roles].where(party_id: party_id, role_id: role_id).get(:id)
        rmt_container_material_type_id = DB[:rmt_container_material_types].where(container_material_type_code: delivery_row['BIN_TYPE']).get(:id)

        rmt_bin_attrs = {
          rmt_delivery_id: rmt_delivery_id,
          season_id: season_id,
          cultivar_id: cultivar_id,
          orchard_id: orchard_id,
          farm_id: farm_id,
          rmt_container_type_id: rmt_container_type_id,
          cultivar_group_id: cultivar_group_id,
          puc_id: puc_id,
          qty_bins: 1,
          tipped_asset_number: tipped_asset_number,
          bin_fullness: 'Full',
          bin_tipped: true,
          bin_received_date_time: date_delivered,
          rmt_container_material_type_id: rmt_container_material_type_id,
          rmt_material_owner_party_role_id: rmt_material_owner_party_role_id
        }
        rmt_bin_id = DB[:rmt_bins].where(rmt_bin_attrs).get(:id)
        if rmt_bin_id.nil? && !debug_mode
          rmt_bin_id = DB[:rmt_bins].insert(rmt_bin_attrs)
          log_status(:rmt_bins, rmt_bin_id, status)
        end
        @data << delivery_row
      end
    end
  end
end
