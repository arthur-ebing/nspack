# frozen_string_literal: true

module FinishedGoodsApp
  class ECertPreverify < BaseService # rubocop:disable Metrics/ClassLength
    attr_accessor :params, :agreement_id, :agreement_code, :business_id, :industry, :pallet_numbers, :create_units, :update_units

    def initialize(params)
      @params = params
      @agreement_id = params[:ecert_agreement_id]
      @agreement_code = FinishedGoodsApp::EcertRepo.new.find_ecert_agreement(@agreement_id)&.code
      @business_id = AppConst::E_CERT_BUSINESS_ID
      @industry = AppConst::E_CERT_INDUSTRY
      @create_units = []
      @update_units = []
    end

    def call # rubocop:disable Metrics/AbcSize
      res = MesscadaApp::ParseString.call(params[:pallet_list])
      return res unless res.success

      @pallet_numbers = res.instance
      res = validate_pallets(:has_nett_weight, pallet_numbers)
      return res unless res.success

      res = find_tracking_unit
      return failed_response(res.message) unless res.success

      res = create_tracking_unit
      return failed_response(res.message) unless res.success

      res = update_tracking_unit
      return failed_response(res.message) unless res.success

      success_response('Processed Tracking Units')
    end

    private

    def repo
      @repo ||= EcertRepo.new
    end

    def api
      @api ||= ECertApi.new
    end

    def validate_pallets(check, pallet_numbers)
      MesscadaApp::TaskPermissionCheck::ValidatePallets.call(check, pallet_numbers)
    end

    def find_tracking_unit
      pallet_numbers.each do |pallet_number|
        res = api.tracking_unit_status(pallet_number)
        return failed_response(res.message) unless res.success

        if res.instance.empty?
          @create_units << pallet_number
        else
          @update_units << pallet_number
        end
      end
      ok_response
    end

    def create_tracking_unit # rubocop:disable Metrics/AbcSize
      return ok_response if create_units.empty?

      res = api.elot(tur_query, repo.compile_preverify_pallets(create_units))
      return failed_response(res.message) unless res.success

      if res.instance['IsSuccessful']
        save_response(res.instance)
      else
        message = res.instance['Message'].to_s.gsub("\n", '<br>').gsub("\r", '')
        failed_response(message)
      end
    end

    def update_tracking_unit # rubocop:disable Metrics/AbcSize
      return ok_response if update_units.empty?

      res = api.elot(tur_query(true), repo.compile_preverify_pallets(update_units))
      return failed_response(res.message) unless res.success

      response = res.instance
      if response['IsSuccessful']
        save_response(response)
      else
        message = response['Message'].gsub("\n", '<br>').gsub("\r", '')
        failed_response(message)
      end
    end

    def save_response(response) # rubocop:disable Metrics/AbcSize
      response_units = []
      response['Data'].each do |tracking_unit|
        pallet_number = tracking_unit['TrackingUnitID']
        next if response_units.include? pallet_number

        response_units << pallet_number
        pallet_id = repo.get_id(:pallets, pallet_number: pallet_number)
        id = repo.get_id(:ecert_tracking_units, pallet_id: pallet_id)

        res = api.tracking_unit_status(pallet_number)
        return failed_response(res.message) unless res.success

        status = res.instance.first || {}
        tracking_unit_statuses = status['TrackingUnitStatuses'].first || {}

        attrs = { ecert_agreement_id: agreement_id,
                  business_id: business_id,
                  industry: industry,
                  pallet_id: pallet_id,
                  elot_key: response['eLotKey'],
                  passed: %w[Passed].include?(tracking_unit_statuses['ProcessStatus']),
                  verification_key: nil,
                  process_result: repo.array_of_text_for_db_col(tracking_unit_statuses['ProcessResult']),
                  rejection_reasons: repo.array_of_text_for_db_col(tracking_unit_statuses['RejectionReasons']) }

        id.nil? ? repo.create(:ecert_tracking_units, attrs) : repo.update(:ecert_tracking_units, id, attrs)
      end
      ok_response
    end

    def tur_query(update = false)
      hash = {
        IsUpdate: update,
        IsTest: false,
        BusinessID: business_id,
        Industry: industry,
        AgreementCode: agreement_code
      }
      URI.encode_www_form(hash)
    end
  end
end
