# frozen_string_literal: true

module MesscadaApp
  class RebinVerification < BaseService
    attr_reader :repo, :user, :scanned_number, :scanned, :carton_label_id, :rebin_id, :carton_label, :owner_id

    def initialize(user, scanned_number)
      @scanned_number = scanned_number
      @user = user
      @repo = MesscadaApp::MesscadaRepo.new
    end

    def call
      res = resolve_scanned_number_params
      return res unless res.success

      res = rebin_verification
      return res unless res.success

      success_response("Successfully verified #{scanned[:scanned_type]}: #{scanned_number}", response_instance)
    end

    private

    def resolve_scanned_number_params
      scan_params = { scanned_number: scanned_number.to_s, expect: :carton_label }
      res = ScanCartonLabelOrPallet.call(scan_params)
      return res unless res.success

      @scanned = res.instance
      @carton_label_id = scanned.carton_label_id
      ok_response
    end

    def rebin_verification
      validations = validate_rebin_verification
      return validations unless validations.success

      repo.transaction do
        unless rebin_exists?
          res = create_rebin
          raise Crossbeams::InfoError, res.message unless res.success

          @rebin_id = res.instance.rebin_id
        end
      end

      ok_response
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def validate_rebin_verification # rubocop:disable Metrics/AbcSize
      return failed_response("Rebin label not found for :#{scanned_number}") if carton_label_id.nil?

      @carton_label = repo.carton_label_attrs_for_rebin(carton_label_id)
      std_pack = repo.standard_pack_attrs_for_rebin(carton_label[:standard_pack_code_id])
      @owner_id = std_pack[:rmt_container_material_owner_id]

      return failed_response("Rebin: #{scanned_number} already verified") if rebin_verified?
      return failed_response("Pack: #{std_pack[:standard_pack_code]} is not a bin") unless std_pack[:bin]
      return failed_response("Pack: #{std_pack[:standard_pack_code]} does not have bin type or owner") unless material_owner_exists?

      ok_response
    end

    def rebin_verified?
      rebin_exists? && repo.exists?(:rmt_bins, bin_asset_number: carton_label_id.to_s)
    end

    def rebin_exists?
      @rebin_id ||= repo.get_id(:rmt_bins, verified_from_carton_label_id: carton_label_id)
      !rebin_id.nil? && !carton_label_id.nil?
    end

    def material_owner_exists?
      repo.exists?(:rmt_container_material_owners, id: owner_id)
    end

    def create_rebin
      CreateRebinFromScannedCartonLabel.call(carton_label_id, set_rebin_params)
    end

    def set_rebin_params # rubocop:disable Metrics/AbcSize
      arr = %i[season_id cultivar_group_id cultivar_id puc_id farm_id orchard_id rmt_class_id]
      params = {
        bin_asset_number: carton_label_id.to_s,
        rmt_delivery_id: nil,
        bin_fullness: 'Full',
        qty_bins: 1,
        nett_weight: nil,
        gross_weight: nil,
        is_rebin: true
      }.merge(carton_label.slice(*arr))

      owner_party_role_id, material_type_id = repo.get_value(:rmt_container_material_owners, %i[rmt_material_owner_party_role_id rmt_container_material_type_id], id: owner_id)
      params[:rmt_container_material_owner_id] = owner_id
      params[:rmt_material_owner_party_role_id] = owner_party_role_id
      params[:rmt_container_material_type_id] = material_type_id
      params[:rmt_container_type_id] = repo.get(:rmt_container_material_types, material_type_id, :rmt_container_type_id)
      params[:location_id] = repo.get(:plant_resources, carton_label[:packhouse_resource_id], :location_id)
      params[:rmt_size_id] = repo.find_rmt_size_id_for(carton_label[:fruit_size_reference_id])
      params[:production_run_rebin_id] = carton_label[:production_run_id]

      params
    end

    def response_instance
      OpenStruct.new(carton_label_id: carton_label_id, rebin_id: rebin_id)
    end
  end
end
