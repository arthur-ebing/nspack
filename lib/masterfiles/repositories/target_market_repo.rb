# frozen_string_literal: true

module MasterfilesApp
  class TargetMarketRepo < BaseRepo
    build_for_select :target_market_group_types,
                     alias: 'tm_group_types',
                     label: :target_market_group_type_code,
                     value: :id,
                     order_by: :target_market_group_type_code
    build_inactive_select :target_market_group_types,
                          alias: 'tm_group_types',
                          label: :target_market_group_type_code,
                          value: :id,
                          order_by: :target_market_group_type_code
    build_for_select :target_market_groups,
                     alias: 'tm_groups',
                     label: :target_market_group_name,
                     value: :id,
                     order_by: :target_market_group_name
    build_inactive_select :target_market_groups,
                          alias: 'tm_groups',
                          label: :target_market_group_name,
                          value: :id,
                          order_by: :target_market_group_name
    build_for_select :target_markets,
                     label: :target_market_name,
                     value: :id,
                     order_by: :target_market_name
    build_inactive_select :target_markets,
                          label: :target_market_name,
                          value: :id,
                          order_by: :target_market_name

    crud_calls_for :target_market_group_types, name: :tm_group_type, wrapper: TmGroupType
    crud_calls_for :target_market_groups, name: :tm_group, wrapper: TmGroup
    crud_calls_for :target_markets, name: :target_market, wrapper: TargetMarket

    def find_target_market(id)
      hash = find_hash(:target_markets, id)
      return nil if hash.nil?

      hash[:country_ids] = target_market_country_ids(id)
      hash[:tm_group_ids] = target_market_tm_group_ids(id)
      hash[:target_customer_ids] = target_market_target_customer_ids(id)
      TargetMarket.new(hash)
    end

    def delete_target_market(id)
      DB[:target_markets_for_countries].where(target_market_id: id).delete
      DB[:target_markets_for_groups].where(target_market_id: id).delete
      DB[:target_markets_target_customers].where(target_market_id: id).delete
      DB[:target_markets].where(id: id).delete
    end

    def link_regions(target_market_group_id, region_ids)
      return nil unless region_ids

      existing_ids      = target_market_group_region_ids(target_market_group_id)
      old_ids           = existing_ids - region_ids
      new_ids           = region_ids - existing_ids

      DB[:destination_regions_tm_groups].where(target_market_group_id: target_market_group_id).where(destination_region_id: old_ids).delete
      new_ids.each do |prog_id|
        DB[:destination_regions_tm_groups].insert(target_market_group_id: target_market_group_id, destination_region_id: prog_id)
      end
    end

    def target_market_group_region_ids(target_market_group_id)
      DB[:destination_regions_tm_groups].where(target_market_group_id: target_market_group_id).select_map(:destination_region_id).sort
    end

    def link_countries(target_market_id, country_ids)
      country_ids = [] if country_ids.nil?

      existing_ids      = target_market_country_ids(target_market_id)
      old_ids           = existing_ids - country_ids
      new_ids           = country_ids - existing_ids

      DB[:target_markets_for_countries].where(target_market_id: target_market_id).where(destination_country_id: old_ids).delete
      new_ids.each do |prog_id|
        DB[:target_markets_for_countries].insert(target_market_id: target_market_id, destination_country_id: prog_id)
      end
    end

    def target_market_country_ids(target_market_id)
      DB[:target_markets_for_countries].where(target_market_id: target_market_id).select_map(:destination_country_id).sort
    end

    def link_tm_groups(target_market_id, tm_group_ids)
      return nil unless tm_group_ids

      existing_ids      = target_market_tm_group_ids(target_market_id)
      old_ids           = existing_ids - tm_group_ids
      new_ids           = tm_group_ids - existing_ids

      DB[:target_markets_for_groups].where(target_market_id: target_market_id).where(target_market_group_id: old_ids).delete
      new_ids.each do |prog_id|
        DB[:target_markets_for_groups].insert(target_market_id: target_market_id, target_market_group_id: prog_id)
      end
    end

    def target_market_tm_group_ids(target_market_id)
      DB[:target_markets_for_groups].where(target_market_id: target_market_id).select_map(:target_market_group_id).sort
    end

    def target_market_group_names_for(target_market_id)
      DB[:target_markets_for_groups].join(:target_market_groups, id: :target_market_group_id).where(target_market_id: target_market_id).select_map(:target_market_group_name).sort
    end

    def destination_country_names_for(target_market_id)
      DB[:target_markets_for_countries].join(:destination_countries, id: :destination_country_id).where(target_market_id: target_market_id).select_map(:country_name).sort
    end

    def for_select_packed_tm_groups(where: {}, active: true)
      DB[:target_market_groups]
        .where(target_market_group_type_id: get_id(:target_market_group_types, target_market_group_type_code: AppConst::PACKED_TM_GROUP))
        .where(active: active)
        .where(where)
        .select_map(%i[target_market_group_name id])
    end

    def for_select_packed_group_tms(where: {}, active: true)
      DB[:target_markets]
        .join(:target_markets_for_groups, target_market_id: :id)
        .where(active: active)
        .where(where)
        .distinct(:target_market_id)
        .select_map(%i[target_market_name target_market_id])
    end

    def find_tm_group_regions(id)
      DB[:destination_regions]
        .join(:destination_regions_tm_groups, destination_region_id: :id)
        .where(target_market_group_id: id)
        .order(:destination_region_name)
        .select_map(:destination_region_name)
    end

    def delete_tm_group(id)
      DB[:destination_regions_tm_groups].where(target_market_group_id: id).delete
      DB[:target_market_groups].where(id: id).delete
      { success: true }
    end

    def find_tm_group_id_from_code(code, type_code)
      DB[:target_market_groups]
        .where(target_market_group_name: code)
        .where(target_market_group_type_id: DB[:target_market_group_types]
          .where(target_market_group_type_code: type_code)
          .get(:id))
        .get(:id)
    end

    def link_target_customers(target_market_id, target_customer_ids)
      target_customer_ids = [] if target_customer_ids.nil?

      existing_ids      = target_market_target_customer_ids(target_market_id)
      old_ids           = existing_ids - target_customer_ids
      new_ids           = target_customer_ids - existing_ids

      DB[:target_markets_target_customers].where(target_market_id: target_market_id).where(target_customer_party_role_id: old_ids).delete
      new_ids.each do |id|
        DB[:target_markets_target_customers].insert(target_market_id: target_market_id, target_customer_party_role_id: id)
      end
    end

    def target_market_target_customer_ids(target_market_id)
      DB[:target_markets_target_customers].where(target_market_id: target_market_id).select_map(:target_customer_party_role_id).sort
    end

    def target_customer_party_role_names_for(target_market_id)
      DB[:target_markets_target_customers]
        .join(:party_roles, id: :target_customer_party_role_id)
        .where(role_id: get_id(:roles, name: AppConst::ROLE_TARGET_CUSTOMER))
        .where(target_market_id: target_market_id)
        .select_map(Sequel.function(:fn_party_role_name, :id)).sort
    end
  end
end
