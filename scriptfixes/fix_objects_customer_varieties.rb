# frozen_string_literal: true

# What this script does:
# ----------------------
# updates customer_variety_id for objects i.e carton_labels, cartons and pallet_sequences
# with customer_variety_id value but its product_setups.customer_variety_id is null
#
# Reason for this script:
# -----------------------
# changed customer_variety_id (customer_varieties.id) from customer_variety_variety_id (customer_variety_varieties.id)
# on product_setups, carton_labels, cartons and pallet_sequences
#
class FixObjectsCustomerVarieties < BaseScript
  def run # rubocop:disable Metrics/AbcSize, Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
    query = <<~SQL
      SELECT DISTINCT customer_variety_id
      FROM carton_labels
      WHERE customer_variety_id NOT IN (SELECT customer_variety_id
                                        FROM customer_variety_varieties)
      UNION
      SELECT DISTINCT customer_variety_id
            FROM cartons
            WHERE customer_variety_id NOT IN (SELECT customer_variety_id
                                              FROM customer_variety_varieties)
      UNION
      SELECT DISTINCT customer_variety_id
            FROM pallet_sequences
            WHERE customer_variety_id NOT IN (SELECT customer_variety_id
                                              FROM customer_variety_varieties);
    SQL
    objects = DB[query].all
    return failed_response('There are no objects to fix') if objects.empty?

    customer_variety_variety_ids = objects.map { |r| r[:customer_variety_id] }
    p "Records affected: #{customer_variety_variety_ids.count}"

    text_data = []
    objects.each do |object|
      customer_variety_variety_id = object[:customer_variety_id]
      next if customer_variety_variety_id.nil_or_empty?

      customer_variety_id = DB["SELECT customer_variety_id FROM customer_variety_varieties WHERE id = #{customer_variety_variety_id}"].get(:customer_variety_id)
      attrs = { customer_variety_id: customer_variety_id }

      carton_label_ids = DB["SELECT id FROM carton_labels WHERE customer_variety_id = #{customer_variety_variety_id}"].map { |r| r[:id] }
      carton_ids = DB["SELECT id FROM cartons WHERE customer_variety_id = #{customer_variety_variety_id}"].map { |r| r[:id] }
      pallet_sequence_ids = DB["SELECT id FROM pallet_sequences WHERE customer_variety_id = #{customer_variety_variety_id}"].map { |r| r[:id] }

      str = "updated carton_labels : #{carton_label_ids.join(',')} : #{attrs} \n
                     cartons : #{carton_ids.join(',')} : #{attrs} \n
                     pallet_sequences : #{pallet_sequence_ids.join(',')} : #{attrs} \n"

      text_data << str

      if debug_mode
        p str
      else
        DB.transaction do
          p str
          DB[:carton_labels].where(id: carton_label_ids).update(attrs) unless carton_label_ids.nil_or_empty?
          DB[:cartons].where(id: carton_ids).update(attrs) unless carton_ids.nil_or_empty?
          DB[:pallet_sequences].where(id: pallet_sequence_ids).update(attrs) unless pallet_sequence_ids.nil_or_empty?
          # log_multiple_statuses(:carton_labels, carton_label_ids.uniq, 'FIXED CUSTOMER VARIETY ID', user_name: 'System')
          # log_multiple_statuses(:cartons, carton_ids.uniq, 'FIXED CUSTOMER VARIETY ID', user_name: 'System')
          # log_multiple_statuses(:pallet_sequences, pallet_sequence_ids.uniq, 'FIXED CUSTOMER VARIETY ID', user_name: 'System')
        end
      end
    end

    infodump = <<~STR
      Script: FixObjectsCustomerVarieties

      What this script does:
      ----------------------
      updates customer_variety_id for objects i.e carton_labels, cartons and pallet_sequences
      with customer_variety_id value but its product_setups.customer_variety_id is null

      Reason for this script:
      -----------------------
      changed customer_variety_id (customer_varieties.id) from customer_variety_variety_id (customer_variety_varieties.id)
      on product_setups, carton_labels, cartons and pallet_sequences

      Results:
      --------
      #{text_data.join("\n\n")}
    STR

    unless objects.nil_or_empty?
      log_infodump(:data_fix,
                   :customer_variety_id,
                   :update_objects_customer_variety_id,
                   infodump)
    end

    if debug_mode
      success_response('Dry run complete')
    else
      success_response('Objects customer variety ids updated successfully')
    end
  end
end
