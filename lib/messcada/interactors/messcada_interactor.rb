# frozen_string_literal: true

module MesscadaApp
  class MesscadaInteractor < BaseInteractor # rubocop:disable Metrics/ClassLength
    # Take a scanned pallet number and convert it to a system pallet number
    # Sometimes a pallet scanned from an external supplier will not be a
    # valid SSCC format.
    def pallet_number_from_scan(scanned_pallet_number)
      ScannedPalletNumber.new(scanned_pallet_number: scanned_pallet_number).pallet_number
    end

    # def validate_pallet_to_be_verified(scanned_pallet_number)
    #   pallet_number = pallet_number_from_scan(scanned_pallet_number)
    #   pallet_sequences = find_pallet_sequences_by_pallet_number(pallet_number)
    #   return failed_response("Scanned Pallet:#{pallet_number} doesn't exist") if pallet_sequences.empty?
    #   return failed_response("Scanned Pallet:#{pallet_number} has already been inspected") if pallet_sequences.first[:inspected]
    #
    #   success_response('pallet found', oldest_pallet_sequence_id: pallet_sequences.first[:id])
    # end

    def pallet_to_be_verified(params)
      res = MesscadaApp::ScanCartonLabelOrPallet.call(params)
      return res unless res.success

      scanned = res.instance
      check_pallet!(:not_scrapped, scanned.pallet_number)
      check_pallet!(:not_inspected, scanned.pallet_number)

      # Get 1st seq...
      sequence_id = scanned.pallet_sequence_id || scanned.first_sequence_id
      success_response('Pallet found', sequence_id)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def combined_verification_scan(params)
      res = carton_verification(params[:carton_number])
      return failed_response(res.message) unless res.success

      res = MesscadaApp::ScanCartonLabelOrPallet.call(scanned_number: params[:carton_number], expect: :carton_label)
      return res unless res.success

      scanned = res.instance
      return failed_response('Carton verification failed to create pallet.') if scanned.pallet_id.nil?

      success_response('Verified Carton', scanned.first_sequence_id)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def find_pallet_by_scanning_pallet_or_carton_number(params)
      res = MesscadaApp::ScanCartonLabelOrPallet.call(params)
      return res unless res.success

      scanned = res.instance
      check_pallet!(:not_scrapped, scanned.pallet_number)
      pallet = repo.find_pallet_flat(scanned.pallet_id)
      success_response("Found Pallet #{scanned.pallet_number}", pallet)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def get_deck_pallets(location, location_scan_field) # rubocop:disable Metrics/AbcSize
      location_id = MasterfilesApp::LocationRepo.new.resolve_location_id_from_scan(location, location_scan_field)
      return failed_response('Location does not exist') if location_id.nil_or_empty?

      location = MasterfilesApp::LocationRepo.new.find_location(location_id)
      return failed_response("Location:#{location[:location_long_code]} is not a deck") unless location[:location_type_code] == AppConst::LOCATION_TYPES_COLD_BAY_DECK

      success_response('ok', pallets: locations_repo.get_deck_pallets(location_id), deck_code: location[:location_long_code])
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    rescue StandardError => e
      ErrorMailer.send_exception_email(e, subject: self.class.name, message: decorate_mail_message(__method__))
      puts e.message
      puts e.backtrace.join("\n")
      failed_response(e.message)
    end

    def find_pallet_sequences_by_pallet_number(scanned_pallet_number)
      pallet_number = pallet_number_from_scan(scanned_pallet_number)
      repo.find_pallet_sequences_by_pallet_number(pallet_number)
    end

    def update_bin_weights_and_tip_bin(params) # rubocop:disable Metrics/AbcSize
      repo.transaction do
        res = update_rmt_bin_weights(params)
        if res.success
          res = tip_rmt_bin(params)
          if res.success
            succ = bin_tipping_response(res, params)
            Crossbeams::RobotResponder.new(succ).render
          else
            err = bin_tipping_response(res, params)
            raise Crossbeams::RobotResponder.new(err).render
          end
        else
          err = MesscadaApp::RobotFeedback.new(device: params[:device],
                                               status: false,
                                               line1: unwrap_failed_response(res))
          raise Crossbeams::RobotResponder.new(err).render
        end
      end
    rescue StandardError => e
      e.message
    end

    def multi_update_bin_weights_and_tip_bin(params) # rubocop:disable Metrics/AbcSize
      bin_numbers = params[:bin_number].split(',')
      gross_weight = (params[:gross_weight].to_f / bin_numbers.size)
      repo.transaction do
        succ = nil
        bin_numbers.each do |bin_number|
          bin_params = { bin_number: bin_number, gross_weight: gross_weight, measurement_unit: params[:measurement_unit], device: params[:device] }
          res = update_rmt_bin_weights(bin_params)
          unless res.success
            err = MesscadaApp::RobotFeedback.new(device: params[:device],
                                                 status: false,
                                                 line1: unwrap_failed_response(res))
            raise Crossbeams::RobotResponder.new(err).render
          end

          res = tip_rmt_bin(bin_params)
          unless res.success
            err = bin_tipping_response(res, bin_params)
            raise Crossbeams::RobotResponder.new(err).render
          end

          succ = MesscadaApp::RobotFeedback.new(device: params[:device], status: true,
                                                line1: "#{res.message} - run:#{res.instance[:run_id]}, tipped: #{res.instance[:bins_tipped]}")
        end

        Crossbeams::RobotResponder.new(succ).render
      end
    rescue StandardError => e
      e.message
    end

    def bin_tipping_response(res, params) # rubocop:disable Metrics/AbcSize
      if res.success
        MesscadaApp::RobotFeedback.new(device: params[:device],
                                       status: true,
                                       line1: "#{res.message} - run:#{res.instance[:run_id]}, tipped: #{res.instance[:bins_tipped]}",
                                       line2: "farm:#{res.instance[:farm_code]}",
                                       line3: "puc:#{res.instance[:puc_code]}",
                                       line4: "orch:#{res.instance[:orchard_code]}",
                                       line5: "cult group: #{res.instance[:cultivar_group_code]}",
                                       line6: "cult:#{res.instance[:cultivar_name]}",
                                       short1: res.message,
                                       short2: "run:#{res.instance[:run_id]}, tipped: #{res.instance[:bins_tipped]}",
                                       short3: "farm:#{res.instance[:farm_code]}, puc:#{res.instance[:puc_code]}, orch:#{res.instance[:orchard_code]}",
                                       short4: "cult: #{res.instance[:cultivar_group_code]}, / #{res.instance[:cultivar_name]}")
      else
        MesscadaApp::RobotFeedback.new(device: params[:device],
                                       status: false,
                                       line1: unwrap_failed_response(res))
      end
    end

    def update_rmt_bin_weights(params) # rubocop:disable Metrics/AbcSize
      res = validate_update_rmt_bin_weights_params(params)
      return validation_failed_response(res) if res.failure?

      MesscadaApp::UpdateBinWeights.call(res)
    rescue Crossbeams::InfoError => e
      ErrorMailer.send_exception_email(e, subject: "INFO: #{self.class.name}", message: decorate_mail_message(__method__))
      puts e.message
      puts e.backtrace.join("\n")
      failed_response(e.message)
    rescue StandardError => e
      ErrorMailer.send_exception_email(e, subject: self.class.name, message: decorate_mail_message(__method__))
      puts e.message
      puts e.backtrace.join("\n")
      failed_response(e.message)
    end

    def tip_rmt_bin(params) # rubocop:disable Metrics/AbcSize
      res = validate_tip_rmt_bin_params(params)
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        res = MesscadaApp::TipBin.call(res)

        if res.success
          log_status(:rmt_bins, res.instance[:rmt_bin_id], 'TIPPED')
          log_transaction
        end
        res
      end
    rescue Crossbeams::InfoError => e
      ErrorMailer.send_exception_email(e, subject: "INFO: #{self.class.name}", message: decorate_mail_message(__method__))
      failed_response(e.message)
    rescue StandardError => e
      ErrorMailer.send_exception_email(e, subject: self.class.name, message: decorate_mail_message(__method__))
      puts e.message
      puts e.backtrace.join("\n")
      failed_response("System error: #{e.message.gsub(/['"`<>]/, '')}")
    end

    def can_tip_bin?(params) # rubocop:disable Metrics/AbcSize
      res = validate_tip_rmt_bin_params(params)
      return validation_failed_response(res) if res.failure?

      MesscadaApp::CanTipBin.call(res[:bin_number], res[:device])
    rescue Crossbeams::InfoError => e
      ErrorMailer.send_exception_email(e, subject: "INFO: #{self.class.name}", message: decorate_mail_message(__method__))
      failed_response(e.message)
    rescue StandardError => e
      ErrorMailer.send_exception_email(e, subject: self.class.name, message: decorate_mail_message(__method__))
      puts e.message
      puts e.backtrace.join("\n")
      failed_response("System error: #{e.message.gsub(/['"`<>]/, '')}")
    end

    def carton_labeling(params) # rubocop:disable Metrics/AbcSize
      cvl_res = nil
      repo.transaction do
        cvl_res = MesscadaApp::CartonLabeling.call(params)
        log_transaction
      end
      cvl_res
    rescue Crossbeams::InfoError => e
      ErrorMailer.send_exception_email(e, subject: "INFO: #{self.class.name}", message: decorate_mail_message(__method__)) unless e.message.start_with?('No setup data cached') || AppConst::ROBOT_DISPLAY_LINES == 4
      AppConst::ROBOT_LOG.warn(e.message)
      puts e.message
      puts e.backtrace.join("\n")
      failed_response(e.message)
    rescue StandardError => e
      ErrorMailer.send_exception_email(e, subject: self.class.name, message: decorate_mail_message(__method__))
      AppConst::ROBOT_LOG.error(e.message)
      puts e
      puts e.backtrace.join("\n")
      failed_response(e.message)
    end

    def xml_carton_labeling(params) # rubocop:disable Metrics/AbcSize
      cvl_res = nil
      repo.transaction do
        cvl_res = MesscadaApp::CartonLabeling.call(params)
        log_transaction
      end
      xml_label_content(params[:system_resource], cvl_res.instance)
    rescue Crossbeams::InfoError => e
      # Only send an email if the error is not caused by an un-allocated button:
      ErrorMailer.send_exception_email(e, subject: "INFO: #{self.class.name}", message: decorate_mail_message(__method__)) unless e.message.start_with?('No setup data cached')
      AppConst::ROBOT_LOG.info(e.message)
      puts e.message
      puts e.backtrace.join("\n")
      failed_response(e.message)
    rescue StandardError => e
      ErrorMailer.send_exception_email(e, subject: self.class.name, message: decorate_mail_message(__method__))
      AppConst::ROBOT_LOG.error(e.message)
      puts e
      puts e.backtrace.join("\n")
      failed_response(e.message)
    end

    def check_weights(params)
      p params
      alloc_hash = production_run_repo.allocation_for_button_code(params[:device])
      raise Crossbeams::InfoError, "There is no allocation for #{params[:device]}" if alloc_hash.nil?

      check_weights = product_setup_repo.check_weights_for_product_setup(alloc_hash[:product_setup_id])
      raise Crossbeams::InfoError, 'No check weights set up for product' if check_weights.nil?

      # Get fruitspec from button (running run)
      # get line from resource
      # labeling_run_for_line(line_id)
      # get alloc for run & resource
      # none: raise InfoError
      # Get STD pack weights
      # { pack_code: 'A123', min_gross_weight: 12, max_gross_weight: 20, commodity_code: 'AP' }
      check_weights
    end

    def check_carton_label_weight(params)
      check_weights = check_weights(params)
      check_weights[:weight] = params[:weight]
      contract = CartonLabelCheckWeightContract.new
      res = contract.call(check_weights)
      return failed_response(unwrap_error_set(res.errors)) if res.failure?

      success_response('ok', params)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def send_label_to_printer(params) # rubocop:disable Metrics/AbcSize
      # Change ctn labeling to handle a gross weight param
      res = carton_labeling(params)
      return res unless res.success

      schema = Nokogiri::XML(res.instance)
      label_name = schema.xpath('.//label/template').text
      quantity = schema.xpath('.//label/quantity').text
      printer = printer_for_robot(params[:system_resource].id)
      vars = {}
      schema.xpath('.//label/fvalue').each_with_index { |node, i| vars["F#{i + 1}".to_sym] = node.text }

      # call messerver to print
      res = MesserverApp::MesserverRepo.new.print_published_label(label_name, vars, quantity, printer)
      # res = success_response('a dummy test')
      # res = failed_response('Pretend fail print...')
      # PRN-01
      # "<label><status>true</status><template>JS_TEST</template><quantity>1</quantity><fvalue>4265559</fvalue><fvalue>41</fvalue><fvalue>PEARS</fvalue><fvalue>PACKHAM'S TRIUMPH</fvalue><fvalue>1A</fvalue><fvalue>A1-2</fvalue><fvalue>E0351</fvalue><fvalue>6113</fvalue><fvalue>V1044</fvalue><fvalue>45</fvalue><fvalue>PR</fvalue><fvalue></fvalue><fvalue>GGN 4050373704834</fvalue><fvalue></fvalue><lcd1>Label JS_TEST</lcd1><lcd2>Label printed...</lcd2><lcd3></lcd3><lcd4></lcd4><lcd5></lcd5><lcd6></lcd6><msg>Carton Label printed successfully</msg></label>"
      return res unless res.success

      log = "Printed (#{label_name}): #{vars.values.join(', ')}"
      success_response(log)
      # success_response(res.message, printer: printer, vars: vars.inspect) # change this to a string rep of lbl, prn & vars
    end

    def carton_verification(scanned_number)  # rubocop:disable Metrics/AbcSize
      cvl_res = nil
      repo.transaction do
        cvl_res = MesscadaApp::CartonVerification.call(@user, scanned_number)
        log_transaction
      end
      cvl_res
    rescue Crossbeams::InfoError => e
      ErrorMailer.send_exception_email(e, subject: "INFO: #{self.class.name}", message: decorate_mail_message(__method__))
      puts e.message
      puts e.backtrace.join("\n")
      failed_response(e.message)
    rescue StandardError => e
      ErrorMailer.send_exception_email(e, subject: self.class.name, message: decorate_mail_message(__method__))
      puts e
      puts e.backtrace.join("\n")
      failed_response(e.message)
    end

    def carton_verification_and_weighing(params) # rubocop:disable Metrics/AbcSize
      res = CartonVerificationAndWeighingSchema.call(params)
      return validation_failed_response(res) if res.failure?

      check_res = validate_device_and_label_exist(res[:device], res[:carton_number])
      return check_res unless check_res.success

      cvl_res = nil
      repo.transaction do
        cvl_res = MesscadaApp::CartonVerification.call(@user, res[:carton_number])
        raise Crossbeams::InfoError, cvl_res.message unless cvl_res.success

        attrs = res.to_h
        attrs[:carton_number] = cvl_res.instance[:carton_label_id]
        cvl_res = MesscadaApp::CartonWeighing.call(attrs)
        raise Crossbeams::InfoError, cvl_res.message unless cvl_res.success

        log_transaction
      end
      cvl_res
    rescue Crossbeams::InfoError => e
      ErrorMailer.send_exception_email(e, subject: "INFO: #{self.class.name}", message: decorate_mail_message(__method__))
      puts e.message
      puts e.backtrace.join("\n")
      failed_response(e.message)
    rescue StandardError => e
      ErrorMailer.send_exception_email(e, subject: self.class.name, message: decorate_mail_message(__method__))
      puts e.message
      puts e.backtrace.join("\n")
      failed_response(e.message)
    end

    def carton_verification_and_weighing_and_labeling(params, request_ip) # rubocop:disable Metrics/AbcSize,  Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      res = CartonVerificationAndWeighingSchema.call(params)
      return validation_failed_response(res) if res.failure?

      check_res = validate_device_and_label_exist(res[:device], res[:carton_number])
      return check_res unless check_res.success

      cvl_res = nil
      repo.transaction do
        cvl_res = MesscadaApp::CartonVerification.call(@user, res[:carton_number])
        raise Crossbeams::InfoError, cvl_res.message unless cvl_res.success

        attrs = res.to_h
        attrs[:carton_number] = cvl_res.instance[:carton_label_id]
        cvl_res = MesscadaApp::CartonWeighing.call(attrs)
        raise Crossbeams::InfoError, cvl_res.message unless cvl_res.success

        cvl_res = MesscadaApp::CartonLabelPrinting.call(attrs, request_ip)
        raise Crossbeams::InfoError, cvl_res.message unless cvl_res.success

        log_transaction
      end
      cvl_res
    rescue Crossbeams::InfoError => e
      ErrorMailer.send_exception_email(e, subject: "INFO: #{self.class.name}", message: decorate_mail_message(__method__)) unless e.message.start_with?('No setup data cached')
      AppConst::ROBOT_LOG.info(e.message)
      puts e.message
      puts e.backtrace.join("\n")
      failed_response(e.message)
    rescue StandardError => e
      ErrorMailer.send_exception_email(e, subject: self.class.name, message: decorate_mail_message(__method__))
      AppConst::ROBOT_LOG.error(e.message)
      puts e.message
      puts e.backtrace.join("\n")
      failed_response(e.message)
    end

    def find_pallet_sequences_from_same_pallet(id)
      repo.find_pallet_sequences_from_same_pallet(id)
    end

    def find_pallet_sequence_attrs(id)
      repo.find_pallet_sequence_attrs(id)
    end

    def verify_pallet_sequence(pallet_sequence_id, verified_by, params) # rubocop:disable Metrics/AbcSize
      return validation_failed_response(messages: { verification_failure_reason: ['is missing'] }) if params[:verification_result] == 'failed' && params[:verification_failure_reason].nil_or_empty?

      pallet_id = repo.get(:pallet_sequences, pallet_sequence_id, :pallet_id)
      changeset = pallet_changes_on_verify(params)

      repo.transaction do
        params.store(:verified_by, verified_by[:user_name])
        update_pallet_sequence_verification_result(pallet_sequence_id, params)

        repo.update_pallet(pallet_id, changeset) unless changeset.empty?
        log_transaction
      end

      if params[:print_pallet_label] == 't'
        print_instance = repo.where_hash(:vw_pallet_label, id: pallet_sequence_id)
        LabelPrintingApp::PrintLabel.call(params[:pallet_label_name], print_instance, params)
      end

      verification_completed = pallet_verified?(pallet_id)
      success_response('Pallet Sequence updated successfully', verification_completed: verification_completed)
    rescue Crossbeams::InfoError => e
      ErrorMailer.send_exception_email(e, subject: "INFO: #{self.class.name}", message: decorate_mail_message(__method__))
      failed_response(e.message)
    end

    def pallet_weighing_for_labeling(user, params) # rubocop:disable Metrics/AbcSize
      res = if AppConst::COMBINE_CARTON_AND_PALLET_VERIFICATION
              combined_verification_scan(params)
            else
              pallet_to_be_verified(params)
            end
      return res unless res.success

      repo.select_values(:pallet_sequences, :id, pallet_number: params[:pallet_number]).each do |id|
        res = verify_pallet_sequence(id, user, verification_result: 'passed')
        return res unless res.success
      end

      fg_pallet_weighing(bin_number: params[:pallet_number], gross_weight: params[:gross_weight], measurement_unit: params[:measurement_unit])
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    rescue StandardError => e
      failed_response(e.message)
    end

    def fg_pallet_weighing(params) # rubocop:disable Metrics/AbcSize
      params[:bin_number] = MesscadaApp::ScannedPalletNumber.new(scanned_pallet_number: params[:bin_number]).pallet_number
      res = FgPalletWeighingSchema.call(params)
      return validation_failed_response(res) if res.failure?

      pallet_number = res[:bin_number]

      return failed_response("Pallet Number :#{pallet_number} could not be found") unless repo.pallet_exists?(pallet_number)

      fpw_res = nil
      repo.transaction do
        fpw_res = MesscadaApp::FgPalletWeighing.call(res)
        log_status(:pallets, fpw_res.instance[:pallet_id], AppConst::PALLET_WEIGHED)
        log_transaction
      end
      fpw_res
    rescue Crossbeams::InfoError => e
      ErrorMailer.send_exception_email(e, subject: "INFO: #{self.class.name}", message: decorate_mail_message(__method__)) unless e.message.include?('pallet number length')
      failed_response(e.message)
    rescue StandardError => e
      ErrorMailer.send_exception_email(e, subject: self.class.name, message: decorate_mail_message(__method__))
      puts e.message
      puts e.backtrace.join("\n")
      failed_response(e.message)
    end

    def repack_pallet(pallet_id) # rubocop:disable Metrics/AbcSize
      pallet = reworks_repo.get_pallet(pallet_id)
      return validation_failed_response(messages: { pallet_number: ['Pallet does not exist'] }) unless pallet

      res = nil
      repo.transaction do
        res = FinishedGoodsApp::RepackPallet.call(pallet_id, @user.user_name)
        log_status(:pallets, pallet_id, AppConst::REWORKS_REPACK_PALLET_STATUS)
        log_multiple_statuses(:pallet_sequences, reworks_repo.pallet_sequence_ids(pallet_id), AppConst::REWORKS_REPACK_PALLET_STATUS)
        log_status(:pallets, res.instance[:new_pallet_id], AppConst::REWORKS_REPACK_PALLET_NEW_STATUS)
        log_multiple_statuses(:pallet_sequences, reworks_repo.pallet_sequence_ids(res.instance[:new_pallet_id]), AppConst::REWORKS_REPACK_PALLET_NEW_STATUS)
      end
      res
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    rescue StandardError => e
      ErrorMailer.send_exception_email(e, subject: self.class.name, message: decorate_mail_message(__method__))
      puts e.message
      puts e.backtrace.join("\n")
      failed_response(e.message)
    end

    def rebin_verification(scanned_number)  # rubocop:disable Metrics/AbcSize
      res = nil
      repo.transaction do
        res = MesscadaApp::RebinVerification.call(@user, scanned_number)
        log_transaction
      end
      res
    rescue Crossbeams::InfoError => e
      ErrorMailer.send_exception_email(e, subject: "INFO: #{self.class.name}", message: decorate_mail_message(__method__))
      puts e.message
      puts e.backtrace.join("\n")
      failed_response(e.message)
    rescue StandardError => e
      ErrorMailer.send_exception_email(e, subject: self.class.name, message: decorate_mail_message(__method__))
      puts e
      puts e.backtrace.join("\n")
      failed_response(e.message)
    end

    def rebin_verification_and_weighing(params) # rubocop:disable Metrics/AbcSize
      res = CartonVerificationAndWeighingSchema.call(params.transform_keys { |k| k == :bin_number ? :carton_number : k })
      return validation_failed_response(res) if res.failure?

      check_res = validate_device_and_label_exist(res[:device], res[:carton_number])
      return check_res unless check_res.success

      cvl_res = nil
      repo.transaction do
        cvl_res = MesscadaApp::RebinVerification.call(@user, res[:carton_number])
        return cvl_res unless cvl_res.success

        attrs = res.to_h
        attrs[:bin_number] = cvl_res.instance[:rebin_id]
        options = { force_find_by_id: false, weighed_manually: true, avg_gross_weight: false }
        cvl_res = MesscadaApp::UpdateBinWeights.call(attrs, options)

        log_transaction
      end
      cvl_res
    rescue Crossbeams::InfoError => e
      ErrorMailer.send_exception_email(e, subject: "INFO: #{self.class.name}", message: decorate_mail_message(__method__))
      puts e.message
      puts e.backtrace.join("\n")
      failed_response(e.message)
    rescue StandardError => e
      ErrorMailer.send_exception_email(e, subject: self.class.name, message: decorate_mail_message(__method__))
      puts e.message
      puts e.backtrace.join("\n")
      failed_response(e.message)
    end

    def pallet_sequence_ids(pallet_id)
      reworks_repo.pallet_sequence_ids(pallet_id)
    end

    def check_pallet!(task, pallet_number)
      res = TaskPermissionCheck::Pallet.call(task, pallet_number: pallet_number)
      raise Crossbeams::InfoError, res.message unless res.success
    end

    def assert_permission!(task, pallet_number)
      res = TaskPermissionCheck::Pallet.call(task, pallet_number: pallet_number)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    # Get the device code from system resources that matches an ip address.
    # Returns nil if not found/not a MODULE.
    # When running in development mode, a passed-in device parameter will be used when present.
    def device_code_from_ip_address(ip_address, params) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      device = if params[:device] && AppConst.development?
                 params[:device]
               else
                 resource_repo.device_code_from_ip_address(ip_address)
               end

      return failed_response("There is no device configured for #{ip_address}") if device.nil?

      sysres_id = resource_repo.get_id(:system_resources, system_resource_code: device)
      return failed_response("#{device} does not exist") if sysres_id.nil?
      return failed_response("#{device} is not a robot") unless resource_repo.system_resource_type_from_resource(sysres_id) == Crossbeams::Config::ResourceDefinitions::MODULE

      # Check to see that device has a printer associated.
      printer_list = resource_repo.linked_printer_for_device(device)
      return failed_response("#{device} does not have a linked printer") if printer_list.empty?
      return failed_response("#{device} has more than one linked printer") if printer_list.length > 1

      success_response('ok', device)
    end

    # build_robot called with ip address / device name?
    def build_robot(device) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      # !------- code to be converted and moved to repo...
      sysres_robot = DB[:system_resources].where(system_resource_code: device).first
      return failed_response("#{device} does not exist") if sysres_robot.nil?

      plantres_robot = DB[:plant_resources].where(system_resource_id: sysres_robot[:id]).first
      line = resource_repo.plant_resource_parent_of_system_resource(Crossbeams::Config::ResourceDefinitions::LINE, sysres_robot[:system_resource_code])
      res = production_run_repo.find_production_runs_for_line_in_state(line.instance, running: true, labeling: true)
      run_id = res.success ? res.instance.first : nil

      buttons = resource_repo.robot_buttons(plantres_robot[:id]).map do |button_plant_id|
        plnt = resource_repo.find_plant_resource_flat(button_plant_id)
        sys = resource_repo.find_system_resource(plnt.system_resource_id)
        # Lookup if btn alloc - enable or not & set button caption
        # What line?
        # What labeling run?
        # What alloc prod + label?
        if run_id.nil?
          enabled = false
        else
          lbl_modules = production_run_repo.button_allocations(run_id)
          # lbl_modules.group_by { |r| [r[:module], r[:alias]] }
          rec = lbl_modules.find { |a| a[:module] == sysres_robot[:system_resource_code] && a[:button] == sys.system_resource_code[/.\d+$/] } # .first
          # p rec
          ar = AppConst::CR_PROD.button_caption_spec.split('$')
          button_caption = ar.map { |s| s.start_with?(':') ? rec[s.delete_prefix(':').to_sym] : s }.compact.join
          # p button_caption
          if button_caption.strip.empty?
            enabled = false
            button_caption = 'Not allocated'
          else
            enabled = true
          end
        end
        # NB. may need client setting to show button name? Or just A/B/C...
        OpenStruct.new(plant_resource_id: plnt.id,
                       button_name: plnt.plant_resource_code,
                       enabled: enabled,
                       button_caption: button_caption,
                       system_name: sys[:system_resource_code],
                       # url: "/messcada/browser/carton_labeling?device=#{sys[:system_resource_code]}&card_reader=$:card_reader$&identifier=$:identifier$",
                       url: "/messcada/browser/carton_labeling/weighing?device=#{sys[:system_resource_code]}&card_reader=$:card_reader$&identifier=$:identifier$&weight=$:weight$",
                       # params: %w[device card_reader identifier]) # Might include scale weight / bin_number ...
                       params: %w[device card_reader identifier weight])
      end
      login_state = login_state(sysres_robot[:system_resource_code])
      # Read res & get login/out/group etc., robot buttons
      success_response('build', { device: sysres_robot[:system_resource_code],
                                  name: plantres_robot[:plant_resource_code],
                                  run_id: run_id,
                                  users: login_state.instance[:users],
                                  login_key: login_state.instance[:login_key],
                                  buttons: buttons })
    end

    def login_state(device) # rubocop:disable Metrics/AbcSize
      sysres_robot = DB[:system_resources].where(system_resource_code: device).first
      if sysres_robot[:group_incentive]
        users = ProductionApp::DashboardRepo.new.robot_group_incentive_details(sysres_robot[:id]).map { |r| "#{r[:first_name]} #{r[:surname]}" }
        login_type = 'group'
        login_key = "group_#{resource_repo.active_group_incentive_id_for(sysres_robot[:id])}"
      else
        users = ProductionApp::DashboardRepo.new.robot_logon_details(sysres_robot[:id]).map { |r| "#{r[:first_name]} #{r[:surname]}" }
        login_type = 'individual'
        login_key = "individual_#{resource_repo.active_individual_incentive_id_for(sysres_robot[:id])}"
      end
      success_response('OK', login_key: login_key, login_type: login_type, users: users)
    end

    private

    def pallet_changes_on_verify(params)
      changeset = {}
      changeset[:fruit_sticker_pm_product_id] = params[:fruit_sticker_pm_product_id] unless params[:fruit_sticker_pm_product_id].nil_or_empty?
      changeset[:fruit_sticker_pm_product_2_id] = params[:fruit_sticker_pm_product_2_id] unless params[:fruit_sticker_pm_product_2_id].nil_or_empty?

      changeset[:gross_weight] = params[:gross_weight] if AppConst::CAPTURE_PALLET_WEIGHT_AT_VERIFICATION

      if AppConst::PALLET_IS_IN_STOCK_WHEN_VERIFIED
        changeset[:in_stock] = true
        changeset[:stock_created_at] = Time.now
      end
      changeset
    end

    def update_pallet_sequence_verification_result(pallet_sequence_id, params)
      repo.update_pallet_sequence_verification_result(pallet_sequence_id, params)
    end

    def pallet_verified?(pallet_id)
      repo.pallet_verified?(pallet_id)
    end

    def repo
      @repo ||= MesscadaRepo.new
    end

    def production_run_repo
      @production_run_repo ||= ProductionApp::ProductionRunRepo.new
    end

    def hr_repo
      @hr_repo ||= HrRepo.new
    end

    def resource_repo
      @resource_repo ||= ProductionApp::ResourceRepo.new
    end

    def reworks_repo
      @reworks_repo ||= ProductionApp::ReworksRepo.new
    end

    def locations_repo
      @locations_repo ||= MasterfilesApp::LocationRepo.new
    end

    def pallet(id)
      repo.find_pallet(id)
    end

    def pallet_flat(id)
      repo.find_pallet_flat(id)
    end

    # TODO: split validation if using asset no or not (string asset vs int id)
    def validate_update_rmt_bin_weights_params(params)
      # For now: bin asset is integer, so strip Habata's SK prefix. LATER make this a string.
      # UpdateRmtBinWeightsSchema.call(params.transform_values { |v| v.match?(/SK/) ? v.sub('SK', '') : v })
      UpdateRmtBinWeightsSchema.call(params)
    end

    def validate_tip_rmt_bin_params(params)
      TipRmtBinSchema.call(params)
    end

    def resource_code_exists?(resource_code)
      repo.resource_code_exists?(resource_code)
    end

    def identifier_exists?(identifier)
      repo.identifier_exists?(identifier)
    end

    def carton_label_exists?(carton_label_id)
      repo.carton_label_exists?(carton_label_id)
    end

    def carton_label_exists_for_pallet?(pallet_no)
      !repo.carton_label_id_for_pallet_no(pallet_no).nil?
    end

    def validate_device_exists(resource_code)
      return failed_response("Resource Code:#{resource_code} could not be found#{AppConst::ROBOT_MSG_SEP}#{resource_code} not found}") unless resource_code_exists?(resource_code)

      ok_response
    end

    def validate_incentivised_labeling(identifier)
      return failed_response('Not logged in') unless identifier_exists?(identifier)

      ok_response
    end

    def validate_device_and_label_exist(device, _carton_id_or_pallet_no)
      res1 = validate_device_exists(device)
      return res1 unless res1.success

      ok_response
    end

    def convert_pallet_no_to_carton_no(res)
      out = res.to_h
      out[:carton_number] = repo.carton_label_id_for_pallet_no(res[:carton_number])
      out
    end

    def get_pallet_label_data(pallet_id)
      production_run_repo.get_pallet_label_data(pallet_id)
    end

    def xml_label_content(system_resource, print_command) # rubocop:disable Metrics/AbcSize
      schema = Nokogiri::XML(print_command)
      label_name = schema.xpath('.//label/template').text
      quantity = schema.xpath('.//label/quantity').text
      printer = printer_for_robot(system_resource.id)
      vars = schema.xpath('.//label/fvalue').each_with_index.map { |node, i| %(F#{i + 1}="#{node.text}") }
      ar = [
        '<ProductLabel',
        'PID="223"',
        'Status="true"',
        'Threading="true"',
        %(RunNumber=""),
        %(Code=""),
        %(LabelTemplateFile="#{label_name}.nsld"),
        %(LabelRenderAmount="#{quantity}"),
        'F0=""'
      ]
      ar += vars
      ar << 'Msg=""'
      ar << %(Printer="#{printer}" />)

      success_response('Label printed', ar.join(' '))
    end

    def printer_for_robot(id)
      LabelApp::PrinterRepo.new.printer_code_for_robot(id)
    end
  end
end
