# frozen_string_literal: true

module MesscadaApp
  # The result from a scan carton or pallet operation.
  #
  # Exposes the value fields from the scan operation and includes helper methods
  # to find related data (like the first pallet sequence id for a scanned pallet)
  class ScannedCartonOrPalletResolver
    include Crossbeams::Responses

    VALUE_FIELDS = %i[id failed_scan pallet_was_scanned formatted_number scanned_number scanned_type].freeze

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

    # Was a carton label id scanned?
    def carton_label?
      assert_ok_scan(__method__)

      !pallet_was_scanned
    end

    def carton_label_id
      assert_ok_scan(__method__)

      pallet_was_scanned ? nil : id
    end

    # could this have been a ctn == plt? in which case we can return the id
    def carton_id
      assert_ok_scan(__method__)

      pallet_was_scanned ? nil : repo.get_id(:cartons, carton_label_id: id)
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

      pallet_was_scanned ? id : repo.get(:pallet_sequences, pallet_sequence_id, :pallet_id)
    end

    def pallet_number
      assert_ok_scan(__method__)

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

    def validation_result(hash)
      Dry::Schema.Params do
        required(:id).maybe(:integer)
        required(:failed_scan).filled(:bool)
        required(:pallet_was_scanned).filled(:bool)
        required(:formatted_number).maybe(:string)
        required(:scanned_number).maybe(:string)
        required(:scanned_type).filled(:string)
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
