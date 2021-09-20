# frozen_null_literal: true

module FinishedGoodsApp
  class TitanRepo < BaseRepo # rubocop:disable Metrics/ClassLength
    crud_calls_for :titan_requests, name: :titan_request

    def find_pallet_for_titan(pallet_id) # rubocop:disable Metrics/AbcSize
      oldest_id = DB[:pallet_sequences].where(pallet_id: pallet_id).order(:id).get(:id)
      query = MesscadaApp::DatasetPalletSequence.call('WHERE pallet_sequences.id = ? AND pallet_sequences.pallet_id IS NOT NULL')
      hash = DB[query, oldest_id].first
      raise Crossbeams::FrameworkError, "Pallet not found for pallet_id: #{pallet_id}" if hash.nil_or_empty?

      if hash[:nett_weight_per_carton].zero? || hash[:gross_weight_per_carton].zero?
        hash[:nett_weight_per_carton] = get_value(:standard_product_weights, :nett_weight, { commodity_id: hash[:commodity_id], standard_pack_id: hash[:standard_pack_id] })
        hash[:gross_weight_per_carton] = get_value(:standard_product_weights, :gross_weight, { commodity_id: hash[:commodity_id], standard_pack_id: hash[:standard_pack_id] })
      end
      hash[:bin] = get(:standard_pack_codes, hash[:standard_pack_id], :bin) || false

      PalletForTitan.new(hash)
    end

    def find_pallet_sequence_for_titan(id)
      query = MesscadaApp::DatasetPalletSequence.call('WHERE pallet_sequences.id = ?')
      hash = DB[query, id].first
      raise Crossbeams::FrameworkError, "Pallet Sequence not found for pallet_sequence_id: #{id}" if hash.nil_or_empty?

      hash[:pallet_percentage] = hash[:pallet_carton_quantity].zero? ? 0 : (hash[:carton_quantity] / hash[:pallet_carton_quantity].to_f).round(3)
      PalletSequenceForTitan.new(hash)
    end

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
      TitanRequestFlat.new(hash)
    end

    def last_titan_addendum_request(load_id)
      hash = DB[:titan_requests].where(load_id: load_id).reverse(:id).first
      return nil if hash.nil?

      TitanRequest.new(hash)
    end

    def parse_titan_inspection_request_doc(hash)
      request_doc = hash[:request_doc] ||= {}
      request_lines = request_doc.delete('consignmentLines') || []
      hash[:request_array] = flatten_to_table(request_doc)
      hash[:request_array] += flatten_to_table(request_lines)
      hash
    end

    def parse_titan_inspection_result_doc(hash)
      result_doc = hash[:result_doc] ||= {}
      result_doc = { 'message' => result_doc } if result_doc.is_a?(String)
      result_doc.delete('type')
      result_doc.delete('traceId')
      result_lines = result_doc.delete('errors') || []
      hash[:result_array] = flatten_to_table(result_doc)
      hash[:result_array] += flatten_to_table(result_lines)
      hash
    end

    def parse_titan_addendum_request_doc(hash)
      request_doc = hash[:request_doc] ||= {}
      addendum_details = request_doc.delete('addendumDetails') || []
      consignment_items = request_doc.delete('consignmentItems') || []
      hash[:request_array] = flatten_to_table(request_doc)
      hash[:request_array] += flatten_to_table(addendum_details, prefix: 'AddendumDetails')
      hash[:request_array] += flatten_to_table(consignment_items, prefix: 'ConsignmentItems')
      hash
    end

    def parse_titan_addendum_result_doc(hash)
      result_doc = hash[:result_doc] ||= {}
      result_doc.delete('type')
      result_doc.delete('traceId')
      result_lines = result_doc.delete('errors')
      hash[:result_array] = flatten_to_table(result_doc)
      hash[:result_array] += flatten_to_table(result_lines, prefix: 'Error: ') if result_lines.is_a? Hash
      hash
    end

    def find_titan_inspection(govt_inspection_sheet_id) # rubocop:disable Metrics/AbcSize
      hash = {}
      ds = DB[:titan_requests].where(govt_inspection_sheet_id: govt_inspection_sheet_id).reverse(:id)
      return nil unless ds.get(:id)

      hash[:govt_inspection_sheet_id] = govt_inspection_sheet_id
      hash[:reinspection] = get(:govt_inspection_sheets, govt_inspection_sheet_id, :reinspection)
      hash[:validated] = ds.where(request_type: 'Validation').get(:success)
      hash[:request_type] = ds.get(:request_type)
      hash[:success] = ds.get(:success)
      hash[:inspection_message_id] = ds.exclude(inspection_message_id: nil).get(:inspection_message_id)
      result_doc = ds.where(request_type: 'Results').get(:result_doc) || {}
      hash[:upn] = result_doc['upn']
      hash[:titan_inspector] = result_doc['inspector']
      hash[:pallets] = []
      consignment_lines = result_doc['consignmentLines'] || []
      consignment_lines.each do |line|
        pallet_number = line['sscc']
        pallet_id = get_id(:pallets, pallet_number: pallet_number)
        raise Crossbeams::FrameworkError, "Pallet id not found for #{pallet_number}" unless pallet_id

        hash[:pallets] << { pallet_id: pallet_id, pallet_number: pallet_number, passed: line['result'] == 'Pass', rejection_reasons: line['rejectionReasons'] || [] }
      end
      TitanInspectionFlat.new(hash)
    end

    def compile_inspection(govt_inspection_sheet_id) # rubocop:disable Metrics/AbcSize
      govt_inspection_sheet = GovtInspectionRepo.new.find_govt_inspection_sheet(govt_inspection_sheet_id)
      { consignmentNumber: govt_inspection_sheet.consignment_note_number,
        bookingRef: govt_inspection_sheet.booking_reference,
        exporter: party_repo.find_registration_code_for_party_role('FBO', govt_inspection_sheet.exporter_party_role_id),
        billingParty: party_repo.find_registration_code_for_party_role('BILLING', govt_inspection_sheet.inspection_billing_party_role_id),
        # inspectionPoint: AppConst::TITAN_INSPECTION_API_USER_ID,
        inspectionPoint: govt_inspection_sheet.inspection_point,
        inspector: govt_inspection_sheet.inspector_code,
        inspectionDate: Time.now.strftime('%Y-%m-%d'),
        inspectionTime: Time.now.strftime('%k:%M:%S'),
        consignmentLines: compile_inspection_pallets(govt_inspection_sheet_id) }
    end

    def compile_inspection_pallets(govt_inspection_sheet_id) # rubocop:disable Metrics/AbcSize
      pallet_ids = select_values(:govt_inspection_pallets, :pallet_id, govt_inspection_sheet_id: govt_inspection_sheet_id)
      govt_inspection_sheet = GovtInspectionRepo.new.find_govt_inspection_sheet(govt_inspection_sheet_id)
      inspection_pallets = []
      pallet_ids.each do |pallet_id|
        pallet = find_pallet_for_titan(pallet_id)
        ecert_agreement_id = get_value(:ecert_tracking_units, :ecert_agreement_id, pallet_id: pallet_id)
        ecert_agreement_code = get(:ecert_agreements, ecert_agreement_id, :code)
        inspection_pallets << { phc: pallet.phc,
                                sscc: pallet.pallet_number,
                                commodity: pallet.commodity,
                                variety: pallet.marketing_variety,
                                class: pallet.grade,
                                inspectionSampleWeight: pallet.nett_weight_per_carton.to_f.round(3),
                                nettWeightPack: pallet.nett_weight_per_carton.to_f.round(3),
                                grossWeightPack: pallet.gross_weight_per_carton.to_f.round(3),
                                carton: pallet.bin ? 'B' : 'C',
                                cartonQty: pallet.pallet_carton_quantity,
                                targetRegion: govt_inspection_sheet.destination_region,
                                targetCountry: govt_inspection_sheet.iso_country_code,
                                protocolExceptionIndicator: govt_inspection_sheet.titan_protocol_exception || 'NA',
                                agreementCode: ecert_agreement_code,
                                consignmentLinePallets: compile_inspection_pallet_sequences(pallet_id) }
      end
      inspection_pallets
    end

    def compile_inspection_pallet_sequences(pallet_id) # rubocop:disable Metrics/AbcSize
      pallet_sequence_ids = select_values(:pallet_sequences, :id, pallet_id: pallet_id)

      inspection_pallet_sequences = []

      pallet_sequence_ids.each do |pallet_sequence_id|
        pallet_sequence = find_pallet_sequence_for_titan(pallet_sequence_id)
        inspection_pallet_sequences << {
          ssccReference: pallet_sequence.pallet_number,
          palletQty: pallet_sequence.carton_quantity,
          ssccSequenceNumber: pallet_sequence.pallet_sequence_number,
          puc: pallet_sequence.puc,
          orchard: pallet_sequence.orchard,
          phytoData: pallet_sequence.phyto_data || '',
          packCode: pallet_sequence.std_pack,
          packDate: pallet_sequence.palletized_at || pallet_sequence.partially_palletized_at,
          # FIXME: remove partially_palletized_at should only use palletized_at
          sizeCount: pallet_sequence.actual_count.nil_or_empty? ? pallet_sequence.size_ref : pallet_sequence.actual_count.to_i,
          inventoryCode: pallet_sequence.inventory_code,
          prePackingTreatment: 'NA'
        }
      end
      inspection_pallet_sequences
    end

    def find_titan_addendum(load_id, mode) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity
      return nil if mode == :request

      request_type = case mode
                     when :status
                       AppConst::TITAN_ADDENDUM_REQUEST
                     when :cancel
                       AppConst::TITAN_ADDENDUM_REQUEST
                     when :load
                       [AppConst::TITAN_ADDENDUM_STATUS, AppConst::TITAN_ADDENDUM_REQUEST]
                     end
      hash = DB[:titan_requests].where(load_id: load_id, request_type: request_type).reverse(:id).first
      return nil unless hash

      status_hash = hash[:result_doc] || {}
      hash[:addendum_status] = status_hash['addendumStatus']
      # hash[:best_regime_code] = status_hash['bestRegimeCode']
      hash[:verification_status] = status_hash['verificationStatus']
      hash[:addendum_validations] = status_hash['addendumValidations']
      # hash[:available_regime_code] = status_hash['availableRegimeCode']
      hash[:e_cert_response_message] = status_hash['eCertResponseMessage']
      hash[:e_cert_hub_tracking_number] = status_hash['eCertHubTrackingNumber']
      hash[:e_cert_hub_tracking_status] = status_hash['eCertHubTrackingStatus']
      # hash[:e_cert_application_status] = status_hash['ecertApplicationStatus']
      # hash[:phyt_clean_verification_key] = status_hash['phytCleanVerificationKey']
      hash[:export_certification_status] = status_hash['exportCertificationStatus']

      cancel = DB[:titan_requests].where(load_id: load_id, request_type: AppConst::TITAN_ADDENDUM_CANCEL).reverse(:id).first || {}
      cancel_hash = cancel[:result_doc] || {}
      hash[:cancelled_status] = cancel_hash['message']
      hash[:cancelled_at] = cancel[:updated_at]
      TitanAddendumFlat.new(hash)
    end

    def compile_addendum(load_id) # rubocop:disable Metrics/AbcSize
      load = LoadRepo.new.find_load(load_id)
      consignor_address = party_repo.find_address_for_party_role('Delivery Address', load.exporter_party_role_id)
      consignee_address = party_repo.find_address_for_party_role('Delivery Address', load.consignee_party_role_id)
      pallet_ids = select_values(:pallets, :id, load_id: load_id)
      ecert_agreement_ids = select_values(:ecert_tracking_units, :ecert_agreement_id, pallet_id: pallet_ids)
      ecert_agreement_codes = select_values(:ecert_agreements, :code, id: ecert_agreement_ids).join('')
      fbo_code = party_repo.find_registration_code_for_party_role('FBO', load.exporter_party_role_id).to_s
      payload = {
        eCertRequired: false,
        cbrid: 0,
        cbrBillingID: 0,
        requestId: "#{fbo_code}#{Time.now.strftime('%Y%m%d')}#{load_id}",
        eCertAgreementCode: ecert_agreement_codes,
        exporterCode: fbo_code,
        consignorName: party_repo.find_organization_for_party_role(load.exporter_party_role_id).medium_description,
        consignorAddressLine1: [consignor_address&.address_line_1, consignor_address&.address_line_2, consignor_address&.address_line_3].compact!.join(', '),
        consignorAddressLine2: consignor_address&.city,
        consignorAddressLine3: consignor_address&.postal_code,
        consigneeId: party_repo.find_organization_for_party_role(load.consignee_party_role_id).short_description,
        consigneeName: party_repo.find_organization_for_party_role(load.consignee_party_role_id).medium_description,
        consigneeAddressLine1: [consignee_address&.address_line_1, consignee_address&.address_line_2, consignee_address&.address_line_3].compact!.join(', '),
        consigneeAddressLine2: consignee_address&.city,
        consigneeAddressLine3: consignee_address&.postal_code,
        consigneeCountryId: load.iso_country_code,
        importCountryId: load.iso_country_code,
        cfCode: party_repo.find_registration_code_for_party_role('CF', load.shipper_party_role_id).to_s,
        lspCode: party_repo.find_registration_code_for_party_role('LSP', load.shipper_party_role_id).to_s,
        transportType: get(:voyage_types, load.voyage_type_id, :industry_description),
        vesselName: load.vessel_code,
        vesselType: load.container ? 'CONTAINER' : 'CONVENTIONAL',
        voyageNumber: load.voyage_number,
        regimeCode: load.temperature_code,
        shippingBookingReference: load.booking_reference,
        loadPort: load.pol_port_code,
        dischargePort: load.pod_port_code,
        shippedTargetCountry: load.iso_country_code,
        shippedTargetRegion: load.destination_region,
        locationOfIssue: load.location_of_issue, # Cannot be blank
        eCertDesiredIssueLocation: '',
        estimatedDepartureDate: load.etd&.strftime('%F'), # Cannot be blank
        supportingDocuments: [
          # {
          #   supportingDocumentCode: '',
          #   supportingDocumentName: ''
          #   mimetype: '',
          #   isPrintable: '',
          #   # supportingDocument: byte[]
          # }
        ],
        consignmentItems: [compile_consignment_items(load)],
        addendumDetails: compile_addendum_details(load_id),
        flexiFields: []
      }
      res = validate_addendum_payload(payload)
      raise Crossbeams::InfoError, "Invalid addendum request: #{unwrap_error_set(res.errors)}" if res.failure?

      res.to_h
    end

    def compile_consignment_items(load)
      pallet_id = select_values_in_order(:pallets, :id, where: { load_id: load.id }, order: :id).first
      pallet = find_pallet_for_titan(pallet_id)
      {
        CommonName: pallet.commodity_description, # Cannot be blank - BUT: "CommonName" (use cultivar?)
        ScientificName: pallet.commodity_description, # Cannot be blank - BUT: "ScientificName"
        nettWeightMeasureCode: 'KG',
        nettWeightMeasure: load.nett_weight.to_f.round(2),
        grossWeightMeasureCode: 'KG',
        grossWeightMeasure: load.verified_gross_weight.to_f.round(2),
        customsHarmonizedSystemClass: '',
        commodityVegetableClass: pallet.commodity, # ???
        commodityConditionClass: '',
        commodityIntentOfUseClass: '',
        appliedProcessStartDate: nil,
        appliedProcessEndDate: nil,
        durationMeasureCode: '',
        durationMeasure: '',
        appliedProcessTreatmentTypeLevel1: '',
        appliedProcessTreatmentTypeLevel2: '',
        appliedProcessChemicalCode: '',
        fullTreatmentInfromation: '',
        appliedProcessTemperatureUnitCode: '',
        appliedProcessTemperature: 0.00,
        appliedProcessConcentrationUnitCode: '',
        appliedProcessConcentration: 0.00,
        appliedProcessAdditionalNotes: '',
        packageLevelCode: 0,
        packageTypeCode: pallet.basic_pack,
        packageItemUnitCode: 'EA',
        packageItemQuantity: load.pallet_count,
        packageShippingMarks: '',
        additionalConsignmentNotes: load.memo_pad
      }
    end

    def compile_addendum_details(load_id) # rubocop:disable Metrics/AbcSize
      gi_repo = GovtInspectionRepo.new
      details = []
      pallet_ids = select_values(:pallets, :id, load_id: load_id)
      pallet_ids.each do |pallet_id| # rubocop:disable Metrics/BlockLength
        pallet = find_pallet_for_titan(pallet_id)
        govt_inspection_sheet = gi_repo.find_govt_inspection_sheet(pallet.govt_inspection_sheet_id)
        govt_inspection_pallet = gi_repo.find_govt_inspection_pallet(pallet.govt_inspection_pallet_id)
        details << {
          stuffLoadDate: pallet.shipped_at.strftime('%F'),
          loadPointFboCode: AppConst::CR_FG.titan_cold_store_fbo_code,
          consignmentNumber: pallet.consignment_note_number,
          phc: pallet.phc,
          inspectedSSCC: pallet.pallet_number,
          clientRef: pallet_id.to_s,
          upn: govt_inspection_sheet.upn,
          inspectedTargetRegion: govt_inspection_sheet.destination_region,
          inspectedTargetCountry: govt_inspection_sheet.iso_country_code,
          commodityCode: pallet.commodity,
          fleshColour: '', # ???
          varietyCode: pallet.marketing_variety,
          protocolExceptionIndicator: govt_inspection_sheet.titan_protocol_exception || 'NA',
          productClass: pallet.grade,
          nettWeight: pallet.nett_weight.to_f.round(2),
          grossWeight: pallet.gross_weight.to_f.round(2), # If derived weight, add this to nett? OR...?
          cartonQuantity: pallet.pallet_carton_quantity,
          inspectionPoint: govt_inspection_sheet.inspection_point,
          inspectorCode: govt_inspection_sheet.inspector_code,
          inspectionDate: govt_inspection_pallet.inspected_at.strftime('%F'),
          containerNumber: pallet.container,
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
          puc: pallet_sequence.puc,
          orchard: pallet_sequence.orchard,
          productionArea: pallet_sequence.production_region,
          phytoData: pallet_sequence.phyto_data || '',
          sizeCountBerrySize: pallet_sequence.edi_size_count, # Cannot be blank
          packCode: pallet_sequence.std_pack,
          palletQuantity: pallet_sequence.carton_quantity,
          nettPalletWeight: pallet_sequence.sequence_nett_weight.to_f.round(2)
        }
      end
      sequences
    end

    def party_repo
      MasterfilesApp::PartyRepo.new
    end

    def humanize(value)
      array = value.to_s.split(/(?=[A-Z])/)
      array.map(&:capitalize).join('')
    end

    def flatten_to_table(input, prefix: nil) # rubocop:disable Metrics/AbcSize
      array_out = []
      is_an_array = input.is_a? Array
      input = [input] unless is_an_array
      Array(0...input.length).each do |i|
        if input[i].is_a?(String)
          array_out << { column: 'Message', value: input[i] }
        else
          input[i].each do |k, v|
            column = "#{prefix}#{humanize(k)}"
            column = "#{humanize(k)}[#{i}]" if is_an_array
            column = "#{prefix}[#{i}].#{humanize(k)}" if prefix && is_an_array
            array_out << { column: column, value: Array(v).map { |vv| UtilityFunctions.scientific_notation_to_s(vv) }.join(' ') }
          end
        end
      end
      array_out
    end

    private

    def validate_addendum_payload(payload)
      TitanAddendumPayloadSchema.call(payload)
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
