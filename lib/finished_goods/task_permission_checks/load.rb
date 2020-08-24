# frozen_string_literal: true

module FinishedGoodsApp
  module TaskPermissionCheck
    class Load < BaseService # rubocop:disable Metrics/ClassLength
      attr_reader :task, :entity, :repo, :id, :pallet_numbers
      def initialize(task, load_id = nil, pallet_numbers = nil)
        @task = task
        @repo = LoadRepo.new
        @id = load_id
        raise ArgumentError, "Load \"#{@id}\" is not valid. Perhaps you scanned a pallet number?" if @id.to_i > AppConst::MAX_DB_INT

        @pallet_numbers = pallet_numbers || @repo.select_values(:pallets, :pallet_number, load_id: id)
        @entity = @repo.find_load_flat(@id)
      end

      CHECKS = {
        create: :create_check,
        edit: :edit_check,
        allocate: :allocate_check,
        allocate_to_load: :allocate_to_load_check,
        truck_arrival: :truck_arrival_check,
        delete_load_vehicle: :delete_load_vehicle_check,
        load_truck: :load_truck_check,
        unload_truck: :unload_truck_check,
        ship: :ship_check,
        unship: :unship_check,
        delete: :delete_check
      }.freeze

      def call
        return failed_response "Value #{id} is too big to be a load. Perhaps you scanned a pallet number?" if id.to_i > AppConst::MAX_DB_INT
        return failed_response 'Record not found' unless @entity || task == :create

        check = CHECKS[task]
        raise ArgumentError, "Task \"#{task}\" is unknown for #{self.class}" if check.nil?

        send(check)
      end

      private

      def create_check
        all_ok
      end

      def edit_check
        all_ok
      end

      def allocate_check
        return failed_response("Load: #{id} truck already here") if vehicle?
        return failed_response("Load: #{id} has already been shipped") if shipped?

        all_ok
      end

      def allocate_to_load_check # rubocop:disable Metrics/AbcSize
        return failed_response("Load: #{id} truck already here") if vehicle?
        return failed_response("Load: #{id} has already been shipped") if shipped?

        check_pallets!(:in_stock, pallet_numbers)
        check_pallets!(:has_nett_weight, pallet_numbers)
        check_pallets!(:has_gross_weight, pallet_numbers)
        check_pallets!(:not_shipped, pallet_numbers)
        check_pallets!(:not_on_load, pallet_numbers, id)
        check_pallets!(:not_failed_otmc, pallet_numbers)
        check_pallets!(:rmt_grade, pallet_numbers, id)

        all_ok
      rescue Crossbeams::InfoError => e
        failed_response(e.message)
      end

      def truck_arrival_check # rubocop:disable Metrics/AbcSize
        return failed_response("Load: #{id} has already been shipped") if shipped?
        return failed_response("Load: #{id} doesn't have pallets allocated") unless allocated?

        check_pallets!(:in_stock, pallet_numbers)
        check_pallets!(:has_nett_weight, pallet_numbers)
        check_pallets!(:has_gross_weight, pallet_numbers)
        check_pallets!(:not_shipped, pallet_numbers)
        check_pallets!(:not_failed_otmc, pallet_numbers)

        all_ok
      rescue Crossbeams::InfoError => e
        failed_response(e.message)
      end

      def delete_load_vehicle_check
        return failed_response("Load: #{id} has been shipped") if shipped?

        all_ok
      end

      def load_truck_check
        return failed_response("Load: #{id} has already been shipped") if shipped?
        return failed_response("Load: #{id} doesnt have pallets allocated") unless allocated?
        return failed_response("Load: #{id} truck arrival not done") unless vehicle?
        return failed_response("Load: #{id} has already been loaded") if loaded?

        all_ok
      end

      def unload_truck_check
        return failed_response("Load: #{id} has already been shipped") if shipped?

        all_ok
      end

      def ship_check # rubocop:disable Metrics/AbcSize
        return failed_response("Load: #{id} has already been shipped") if shipped?
        return failed_response("Load: #{id} doesnt have pallets allocated") unless allocated?
        return failed_response("Load: #{id} truck arrival not done") unless vehicle?
        return failed_response("Load: #{id} hasn't been loaded") unless loaded?
        return failed_response("Load: #{id} requires a temp tail to be set") unless temp_tail?

        all_ok
      end

      def unship_check
        return failed_response("Load: #{id} was not shipped") unless shipped?

        all_ok
      end

      def delete_check
        return failed_response("Load: #{id} has pallets allocated") if allocated?
        return failed_response("Load: #{id} truck already here") if vehicle?
        return failed_response("Load: #{id} has already been shipped") if shipped?

        all_ok
      end

      def shipped?
        @entity.shipped
      end

      def allocated?
        @entity.allocated
      end

      def vehicle?
        @entity.vehicle
      end

      def loaded?
        @entity.loaded
      end

      def temp_tail?
        if @entity.requires_temp_tail
          @entity.temp_tail
        else
          true
        end
      end

      def check_pallets!(check, pallet_numbers, load_id = nil)
        res = MesscadaApp::TaskPermissionCheck::Pallets.call(check, pallet_numbers, load_id)
        raise Crossbeams::InfoError, res.message unless res.success
      end
    end
  end
end
