# frozen_string_literal: true

module FinishedGoodsApp
  class ProcessOrderLines < BaseService # rubocop:disable Metrics/ClassLength
    attr_reader :repo, :user
    attr_accessor :load_id, :order_id

    def initialize(user, args)
      @repo = OrderRepo.new
      @load_id = args[:load_id]
      @order_id = args[:order_id] || DB[:orders_loads].where(load_id: @load_id).get(:order_id)
      @load_id ||= DB[:orders_loads].where(order_id: @order_id).get(:load_id)
      @user = user
    end

    def call
      return failed_response('No order_id found') if order_id.nil?

      create_order_items
      delete_orphaned_order_items_pallet_sequences
      success_response('Updated Order Lines')
    end

    private

    def create_order_items # rubocop:disable Metrics/AbcSize
      current_order_items = DB[:order_items].where(order_id: order_id).all

      compile_order_items_from_pallet_sequences.each do |order_item|
        order_item_id = nil
        pallet_sequence_ids = order_item.delete(:pallet_sequence_ids)
        # treatment_ids = Array(order_item[:treatment_ids] || [0])
        # treatment_ids.sort.each do |treatment_id|
        #   order_item[:treatment_id] = treatment_id.zero? ? nil : treatment_id
        order_item = OrderItemSchema.call(order_item).to_h
        next unless current_order_items

        current_order_items.each do |item|
          item = OrderItemSchema.call(item).to_h

          item_id = item.delete(:id)
          compare = item.compact.reject { |k| %i[order_id carton_quantity price_per_carton price_per_kg].include?(k) }
          if order_item.slice(*compare.keys) == compare
            order_item_id = item_id
            break
          end
        end
        # end

        order_item_id ||= create_order_item(order_item)
        link_order_items_pallet_sequences(order_item_id, pallet_sequence_ids)
      end
    end

    def link_order_items_pallet_sequences(order_item_id, pallet_sequence_ids)
      Array(pallet_sequence_ids).each do |pallet_sequence_id|
        id, current_order_item_id = DB[:order_items_pallet_sequences].where(pallet_sequence_id: pallet_sequence_id).get(%i[id order_item_id])
        if current_order_item_id != order_item_id
          repo.delete(:order_items_pallet_sequences, id)
          id = nil
        end
        repo.create(:order_items_pallet_sequences, pallet_sequence_id: pallet_sequence_id, order_item_id: order_item_id) if id.nil?
      end
    end

    def create_order_item(params)
      res = OrderItemSchema.call(params)
      raise Crossbeams::InfoError, validation_failed_response(res).errors if res.failure?

      id = repo.create(:order_items, res)
      repo.log_status(:order_items, id, 'CREATED FROM LOAD', user_name: user.user_name)
      id
    end

    def delete_orphaned_order_items_pallet_sequences
      ids = DB[:order_items_pallet_sequences]
            .join(:pallet_sequences, id: :pallet_sequence_id)
            .join(:pallets, id: :pallet_id)
            .where(load_id: nil)
            .select_map(Sequel[:order_items_pallet_sequences][:id])

      repo.delete(:order_items_pallet_sequences, ids)
    end

    def compile_order_items_from_pallet_sequences
      query = <<~SQL
        SELECT
            orders_loads.order_id,
            orders_loads.load_id,
            ARRAY_AGG(pallet_sequences.id) AS pallet_sequence_ids,
            cultivars.commodity_id,
            pallet_sequences.basic_pack_code_id AS basic_pack_id,
            pallet_sequences.standard_pack_code_id AS standard_pack_id,
            pallet_sequences.fruit_actual_counts_for_pack_id AS actual_count_id,
            pallet_sequences.fruit_size_reference_id AS size_reference_id,
            pallet_sequences.inventory_code_id AS inventory_id,
            pallet_sequences.grade_id,
            pallet_sequences.mark_id,
            pallet_sequences.marketing_variety_id,
            pallet_sequences.carton_quantity,
            pallet_sequences.sell_by_code,
            pallet_sequences.pallet_format_id,
            pallet_sequences.pm_mark_id,
            pallet_sequences.pm_bom_id,
            pallet_sequences.rmt_class_id,
            pallet_sequences.treatment_ids AS treatment_ids,
            SUM(pallet_sequences.carton_quantity) AS carton_quantity,
            null AS price_per_carton,
            null AS price_per_kg
        FROM orders
        JOIN orders_loads ON orders.id = orders_loads.order_id
        JOIN loads ON loads.id = orders_loads.load_id
        JOIN pallets ON pallets.load_id = loads.id
        LEFT JOIN pallet_sequences ON pallet_sequences.pallet_id = pallets.id
        LEFT JOIN cultivars ON pallet_sequences.cultivar_id = cultivars.id

        WHERE orders.id = ?
        GROUP BY
            orders_loads.order_id,
            orders_loads.load_id,
            cultivars.commodity_id,
            pallet_sequences.basic_pack_code_id,
            pallet_sequences.standard_pack_code_id,
            pallet_sequences.fruit_actual_counts_for_pack_id,
            pallet_sequences.fruit_size_reference_id,
            pallet_sequences.inventory_code_id,
            pallet_sequences.grade_id,
            pallet_sequences.mark_id,
            pallet_sequences.marketing_variety_id,
            pallet_sequences.carton_quantity,
            pallet_sequences.sell_by_code,
            pallet_sequences.pallet_format_id,
            pallet_sequences.pm_mark_id,
            pallet_sequences.pm_bom_id,
            pallet_sequences.rmt_class_id,
            pallet_sequences.treatment_ids
      SQL
      DB[query, order_id].all
    end
  end
end
