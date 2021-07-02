# frozen_string_literal: true

module RawMaterialsApp
  class BinLoadRepo < BaseRepo # rubocop:disable Metrics/ClassLength
    build_for_select :bin_load_purposes, label: :purpose_code, value: :id, order_by: :purpose_code
    build_inactive_select :bin_load_purposes, label: :purpose_code,  value: :id, order_by: :purpose_code
    crud_calls_for :bin_load_purposes, name: :bin_load_purpose, wrapper: BinLoadPurpose
    build_for_select :bin_loads,  label: :id, value: :id, order_by: :id
    build_inactive_select :bin_loads, label: :id,  value: :id, order_by: :id
    crud_calls_for :bin_loads, name: :bin_load, wrapper: BinLoad
    build_for_select :bin_load_products,  label: :id,  value: :id,  order_by: :id
    build_inactive_select :bin_load_products, label: :id,  value: :id,  order_by: :id
    crud_calls_for :bin_load_products, name: :bin_load_product, wrapper: BinLoadProduct

    def find_bin_load_flat(id)
      hash = find_with_association(:bin_loads, id,
                                   parent_tables: [{ parent_table: :bin_load_purposes, foreign_key: :bin_load_purpose_id, columns: %i[purpose_code], flatten_columns: { purpose_code: :purpose_code } },
                                                   { parent_table: :depots,  foreign_key: :dest_depot_id, columns: %i[depot_code], flatten_columns: { depot_code: :dest_depot } }],
                                   lookup_functions: [{ function: :fn_party_role_name, args: [:customer_party_role_id], col_name: :customer },
                                                      { function: :fn_party_role_name, args: [:transporter_party_role_id], col_name: :transporter },
                                                      { function: :fn_current_status, args: ['bin_loads', :id], col_name: :status }])
      return nil if hash.nil?

      hash[:products] = exists?(:bin_load_products, bin_load_id: id)
      hash[:allocated] = exists?(:rmt_bins, bin_load_product_id: select_values(:bin_load_products, :id, bin_load_id: id))
      hash[:qty_product_bins] = select_values(:bin_load_products, :qty_bins, bin_load_id: id).sum
      BinLoadFlat.new(hash)
    end

    def find_bin_load_product_flat(id)
      hash = find_with_association(:bin_load_products, id,
                                   parent_tables: [{ parent_table: :bin_loads, foreign_key: :bin_load_id, columns: %i[completed shipped], flatten_columns: { completed: :completed, shipped: :shipped } },
                                                   { parent_table: :cultivar_groups, foreign_key: :cultivar_group_id, columns: %i[cultivar_group_code], flatten_columns: { cultivar_group_code: :cultivar_group_code } },
                                                   { parent_table: :cultivars, foreign_key: :cultivar_id, columns: %i[cultivar_name], flatten_columns: { cultivar_name: :cultivar_name } },
                                                   { parent_table: :farms,  foreign_key: :farm_id, columns: %i[farm_code], flatten_columns: { farm_code: :farm_code } },
                                                   { parent_table: :pucs, foreign_key: :puc_id,  columns: %i[puc_code], flatten_columns: { puc_code: :puc_code } },
                                                   { parent_table: :orchards, foreign_key: :orchard_id, columns: %i[orchard_code], flatten_columns: { orchard_code: :orchard_code } },
                                                   { parent_table: :rmt_classes, foreign_key: :rmt_class_id, columns: %i[rmt_class_code], flatten_columns: { rmt_class_code: :rmt_class_code } },
                                                   { parent_table: :rmt_container_material_types, foreign_key: :rmt_container_material_type_id, columns: %i[container_material_type_code], flatten_columns: { container_material_type_code: :container_material_type_code } }],
                                   lookup_functions: [{ function: :fn_current_status, args: ['bin_load_products', :id], col_name: :status },
                                                      { function: :fn_party_role_name, args: [:rmt_material_owner_party_role_id], col_name: :container_material_owner }])
      return nil if hash.nil?

      keys = %i[cultivar_name container_material_type_code container_material_owner farm_code puc_code orchard_code rmt_class_code]
      hash[:product_code] = "#{hash[:cultivar_group_code]}_#{keys.map { |k| hash[k] || '***' }.join('_')}"
      BinLoadProductFlat.new(hash)
    end

    def rmt_bins_matching_bin_load(column, args = {}) # rubocop:disable Metrics/AbcSize
      raise Crossbeams::FrameworkError, "rmt_bins_matching_bin_load(#{args})" if args.values.any?(&:nil?)

      query = <<~SQL
        SELECT DISTINCT
          rmt_bins.id AS bin_id,
          rmt_bins.bin_asset_number,
          bin_load_products.id AS bin_load_product_id,
          bin_load_products.bin_load_id
        FROM rmt_bins
        JOIN cultivars ON rmt_bins.cultivar_id = cultivars.id
        JOIN bin_load_products ON bin_load_products.cultivar_group_id = cultivars.cultivar_group_id

        WHERE rmt_bins.bin_asset_number <> ''
        AND rmt_bins.bin_asset_number IS NOT NULL
        AND rmt_bins.exit_ref IS NULL
        AND (rmt_bins.bin_load_product_id IS NULL OR rmt_bins.bin_load_product_id = bin_load_products.id)
        AND cultivars.cultivar_group_id IN (COALESCE(bin_load_products.cultivar_group_id, cultivars.cultivar_group_id))
        AND rmt_bins.cultivar_id IN (COALESCE(bin_load_products.cultivar_id, rmt_bins.cultivar_id))
        AND COALESCE(rmt_bins.farm_id,0) IN (COALESCE(bin_load_products.farm_id, COALESCE(rmt_bins.farm_id,0)))
        AND COALESCE(rmt_bins.puc_id,0) IN (COALESCE(bin_load_products.puc_id, COALESCE(rmt_bins.puc_id,0)))
        AND COALESCE(rmt_bins.orchard_id,0) IN (COALESCE(bin_load_products.orchard_id, COALESCE(rmt_bins.orchard_id,0)))
        AND COALESCE(rmt_bins.rmt_class_id,0) IN (COALESCE(bin_load_products.rmt_class_id, COALESCE(rmt_bins.rmt_class_id,0)))
        AND COALESCE(rmt_bins.rmt_container_material_type_id,0) IN (COALESCE(bin_load_products.rmt_container_material_type_id, COALESCE(rmt_bins.rmt_container_material_type_id,0)))
        AND COALESCE(rmt_bins.rmt_material_owner_party_role_id,0) IN (COALESCE(bin_load_products.rmt_material_owner_party_role_id, COALESCE(rmt_bins.rmt_material_owner_party_role_id,0)))
      SQL
      query = "#{query} AND UPPER(rmt_bins.bin_asset_number) = UPPER('#{args[:bin_asset_number]}')" unless args[:bin_asset_number].nil?
      query = "#{query} AND bin_load_products.bin_load_id = #{args[:bin_load_id]}" unless args[:bin_load_id].nil?
      query = "#{query} AND bin_load_products.id = #{args[:bin_load_product_id]}" unless args[:bin_load_product_id].nil?
      query = "#{query} AND rmt_bins.id IN (#{args[:bin_id].join(',')})" unless args[:bin_id].nil_or_empty?

      DB[query].map { |q| q[column] }.uniq.first(100)
    end

    def allocate_bins(bin_load_product_id, bin_ids, user)
      return if bin_ids.nil_or_empty?

      qty_bins = get(:bin_load_products, bin_load_product_id, :qty_bins)
      current_qty_rmt_bins = select_values(:rmt_bins, :qty_bins, bin_load_product_id: bin_load_product_id).sum
      new_qty_rmt_bins = select_values(:rmt_bins, :qty_bins, id: bin_ids).sum
      raise Crossbeams::InfoError, 'Bin allocation exceeded product specification' if (current_qty_rmt_bins + new_qty_rmt_bins) > qty_bins

      update(:rmt_bins, bin_ids, bin_load_product_id: bin_load_product_id)
      log_multiple_statuses(:rmt_bins, bin_ids, 'BIN ALLOCATED ON LOAD', user_name: user.user_name)
    end

    def unallocate_bins(bin_ids, user)
      return if bin_ids.nil_or_empty?

      update(:rmt_bins, bin_ids, bin_load_product_id: nil)
      log_multiple_statuses(:rmt_bins, bin_ids, 'BIN UNALLOCATED FROM LOAD', user_name: user.user_name)
    end

    def ship_bin_load(bin_load_id, user, status = 'SHIPPED')
      params = { shipped: true,
                 shipped_at: Time.now }
      params.merge!(completed: true, completed_at: Time.now) unless get(:bin_loads, bin_load_id, :completed)
      update_bin_load(bin_load_id, params)
      log_status(:bin_loads, bin_load_id, status, user_name: user.user_name)

      bin_load_product_ids = select_values(:bin_load_products, :id, bin_load_id: bin_load_id)
      rmt_bins = select_values(:rmt_bins, %i[id bin_asset_number], bin_load_product_id: bin_load_product_ids)
      rmt_bins.each do |rmt_bin_id, bin_asset_number|
        params = { shipped_asset_number: bin_asset_number,
                   bin_asset_number: nil,
                   exit_ref: 'SHIPPED',
                   exit_ref_date_time: Time.now }
        update(:rmt_bins, rmt_bin_id, params)
        log_status(:rmt_bins, rmt_bin_id, 'BIN DISPATCHED ON LOAD', user_name: user.user_name)
      end
      ship_deliveries(bin_load_id, user)
    end

    def unship_bin_load(bin_load_id, user)
      unship_deliveries(bin_load_id, user)

      unship_bins(bin_load_id, user)

      params = { shipped: false,
                 shipped_at: nil }
      update_bin_load(bin_load_id, params)
      log_status(:bin_loads, bin_load_id, 'UNSHIPPED', user_name: user.user_name)
    end

    def unship_bins(bin_load_id, user)
      bin_load_product_ids = select_values(:bin_load_products, :id, bin_load_id: bin_load_id)
      bin_load_product_ids.each do |bin_load_product_id|
        rmt_bin_ids = select_values(:rmt_bins, :id, bin_load_product_id: bin_load_product_id)
        rmt_bin_ids.each do |rmt_bin_id|
          bin_asset_number = get(:rmt_bins, rmt_bin_id, :shipped_asset_number)
          raise Sequel::UniqueConstraintViolation, "Bin Asset Number #{bin_asset_number} allocated elsewhere, Unable to unship load." if exists?(:rmt_bins, bin_asset_number: bin_asset_number)

          params = { bin_asset_number: bin_asset_number,
                     shipped_asset_number: nil,
                     exit_ref: nil,
                     exit_ref_date_time: nil }
          update(:rmt_bins, rmt_bin_id, params)
          log_status(:rmt_bins, rmt_bin_id, 'UNSHIPPED', user_name: user.user_name)
        end
      end
    end

    def ship_deliveries(bin_load_id, user) # rubocop:disable Metrics/AbcSize
      ds = DB[:rmt_deliveries].join(:rmt_bins, rmt_delivery_id: :id).join(:bin_load_products, id: :bin_load_product_id).join(:bin_loads, id: :bin_load_id)
      rmt_delivery_ids = ds.where(Sequel[:bin_loads][:id] => bin_load_id).select_map(Sequel[:rmt_deliveries][:id]).uniq
      rmt_delivery_ids.each do |rmt_delivery_id|
        delivery_shipped = get(:rmt_deliveries, rmt_delivery_id, :shipped)
        next if delivery_shipped

        ship_delivery = ds.where(Sequel[:rmt_deliveries][:id] => rmt_delivery_id).select_map(Sequel[:bin_loads][:shipped]).all?
        next unless ship_delivery

        update(:rmt_deliveries, rmt_delivery_id, shipped: true)
        log_status(:rmt_deliveries, rmt_delivery_id, 'DELIVERY SHIPPED', user_name: user.user_name)
      end
    end

    def unship_deliveries(bin_load_id, user)
      ds = DB[:rmt_deliveries].join(:rmt_bins, rmt_delivery_id: :id).join(:bin_load_products, id: :bin_load_product_id).join(:bin_loads, id: :bin_load_id)
      rmt_delivery_ids = ds.where(Sequel[:bin_loads][:id] => bin_load_id).select_map(Sequel[:rmt_deliveries][:id]).uniq
      rmt_delivery_ids.each do |rmt_delivery_id|
        delivery_shipped = get(:rmt_deliveries, rmt_delivery_id, :shipped)
        next unless delivery_shipped

        update(:rmt_deliveries, rmt_delivery_id, shipped: false)
        log_status(:rmt_deliveries, rmt_delivery_id, 'DELIVERY UNSHIPPED', user_name: user.user_name)
      end
    end

    def rmt_bins_exists?(bin_ids)
      DB[:rmt_bins].where(id: bin_ids).select_map(:id)
    end
  end
end
