# frozen_string_literal: true

module MasterfilesApp
  class DestinationRepo < BaseRepo
    build_inactive_select :destination_regions,
                          label: :destination_region_name,
                          value: :id,
                          order_by: :destination_region_name

    build_inactive_select :destination_countries,
                          label: :country_name,
                          value: :id,
                          order_by: :country_name

    build_for_select :destination_cities,
                     label: :city_name,
                     value: :id,
                     order_by: :city_name
    build_inactive_select :destination_cities,
                          label: :city_name,
                          value: :id,
                          order_by: :city_name

    crud_calls_for :destination_regions, name: :region, wrapper: Region, exclude: %i[delete]
    crud_calls_for :destination_countries, name: :country, exclude: %i[create delete]
    crud_calls_for :destination_cities, name: :city, exclude: [:create]

    # REGIONS
    # --------------------------------------------------------------------------
    def for_select_destination_regions(where: {}, active: true)
      DB[:destination_regions]
        .join(:destination_regions_tm_groups, destination_region_id: :id)
        .distinct
        .where(active: active)
        .where(where)
        .select_map(%i[destination_region_name id])
    end

    def delete_region(id)
      countries = DB[:destination_countries].where(destination_region_id: id)
      country_ids = countries.select_map(:id).sort

      DB[:destination_cities].where(destination_country_id: country_ids).delete
      countries.delete
      DB[:destination_regions_tm_groups].where(destination_region_id: id).delete
      DB[:destination_regions].where(id: id).delete
    end

    # COUNTRIES
    # --------------------------------------------------------------------------
    def for_select_destination_countries(where: {}, active: true)
      DB[:destination_countries]
        .join(:destination_regions, id: :destination_region_id)
        .where(Sequel[:destination_countries][:active] => active)
        .where(where)
        .distinct
        .select_map([:country_name, Sequel[:destination_countries][:id]])
    end

    def find_country(id)
      hash = find_hash(:destination_countries, id)
      return nil if hash.nil?

      region_hash = where_hash(:destination_regions, id: hash[:destination_region_id])
      hash[:region_name] = region_hash[:destination_region_name] if region_hash

      Country.new(hash)
    end

    def delete_country(id)
      DB[:target_markets_for_countries].where(destination_country_id: id).delete
      DB[:destination_cities].where(destination_country_id: id).delete
      DB[:destination_countries].where(id: id).delete
    end

    def create_country(region_id, attrs)
      if region_id.nil?
        DB[:destination_countries].insert(attrs.to_h)
      else
        DB[:destination_countries].insert(attrs.to_h.merge(destination_region_id: region_id))
      end
    end

    # CITIES
    # --------------------------------------------------------------------------
    def find_city(id)
      hash = find_hash(:destination_cities, id)
      return nil if hash.nil?

      country_hash = where_hash(:destination_countries, id: hash[:destination_country_id])
      if country_hash
        region_hash = where_hash(:destination_regions, id: country_hash[:destination_region_id])
        hash[:country_name] = country_hash[:country_name] if country_hash
        hash[:iso_country_code] = country_hash[:iso_country_code] if country_hash
        hash[:region_name] = region_hash[:destination_region_name] if region_hash
      end

      City.new(hash)
    end

    def create_city(id, attrs)
      DB[:destination_cities].insert(attrs.to_h.merge(destination_country_id: id))
    end

    # --------------------------------------------------------------------------
    def find_region_tm_group_names(id)
      DB[:target_market_groups]
        .join(:destination_regions_tm_groups, target_market_group_id: :id)
        .where(destination_region_id: id)
        .order(:target_market_group_name)
        .select_map(:target_market_group_name)
    end
  end
end
