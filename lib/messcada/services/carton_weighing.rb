# frozen_string_literal: true

module MesscadaApp
  class CartonWeighing < BaseService
    attr_reader :repo, :carton_is_pallet, :provide_pack_type, :carton_label_id, :resource_code, :gross_weight, :uom,
                :plant_resource_button_indicator, :standard_pack_code_id

    def initialize(params)
      @carton_label_id = params[:carton_number]
      @gross_weight = BigDecimal(params[:gross_weight])
      @uom = params[:measurement_unit]
      @resource_code = params[:device]
    end

    def call
      @repo = MesscadaApp::MesscadaRepo.new
      @carton_is_pallet = AppConst::CARTON_EQUALS_PALLET
      # @provide_pack_type = AppConst::PROVIDE_PACK_TYPE_AT_VERIFICATION
      @provide_pack_type = AppConst::CR_PROD.provide_pack_type_at_carton_verification?
      @plant_resource_button_indicator = resource_code.split('-').last
      res = carton_weighing
      raise Crossbeams::InfoError, unwrap_failed_response(res) unless res.success

      ok_response
    end

    private

    def carton_weighing  # rubocop:disable Metrics/AbcSize
      return failed_response("Carton / Bin:#{carton_label_id} not verified") unless carton_label_carton_exists?

      if provide_pack_type
        return failed_response("Pack Type for button :#{plant_resource_button_indicator} not found") unless standard_pack_code_exists?
        return failed_response("Button Indicator for button:#{plant_resource_button_indicator} referenced by more than 1 Standard Pack Code") unless one_standard_pack_code?

        @standard_pack_code_id = find_standard_pack_code(plant_resource_button_indicator)

      end

      attrs = update_attrs
      update_carton(carton.id, attrs)

      ok_response
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def carton_label_carton_exists?
      repo.carton_label_carton_exists?(carton_label_id)
    end

    def standard_pack_code_exists?
      repo.standard_pack_code_exists?(plant_resource_button_indicator)
    end

    def one_standard_pack_code?
      repo.one_standard_pack_code?(plant_resource_button_indicator)
    end

    def carton
      repo.where(:cartons, MesscadaApp::Carton, carton_label_id: carton_label_id)
    end

    def update_attrs
      attrs = { gross_weight: gross_weight }
      if provide_pack_type
        nett_weight = gross_weight - BigDecimal(repo.find_standard_pack_code_material_mass(standard_pack_code_id))
        attrs = attrs.to_h.merge(nett_weight: nett_weight)
      end
      attrs
    end

    def find_standard_pack_code(plant_resource_button_indicator)
      repo.find_standard_pack_code(plant_resource_button_indicator)
    end

    def update_carton(id, attrs)  # rubocop:disable Metrics/AbcSize
      repo.update_carton_label(carton_label_id, { standard_pack_code_id: standard_pack_code_id }) if provide_pack_type
      repo.update_carton(id, attrs)
      return unless carton_is_pallet

      DB[:pallet_sequences].where(scanned_from_carton_id: id).update(standard_pack_code_id: standard_pack_code_id) if provide_pack_type
      pallet_id = find_pallet_from_carton(id)
      DB[:pallets].where(id: pallet_id).update(gross_weight: gross_weight)
    end

    def find_pallet_from_carton(carton_id)
      repo.find_pallet_from_carton(carton_id)
    end
  end
end
