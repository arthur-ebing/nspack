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
      @params = params
    end

    def call  # rubocop:disable Metrics/AbcSize
      @repo = MesscadaApp::MesscadaRepo.new
      @carton_is_pallet = (AppConst::CARTONS_IS_PALLETS == 'true')
      @provide_pack_type = (AppConst::PROVIDE_PACK_TYPE_AT_VERIFICATION == 'true')
      @plant_resource_button_indicator = resource_code.split('-').last

      return failed_response("Carton / Bin:#{carton_label_id} already verified") if carton_label_carton_exists?

      res = carton_verification_and_weighing
      raise "#{res.message} - #{res.errors.map { |fld, errs| p "#{fld} #{errs.join(', ')}" }.join('; ')}" unless res.success

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

      begin
        repo.transaction do
          MesscadaApp::CartonVerification.new(params).call
          update_carton(carton_label_carton_id, update_attrs)
        end
      rescue StandardError
        return failed_response($ERROR_INFO)
      end

      ok_response
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
        nett_weight = gross_weight.to_f - repo.find_standard_pack_code_material_mass(plant_resource_button_indicator)
        attrs = attrs.to_h.merge(nett_weight: nett_weight)
      end
      attrs
    end

    def update_carton(id, attrs)
      repo.update_carton(id, attrs)
      DB[:pallet_sequences].where(scanned_from_carton_id: id).update(attrs) if carton_is_pallet
      # ProductionApp::RunStatsUpdateJob.enqueue(id, nett_weight, 'CARTONS_PACKED_WEIGHT')
    end
  end
end
