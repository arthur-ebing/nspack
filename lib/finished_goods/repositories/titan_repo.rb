# frozen_null_literal: true

module FinishedGoodsApp
  class TitanRepo < BaseRepo # rubocop:disable Metrics/ClassLength
    crud_calls_for :titan_requests, name: :titan_request

    def find_titan_request(id)
      hash = find_hash(:titan_requests, id)
      return nil unless hash

      if hash[:govt_inspection_sheet_id]
        hash = parse_titan_inspection_request_doc(hash)
        hash = parse_titan_inspection_result_doc(hash)
      end
      if hash[:load_id]
        hash = parse_titan_addendum_request_doc(hash)
        hash = parse_titan_addendum_result_doc(hash)
      end
      TitanRequest.new(hash)
    end

    def parse_titan_inspection_request_doc(hash) # rubocop:disable Metrics/AbcSize
      request_doc = hash[:request_doc] ||= {}
      request_lines = request_doc.delete('consignmentLines') || []
      hash[:request_array] = []
      request_doc.each { |k, v| hash[:request_array] << { column: humanize(k), value: Array(v).join(' ') } }
      Array(0...request_lines.length).each do |i|
        request_lines[i].each { |k, v| hash[:request_array] << { column: "#{humanize(k)}[#{i}]", value: Array(v).join(', ') } }
      end
      hash
    end

    def parse_titan_inspection_result_doc(hash) # rubocop:disable Metrics/AbcSize
      result_doc = hash[:result_doc] ||= {}
      result_lines = result_doc.delete('errors') || []
      hash[:result_array] = []

      result_doc.each { |k, v| hash[:result_array] << { column: humanize(k), value: Array(v).join(' ') } }

      Array(0...result_lines.length).each do |i|
        result_lines[i].each { |k, v| hash[:result_array] << { column: "#{humanize(k)}[#{i}]", value: Array(v).join(' ') } }
      end
      hash
    end

    def parse_titan_addendum_request_doc(hash) # rubocop:disable Metrics/AbcSize
      request_doc = hash[:request_doc] ||= {}
      hash[:request_array] = []

      addendum_details = request_doc.delete('addendumDetails') || []
      consignment_items = request_doc.delete('consignmentItems') || []
      request_doc.each { |k, v| hash[:request_array] << { column: humanize(k), value: Array(v).join(' ') } }

      Array(0...addendum_details.length).each do |i|
        addendum_details[i].each { |k, v| hash[:request_array] << { column: "AddendumDetails[#{i}].#{humanize(k)}", value: Array(v).join(', ') } }
      end
      Array(0...consignment_items.length).each do |i|
        consignment_items[i].each { |k, v| hash[:request_array] << { column: "ConsignmentItems[#{i}].#{humanize(k)}", value: Array(v).join(', ') } }
      end

      hash
    end

    def parse_titan_addendum_result_doc(hash) # rubocop:disable Metrics/AbcSize
      result_doc = hash[:result_doc] ||= {}
      result_doc.delete('type')
      result_doc.delete('traceId')
      result_lines = result_doc.delete('errors')
      hash[:result_array] = []
      result_doc.each { |k, v| hash[:result_array] << { column: humanize(k), value: Array(v).join(' ') } }
      result_lines.each { |k, v| hash[:result_array] << { column: "Error: #{humanize(k)}", value: Array(v).join(' ') } } if result_lines.is_a? Hash
      hash
    end

    def humanize(value)
      array = value.to_s.split(/(?=[A-Z])/)
      array.map(&:capitalize).join('')
    end

    def find_titan_inspection(govt_inspection_sheet_id) # rubocop:disable Metrics/AbcSize
      hash = {}
      ds = DB[:titan_requests].where(govt_inspection_sheet_id: govt_inspection_sheet_id).reverse(:id)
      return nil unless ds.get(:id)

      hash[:govt_inspection_sheet_id] = govt_inspection_sheet_id
      hash[:request_type] = ds.get(:request_type)
      hash[:success] = ds.get(:success)
      hash[:inspection_message_id] = ds.exclude(inspection_message_id: nil).get(:inspection_message_id)
      result_doc = ds.where(request_type: 'Results').get(:result_doc) || {}
      hash[:upn] = result_doc['upn']
      hash[:pallets] = []
      consignment_lines = result_doc['consignmentLines'] || []
      consignment_lines.each do |line|
        pallet_number = line['sscc']
        pallet_id = get_id(:pallets, pallet_number: pallet_number)
        hash[:pallets] << { pallet_id: pallet_id, pallet_number: pallet_number, passed: line['result'] == 'Pass', rejection_reasons: line['rejectionReasons'] || [] }
      end
      TitanInspectionFlat.new(hash)
    end

    def compile_inspection(govt_inspection_sheet_id) # rubocop:disable Metrics/AbcSize
      govt_inspection_sheet = FinishedGoodsApp::GovtInspectionRepo.new.find_govt_inspection_sheet(govt_inspection_sheet_id)

      { consignmentNumber: govt_inspection_sheet.consignment_note_number,
        transactionType: '202',
        bookingRef: govt_inspection_sheet.booking_reference,
        exporter: MasterfilesApp::PartyRepo.new.find_registration_code_for_party_role('FBO', govt_inspection_sheet.exporter_party_role_id),
        billingParty: MasterfilesApp::PartyRepo.new.find_registration_code_for_party_role('BILLING', govt_inspection_sheet.inspection_billing_party_role_id),
        inspectionPoint: AppConst::TITAN_INSPECTION_API_USER_ID,
        inspector: govt_inspection_sheet.inspector_code,
        inspectionDate: Time.now.strftime('%Y-%m-%d'),
        inspectionTime: Time.now.strftime('%k:%M:%S'),
        consignmentLines: compile_inspection_pallets(govt_inspection_sheet_id) }
    end

    def compile_inspection_pallets(govt_inspection_sheet_id) # rubocop:disable Metrics/AbcSize
      govt_inspection_sheet = FinishedGoodsApp::GovtInspectionRepo.new.find_govt_inspection_sheet(govt_inspection_sheet_id)
      pallet_ids = select_values(:govt_inspection_pallets, :pallet_id, govt_inspection_sheet_id: govt_inspection_sheet_id)

      inspection_pallets = []
      pallet_ids.each do |pallet_id|
        instance = where_hash(:vw_pallet_sequence_flat, pallet_id: pallet_id)

        commodity_id = get_id(:commodities, code: instance[:commodity])
        nett_weight = instance[:nett_weight].nil_or_empty? ? get(:standard_product_weights, commodity_id, :nett_weight) : (instance[:nett_weight] / instance[:carton_quantity])
        gross_weight = instance[:gross_weight].nil_or_empty? ? get(:standard_product_weights, commodity_id, :gross_weight) : (instance[:gross_weight] / instance[:carton_quantity])
        ecert_agreement_id = get_value(:ecert_tracking_units, :ecert_agreement_id, pallet_id: pallet_id)
        ecert_agreement_code = get(:ecert_agreements, ecert_agreement_id, :code)

        inspection_pallets << { phc: instance[:phc],
                                sscc: instance[:pallet_number],
                                commodity: instance[:commodity],
                                variety: instance[:marketing_variety],
                                class: instance[:grade],
                                inspectionSampleWeight: nett_weight.to_f.round(3),
                                nettWeightPack: nett_weight.to_f.round(3),
                                grossWeightPack: gross_weight.to_f.round(3),
                                carton: 'C',
                                cartonQty: get(:pallets, pallet_id, :carton_quantity),
                                targetRegion: govt_inspection_sheet.destination_region,
                                targetCountry: govt_inspection_sheet.destination_country,
                                protocolExceptionIndicator: 'NA',
                                agreementCode: ecert_agreement_code,
                                consignmentLinePallets: compile_inspection_pallet_sequences(pallet_id) }
      end
      inspection_pallets
    end

    def compile_inspection_pallet_sequences(pallet_id) # rubocop:disable Metrics/AbcSize
      pallet_sequence_ids = select_values(:pallet_sequences, :id, pallet_id: pallet_id)

      inspection_pallet_sequences = []
      pallet_sequence_ids.each do |pallet_sequence_id|
        instance = where_hash(:vw_pallet_sequence_flat, id: pallet_sequence_id)
        inspection_pallet_sequences << { ssccReference: instance[:pallet_number],
                                         palletQty: get(:pallet_sequences, pallet_sequence_id, :carton_quantity),
                                         ssccSequenceNumber: instance[:pallet_sequence_number],
                                         puc: instance[:puc],
                                         orchard: instance[:orchard],
                                         phytoData: '',
                                         packCode: instance[:std_pack],
                                         packDate: instance[:palletized_at],
                                         sizeCount: instance[:actual_count].nil_or_empty? ? instance[:size_ref] : instance[:actual_count].to_i,
                                         inventoryCode: instance[:inventory_code],
                                         prePackingTreatment: 'NA' }
      end
      inspection_pallet_sequences
    end

    def find_titan_addendum(load_id) # rubocop:disable Metrics/AbcSize
      ds = DB[:titan_requests].where(load_id: load_id).reverse(:id).where(request_type: 'Addendum Status')
      hash = find_hash(:titan_requests, ds.get(:id))
      return nil unless hash

      status_hash = ds.where(request_type: 'Addendum Status').get(:result_doc) || {}
      hash[:addendum_status] = status_hash['addendumStatus']
      hash[:best_regime_code] = status_hash['bestRegimeCode']
      hash[:verification_status] = status_hash['verificationStatus']
      hash[:addendum_validations] = status_hash['addendumValidations']
      hash[:available_regime_code] = status_hash['availableRegimeCode']
      hash[:e_cert_response_message] = status_hash['eCertResponseMessage']
      hash[:e_cert_hub_tracking_number] = status_hash['eCertHubTrackingNumber']
      hash[:e_cert_hub_tracking_status] = status_hash['eCertHubTrackingStatus']
      hash[:e_cert_application_status] = status_hash['ecertApplicationStatus']
      hash[:phyt_clean_verification_key] = status_hash['phytCleanVerificationKey']
      hash[:export_certification_status] = status_hash['exportCertificationStatus']

      cancel_hash = ds.where(request_type: 'Cancel Addendum').get(:result_doc) || {}
      hash[:cancelled_status] = cancel_hash['message']
      hash[:cancelled_at] = ds.where(request_type: 'cancel').get(:updated_at)
      TitanAddendumFlat.new(hash)
    end

    def compile_addendum(load_id) # rubocop:disable Metrics/AbcSize
      load = FinishedGoodsApp::LoadRepo.new.find_load_flat(load_id)
      consignor_address = MasterfilesApp::PartyRepo.new.find_address_for_party_role('Delivery Address', load.exporter_party_role_id)
      consignee_address = MasterfilesApp::PartyRepo.new.find_address_for_party_role('Delivery Address', load.consignee_party_role_id)
      pallet_ids = select_values(:pallets, :id, load_id: load_id)
      ecert_agreement_ids = select_values(:ecert_tracking_units, :ecert_agreement_id, pallet_id: pallet_ids)
      ecert_agreement_codes = select_values(:ecert_agreements, :code, id: ecert_agreement_ids).join('')

      {
        eCertRequired: false,
        cbrid: 1, # central business register id
        cbrBillingID: 1,
        requestId: load_id,
        eCertAgreementCode: ecert_agreement_codes,
        eCertDesiredIssueLocation: 1,
        exporterCode: MasterfilesApp::PartyRepo.new.find_registration_code_for_party_role('FBO', load.exporter_party_role_id).to_s,
        consignorName: MasterfilesApp::PartyRepo.new.find_organization_for_party_role(load.exporter_party_role_id).short_description,
        consignorAddressLine1: [consignor_address&.address_line_1, consignor_address&.address_line_2, consignor_address&.address_line_3].compact!.join(', '),
        consignorAddressLine2: consignor_address&.city,
        consignorAddressLine3: consignor_address&.postal_code,
        consigneeId: MasterfilesApp::PartyRepo.new.find_organization_for_party_role(load.consignee_party_role_id).short_description,
        consigneeName: MasterfilesApp::PartyRepo.new.find_organization_for_party_role(load.consignee_party_role_id).medium_description,
        consigneeAddressLine1: [consignee_address&.address_line_1, consignee_address&.address_line_2, consignee_address&.address_line_3].compact!.join(', '),
        consigneeAddressLine2: consignee_address&.city,
        consigneeAddressLine3: consignee_address&.postal_code,
        consigneeCountryId: load.destination_country,
        importCountryId: load.destination_country,
        cfCode: MasterfilesApp::PartyRepo.new.find_registration_code_for_party_role('CF', load.shipper_party_role_id).to_s,
        lspCode: MasterfilesApp::PartyRepo.new.find_registration_code_for_party_role('LSP', load.shipper_party_role_id).to_s,
        transportType: get(:voyage_types, load.voyage_type_id, :industry_description),
        vesselName: load.vessel_code,
        vesselType: load.container ? 'CONTAINER' : 'CONVENTIONAL',
        voyageNumber: load.voyage_number,
        regimeCode: load.temperature_code,
        shippingBookingReference: load.booking_reference,
        loadPort: load.pol_port_code,
        dischargePort: load.pod_port_code,
        shippedTargetCountry: load.destination_country,
        shippedTargetRegion: load.destination_region,
        locationOfIssue: load.location_of_issue,
        estimatedDepartureDate: load.etd,
        supportingDocuments: [
          # {
          #   supportingDocumentCode: '',
          #   supportingDocumentName: ''
          #   # supportingDocument: byte[]
          # }
        ],
        consignmentItems: [compile_consignment_items(load_id)],
        addendumDetails: compile_addendum_details(load_id),
        flexiFields: []
      }
    end

    def compile_consignment_items(load_id) # rubocop:disable Metrics/AbcSize
      load = FinishedGoodsApp::LoadRepo.new.find_load_flat(load_id)
      pallet_id = select_values_in_order(:pallets, :id, where: { load_id: load_id }, order: :id).first
      pallet = find_pallet_for_titan(pallet_id)
      pallet_sequence = find_pallet_sequence_for_titan(pallet&.oldest_pallet_sequence_id)

      {
        productDescription: pallet_sequence&.commodity_description,
        commonName: 'required', # Common name of product. Required if flag eCertRequired is set to true
        scientificName: 'required',
        nettWeightMeasureCode: 'KG',
        nettWeightMeasure: load.nett_weight.to_f.round(2),
        grossWeightMeasureCode: 'KG',
        grossWeightMeasure: load.verified_gross_weight.to_f.round(2),
        customsHarmonizedSystemClass: '',
        commodityVegetableClass: '',
        commodityConditionClass: '',
        commodityIntentOfUseClass: '',
        appliedProcessTypeCode: '',
        appliedProcessStartDate: '2019-09-07',
        appliedProcessEndDate: '2019-09-07',
        durationMeasureCode: '',
        durationMeasure: '2.5',
        appliedProcessTreatmentTypeLevel1: '',
        appliedProcessTreatmentTypeLevel2: '',
        appliedProcessChemicalCode: '',
        appliedProcessTemperatureUnitCode: '',
        appliedProcessTemperature: 0.00,
        appliedProcessConcentrationUnitCode: '',
        appliedProcessConcentration: 0.00,
        appliedProcessAdditionalNotes: '',
        packageLevelCode: 0,
        packageTypeCode: 'CT',
        packageItemUnitCode: 'a',
        packageItemQuantity: load.pallet_count,
        packageShippingMarks: '',
        additionalConsignmentNotes: load.memo_pad
      }
    end

    def find_pallet_for_titan(pallet_id) # rubocop:disable Metrics/AbcSize
      hash = find_with_association(:pallets, pallet_id)
      return nil if hash.nil?

      hash[:govt_inspection_pallet_id] = DB[:govt_inspection_pallets].where(pallet_id: pallet_id).get(:id)
      hash[:govt_inspection_sheet_id] = DB[:govt_inspection_pallets].where(pallet_id: pallet_id).get(:govt_inspection_sheet_id)
      hash[:oldest_pallet_sequence_id] = DB[:pallet_sequences].where(pallet_id: pallet_id).order(:id).get(:id)
      hash[:nett_weight] = hash[:nett_weight].to_f.round(2)
      hash[:gross_weight] = hash[:gross_weight].to_f.round(2)

      PalletForTitan.new(hash)
    end

    def find_pallet_sequence_for_titan(id) # rubocop:disable Metrics/AbcSize
      hash = find_with_association(:pallet_sequences, id)
      return nil if hash.nil?

      hash[:commodity_code] = get(:commodities, hash[:commodity_id], :code)
      hash[:commodity_description] = get(:commodities, hash[:commodity_id], :description)
      hash[:marketing_variety_code] = get(:marketing_varieties, hash[:marketing_variety_id], :marketing_variety_code)
      hash[:grade_code] = get(:grades, hash[:grade_id], :grade_code)
      hash[:puc_code] = get(:pucs, hash[:puc_id], :puc_code)
      hash[:orchard_code] = get(:orchards, hash[:orchard_id], :orchard_code)
      hash[:production_region_code] = get(:production_regions, hash[:production_region_id], :production_region_code)
      hash[:fruit_size_reference] = get(:fruit_size_references, hash[:fruit_size_reference_id], :size_reference)
      hash[:standard_pack_code] = get(:standard_pack_codes, hash[:standard_pack_code_id], :standard_pack_code)
      hash[:pallet_percentage] = hash[:pallet_carton_quantity].zero? ? 0 : (hash[:carton_quantity] / hash[:pallet_carton_quantity].to_f).round(3)
      hash[:nett_weight] = hash[:nett_weight].to_f.round(2)

      PalletSequenceForTitan.new(hash)
    end

    def compile_addendum_details(load_id) # rubocop:disable Metrics/AbcSize
      load = FinishedGoodsApp::LoadRepo.new.find_load_flat(load_id)

      details = []
      pallet_ids = select_values(:pallets, :id, load_id: load_id)
      pallet_ids.each do |pallet_id| # rubocop:disable Metrics/BlockLength
        pallet = find_pallet_for_titan(pallet_id)

        pallet_sequence = find_pallet_sequence_for_titan(pallet&.oldest_pallet_sequence_id)
        govt_inspection_sheet = GovtInspectionRepo.new.find_govt_inspection_sheet(pallet&.govt_inspection_sheet_id)
        govt_inspection_pallet = GovtInspectionRepo.new.find_govt_inspection_pallet_flat(pallet&.govt_inspection_pallet_id)

        details << {
          inspectedSSCC: pallet.pallet_number,
          stuffLoadDate: load&.shipped_at&.strftime('%F'),
          loadPointFboCode: govt_inspection_sheet&.inspection_point,
          consignmentNumber: govt_inspection_sheet&.consignment_note_number,
          phc: pallet.phc,
          clientRef: pallet_sequence&.pallet_sequence_number,
          commodityCode: pallet_sequence&.commodity_code,
          varietyCode: pallet_sequence&.marketing_variety_code,
          protocolExceptionIndicator: 'X7', # Smartfresh, X7, X8, X9 where the first character denotes the destination and the second character denotes the applicable phytosanitary
          productClass: pallet_sequence&.grade_code,
          nettWeight: pallet.nett_weight,
          grossWeight: pallet.gross_weight,
          cartonQuantity: pallet.carton_quantity,
          inspectionPoint: govt_inspection_sheet&.inspection_point,
          inspectorCode: govt_inspection_sheet&.inspector_code,
          inspectionDate: govt_inspection_pallet&.inspected_at,
          upn: govt_inspection_sheet&.upn,
          inspectedTargetRegion: govt_inspection_sheet&.destination_region,
          inspectedTargetCountry: govt_inspection_sheet&.destination_country,
          containerNumber: load&.container_code,
          addendumDetailLines: compile_addendum_detail_sequences(pallet_id)
        }
      end
      details
    end

    def compile_addendum_detail_sequences(pallet_id)
      pallet_sequence_ids = select_values(:pallet_sequences, :id, pallet_id: pallet_id)
      sequences = []
      pallet_sequence_ids.each do |pallet_sequence_id|
        pallet_sequence = find_pallet_sequence_for_titan(pallet_sequence_id)
        sequences << {
          sequenceNumberOfInspectedSSCC: pallet_sequence.pallet_sequence_number,
          puc: pallet_sequence.puc_code,
          orchard: pallet_sequence.orchard_code,
          productionArea: pallet_sequence.production_region_code,
          phytoData: pallet_sequence.phyto_data || '',
          sizeCountBerrySize: pallet_sequence.fruit_size_reference,
          packCode: pallet_sequence.standard_pack_code,
          palletQuantity: pallet_sequence.pallet_percentage
        }
      end
      sequences
    end

    # def sort_like(left, right)
    #   raise ArgumentError, 'Hash input required for "sort_like" method' unless (left.is_a? Hash) || (right.is_a? Hash)
    #
    #   right_sorted = {}
    #   left.each do |left_key, left_value|
    #     right_value = right[left_key]
    #     if right_value.is_a? Array
    #       sorted_array = []
    #       right_value.each do |hash|
    #         sorted_array << sort_like(left_value.first, hash)
    #       end
    #       right_sorted[left_key] = sorted_array
    #       next
    #     end
    #     right_sorted[left_key] = right[left_key]
    #   end
    #
    #   # check that all keys are present
    #   right.each do |k, v|
    #     next if right_sorted[k]
    #
    #     right_sorted[k] = v
    #   end
    #
    #   right_sorted
    # end
  end
end
