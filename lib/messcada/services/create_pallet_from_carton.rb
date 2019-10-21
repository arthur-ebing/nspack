# frozen_string_literal: true

module MesscadaApp
  class CreatePalletFromCarton < BaseService
    attr_reader :repo, :carton_id, :carton_quantity, :carton, :cartons_per_pallet,
                :pallet, :pallet_sequence

    def initialize(carton_id, carton_quantity)
      @carton_id = carton_id
      @carton_quantity = carton_quantity
    end

    def call
      @repo = MesscadaApp::MesscadaRepo.new
      return failed_response("Carton / Bin:#{carton_id} not verified") unless carton_exists?

      @carton = find_carton
      @cartons_per_pallet = carton_cartons_per_pallet

      res = create_pallet_and_sequences
      raise unwrap_failed_response(res) unless res.success

      ok_response
    end

    private

    def carton_exists?
      repo.carton_exists?(carton_id)
    end

    def find_carton
      repo.find_carton(carton_id)
    end

    # def find_oldest_pallet_sequence
    #   repo.find_oldest_pallet_sequence(carton_id)
    # end
    #
    # def find_oldest_pallet_sequence_carton
    #   repo.find_oldest_pallet_sequence_carton(carton_id)
    # end
    #
    # def find_total_pallet_sequence_quantity
    #   repo.find_total_pallet_sequence_quantity(carton_id)
    # end

    def carton_cartons_per_pallet
      repo.find_cartons_per_pallet(carton[:cartons_per_pallet_id])
    end

    def create_pallet_and_sequences
      res = create_pallet
      return res unless res.success

      res = create_pallet_sequence
      return res unless res.success

      repo.transaction do
        repo.create_pallet_and_sequences(pallet, pallet_sequence)
      end

      ok_response
    end

    def create_pallet
      pallet_params = set_pallet_params
      res = validate_pallet_params(pallet_params)
      return validation_failed_response(res) unless res.messages.empty?

      @pallet = res.to_h

      ok_response
    end

    def set_pallet_params
      {
        status: AppConst::PALLETIZED_NEW_PALLET,
        location_id: resource_location,
        phc: resource_phc,
        fruit_sticker_pm_product_id: carton[:fruit_sticker_pm_product_id],
        pallet_format_id: carton[:pallet_format_id],
        plt_packhouse_resource_id: carton[:packhouse_resource_id],
        plt_line_resource_id: carton[:production_line_resource_id]
      }
    end

    def resource_location
      repo.find_resource_location_id(carton[:packhouse_resource_id])
    end

    def resource_phc
      # repo.find_resource_phc(carton[:production_line_resource_id]) || repo.find_resource_phc(carton[:packhouse_resource_id])
      'test'
    end

    def validate_pallet_params(params)
      PalletSchema.call(params)
    end

    def create_pallet_sequence  # rubocop:disable Metrics/AbcSize
      attrs = pallet_sequence_carton_params.to_h.merge(pallet_sequence_pallet_params).to_h
      res = validate_pallet_sequence_params(attrs)
      return validation_failed_response(res) unless res.messages.empty?

      attrs = attrs.to_h
      treatment_ids = attrs.delete(:treatment_ids)
      attrs = attrs.merge(treatment_ids: "{#{treatment_ids.join(',')}}") unless treatment_ids.nil?

      @pallet_sequence = attrs

      ok_response
    end

    def pallet_sequence_carton_params
      carton_rejected_fields = %i[id resource_id label_name fruit_sticker_pm_product_id carton_label_id gross_weight nett_weight active created_at updated_at]
      repo.find_hash(:cartons, carton_id).reject { |k, _| carton_rejected_fields.include?(k) }
    end

    def pallet_sequence_pallet_params
      {
        scanned_from_carton_id: carton_id,
        carton_quantity: carton_quantity.nil? ? cartons_per_pallet : carton_quantity,
        pick_ref: calc_pick_ref
      }
    end

    def calc_pick_ref  # rubocop:disable Metrics/AbcSize
      iso_week = Date.today.cweek.to_s
      iso_week = '0' + iso_week if iso_week.length == 1
      day = Time.now.wday.to_s
      day = '7' if day == '0'

      iso_week.slice(1, 1) + day + packhouse_no + iso_week.slice(0, 1)
    end

    def packhouse_no
      repo.find_resource_packhouse_no(carton[:packhouse_resource_id])
    end

    def validate_pallet_sequence_params(params)
      PalletSequenceSchema.call(params)
    end
  end
end
