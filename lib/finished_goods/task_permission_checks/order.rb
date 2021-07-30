# frozen_string_literal: true

module FinishedGoodsApp
  module TaskPermissionCheck
    class Order < BaseService
      attr_reader :task, :entity, :order_id, :repo
      def initialize(task, order_id = nil)
        @task = task
        @repo = OrderRepo.new
        @order_id = order_id
        @entity = @order_id ? @repo.find_order(@order_id) : nil
      end

      CHECKS = {
        create: :create_check,
        edit: :edit_check,
        delete: :delete_check,
        ship: :ship_check
      }.freeze

      def call
        return failed_response 'Order record not found' unless @entity || task == :create

        check = CHECKS[task]
        raise ArgumentError, "Task \"#{task}\" is unknown for #{self.class}" if check.nil?

        send(check)
      end

      private

      def create_check
        all_ok
      end

      def edit_check
        return failed_response 'Unable to edit, some loads on this Orders have already been shipped.' if entity.shipping

        all_ok
      end

      def delete_check
        all_ok
      end

      def ship_check
        return failed_response 'Not all Loads on this order have been Shipped.' unless all_order_loads_shipped?
        return failed_response 'Required order carton quantities not fulfilled.' unless order_quantity_fulfilled?

        all_ok
      end

      def all_order_loads_shipped?
        repo.all_order_loads_shipped?(order_id)
      end

      def order_quantity_fulfilled?
        repo.order_quantity_fulfilled?(order_id)
      end
    end
  end
end
