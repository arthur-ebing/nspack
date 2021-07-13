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

    def for_select_delivery_context_info
      qry = <<~SQL
        SELECT d.id, d.id || '_' || p.puc_code || '_' || o.orchard_code || '_' || c.cultivar_name || '_' || to_char(d.date_delivered, 'YYYY-MM-DD') as delivery_code
        FROM rmt_deliveries d
        join farms f on f.id=d.farm_id
        join pucs p on p.id=d.puc_id
        join orchards o on o.id=d.orchard_id
        join cultivars c on c.id=d.cultivar_id
        where delivery_tipped is false
        order by id desc
        limit 20
      SQL
      DB[qry].all.map { |p| [p[:delivery_code], p[:id]] }
    end

    def get_bin_delivery(id)
      qry = <<~SQL
        SELECT d.id,f.farm_code,p.puc_code, o.orchard_code, c.cultivar_name, to_char(d.date_delivered, 'YYYY-MM-DD') as date_delivered, to_char(d.date_picked, 'YYYY-MM-DD') as date_picked
        ,(select sum(qty_bins) from rmt_bins where rmt_delivery_id=d.id and bin_tipped is true) as qty_bins_tipped
        ,(select count(id) from rmt_bins where rmt_delivery_id=d.id) as qty_bins_received
        FROM rmt_deliveries d
        join farms f on f.id=d.farm_id
        join pucs p on p.id=d.puc_id
        join orchards o on o.id=d.orchard_id
        join cultivars c on c.id=d.cultivar_id
        WHERE d.id = ?
      SQL
      DB[qry, id].first
    end

    def latest_delivery
      qry = <<~SQL
        SELECT d.*
        FROM rmt_deliveries d
        ORDER BY id desc
      SQL
      DB[qry].first
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
                                                   { parent_table: :rmt_sizes, columns: [:size_code], flatten_columns: { size_code: :size_code } },
                                                   { parent_table: :pucs, columns: [:puc_code], flatten_columns: { puc_code: :puc_code } },
                                                   { parent_table: :seasons, columns: [:season_code], flatten_columns: { season_code: :season_code } },
                                                   { parent_table: :rmt_classes, columns: [:rmt_class_code], flatten_columns: { rmt_class_code: :class_code } },
                                                   { parent_table: :locations, columns: [:location_long_code], flatten_columns: { location_long_code: :location_long_code } },
                                                   { parent_table: :rmt_container_types, columns: [:container_type_code], flatten_columns: { container_type_code: :container_type_code } },
                                                   { parent_table: :rmt_container_material_types, columns: [:container_material_type_code], flatten_columns: { container_material_type_code: :container_material_type_code } },
                                                   # { parent_table: :party_roles, columns: [:container_material_owner_code], flatten_columns: { container_material_type_code: :container_material_type_code } },
                                                   { parent_table: :cultivars,
                                                     foreign_key: :cultivar_id,
                                                     flatten_columns: { cultivar_code: :cultivar_code,
                                                                        cultivar_name: :cultivar_name,
                                                                        commodity_id: :commodity_id } },
                                                   { parent_table: :commodities, foreign_key: :commodity_id, flatten_columns: { code: :commodity_code } }],
                                   lookup_functions: [{ function: :fn_current_status,
                                                        args: ['rmt_bins', :id],
                                                        col_name: :status }])

      return nil if hash.nil?

      hash[:asset_number] = hash[:bin_asset_number] || hash[:shipped_asset_number] || hash[:tipped_asset_number] || hash[:scrapped_bin_asset_number]
      hash[:received] = get(:rmt_deliveries, hash[:rmt_delivery_id], :received)
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

    def rebin_details(id)
      query = <<~SQL
        select b.id, c.cultivar_name, cg.cultivar_group_code, f.farm_code, p.puc_code, o.orchard_code, b.rmt_delivery_id, b.bin_fullness
        , b.rmt_container_type_id, b.rmt_container_material_type_id, b.rmt_material_owner_party_role_id, b.qty_bins
        , b.rmt_class_id, b.production_run_rebin_id, r.production_line_id, s.season_code, b.gross_weight
        from rmt_bins b
        join production_runs r on r.id=b.production_run_rebin_id
        join cultivars c on c.id=b.cultivar_id
        join cultivar_groups cg on cg.id=c.cultivar_group_id
        join farms f on f.id=b.farm_id
        join pucs p on p.id=b.puc_id
        join orchards o on o.id=b.orchard_id
        join seasons s on s.id=b.season_id
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

    def rebin_label_printing_instance(id)
      DB[:vw_rebin_label].where(id: id).first
    end

    def find_pallet_sequences_for_by_bin_assets(bin_asset_numbers)
      DB[:rmt_bins]
        .join(:pallet_sequences, source_bin_id: :id)
        .where(bin_asset_number: bin_asset_numbers)
        .select_map(:bin_asset_number)
    end

    def get_line_packhouse_resource(line_resource_id) # rubocop:disable Metrics/AbcSize
      DB[Sequel[:plant_resources].as(:l)]
        .join(:tree_plant_resources, descendant_plant_resource_id: :id)
        .join(Sequel[:plant_resources].as(:p), id: :ancestor_plant_resource_id)
        .join(Sequel[:plant_resource_types].as(:tp), id: Sequel[:p][:plant_resource_type_id])
        .where(Sequel[:l][:id] => line_resource_id)
        .where(Sequel[:tp][:plant_resource_type_code] => Crossbeams::Config::ResourceDefinitions::PACKHOUSE)
        .select(Sequel[:p][:id], Sequel[:p][:location_id])
        .first
        .to_h
    end

    def registered_orchard_by_puc_orchard_and_cultivar(puc_id, orchard_id, cultivar_id) # rubocop:disable Metrics/AbcSize
      DB[:registered_orchards]
        .join(:pucs, puc_code: :puc_code)
        .join(:orchards, orchard_code: Sequel[:registered_orchards][:orchard_code])
        .join(:cultivars, cultivar_code: Sequel[:registered_orchards][:cultivar_code])
        .where(marketing_orchard: true, Sequel[:pucs][:id] => puc_id, Sequel[:orchards][:id] => orchard_id, Sequel[:cultivars][:id] => cultivar_id)
        .get(Sequel[:registered_orchards][:id])
    end

    def find_suggested_runs_for_untipped_bins(selection)
      qry = <<~SQL
        WITH
          tipped_bin_runs AS (
            SELECT DISTINCT
              rmt_delivery_id,
              production_runs.started_at,
              production_run_tipped_id AS run_id
            FROM rmt_bins
            JOIN production_runs on production_runs.id=rmt_bins.production_run_tipped_id
            WHERE rmt_bins.bin_tipped order by rmt_delivery_id),

          tipped_bin_runs_grp AS (
            SELECT
              rmt_bins.id as bin_id,
              rmt_bins.rmt_delivery_id,
              ARRAY_AGG(DISTINCT run_id) AS matching_run_ids,
              (select run_id from tipped_bin_runs i where i.rmt_delivery_id=rmt_bins.rmt_delivery_id order by (ABS(started_at::timestamp::date - rmt_bins.bin_received_date_time::timestamp::date)) asc limit 1) as suggested_tip_run_id,
              (select started_at from tipped_bin_runs i where i.rmt_delivery_id=rmt_bins.rmt_delivery_id order by (ABS(started_at::timestamp::date - rmt_bins.bin_received_date_time::timestamp::date)) asc limit 1) as suggested_tip_run_start_date
            FROM rmt_bins
            JOIN tipped_bin_runs o on o.rmt_delivery_id=rmt_bins.rmt_delivery_id
            WHERE NOT rmt_bins.bin_tipped
            GROUP BY bin_id, rmt_bins.rmt_delivery_id),

          untipped_bin_runs AS (
            SELECT
              rmt_bins.id as bin_id,
              production_runs.id AS run_id,
              production_runs.started_at ,
              ABS(production_runs.started_at::timestamp::date - rmt_bins.bin_received_date_time::timestamp::date) AS days_apart
            FROM rmt_bins
            LEFT JOIN cultivars ON rmt_bins.cultivar_id = cultivars.id
            LEFT JOIN production_runs ON rmt_bins.farm_id = production_runs.farm_id
            AND rmt_bins.puc_id = production_runs.puc_id
            AND rmt_bins.orchard_id = production_runs.orchard_id
            AND (rmt_bins.cultivar_group_id = production_runs.cultivar_group_id or cultivars.cultivar_group_id = production_runs.cultivar_group_id)
            WHERE NOT rmt_bins.bin_tipped),

          untipped_bin_runs_grp AS (
            SELECT
              bin_id,
              ARRAY_AGG(DISTINCT run_id) AS matching_run_ids,
              (select run_id from untipped_bin_runs i where o.bin_id=i.bin_id order by days_apart asc limit 1) as suggested_tip_run_id,
              (select started_at from untipped_bin_runs i where o.bin_id=i.bin_id order by days_apart asc limit 1) as suggested_tip_run_start_date
            FROM untipped_bin_runs o
            GROUP BY bin_id)

          SELECT
            vw_bins.id, vw_bins.bin_asset_number, vw_bins.bin_received_date_time, vw_bins.cultivar_name, vw_bins.farm_code,
            vw_bins.puc_code, vw_bins.orchard_code, vw_bins.rmt_delivery_id, '' as enter_tip_run_id,
            COALESCE(tipped_bin_runs_grp.suggested_tip_run_id, untipped_bin_runs_grp.suggested_tip_run_id) AS suggested_tip_run_id,
            CASE
              WHEN tipped_bin_runs_grp.matching_run_ids IS NOT NULL THEN 'delivery runs'
              WHEN untipped_bin_runs_grp.matching_run_ids IS NOT NULL THEN 'runs only'
            END matching_method,
            ABS(vw_bins.bin_received_date_time::timestamp::date - COALESCE(tipped_bin_runs_grp.suggested_tip_run_start_date, untipped_bin_runs_grp.suggested_tip_run_start_date)::timestamp::date) AS days_apart,
            CASE
              WHEN COALESCE(tipped_bin_runs_grp.suggested_tip_run_id, untipped_bin_runs_grp.suggested_tip_run_id) IS NOT NULL
              THEN COALESCE(tipped_bin_runs_grp.matching_run_ids, untipped_bin_runs_grp.matching_run_ids)
              ELSE NULL
            END matching_run_ids,
            fn_production_run_code(COALESCE(tipped_bin_runs_grp.suggested_tip_run_id, untipped_bin_runs_grp.suggested_tip_run_id)) AS suggested_tip_run_code,
            COALESCE(tipped_bin_runs_grp.suggested_tip_run_start_date, untipped_bin_runs_grp.suggested_tip_run_start_date) AS suggested_tip_run_start_date,
            cultivar_id, farm_id, puc_id, orchard_id
          FROM vw_bins
          LEFT JOIN tipped_bin_runs_grp on tipped_bin_runs_grp.bin_id=vw_bins.id
          LEFT JOIN untipped_bin_runs_grp on untipped_bin_runs_grp.bin_id=vw_bins.id
          WHERE NOT vw_bins.bin_tipped AND id IN(#{selection.join(',')})
          ORDER BY id desc
      SQL
      DB[qry].all
    end

    def delivery_tripsheet_discreps(delivery_id)
      query = <<~SQL
        SELECT rmt_bins.id AS bin_id, vehicle_job_units.id AS vehicle_job_unit_id
        FROM rmt_bins
        LEFT JOIN vehicle_job_units ON vehicle_job_units.stock_item_id = rmt_bins.id
        WHERE rmt_bins.rmt_delivery_id = ? AND vehicle_job_units.id IS NULL

        UNION

        SELECT rmt_bins.id AS bin_id, vehicle_job_units.id AS vehicle_job_unit_id
        FROM vehicle_job_units
        JOIN vehicle_jobs ON vehicle_jobs.id=vehicle_job_units.vehicle_job_id
        LEFT JOIN rmt_bins ON rmt_bins.id = vehicle_job_units.stock_item_id
        WHERE vehicle_jobs.rmt_delivery_id = ? AND rmt_bins.id IS NULL
      SQL
      DB[query, delivery_id, delivery_id].all
    end

    def delivery_tripsheets(delivery_id)
      DB[:rmt_deliveries]
        .join(:rmt_bins, rmt_delivery_id: :id)
        .join(:vehicle_job_units, stock_item_id: :id)
        .join(:vehicle_jobs, id: :vehicle_job_id)
        .where(Sequel[:rmt_deliveries][:id] => delivery_id, Sequel[:vehicle_jobs][:offloaded_at] => nil)
        .select_map(Sequel[:vehicle_jobs][:id])
        .uniq
    end

    def tripsheet_bins(vehicle_job_id)
      query = <<~SQL
        SELECT u.*, b.bin_asset_number
        FROM  vehicle_job_units u
        JOIN rmt_bins b on b.id=u.stock_item_id
        WHERE u.vehicle_job_id = ?
      SQL
      DB[query, vehicle_job_id]
    end
  end
end
