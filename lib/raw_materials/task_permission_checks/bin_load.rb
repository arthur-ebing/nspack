# frozen_string_literal: true

module RawMaterialsApp
  module TaskPermissionCheck
    class BinLoad < BaseService
      attr_reader :repo, :task, :id, :params, :bin_load
      def initialize(task, id = nil, params = nil)
        @repo = BinLoadRepo.new
        @task = task
        @id = id
        @params = params
        @bin_load = id ? repo.find_bin_load_flat(id) : nil
      end

      CHECKS = {
        create: :create_check,
        edit: :edit_check,
        delete: :delete_check,
        reopen: :reopen_check,
        complete: :complete_check,
        ship: :ship_check,
        unship: :unship_check
      }.freeze

      def call
        return failed_response 'Bin load record not found' unless bin_load || task == :create

        check = CHECKS[task]
        raise ArgumentError, "Task \"#{task}\" is unknown for #{self.class}" if check.nil?

        send(check)
      end

      private

      def create_check
        all_ok
      end

      def edit_check
        return failed_response "Bin load:#{id} has been completed" if completed?

        all_ok
      end

      def delete_check
        return failed_response "Bin load:#{id} has been completed" if completed?

        all_ok
      end

      def reopen_check
        return failed_response "Bin load:#{id} has not been completed" unless completed?

        all_ok
      end

      def complete_check
        return failed_response "Bin load:#{id} - Product Qty's do not match load Qty" unless bin_load.qty_bins == bin_load.qty_product_bins
        return failed_response "Bin load:#{id} - Does not have products" unless products?
        return failed_response "Bin load:#{id} - has already been completed" if completed?

        all_ok
      end

      def ship_check
        return failed_response "Bin load:#{id} - has already been shipped" if shipped?
        return failed_response "Bin load:#{id} - Incorrect bins allocated" unless correctly_allocated?

        all_ok
      end

      def unship_check
        return failed_response "Bin load:#{id} - has not been shipped" unless shipped?

        all_ok
      end

      def qty_product_bins
        repo.select_values(:bin_load_products, :qty_bins, bin_load_id: id).sum
      end

      def completed?
        bin_load.completed
      end

      def products?
        bin_load.products
      end

      def shipped?
        bin_load.shipped
      end

      def correctly_allocated?
        bin_load_products = repo.select_values(:bin_load_products, %i[id qty_bins], bin_load_id: id)
        bin_load_products.each do |bin_load_product_id, qty_bins|
          return false unless qty_bins == repo.select_values(:rmt_bins, :qty_bins, bin_load_product_id: bin_load_product_id).sum
        end
        true
      end
    end
  end
end
