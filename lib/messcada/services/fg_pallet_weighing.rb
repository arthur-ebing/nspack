# frozen_string_literal: true

module MesscadaApp
  class FgPalletWeighing < BaseService
    attr_reader :repo, :pallet_number, :gross_weight, :uom

    def initialize(params)
      # @pallet_number = params[:pallet_number]
      @pallet_number = params[:bin_number]
      @gross_weight = BigDecimal(params[:gross_weight])
      @uom = params[:measurement_unit]
      @repo = MesscadaApp::MesscadaRepo.new
    end

    def call
      res = fg_pallet_weighing
      raise Crossbeams::InfoError, unwrap_failed_response(res) unless res.success

      success_response('FgPalletWeighing was successful', pallet_id: res.instance[:pallet_id])
    end

    private

    def fg_pallet_weighing
      return failed_response("Pallet Number :#{pallet_number} could not be found") unless pallet_exists?

      attrs = { gross_weight: gross_weight, gross_weight_measured_at: Time.now }
      update_pallet(pallet.id, attrs)

      success_response('ok', pallet_id: pallet.id)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def pallet_exists?
      repo.pallet_exists?(pallet_number)
    end

    def pallet
      repo.where(:pallets, MesscadaApp::Pallet, pallet_number: pallet_number)
    end

    def update_pallet(id, attrs)
      repo.update_pallet(id, attrs)
    end
  end
end
