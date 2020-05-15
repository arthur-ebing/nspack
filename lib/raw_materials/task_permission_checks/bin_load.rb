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
        unship: :unship_check,
        qty_match: :qty_match_check,
        bin_load: :bin_load_check,
        bin_exists: :bin_exists_check

      }.freeze

      def call
        return failed_response 'Bin Load record not found' unless bin_load || task == :create

        check = CHECKS[task]
        raise ArgumentError, "Task \"#{task}\" is unknown for #{self.class}" if check.nil?

        send(check)
      end

      private

      def create_check
        all_ok
      end

      def edit_check
        return failed_response "Bin Load: #{id} has been completed" if completed?

        all_ok
      end

      def delete_check
        return failed_response "Bin Load: #{id} has been completed" if completed?

        all_ok
      end

      def reopen_check
        return failed_response "Bin Load: #{id} has not been completed" unless completed?

        all_ok
      end

      def qty_match_check
        qty_bins = params[:qty_bins].to_i
        return failed_response "Bin Qty does not match Product Qty's" unless qty_bins == qty_product_bins

        all_ok
      end

      def complete_check
        return failed_response "Bin Qty's does not match" unless bin_load.qty_bins == bin_load.qty_product_bins
        return failed_response "Bin Load: #{id} does not have products" unless products?
        return failed_response "Bin Load: #{id} has already been completed" if completed?

        all_ok
      end

      def bin_load_check # rubocop:disable Metrics/AbcSize
        return failed_response "Bin Load: #{id} has not been completed" unless completed?
        return failed_response "Bin Load: #{id} has already been shipped" if shipped?

        products = repo.select_values(:bin_load_products, %i[id qty_bins], bin_load_id: id)
        products.each do |bin_load_product_id, qty_bins|
          qty_available = repo.rmt_bins_matching_bin_load(:bin_asset_number, bin_load_product_id: bin_load_product_id).count
          return failed_response("Bin Load: #{id} Insufficient bins available") if qty_available < qty_bins
        end

        all_ok
      end

      def ship_check
        return failed_response "Bin Load: #{id} has not been completed" unless completed?

        all_ok
      end

      def unship_check
        return failed_response "Bin Load: #{id} has not been shipped" unless shipped?

        all_ok
      end

      def bin_exists_check
        bin_number = params[:bin_asset_number]
        bin_id, exit_ref = repo.get_value(:rmt_bins, %i[id exit_ref], bin_asset_number: bin_number)
        return failed_response("Bin:#{bin_number} not found") if bin_id.nil?

        return failed_response("Bin:#{bin_number} is not in stock, exit reference:#{exit_ref}") unless exit_ref.nil?

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
    end
  end
end
