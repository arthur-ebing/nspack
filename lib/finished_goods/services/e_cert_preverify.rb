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

      res = api.auth_token_call
      return failed_response(res.message) unless res.success

      find_tracking_unit

      res = create_tracking_unit
      return failed_response(res.message) unless res.success

      res = update_tracking_unit
      return failed_response(res.message) unless res.success

      success_response('Processed Tracking Units')
    end

    private

    def repo
      @repo ||= MesscadaApp::MesscadaRepo.new
    end

    def api
      @api ||= ECertApi.new
    end

    def validate_pallets(check, pallet_numbers)
      MesscadaApp::TaskPermissionCheck::ValidatePallets.call(check, pallet_numbers)
    end

    def find_tracking_unit
      pallet_numbers.each do |pallet_number|
        res = api.find_tracking_unit(pallet_number)
        if res.success
          @update_units << pallet_number
        else
          @create_units << pallet_number
        end
      end
    end

    def create_tracking_unit # rubocop:disable Metrics/AbcSize
      url = "#{AppConst::E_CERT_ENVIRONMENT}tur.ecert.co.za/api/TrackingUnit/eLot?#{tur_query}"
      return ok_response if create_units.empty?

      res = api.elot_preverify(url, compile_preverify_pallets(create_units))
      response = res.instance
      if response['IsSuccessful']
        save_response(response)
      else
        message = response['Message'].gsub("\n", '<br>').gsub("\r", '')
        failed_response(message)
      end
    end

    def update_tracking_unit # rubocop:disable Metrics/AbcSize
      url = "#{AppConst::E_CERT_ENVIRONMENT}tur.ecert.co.za/api/TrackingUnit/eLot?#{tur_query(true)}"
      return ok_response if update_units.empty?

      res = api.elot_preverify(url, compile_preverify_pallets(update_units))
      response = res.instance
      if response['IsSuccessful']
        save_response(response)
      else
        message = response['Message'].gsub("\n", '<br>').gsub("\r", '')
        failed_response(message)
      end
    end

    def save_response(response) # rubocop:disable Metrics/AbcSize
      response['Data'].each do |tracking_unit|
        pallet_id = repo.get_id(:pallets, pallet_number: tracking_unit['TrackingUnitID'])
        id = repo.get_id(:ecert_tracking_units, pallet_id: pallet_id)
        attrs = { ecert_agreement_id: agreement_id,
                  business_id: business_id,
                  industry: industry,
                  pallet_id: pallet_id,
                  elot_key: response['eLotKey'],
                  passed: tracking_unit['ProcessStatus'] == 'Passed',
                  verification_key: tracking_unit['VerificationKey'],
                  process_result: tracking_unit['ProcessResult'],
                  rejection_reasons: tracking_unit['RejectionReasons'] }
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

    def compile_preverify_pallets(pallet_numbers)
      preverify_pallets = []
      pallet_numbers.each do |pallet_number|
        pallet = repo.find_pallet_sequences_by_pallet_number(pallet_number).first || {}
        preverify_pallets << { TrackingUnitID: pallet_number,
                               Reference1: nil,
                               Reference2: nil,
                               ExportDate: nil,
                               Weight: pallet[:nett_weight],
                               WeightUnitCode: 'KG',
                               NumberOfPackageItems: pallet[:pallet_carton_quantity],
                               TrackingUnitDetails: compile_preverify_pallet_sequences(pallet_number) }
      end
      preverify_pallets
    end

    def compile_preverify_pallet_sequences(pallet_number)
      preverify_pallet_sequences = []
      pallet_sequences = repo.find_pallet_sequences_by_pallet_number(pallet_number)
      pallet_sequences.each do |pallet_sequence|
        preverify_pallet_sequences << { OperatorCode: pallet_sequence[:puc],
                                        OriginLocation: pallet_sequence[:orchard],
                                        SPSStatus: pallet_sequence[:phyto_data],
                                        PackOperatorCode: pallet_sequence[:phc],
                                        CommodityCode: pallet_sequence[:commodity],
                                        MarketingIndicationCode: pallet_sequence[:marketing_variety],
                                        ClassCategory: pallet_sequence[:grade],
                                        NumberOfPackagedItems: pallet_sequence[:carton_quantity],
                                        PackageType: 'CT',
                                        Weight: pallet_sequence[:sequence_nett_weight],
                                        WeightUnitCode: 'KG',
                                        TrackingUnitLocation: nil,
                                        TrackingUnitOrigin: pallet_sequence[:production_region] }
      end
      preverify_pallet_sequences
    end
  end
end
