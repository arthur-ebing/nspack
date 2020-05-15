# frozen_string_literal: true

# What this script does:
# ----------------------
#  1. updates product_setups.customer_variety_id updated before 05/05/2020
#  2. updates customer_variety_id for product_setups' objects  i.e carton_labels, cartons and pallet_sequences
#
# Reason for this script:
# -----------------------
# changed customer_variety_id (customer_varieties.id) from customer_variety_variety_id (customer_variety_varieties.id)
# on product_setups, carton_labels, cartons and pallet_sequences
#
class FixProductSetupCustomerVarieties < BaseScript
  def run  # rubocop:disable Metrics/AbcSize, Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
    query = <<~SQL
      SELECT id, customer_variety_id
      FROM product_setups
      WHERE customer_variety_id IS NOT NULL
        AND updated_at < '2020-05-06';
    SQL
    product_setups = DB[query].all
    return failed_response('There are no product_setups to fix') if product_setups.empty?

    product_setup_ids = product_setups.map { |r| r[:id] }
    p "Records affected: #{product_setup_ids.count}"

    text_data = []
    product_setups.each do |product_setup|
      product_setup_id = product_setup[:id]
      customer_variety_id = DB["SELECT customer_variety_id FROM customer_variety_varieties WHERE id = #{product_setup[:customer_variety_id]}"].get(:customer_variety_id)
      attrs = { customer_variety_id: customer_variety_id }
      text_data << "updated product setup : #{product_setup_id} : #{attrs} \n"

      product_resource_allocation_ids = DB["SELECT distinct id FROM product_resource_allocations WHERE product_setup_id = #{product_setup_id}"].map { |r| r[:id] }
      unless product_resource_allocation_ids.nil_or_empty?
        carton_label_ids = DB["SELECT id FROM carton_labels WHERE product_resource_allocation_id IN (#{product_resource_allocation_ids.join(',')})"].map { |r| r[:id] }
        carton_ids = DB["SELECT id FROM cartons WHERE product_resource_allocation_id IN (#{product_resource_allocation_ids.join(',')})"].map { |r| r[:id] }
        pallet_sequence_ids = DB["SELECT id FROM pallet_sequences WHERE product_resource_allocation_id IN (#{product_resource_allocation_ids.join(',')})"].map { |r| r[:id] }

        str = "carton_labels : #{carton_label_ids.join(',')} : #{attrs} \n
               cartons : #{carton_ids.join(',')} : #{attrs} \n
               pallet_sequences : #{pallet_sequence_ids.join(',')} : #{attrs} \n"
      end

      text_data << str

      if debug_mode
        p str
      else
        DB.transaction do
          p str
          DB[:product_setups].where(id: product_setup_id).update(attrs)
          DB[:carton_labels].where(id: carton_label_ids).update(attrs) unless carton_label_ids.nil_or_empty?
          DB[:cartons].where(id: carton_ids).update(attrs) unless carton_ids.nil_or_empty?
          DB[:pallet_sequences].where(id: pallet_sequence_ids).update(attrs) unless pallet_sequence_ids.nil_or_empty?
          # log_status(:product_setups, product_setup_id, 'FIXED CUSTOMER VARIETY ID', user_name: 'System')
          # log_multiple_statuses(:carton_labels, carton_label_ids.uniq, 'FIXED CUSTOMER VARIETY ID', user_name: 'System')
          # log_multiple_statuses(:cartons, carton_ids.uniq, 'FIXED CUSTOMER VARIETY ID', user_name: 'System')
          # log_multiple_statuses(:pallet_sequences, pallet_sequence_ids.uniq, 'FIXED CUSTOMER VARIETY ID', user_name: 'System')
        end
      end
    end

    infodump = <<~STR
      Script: FixProductSetupCustomerVarieties

      What this script does:
      ----------------------
      1. updates product_setups.customer_variety_id
      2. updates customer_variety_id for objects created before 05/05/2020 i.e carton_labels, cartons and pallet_sequences

      Reason for this script:
      -----------------------
      changed customer_variety_id (customer_varieties.id) from customer_variety_variety_id (customer_variety_varieties.id)
      on product_setups, carton_labels, cartons and pallet_sequences

      Results:
      --------
      #{text_data.join("\n\n")}
    STR

    unless product_setups.nil_or_empty?
      log_infodump(:data_fix,
                   :customer_variety_id,
                   :update_product_setups_customer_variety_id,
                   infodump)
    end

    if debug_mode
      success_response('Dry run complete')
    else
      success_response('Product_setups customer variety ids updated successfully')
    end
  end
end
