# frozen_string_literal: true

module MasterfilesApp
  class LookupMasterfileValues < BaseService
    attr_reader :repo, :edi_repo, :record, :errors, :mf

    def initialize(record)
      @repo = RawMaterialsApp::RmtDeliveryRepo.new
      @edi_repo = EdiApp::EdiInRepo.new
      @record = record
      @errors = []
      @mf = {}
    end

    def call
      %i[farm_code puc_code orchard_code product_class_code commodity_code rmt_variety_code season_code size_code location_code container_material_type_code delivery_destination_code].each do |key|
        next unless record.keys.include?(key)

        build_record(key)
      end
      return failed_response(errors.join('. ')) unless errors.empty?

      success_response('ok', mf)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    private

    def build_record(key) # rubocop:disable Metrics/CyclomaticComplexity,  Metrics/AbcSize
      case key
      when :farm_code
        simple_lookup(key, :farm_code, :farms, :farm_id, 'Farm')
      when :puc_code
        lookup_puc(key)
      when :orchard_code
        lookup_orchard(key)
      when :product_class_code
        simple_lookup(key, :rmt_class_code, :rmt_classes, :rmt_class_id, 'RmtClass')
      when :commodity_code
        simple_lookup(key, :code, :commodities, :commodity_id, 'Commodity')
      when :rmt_variety_code
        lookup_rmt_variety(key)
      when :season_code
        lookup_season(key)
      when :size_code
        simple_lookup(key, :size_code, :rmt_sizes, :rmt_size_id, 'Size')
      when :location_code
        simple_lookup(key, :location_long_code, :locations, :location_id, 'Location')
      when :container_material_type_code
        simple_lookup(key, :container_material_type_code, :rmt_container_material_types, :rmt_container_material_type_id, 'Container Material Type')
      when :delivery_destination_code
        simple_lookup(key, :delivery_destination_code, :rmt_delivery_destinations, :rmt_delivery_destination_id, 'Delivery Destination') if AppConst::CR_RMT.include_destination_in_delivery?
      else
        raise Crossbeams::FrameworkError, "MF Key #{key} is not expected"
      end
    end

    def simple_lookup(key, lookup_key, table, mf_id_field, text)
      mf_id = (repo.get_value(table, :id, lookup_key => record[key]) || edi_repo.get_variant_id(table, record[key]))
      store_mf_or_error(mf_id, mf_id_field, "#{text}: #{record[key]}")
    end

    def lookup_puc(key) # rubocop:disable Metrics/AbcSize
      mf_id = MasterfilesApp::FarmRepo.new.find_puc_by_puc_code_and_farm(record[key], mf[:farm_id])
      mf_id ||= MasterfilesApp::FarmRepo.new.find_puc_by_variant_and_farm(record[key], mf[:farm_id])
      store_mf_or_error(mf_id, :puc_id, "PUC: #{record[key]} Farm: #{record[:farm_code]}")
    end

    def lookup_orchard(key) # rubocop:disable Metrics/AbcSize
      mf_id = repo.get_value(:orchards, :id, orchard_code: record[key], farm_id: mf[:farm_id], puc_id: mf[:puc_id])
      mf_id ||= MesscadaApp::MesscadaRepo.new.find_orchard_by_variant_and_puc_and_farm(record[key], mf[:puc_id], mf[:farm_id])
      store_mf_or_error(mf_id, :orchard_id, "Orchard: #{record[key]} PUC: #{record[:puc_code]} Farm: #{record[:farm_code]}")
    end

    def lookup_rmt_variety(key) # rubocop:disable Metrics/AbcSize
      mf_id = MasterfilesApp::CultivarRepo.new.find_cultivar_by_cultivar_name_and_commodity_and_orchard(record[key], record[:commodity_code], mf[:orchard_id])
      mf_id ||= MasterfilesApp::CultivarRepo.new.find_cultivar_by_variant_and_commodity_and_orchard(record[key], record[:commodity_code], mf[:orchard_id])
      store_mf_or_error(mf_id, :cultivar_id, "Cultivar: #{record[key]} Commodity: #{record[:commodity_code]} Farm: #{record[:farm_code]} Orchard: #{record[:orchard_code]}")
    end

    def lookup_season(key) # rubocop:disable Metrics/AbcSize
      mf_id = MasterfilesApp::CalendarRepo.new.find_cultivar_by_season_code_and_commodity_code(record[key], record[:commodity_code])
      mf_id ||= MasterfilesApp::CalendarRepo.new.find_season_by_variant(record[key], record[:commodity_code])
      store_mf_or_error(mf_id, :season_id, "Season: #{record[key]} Commodity: #{record[:commodity_code]}")
    end

    def store_mf_or_error(mf_value, mf_name, err)
      if mf_value.nil?
        errors << "Missing MF. #{err}"
      else
        mf[mf_name] = mf_value
      end
    end
  end
end
