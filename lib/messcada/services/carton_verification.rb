# frozen_string_literal: true

module MesscadaApp
  class CartonVerification < BaseService
    attr_reader :repo, :carton_quantity, :carton_is_pallet, :carton_label_id, :resource_code, :user,
                :palletizer_identifier, :palletizing_bay_resource_id

    def initialize(user, params, palletizer_identifier = nil, palletizing_bay_resource_id = nil)
      @carton_label_id = params[:carton_number]
      @user = user
      @palletizer_identifier = palletizer_identifier
      @palletizing_bay_resource_id = palletizing_bay_resource_id
    end

    def call
      @repo = MesscadaApp::MesscadaRepo.new
      @carton_quantity = 1
      @carton_is_pallet = AppConst::CARTON_EQUALS_PALLET
      @container_type = @carton_is_pallet ? 'Bin' : 'Carton'
      res = carton_verification
      raise Crossbeams::InfoError, unwrap_failed_response(res) unless res.success

      success_response("#{@container_type} verified")
    end

    private

    def carton_verification  # rubocop:disable Metrics/AbcSize
      # return failed_response("#{@container_type} #{carton_label_id} already verified") if carton_label_carton_exists?

      unless carton_label_carton_exists?
        palletizer_identifier_id = find_personnel_identifier unless palletizer_identifier.nil?
        attrs = { carton_label_id: carton_label_id,
                  palletizer_identifier_id: palletizer_identifier_id,
                  palletizing_bay_resource_id: palletizing_bay_resource_id }
        carton_params = carton_label_carton_params.to_h.merge(attrs)

        id = DB[:cartons].insert(carton_params)
        MesscadaApp::CreatePalletFromCarton.new(user, id, carton_quantity).call if carton_is_pallet
      end

      ok_response
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def carton_label_carton_exists?
      repo.carton_label_carton_exists?(carton_label_id)
    end

    def carton_label_carton_params
      repo.find_hash(:carton_labels, carton_label_id).reject { |k, _| %i[id resource_id label_name carton_equals_pallet active created_at updated_at].include?(k) }
    end

    def find_personnel_identifier
      repo.find_personnel_identifiers_by_palletizer_identifier(palletizer_identifier)
    end
  end
end
