# frozen_string_literal: true

module MesscadaApp
  class CartonVerificationAndWeighing < BaseService
    attr_reader :repo, :carton_is_pallet, :provide_pack_type, :carton_label_id, :resource_code, :gross_weight, :uom,
                :plant_resource_button_indicator, :params

    def initialize(params)
      @carton_label_id = params[:carton_number]
      @gross_weight = params[:gross_weight]
      @uom = params[:measurement_unit]
      @resource_code = params[:device]
      @params = params.to_h.merge(carton_and_pallet_verification: false)
    end

    def call
      @repo = MesscadaApp::MesscadaRepo.new
      @carton_is_pallet = AppConst::CARTONS_IS_PALLETS
      @provide_pack_type = AppConst::PROVIDE_PACK_TYPE_AT_VERIFICATION
      @plant_resource_button_indicator = resource_code.split('-').last

      return failed_response("Carton / Bin:#{carton_label_id} already verified") if carton_label_carton_exists?

      res = carton_verification_and_weighing
      raise Crossbeams::InfoError, unwrap_failed_response(res) unless res.success

      ok_response
    end

    private

    def carton_label_carton_exists?
      repo.carton_label_carton_exists?(carton_label_id)
    end

    def carton_verification_and_weighing  # rubocop:disable Metrics/AbcSize
      if provide_pack_type
        return failed_response("Pack Type for button :#{plant_resource_button_indicator} not found") unless standard_pack_code_exists?
        return failed_response("Button Indicator for button:#{plant_resource_button_indicator} referenced by more than 1 Standard Pack Code") unless one_standard_pack_code?
      end

      MesscadaApp::CartonVerification.new(params).call
      update_carton(carton_label_carton_id, update_attrs) if provide_pack_type

      ok_response
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def standard_pack_code_exists?
      repo.standard_pack_code_exists?(plant_resource_button_indicator)
    end

    def one_standard_pack_code?
      repo.one_standard_pack_code?(plant_resource_button_indicator)
    end

    def carton_label_carton_id
      repo.carton_label_carton_id(carton_label_id)
    end

    def update_attrs
      attrs = { gross_weight: gross_weight }
      if provide_pack_type
        standard_pack_code_id = find_standard_pack_code(plant_resource_button_indicator)
        nett_weight = gross_weight.to_f - repo.find_standard_pack_code_material_mass(standard_pack_code_id).to_f
        attrs = attrs.to_h.merge(nett_weight: nett_weight,
                                 standard_pack_code_id: standard_pack_code_id)
      end
      attrs
    end

    def find_standard_pack_code(plant_resource_button_indicator)
      repo.find_standard_pack_code(plant_resource_button_indicator)
    end

    def update_carton(id, attrs)
      repo.update_carton(id, attrs)
      return unless carton_is_pallet

      DB[:pallet_sequences].where(scanned_from_carton_id: id).update(standard_pack_code_id: attrs[:standard_pack_code_id])
      pallet_id = find_pallet_from_carton(id)
      DB[:pallets].where(id: pallet_id).update(gross_weight: gross_weight)
    end

    def find_pallet_from_carton(carton_id)
      repo.find_pallet_from_carton(carton_id)
    end
  end
end
