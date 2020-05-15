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
                                   parent_tables: [{ parent_table: :bin_load_purposes, foreign_key: :bin_load_purpose, columns: %i[purpose_code], flatten_columns: { purpose_code: :purpose_code } },
                                                   { parent_table: :depots,  foreign_key: :dest_depot_id, columns: %i[depot_code], flatten_columns: { depot_code: :dest_depot } }],
                                   lookup_functions: [{ function: :fn_party_role_name, args: [:customer_party_role_id], col_name: :customer },
                                                      { function: :fn_party_role_name, args: [:transporter_party_role_id], col_name: :transporter },
                                                      { function: :fn_current_status, args: ['bin_loads', :id], col_name: :status }])
      return nil if hash.nil?

      hash[:products] = exists?(:bin_load_products, bin_load_id: id)
      hash[:qty_product_bins] = select_values(:bin_load_products, :qty_bins, bin_load_id: id).reduce(0, :+)
      BinLoadFlat.new(hash)
    end

    def find_bin_load_product_flat(id)
      hash = find_with_association(:bin_load_products, id,
                                   parent_tables: [{ parent_table: :cultivar_groups, foreign_key: :cultivar_group_id, columns: %i[cultivar_group_code], flatten_columns: { cultivar_group_code: :cultivar_group_code } },
                                                   { parent_table: :cultivars, foreign_key: :cultivar_id, columns: %i[cultivar_name], flatten_columns: { cultivar_name: :cultivar_name } },
                                                   { parent_table: :farms,  foreign_key: :farm_id, columns: %i[farm_code], flatten_columns: { farm_code: :farm_code } },
                                                   { parent_table: :pucs, foreign_key: :puc_id,  columns: %i[puc_code], flatten_columns: { puc_code: :puc_code } },
                                                   { parent_table: :orchards, foreign_key: :orchard_id, columns: %i[orchard_code], flatten_columns: { orchard_code: :orchard_code } },
                                                   { parent_table: :rmt_classes, foreign_key: :rmt_class_id, columns: %i[rmt_class_code], flatten_columns: { rmt_class_code: :rmt_class_code } },
                                                   { parent_table: :rmt_container_material_types, foreign_key: :rmt_container_material_type_id, columns: %i[container_material_type_code], flatten_columns: { container_material_type: :container_material_type_code } }],
                                   lookup_functions: [{ function: :fn_current_status, args: ['bin_load_products', :id], col_name: :status },
                                                      { function: :fn_party_role_name, args: [:rmt_material_owner_party_role_id], col_name: :container_material_owner }])
      return nil if hash.nil?

      product_code = hash[:cultivar_group_code]
      keys = %i[cultivar_name container_material_type_code container_material_owner farm_code puc_code orchard_code rmt_class_code]
      keys.each do |k|
        product_code = "#{product_code}_#{hash[k] || '***'}"
      end
      hash[:product_code] = product_code
      BinLoadProductFlat.new(hash)
    end

    def rmt_bins_matching_bin_load(column, args = {}) # rubocop:disable Metrics/AbcSize
      raise Crossbeams::FrameworkError, "rmt_bins_matching_bin_load(#{args})" if args.values.include? nil

      query = <<~SQL
        SELECT DISTINCT
          rmt_bins.bin_asset_number,
          bin_load_products.id AS bin_load_product_id,
          bin_load_products.bin_load_id
        FROM rmt_bins
        JOIN cultivars ON rmt_bins.cultivar_id = cultivars.id
        JOIN bin_load_products ON bin_load_products.cultivar_group_id = cultivars.cultivar_group_id

        WHERE rmt_bins.bin_asset_number <> ''
        AND rmt_bins.exit_ref IS NULL
        AND cultivars.cultivar_group_id IN (COALESCE(bin_load_products.cultivar_group_id, cultivars.cultivar_group_id))
        AND rmt_bins.cultivar_id IN (COALESCE(bin_load_products.cultivar_id, rmt_bins.cultivar_id))
        AND rmt_bins.farm_id IN (COALESCE(bin_load_products.farm_id, rmt_bins.farm_id))
        AND rmt_bins.puc_id IN (COALESCE(bin_load_products.puc_id, rmt_bins.puc_id))
        AND rmt_bins.orchard_id IN (COALESCE(bin_load_products.orchard_id, rmt_bins.orchard_id))
        AND COALESCE(rmt_bins.rmt_class_id,0) IN (COALESCE(bin_load_products.rmt_class_id, COALESCE(rmt_bins.rmt_class_id,0)))
        AND rmt_bins.rmt_container_material_type_id IN (COALESCE(bin_load_products.rmt_container_material_type_id, rmt_bins.rmt_container_material_type_id))
        AND rmt_bins.rmt_material_owner_party_role_id IN (COALESCE(bin_load_products.rmt_material_owner_party_role_id, rmt_bins.rmt_material_owner_party_role_id))
      SQL
      query = "#{query} AND bin_load_products.bin_load_id = #{args[:bin_load_id]}" unless args[:bin_load_id].nil?
      query = "#{query} AND bin_load_products.id = #{args[:bin_load_product_id]}" unless args[:bin_load_product_id].nil?
      query = "#{query} AND rmt_bins.bin_asset_number = #{args[:bin_asset_number]}::TEXT" unless args[:bin_asset_number].nil?
      DB[query].map { |q| q[column] }.uniq
    end

    def ship_bin_load(id, product_bin, user)
      params = { shipped: true,
                 shipped_at: Time.now }
      update_bin_load(id, params)
      log_status(:bin_loads, id, 'SHIPPED', user_name: user.user_name)

      product_bin.each do |bin_load_product_id, bin_asset_number|
        rmt_bin_id = get_id(:rmt_bins, bin_asset_number: bin_asset_number)
        params = { shipped_asset_number: bin_asset_number,
                   bin_asset_number: nil,
                   bin_load_product_id: bin_load_product_id,
                   exit_ref: 'SHIPPED',
                   exit_ref_date_time: Time.now }
        update(:rmt_bins, rmt_bin_id, params)
        log_status(:rmt_bins, rmt_bin_id, 'BIN_DISPATCHED_ON_LOAD', user_name: user.user_name)
      end
    end

    def unship_bin_load(id, user)
      params = { shipped: false,
                 shipped_at: nil,
                 completed: false,
                 completed_at: nil }
      update_bin_load(id, params)
      log_status(:bin_loads, id, 'UNSHIPPED', user_name: user.user_name)

      bin_load_product_ids = select_values(:bin_load_products, :id, bin_load_id: id)
      bin_load_product_ids.each do |bin_load_product_id|
        rmt_bin_ids = select_values(:rmt_bins, :id, bin_load_product_id: bin_load_product_id)
        rmt_bin_ids.each do |rmt_bin_id|
          bin_asset_number = get(:rmt_bins, rmt_bin_id, :shipped_asset_number)
          raise Sequel::UniqueConstraintViolation if exists?(:rmt_bins, bin_asset_number: bin_asset_number)

          params = { bin_asset_number: bin_asset_number,
                     shipped_asset_number: nil,
                     bin_load_product_id: nil,
                     exit_ref: nil,
                     exit_ref_date_time: nil }
          update(:rmt_bins, rmt_bin_id, params)
          log_status(:rmt_bins, rmt_bin_id, 'UNSHIPPED', user_name: user.user_name)
        end
      end
    end
  end
end
