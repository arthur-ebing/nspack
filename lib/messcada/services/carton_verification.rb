# frozen_string_literal: true

module MesscadaApp
  class CartonVerification < BaseService
    attr_reader :repo, :hr_repo, :carton_quantity, :carton_label_id, :carton_id, :resource_code, :user, :palletizer_identifier, :palletizing_bay_resource_id

    def initialize(user, params, palletizer_identifier = nil, palletizing_bay_resource_id = nil)
      @carton_label_id = params[:carton_number]
      @user = user
      @palletizer_identifier = palletizer_identifier
      @palletizing_bay_resource_id = palletizing_bay_resource_id
      @repo = MesscadaApp::MesscadaRepo.new
      @hr_repo = MesscadaApp::HrRepo.new
      @carton_quantity = 1
      @container_type = AppConst::CARTON_EQUALS_PALLET ? 'Bin' : 'Carton'
    end

    def call
      carton_verification

      # Temporary fix to handle UD & SR.
      # TODO: redesign process for UD
      unless AppConst::CARTON_VERIFICATION_REQUIRED
        bin = check_if_bin?
        create_pallet_from_bin if bin
      end

      success_response("#{@container_type} verified")
    end

    private

    def check_if_bin?
      return true if AppConst::CARTON_EQUALS_PALLET

      standard_pack_code_id = repo.get(:carton_labels, carton_label_id, :standard_pack_code_id)
      repo.get(:standard_pack_codes, standard_pack_code_id, :bin)
    end

    def create_pallet_from_bin
      has_pallet = repo.get_value(:cartons, :pallet_sequence_id, carton_label_id: carton_label_id)
      already_scanned = repo.exists?(:pallet_sequences, scanned_from_carton_id: carton_id)
      return if has_pallet || already_scanned

      MesscadaApp::CreatePalletFromCarton.new(user, carton_id, carton_quantity).call
    end

    def carton_verification
      @carton_id = repo.get_id(:cartons, carton_label_id: carton_label_id)
      return if @carton_id

      unless palletizer_identifier.nil?
        palletizer_identifier_id = find_personnel_identifier_id
        palletizer_contract_worker_id = find_palletizer_contract_worker_id(palletizer_identifier_id)
      end
      attrs = { carton_label_id: carton_label_id,
                palletizer_identifier_id: palletizer_identifier_id,
                palletizer_contract_worker_id: palletizer_contract_worker_id,
                palletizing_bay_resource_id: palletizing_bay_resource_id }
      @carton_id = DB[:cartons].insert(attrs)
    end

    def carton_label_carton_exists?
      repo.carton_label_carton_exists?(carton_label_id)
    end

    def carton_label_carton_params
      repo.find_hash(:carton_labels, carton_label_id).reject { |k, _| %i[id resource_id label_name carton_equals_pallet active created_at updated_at].include?(k) }
    end

    def find_personnel_identifier_id
      hr_repo.personnel_identifier_id_from_device_identifier(palletizer_identifier)
    end

    def find_palletizer_contract_worker_id(palletizer_identifier_id)
      hr_repo.contract_worker_id_from_personnel_id(palletizer_identifier_id)
    end
  end
end
