# frozen_string_literal: true

module RawMaterialsApp
  class RmtDeliveryRepo < BaseRepo # rubocop:disable Metrics/ClassLength
    build_for_select :rmt_deliveries,
                     label: :id,
                     value: :id,
                     order_by: :id
    build_inactive_select :rmt_deliveries,
                          label: :id,
                          value: :id,
                          order_by: :id

    build_for_select :rmt_bins,
                     label: :status,
                     value: :id,
                     order_by: :status
    build_inactive_select :rmt_bins,
                          label: :status,
                          value: :id,
                          order_by: :status

    build_for_select :cost_types,
                     label: :cost_type_code,
                     value: :id,
                     no_active_check: true,
                     order_by: :id

    build_for_select :costs,
                     label: :cost_code,
                     value: :id,
                     no_active_check: true,
                     order_by: :id

    crud_calls_for :rmt_deliveries, name: :rmt_delivery, wrapper: RmtDelivery
    crud_calls_for :rmt_bins, name: :rmt_bin, wrapper: RmtBin
    crud_calls_for :rmt_bin_labels, name: :rmt_bin_label, wrapper: RmtBinLabel
    crud_calls_for :cost_types, name: :cost_type, wrapper: MasterfilesApp::CostType
    crud_calls_for :costs, name: :cost, wrapper: MasterfilesApp::Cost
    crud_calls_for :rmt_delivery_costs, name: :rmt_delivery_cost, wrapper: RmtDeliveryCost

    def create_rmt_delivery(res)
      attrs = res.to_h
      attrs = append_valid_season_id(attrs) unless attrs[:season_id]
      DB[:rmt_deliveries].where(current: true).update(current: false) if attrs[:current]

      create(:rmt_deliveries, attrs)
    end

    def append_valid_season_id(attrs, rmt_delivery_id = nil)
      return attrs unless attrs[:cultivar_id] || attrs[:date_delivered]

      instance = find_rmt_delivery(rmt_delivery_id)
      cultivar_id = attrs[:cultivar_id] || instance.cultivar_id
      received_at = attrs[:date_delivered] || instance.date_delivered
      attrs[:season_id] = MasterfilesApp::CalendarRepo.new.get_season_id(cultivar_id, received_at)
      raise Crossbeams::InfoError, 'Season not found for delivery' unless attrs[:season_id]

      attrs
    end

    def update_rmt_delivery(id, res)
      attrs = res.to_h
      attrs = append_valid_season_id(attrs, id) unless attrs[:season_id]
      DB[:rmt_deliveries].where(current: true).update(current: false) if attrs[:current]

      update_untipped_rmt_delivery_bins(id, attrs)
      update(:rmt_deliveries, id, attrs)
    end

    def update_untipped_rmt_delivery_bins(id, attrs)
      bin_attrs = { orchard_id: attrs[:orchard_id],
                    season_id: attrs[:season_id],
                    cultivar_id: attrs[:cultivar_id],
                    bin_received_date_time: attrs[:date_delivered],
                    farm_id: attrs[:farm_id],
                    puc_id: attrs[:puc_id] }.delete_if { |_, v| v.nil? }
      return if bin_attrs.empty?

      DB[:rmt_bins].where(rmt_delivery_id: id, bin_tipped: false).update(bin_attrs)
    end

    def delivery_bin_count(id)
      DB[:rmt_bins].where(rmt_delivery_id: id).count
    end

    def update_rmt_bin_asset_level(bin_asset_number, bin_fullness)
      DB[:rmt_bins].where(bin_asset_number: bin_asset_number).update(bin_fullness: bin_fullness)
    end

    def get_bin_delivery(id)
      qry = <<~SQL
        SELECT d.*,f.farm_code,p.puc_code, o.orchard_code
        ,(select sum(qty_bins) from rmt_bins where rmt_delivery_id=d.id and bin_tipped is true) as qty_bins_tipped
        ,(select count(id) from rmt_bins where rmt_delivery_id=d.id) as qty_bins_received
        FROM rmt_deliveries d
        join farms f on f.id=d.farm_id
        join pucs p on p.id=d.puc_id
        join orchards o on o.id=d.orchard_id
        WHERE d.id = ?
      SQL
      DB[qry, id].first
    end

    def all_bins_tipped?(id)
      return false if DB[:rmt_bins].where(rmt_delivery_id: id).count.zero?

      DB[:rmt_bins]
        .where(rmt_delivery_id: id, bin_tipped: false)
        .count.zero?
    end

    def find_delivery_tipped_bins(id)
      DB[:rmt_bins].where(rmt_delivery_id: id, bin_tipped: true).all
    end

    def find_cost_flat(id)
      hash = find_with_association(:costs,
                                   id,
                                   parent_tables: [{ parent_table: :cost_types, columns: [:cost_type_code], flatten_columns: { cost_type_code: :cost_type_code } }])

      return nil if hash.nil?

      MasterfilesApp::CostFlat.new(hash)
    end

    def find_rmt_delivery_cost_flat(rmt_delivery_id, cost_id)
      query = <<~SQL
        SELECT rmt_delivery_costs.amount, costs.cost_code, costs.default_amount, costs.description
        , cost_types.cost_unit, cost_types.cost_type_code, rmt_delivery_costs.rmt_delivery_id, rmt_delivery_costs.cost_id
        FROM rmt_delivery_costs
        JOIN costs ON costs.id = rmt_delivery_costs.cost_id
        JOIN cost_types ON cost_types.id = costs.cost_type_id
        WHERE rmt_delivery_costs.rmt_delivery_id = ? and rmt_delivery_costs.cost_id = ?
      SQL
      DB[query, rmt_delivery_id, cost_id].first
    end

    def find_rmt_bin_flat(id)
      hash = find_with_association(:rmt_bins,
                                   id,
                                   parent_tables: [{ parent_table: :orchards, columns: [:orchard_code], flatten_columns: { orchard_code: :orchard_code } },
                                                   { parent_table: :farms, columns: [:farm_code], flatten_columns: { farm_code: :farm_code } },
                                                   { parent_table: :pucs, columns: [:puc_code], flatten_columns: { puc_code: :puc_code } },
                                                   { parent_table: :seasons, columns: [:season_code], flatten_columns: { season_code: :season_code } },
                                                   { parent_table: :locations, columns: [:location_long_code], flatten_columns: { location_long_code: :location_long_code } },
                                                   { parent_table: :rmt_container_types, columns: [:container_type_code], flatten_columns: { container_type_code: :container_type_code } },
                                                   { parent_table: :rmt_container_material_types, columns: [:container_material_type_code], flatten_columns: { container_material_type_code: :container_material_type_code } },
                                                   # { parent_table: :party_roles, columns: [:container_material_owner_code], flatten_columns: { container_material_type_code: :container_material_type_code } },
                                                   { parent_table: :cultivars, columns: [:cultivar_name], flatten_columns: { cultivar_name: :cultivar_name } }],
                                   lookup_functions: [{ function: :fn_current_status,
                                                        args: ['rmt_bins', :id],
                                                        col_name: :status }])

      return nil if hash.nil?

      hash[:asset_number] = hash[:bin_asset_number]
      RmtBinFlat.new(hash)
    end

    def farm_pucs(farm_id)
      DB[:pucs].where(id: DB[:farms_pucs].where(farm_id: farm_id).select(:puc_id)).map { |p| [p[:puc_code], p[:id]] }
    end

    def orchard_cultivars(orchard_id)
      DB["SELECT cultivars.*
         FROM cultivars
         JOIN orchards ON cultivars.id = ANY (orchards.cultivar_ids)
         WHERE orchards.id = ?", orchard_id].map { |o| [o[:cultivar_name], o[:id]] }
    end

    def orchards(farm_id, puc_id)
      DB[:orchards].where(farm_id: farm_id, puc_id: puc_id).map { |o| [o[:orchard_code], o[:id]] }
    end

    def cultivar_by_delivery_id(delivery_id)
      DB[:cultivars].where(id: DB[:rmt_deliveries].where(id: delivery_id).select(:cultivar_id)).map { |p| p[:id] }.first
    end

    def orchard_by_delivery_id(delivery_id)
      DB[:orchards].where(id: DB[:rmt_deliveries].where(id: delivery_id).select(:orchard_id)).map { |p| p[:id] }.first
    end

    def rmt_container_type_by_container_type_code(container_type_code)
      DB[:rmt_container_types].where(container_type_code: container_type_code).first
    end

    def rmt_container_type_rmt_inner_container_type(container_type_id)
      DB[:rmt_container_types].where(id: container_type_id).map { |r| r[:rmt_inner_container_type_id] }.first
    end

    def rmt_inner_container_type_rmt_inner_container_material_type(rmt_inner_container_type_id)
      DB[:rmt_container_material_types].where(rmt_container_type_id: rmt_inner_container_type_id).map { |r| r[:id] }
    end

    def default_farm_puc
      default_farm = AppConst::DELIVERY_DEFAULT_FARM
      return { farm_id: nil, puc_id: nil } if default_farm.nil?

      farm_pucs = DB[:farms_pucs].where(farm_id: DB[:farms].where(farm_code: default_farm).select(:id)).all
      return { farm_id: nil, puc_id: nil } if farm_pucs.empty?
      return farm_pucs[0] if farm_pucs.length == 1

      { farm_id: farm_pucs[0][:farm_id], puc_id: nil }
    end

    def find_container_material_owners_by_container_material_type(container_material_type_id)
      query = <<~SQL
        SELECT rmt_material_owner_party_role_id AS id, fn_party_role_name_with_role(rmt_material_owner_party_role_id) AS party_name
        FROM rmt_container_material_owners
        WHERE rmt_container_material_type_id = ?
      SQL
      # DB[query, container_material_type_id].select_map(%i[party_name id])
      DB[query, container_material_type_id].map { |p| [p[:party_name], p[:id]] }
    end

    def delivery_confirmation_details(id)
      query = <<~SQL
        select d.id, c.cultivar_name, cg.cultivar_group_code, f.farm_code, p.puc_code, o.orchard_code
        , d.truck_registration_number, d.date_delivered, d.date_picked
        , count(b.id) as bins_received, (d.quantity_bins_with_fruit - count(b.id)) as qty_bins_remaining
        from rmt_deliveries d
        join cultivars c on c.id=d.cultivar_id
        join cultivar_groups cg on cg.id=c.cultivar_group_id
        join farms f on f.id=d.farm_id
        join pucs p on p.id=d.puc_id
        join orchards o on o.id=d.orchard_id
        left outer join rmt_bins b on b.rmt_delivery_id=d.id
        where d.id = ?
        group by d.id, c.cultivar_name, cg.cultivar_group_code, f.farm_code, p.puc_code, o.orchard_code
        , d.truck_registration_number, d.date_delivered
      SQL
      DB[query, id].first
    end

    def bin_details(id)
      query = <<~SQL
        select b.id, c.cultivar_name, cg.cultivar_group_code, f.farm_code, p.puc_code, o.orchard_code, b.rmt_delivery_id, b.bin_fullness
        , b.rmt_container_type_id, b.rmt_container_material_type_id, b.rmt_material_owner_party_role_id, b.qty_bins
        from rmt_bins b
        join cultivars c on c.id=b.cultivar_id
        join cultivar_groups cg on cg.id=c.cultivar_group_id
        join farms f on f.id=b.farm_id
        join pucs p on p.id=b.puc_id
        join orchards o on o.id=b.orchard_id
        where b.id = ?
      SQL
      DB[query, id].first
    end

    def get_available_bin_asset_numbers(count)
      query = <<~SQL
        select a.id, a.bin_asset_number
        from bin_asset_numbers a
        WHERE NOT EXISTS(SELECT id FROM rmt_bins WHERE bin_asset_number = a.bin_asset_number)
        order by last_used_at asc
        limit ?
      SQL
      DB[query, count].select_map(%i[id bin_asset_number]).sort_by(&:last)
    end

    def find_rmt_container_material_owner(rmt_material_owner_party_role_id, rmt_container_material_type_id)
      DB[:rmt_container_material_owners]
        .where(rmt_material_owner_party_role_id: rmt_material_owner_party_role_id, rmt_container_material_type_id:  rmt_container_material_type_id)
        .select(
          Sequel.as(:rmt_material_owner_party_role_id, :id),
          Sequel.function(:fn_party_role_name_with_role, :rmt_material_owner_party_role_id).as(:container_material_owner)
        ).first
    end

    def find_rmt_delivery_by_bin_id(id)
      OpenStruct.new DB[:rmt_deliveries].where(id: DB[:rmt_bins].where(id: id).select(:rmt_delivery_id)).first
    end

    def bin_asset_number_available?(bin_asset_number)
      DB[:rmt_bins].where(bin_asset_number: bin_asset_number, exit_ref: nil).count.zero?
    end

    def only_one_farm_batch?(batch_number)
      DB[:rmt_deliveries].where(batch_number: batch_number).select_map(:farm_id).uniq.count == 1
    end

    def find_bin_by_asset_number(bin_asset_number)
      rmt_bin = DB["SELECT *
                    FROM rmt_bins
                    WHERE (bin_asset_number = '#{bin_asset_number}') AND (exit_ref is Null)"].first

      return rmt_bin unless rmt_bin.nil_or_empty?

      DB["SELECT * FROM rmt_bins WHERE (tipped_asset_number = '#{bin_asset_number}')"].first
    end

    def find_rmt_bin_stock(bin_number)
      DB[:rmt_bins].where(id: bin_number, exit_ref: nil).first
    end

    def find_bin_label_data(bin_id)
      DB["select b.id, o.orchard_code, c.cultivar_name
          from rmt_bins b
          join orchards o on o.id=b.orchard_id
          join cultivars c on c.id=b.cultivar_id
          WHERE b.id = ?", bin_id].first
    end

    def get_rmt_bin_tare_weight(rmt_bin)
      inner_tare = calculate_inner_tare_weight(rmt_bin)

      tare_weight = get(:rmt_container_material_types, rmt_bin[:rmt_container_material_type_id], :tare_weight)
      return tare_weight + inner_tare unless tare_weight.nil?

      new_tare = get(:rmt_container_types, rmt_bin[:rmt_container_type_id], :tare_weight)
      (new_tare || AppConst::BIG_ZERO) + inner_tare
    end

    def calculate_inner_tare_weight(rmt_bin)
      return AppConst::BIG_ZERO if rmt_bin[:qty_inner_bins].nil? || rmt_bin[:qty_inner_bins].zero? # (OR One? is this always set to at least 1?

      tare_weight = get(:rmt_container_material_types, rmt_bin[:rmt_inner_container_material_id], :tare_weight)
      tare_weight = get(:rmt_container_types, rmt_bin[:rmt_inner_container_type_id], :tare_weight) if tare_weight.nil?

      return AppConst::BIG_ZERO if tare_weight.nil?

      tare_weight * rmt_bin[:qty_inner_bins]
    end

    def find_bins_by_delivery_id(id)
      DB[:rmt_bins].where(rmt_delivery_id: id).all
    end

    def find_current_delivery
      DB[:rmt_deliveries].where(current: true).get(:id)
    end

    def delivery_set_current(id)
      DB[:rmt_deliveries].where(current: true).update(current: false)
      update(:rmt_deliveries, id, current: true)
    end

    def find_container_material_owners_for_container_material_type(container_material_type_id)
      DB[:rmt_container_material_owners]
        .where(rmt_container_material_type_id: container_material_type_id)
        .select(:rmt_material_owner_party_role_id, Sequel.function(:fn_party_role_name, :rmt_material_owner_party_role_id))
        .map { |r| [r[:fn_party_role_name], r[:rmt_material_owner_party_role_id]] }
    end

    def get_run_packhouse_location(id)
      query = <<~SQL
        select p.location_id
        from production_runs r
        JOIN plant_resources p on p.id=r.packhouse_resource_id
        WHERE r.id = ?
      SQL
      DB[query, id].get(:location_id)
    end

    def update_rmt_delivery_cost(rmt_delivery_id, cost_id, attrs)
      DB[:rmt_delivery_costs].where(rmt_delivery_id: rmt_delivery_id, cost_id: cost_id).update(attrs.to_h)
    end

    def delete_rmt_delivery_cost(rmt_delivery_id, cost_id)
      DB[:rmt_delivery_costs].where(rmt_delivery_id: rmt_delivery_id, cost_id: cost_id).delete
    end
  end
end
