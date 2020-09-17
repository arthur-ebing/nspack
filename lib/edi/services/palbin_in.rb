# frozen_string_literal: true

module EdiApp
  class PalbinIn < BaseEdiInService
    attr_accessor :missing_masterfiles, :match_data, :parsed_bins
    attr_reader :user, :repo

    def initialize(edi_in_transaction_id, file_path, logger, edi_in_result)
      super(edi_in_transaction_id, file_path, logger, edi_in_result)
      @repo = EdiApp::EdiInRepo.new
      @user = OpenStruct.new(user_name: 'System')
      @missing_masterfiles = []
      @match_data = []
    end

    def call
      parse_palbin_edi

      match_data_on(prepare_array_for_match(match_data))

      check_missing_masterfiles

      business_validation

      create_records

      success_response('Palbin processed')
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    private

    def create_records # rubocop:disable Metrics/AbcSize
      repo.transaction do
        parsed_bins.each do |attrs|
          delivery_attrs = { season_id: attrs[:season_id],
                             farm_id: attrs[:farm_id],
                             puc_id: attrs[:puc_id],
                             orchard_id: attrs[:orchard_id],
                             cultivar_id: attrs[:cultivar_id],
                             received: false,
                             date_delivered: attrs[:bin_received_date_time],
                             reference_number: attrs.delete(:reference_number) }
          rmt_delivery_id = repo.get_id_or_create_with_status(:rmt_deliveries, 'PALBIN_RECEIVED', delivery_attrs)

          repo.get_id_or_create_with_status(:rmt_bins, 'PALBIN_RECEIVED', attrs.merge(rmt_delivery_id: rmt_delivery_id))
        end
      end
    end

    def business_validation
      bin_asset_numbers_in_use = []
      parsed_bins.each do |bin|
        bin_asset_number = bin[:bin_asset_number]
        bin_asset_numbers_in_use << bin_asset_number if repo.exists?(:rmt_bins, bin_asset_number: bin_asset_number)
      end
      raise Crossbeams::InfoError, "Bin Asset Numbers still in use: #{bin_asset_numbers_in_use.join(', ')}" unless bin_asset_numbers_in_use.empty?

      business_validation_passed
    end

    def check_missing_masterfiles
      return if missing_masterfiles.empty?

      notes = "Missing masterfiles for #{missing_masterfiles.uniq.join(", \n")}"
      missing_masterfiles_detected(notes)
      raise Crossbeams::InfoError, 'Missing masterfiles'
    end

    def parse_palbin_edi # rubocop:disable Metrics/AbcSize
      @parsed_bins = []
      @edi_records.each do |params|
        res = EdiPalbinInSchema.call(params)
        raise Crossbeams::InfoError, "Validation error: #{res.messages}" if res.failure?

        palbin = res.to_h
        match_data << palbin[:sscc]
        hash = { reference_number: "#{palbin[:destination]}_#{palbin[:depot]}_#{file_name}",
                 bin_asset_number: palbin[:sscc],
                 bin_received_date_time: palbin[:shipped_at],
                 farm_id: get_masterfile_id(:farms, farm_code: palbin[:farm]),
                 puc_id: get_masterfile_or_variant(:pucs, puc_code: palbin[:puc]),
                 rmt_class_id: get_masterfile_id(:rmt_classes, rmt_class_code: palbin[:grade]),
                 rmt_container_type_id: get_masterfile_id(:rmt_container_types, container_type_code: 'BIN'),
                 rmt_container_material_type_id: get_masterfile_value(:standard_pack_codes, :rmt_container_material_type_id, standard_pack_code: palbin[:pack]),
                 bin_fullness: 'full',
                 qty_bins: 1,
                 gross_weight: palbin[:gross_weight],
                 nett_weight: palbin[:nett_weight] }

        hash[:orchard_id] = get_masterfile_id(:orchards, orchard_code: palbin[:orchard], farm_id: hash[:farm_id], puc_id: hash[:puc_id])
        commodity_id = get_masterfile_id(:commodities, code: palbin[:commodity])
        hash[:cultivar_id] = get_masterfile_id(:cultivars, cultivar_name: palbin[:cultivar], commodity_id: commodity_id)

        hash[:season_id] = MasterfilesApp::CalendarRepo.new.get_season_id(hash[:cultivar_id], hash[:bin_received_date_time])
        missing_masterfiles << "seasons: cultivar: #{palbin[:cultivar]}, received: #{hash[:bin_received_date_time]}" if hash[:season_id].nil?

        parsed_bins << hash
      end
    end

    def get_masterfile_or_variant(table_name, args)
      id = repo.get_id(table_name, args) || repo.get_variant_id(table_name, args.values.first)
      return id unless id.nil?

      missing_masterfiles << "#{table_name}: #{args}"
      nil
    end

    def get_masterfile_id(table_name, args)
      get_masterfile_value(table_name, :id, args)
    end

    def get_masterfile_value(table_name, column, args)
      value = repo.get_value(table_name, column, args)
      return value unless value.nil?

      missing_masterfiles << "#{table_name}.#{column} #{args}"
      nil
    end
  end
end
