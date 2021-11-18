# frozen_string_literal: true

# What this script does:
# ----------------------
# Loops through the wo_fullfillment_queue records and
# 1. calculates the total quantity of cartons across all pallet_sequences for each work_order_item matching on season_id
# 2. updates work_order_item.quantity_produced
# 3. sends an email for each work order item within wo_fulfillment_pallet_warning_level
#
# Reason for this script:
# -----------------------
# Work order item fulfillment process
#
# To run:
# -------
# Debug : DEBUG=y RACK_ENV=production ruby scripts/base_script.rb ProcessWoFulfillmentQueue
# Live  : RACK_ENV=production ruby scripts/base_script.rb ProcessWoFulfillmentQueue
# Dev   : ruby scripts/base_script.rb ProcessWoFulfillmentQueue
#
class ProcessWoFulfillmentQueue < BaseScript
  attr_reader :repo, :queue_ids, :email_list, :work_order_item_code, :work_order_item_ids

  def run # rubocop:disable Metrics/AbcSize
    @repo = DevelopmentApp::UserRepo.new
    @email_list = repo.email_addresses(user_email_group: AppConst::EMAIL_WORK_ORDER_MANAGERS)

    @work_order_item_ids = []
    DB.transaction do
      @queue_ids = repo.select_values(:wo_fulfillment_queue, :id)

      unless queue_ids.empty?
        work_order_item_ids_for_fulfillment(queue_ids).each do |work_order_item_id, woi_code|
          @work_order_item_code = woi_code
          repo.update(:work_order_items, work_order_item_id, carton_qty_produced: quantity_produced_for(work_order_item_id))
          if pallet_warning_level_reached?(work_order_item_id)
            work_order_item_ids << work_order_item_id
            send_warning_notification_email
          end
        end
        DB[:wo_fulfillment_queue].where(id: queue_ids).delete

        infodump
      end

      success_response('ok')
    end
  rescue StandardError => e
    failed_response(e.message)
  end

  private

  def work_order_item_ids_for_fulfillment(queue_ids)
    DB[:wo_fulfillment_queue]
      .where(id: queue_ids)
      .distinct
      .select(:work_order_item_id,
              Sequel.function(:fn_work_order_item_code, :work_order_item_id).as('work_order_item_code'))
      .map(%i[work_order_item_id work_order_item_code])
  end

  def quantity_produced_for(work_order_item_id)
    DB[:pallet_sequences]
      .where(work_order_item_id: work_order_item_id)
      .where(season_id: DB[:work_order_items]
                          .join(:work_orders, id: Sequel[:work_order_items][:work_order_id])
                          .join(:marketing_orders, id: :marketing_order_id)
                          .where(Sequel[:work_order_items][:id] => work_order_item_id)
                          .get(:season_id))
      .sum(:carton_quantity).to_i
  end

  def pallet_warning_level_reached?(work_order_item_id)
    DB.get(Sequel.function(:fn_woi_pallets_outstanding, work_order_item_id)) < AppConst::CR_FG.wo_fulfillment_pallet_warning_level
  end

  def send_warning_notification_email
    return if email_list.empty?

    mail_opts = {
      to: format_recipients,
      subject: "WO almost fulfilled: #{work_order_item_code}",
      body: body
    }
    DevelopmentApp::SendMailJob.enqueue(mail_opts)
  end

  def format_recipients
    email_list.map { |r| "#{r.first} <#{r.last}>" }
  end

  def body
    <<~STR
      Work order item #{work_order_item_code} is within #{AppConst::CR_FG.wo_fulfillment_pallet_warning_level} pallets of being fulfilled.
    STR
  end

  def infodump
    infodump = <<~STR
      Script: ProcessWoFulfillmentQueue

      Reason for this script:
      -----------------------
      Work order item fulfillment process
      Loops through the wo_fullfillment_queue records and
      1. calculates the total quantity of cartons across all pallet_sequences for each work_order_item matching on season_id
      2. updates work_order_item.quantity_produced
      3. sends an email for each work order item within wo_fulfillment_pallet_warning_level

      Results:
      --------
      output:
      queued wo_fulfillment_queue ids = #{queue_ids}
      work_order_items ids close to fulfillment = #{work_order_item_ids}

    STR
    log_infodump(:work_orders,
                 :process_wo_fulfillment_queue,
                 :queue_processor,
                 infodump)
  end
end
