# frozen_string_literal: true

module MesscadaApp
  # The result from a scan carton or pallet operation.
  #
  # Exposes the value fields from the scan operation and includes helper methods
  # to find related data (like the first pallet sequence id for a scanned pallet)
  class ScannedCartonOrPalletResolver
    include Crossbeams::Responses

    VALUE_FIELDS = %i[id failed_scan pallet_was_scanned formatted_number scanned_number scanned_type carton_id].freeze

    def initialize(hash)
      @entity = validation_result(hash)
      raise Crossbeams::FrameworkError, "Scan result invalid: #{unwrap_error_set(@entity.errors)}" if @entity.failure?
    end

    def to_h
      @entity.to_h
    end

    def [](key)
      @entity[key]
    end

    # Was a pallet number scanned?
    def pallet?
      assert_ok_scan(__method__)

      pallet_was_scanned
    end

    # Was a carton label id scanned or pallet label of a carton=pallet carton?
    def carton_label?
      assert_ok_scan(__method__)

      !pallet_was_scanned
    end

    # Was a pallet label scanned that represents a carton (carton=pallet carton)?
    def carton_with_pallet_label?
      assert_ok_scan(__method__)

      @entity[:carton_with_pallet_label]
    end

    def carton_label_id
      assert_ok_scan(__method__)

      pallet_was_scanned ? nil : id
    end

    def carton_id
      assert_ok_scan(__method__)

      pallet_was_scanned ? nil : repo.get_id(:cartons, carton_label_id: carton_label_id)
    end

    def pallet_sequence_id
      assert_ok_scan(__method__)

      pallet_was_scanned ? nil : repo.get(:cartons, carton_id, :pallet_sequence_id)
    end

    def first_sequence_id
      assert_ok_scan(__method__)

      repo.find_first_sequence_id_for_pallet_number(pallet_number)
    end

    def pallet_id
      assert_ok_scan(__method__)

      return @entity[:carton_equals_pallet_id] if carton_with_pallet_label?

      pallet_was_scanned ? id : repo.get(:pallet_sequences, pallet_sequence_id, :pallet_id)
    end

    def pallet_number
      assert_ok_scan(__method__)

      return formatted_number if carton_with_pallet_label?

      pallet_was_scanned ? formatted_number : repo.get(:pallets, pallet_id, :pallet_number)
    end

    private

    def respond_to_missing?(meth)
      VALUE_FIELDS.include?(meth)
    end

    def method_missing(meth, *args)
      if VALUE_FIELDS.include?(meth)
        @entity[meth]
      else
        super
      end
    end

    def validation_result(hash) # rubocop:disable Metrics/AbcSize
      Dry::Schema.Params do
        required(:id).maybe(:integer)
        required(:failed_scan).filled(:bool)
        required(:pallet_was_scanned).filled(:bool)
        required(:carton_with_pallet_label).filled(:bool)
        required(:formatted_number).maybe(:string)
        required(:scanned_number).maybe(:string)
        required(:scanned_type).filled(:string)
        required(:carton_equals_pallet_id).maybe(:integer)
      end.call(hash)
    end

    def assert_ok_scan(meth)
      raise Crossbeams::FrameworkError, "Cannot call '#{meth}' - the scan failed." if failed_scan
    end

    def repo
      @repo ||= MesscadaRepo.new
    end
  end
end
