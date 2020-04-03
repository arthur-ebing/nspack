# frozen_string_literal: true

module FinishedGoodsApp
  class EcertRepo < BaseRepo
    build_for_select :ecert_agreements,
                     label: %i[code name],
                     value: :id,
                     order_by: :code
    build_inactive_select :ecert_agreements,
                          label: %i[code name],
                          value: :id,
                          order_by: :code

    crud_calls_for :ecert_agreements, name: :ecert_agreement, wrapper: EcertAgreement
    crud_calls_for :ecert_tracking_units, name: :ecert_tracking_unit, wrapper: EcertTrackingUnit

    def flatten_hash(hash) # rubocop:disable Metrics/AbcSize
      return {} if hash.nil?

      hash = UtilityFunctions.symbolize_keys(hash)
      instance = {}
      array_instance = {}

      hash.each do |k, v|
        if v.is_a?(Array)
          v.each do |h|
            h = UtilityFunctions.symbolize_keys(h)
            args = { pallet_number: hash[:TrackingUnitID],
                     puc: h[:OperatorCode],
                     orchard: h[:OriginLocation],
                     phc: h[:PackOperatorCode],
                     commodity: h[:CommodityCode],
                     marketing_variety: h[:MarketingIndicationCode],
                     grade: h[:ClassCategory],
                     carton_quantity: h[:NumberOfPackagedItems],
                     production_region: h[:TrackingUnitOrigin] }
            pallet_sequence = select_values(:vw_pallet_sequence_flat, :pallet_sequence_number, args)

            # have to lookup a unique identifier as eCert doesnt give one
            prefix = pallet_sequence.length == 1 ? "seq#{pallet_sequence.first}_" : 'seq?_'

            h.each do |hk, hv|
              if k == :TrackingUnitStatuses
                instance[hk.to_sym] = hv
              else
                array_instance["#{prefix}#{hk}".to_sym] = hv
              end
            end
          end
        else
          instance[k.to_sym] = v
        end
      end
      instance.sort.to_h.merge(array_instance)
    end

    def compile_preverify_pallets(pallet_numbers)
      return [{}] if pallet_numbers.nil?

      preverify_pallets = []
      Array(pallet_numbers).each do |pallet_number|
        pallet = where_hash(:pallets, pallet_number: pallet_number) || {}
        preverify_pallets << { TrackingUnitID: pallet_number,
                               Reference1: nil,
                               Reference2: nil,
                               ExportDate: nil,
                               Weight: pallet[:nett_weight].to_f.round(2),
                               WeightUnitCode: 'KG',
                               NumberOfPackageItems: pallet[:carton_quantity],
                               TrackingUnitDetails: compile_preverify_pallet_sequences(pallet_number) }
      end
      preverify_pallets
    end

    def compile_preverify_pallet_sequences(pallet_number) # rubocop:disable Metrics/AbcSize
      preverify_pallet_sequences = []
      pallet_sequences = MesscadaApp::MesscadaRepo.new.find_pallet_sequences_by_pallet_number(pallet_number)
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
                                        Weight: pallet_sequence[:sequence_nett_weight].to_f.round(2),
                                        WeightUnitCode: 'KG',
                                        TrackingUnitLocation: nil,
                                        TrackingUnitOrigin: pallet_sequence[:production_region] }
      end
      preverify_pallet_sequences
    end
  end
end
