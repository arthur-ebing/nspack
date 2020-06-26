# frozen_string_literal: true

module MesscadaApp
  class PalletizingInteractor < BaseInteractor # rubocop:disable Metrics/ClassLength
    def scan_carton(params) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity
      res = CartonPalletizingScanSchema.call(params)
      return validation_failed_response(res) unless res.messages.empty?

      check_res = validate_params_input(params)
      return check_res unless check_res.success

      state_machine = state_machine(params)

      return failed_response("Cannot scan in #{state_machine.current} state.", current_bay_attributes(state_machine)) if state_machine.cannot?(:scan)

      state_machine.scan
      case state_machine.target.action
      when :create_pallet
        start_new_pallet(state_machine, params)
      when :add_carton
        add_to_pallet(state_machine, params)
      when :return_to_bay
        return_pallet_to_bay(state_machine, params)
      when :mark_qc_carton
        mark_carton_for_qc(state_machine, params)
      else
        raise Crossbeams::FrameworkError, 'No action returned from state machine'
      end
    rescue Crossbeams::InfoError => e
      failed_response(e.message, current_bay_attributes(state_machine))
    rescue StandardError => e
      ErrorMailer.send_exception_email(e, subject: self.class.name, message: decorate_mail_message("scan_carton\nParams: #{params.inspect}\nState: #{state_machine&.target.inspect}"))
      puts e.message
      puts e.backtrace.join("\n")
      failed_response(e.message, current_bay_attributes(state_machine))
    end

    def qc_out(params) # rubocop:disable Metrics/AbcSize
      state_machine = state_machine(params)
      state_machine.qc_checkout

      if state_machine.target.action == :prepare_qc
        repo.transaction do
          changeset = { current_state: state_machine.current.to_s }
          repo.update_palletizing_bay_state(state_machine.target.id, changeset)
          log_transaction
        end
        success_response('ok', current_bay_attributes(state_machine))
      else
        failed_response("Bay is in #{state_machine.current} state - cannot select a QC carton", current_bay_attributes(state_machine))
      end
    rescue StandardError => e
      ErrorMailer.send_exception_email(e, subject: self.class.name, message: decorate_mail_message("qc_out\nParams: #{params.inspect}\nState: #{state_machine&.target.inspect}"))
      puts e.message
      puts e.backtrace.join("\n")
      failed_response(e.message, current_bay_attributes(state_machine))
    end

    def return_to_bay(params) # rubocop:disable Metrics/AbcSize
      res = CartonPalletizingSchema.call(params)
      return validation_failed_response(res) unless res.messages.empty?

      check_res = validate_params_input(params)
      return check_res unless check_res.success

      state_machine = state_machine(params)
      state_machine.return_to_bay

      return failed_response("Cannot return to bay: #{state_machine.current} state", current_bay_attributes(state_machine)) unless state_machine.target.action == :prepare_return

      repo.transaction do
        changeset = { current_state: state_machine.current.to_s }
        repo.update_palletizing_bay_state(state_machine.target.id, changeset)
        log_transaction
      end
      success_response('ok', current_bay_attributes(state_machine))
    rescue StandardError => e
      ErrorMailer.send_exception_email(e, subject: self.class.name, message: decorate_mail_message("return_to_bay\nParams: #{params.inspect}\nState: #{state_machine&.target.inspect}"))
      puts e.message
      puts e.backtrace.join("\n")
      failed_response(e.message, current_bay_attributes(state_machine))
    end

    def refresh(params) # rubocop:disable Metrics/AbcSize
      res = CartonPalletizingSchema.call(params)
      return validation_failed_response(res) unless res.messages.empty?

      check_res = validate_params_input(params)
      return check_res unless check_res.success

      state_machine = state_machine(params)
      state_machine.refresh

      return failed_response("Cannot refresh in #{state_machine.current} state.", current_bay_attributes(state_machine)) unless state_machine.target.action == :refresh

      repo.transaction do
        changeset = { current_state: state_machine.current.to_s }
        repo.update_palletizing_bay_state(state_machine.target.id, changeset)
        log_transaction
      end
      success_response('ok', current_bay_attributes(state_machine))
    rescue StandardError => e
      ErrorMailer.send_exception_email(e, subject: self.class.name, message: decorate_mail_message("refresh\nParams: #{params.inspect}\nState: #{state_machine&.target.inspect}"))
      puts e.message
      puts e.backtrace.join("\n")
      failed_response(e.message, current_bay_attributes(state_machine))
    end

    def complete(params) # rubocop:disable Metrics/AbcSize
      res = CartonPalletizingSchema.call(params)
      return validation_failed_response(res) unless res.messages.empty?

      check_res = validate_params_input(params)
      return check_res unless check_res.success

      state_machine = state_machine(params)
      state_machine.complete

      return failed_response("Cannot complete in #{state_machine.current} state.", current_bay_attributes(state_machine)) unless state_machine.target.action == :complete_pallet

      confirm = {
        confirm_text: "Complete pallet #{current_bay_attributes(state_machine)[:pallet_number]}?",
        confirm_url: URI.encode_www_form_component("#{AppConst::URL_BASE}/messcada/carton_palletizing/complete_pallet?device=#{params[:device]}&reader_id=#{params[:reader_id]}&identifier=#{params[:identifier]}"),
        cancel_url: 'noop'
      }

      success_response('ok', current_bay_attributes(state_machine, confirm))
    rescue StandardError => e
      ErrorMailer.send_exception_email(e, subject: self.class.name, message: decorate_mail_message("complete\nParams: #{params.inspect}\nState: #{state_machine&.target.inspect}"))
      puts e.message
      puts e.backtrace.join("\n")
      failed_response(e.message, current_bay_attributes(state_machine))
    end

    def complete_pallet(params) # rubocop:disable Metrics/AbcSize
      state_machine = state_machine(params)
      state_machine.complete

      return failed_response("Cannot complete in #{state_machine.current} state.", current_bay_attributes(state_machine)) unless state_machine.target.action == :complete_pallet

      res = nil
      repo.transaction do
        res = MesscadaApp::CompletePallet.call(palletizing_bay_state(state_machine.target.id)&.pallet_id)

        changeset = { current_state: state_machine.current.to_s }
        repo.update_palletizing_bay_state(state_machine.target.id, changeset)
        log_transaction
      end
      success_response('ok', current_bay_attributes(state_machine))
    rescue StandardError => e
      ErrorMailer.send_exception_email(e, subject: self.class.name, message: decorate_mail_message("complete_pallet\nParams: #{params.inspect}\nState: #{state_machine&.target.inspect}"))
      puts e.message
      puts e.backtrace.join("\n")
      failed_response(e.message, current_bay_attributes(state_machine))
    end

    def empty_bay_carton_transfer(params) # rubocop:disable Metrics/AbcSize
      state_machine = state_machine(params)
      state_machine.scan

      return failed_response("Cannot transfer carton in #{state_machine.current} state", current_bay_attributes(state_machine)) unless state_machine.target.action == :create_pallet

      carton_id = palletizing_bay_state(state_machine.target.id)&.last_carton_id
      repo.transaction do
        changeset = { last_carton_id: carton_id }
        repo.update_palletizing_bay_state(state_machine.target.id, changeset)
        log_transaction
      end
      success_response('Carton transfer was successful', current_bay_attributes(state_machine))
    rescue StandardError => e
      ErrorMailer.send_exception_email(e, subject: self.class.name, message: decorate_mail_message("empty_bay_carton_transfer\nParams: #{params.inspect}\nState: #{state_machine&.target.inspect}"))
      puts e.message
      puts e.backtrace.join("\n")
      failed_response(e.message, current_bay_attributes(state_machine))
    end

    def transfer_carton(params) # rubocop:disable Metrics/AbcSize
      res = CartonPalletizingSchema.call(params)
      return validation_failed_response(res) unless res.messages.empty?

      check_res = validate_params_input(params)
      return check_res unless check_res.success

      state_machine = state_machine(params)
      state_machine.scan

      return failed_response("Cannot transfer carton in #{state_machine.current} state", current_bay_attributes(state_machine)) if state_machine.cannot?(:scan)

      transfer_bay_carton(state_machine, params)
    rescue StandardError => e
      ErrorMailer.send_exception_email(e, subject: self.class.name, message: decorate_mail_message("transfer_carton\nParams: #{params.inspect}\nState: #{state_machine&.target.inspect}"))
      puts e.message
      puts e.backtrace.join("\n")
      failed_response(e.message, current_bay_attributes(state_machine))
    end

    def palletizing_robot_feedback(device, res) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      current_state = current_state_string(res.instance)
      if res.success
        orange = %w[empty qc_out return_to_bay].include?(res.instance[:current_state])

        line1 = orange ? "#{res.instance[:bay_name]}: #{res.instance[:current_state]} bay" : res.instance[:bay_name]
        line2 = if current_state == '[EMPTY]'
                  'Please remove completed Plt'
                elsif res.instance[:current_state].to_s == 'return_to_bay'
                  'Scan Carton to RTB'
                else
                  res.instance[:pallet_number]
                end
        line3 = orange ? '' : current_state
        line4 = last_carton?(res.instance) && !orange ? 'Press Complete Btn to finish buildup' : ''

        feedback = {
          device: device,
          status: true,
          orange: orange,
          line1: line1,
          line2: line2,
          line3: line3,
          line4: line4
        }
        if res.instance[:confirm_text]
          feedback[:confirm_text] = res.instance[:confirm_text]
          feedback[:confirm_url] = res.instance[:confirm_url]
          feedback[:cancel_url] = res.instance[:cancel_url]
        end
        MesscadaApp::RobotFeedback.new(feedback)
      else
        mix_rule_error = res.instance[:mix_rule_error]
        line1 = mix_rule_error ? "MIXING: #{res.instance[:rule_column]} NOT ALLOWED" : res.instance[:bay_name]
        line2 = mix_rule_error ? "PLT: #{res.instance[:old_value]}" : unwrap_failed_response(res)
        line3 = mix_rule_error ? "CTN: #{res.instance[:new_value]}" : current_state

        MesscadaApp::RobotFeedback.new(device: device,
                                       status: false,
                                       line1: line1,
                                       line2: line2,
                                       line3: line3)
      end
    end

    private

    def current_state_string(instance)
      if instance[:current_state] == 'empty'
        '[EMPTY]'
      else
        "[#{instance[:current_state].to_s.upcase}] #{instance[:carton_quantity]} / #{instance[:cartons_per_pallet]}"
      end
    end

    def current_bay_attributes(state_machine, options = {})
      repo.current_palletizing_bay_attributes(state_machine.target.id, options)
    end

    def palletizing_bay_attributes(id, options = {})
      repo.current_palletizing_bay_attributes(id, options)
    end

    def start_new_pallet(state_machine, params) # rubocop:disable Metrics/AbcSize
      return failed_response("Cannot create pallet in #{state_machine.current} state", current_bay_attributes(state_machine)) unless state_machine.target.action == :create_pallet

      carton_number = params[:carton_number]
      return failed_response("Carton:#{carton_number} doesn't exist", current_bay_attributes(state_machine)) unless carton_number_exists?(carton_number)

      carton_id = get_palletizing_carton(carton_number, state_machine.current.to_s, params[:identifier])
      return failed_response('Carton belongs to a completed plt', current_bay_attributes(state_machine)) if completed_pallet?(carton_id)

      return failed_response('Carton belongs to a closed Run', current_bay_attributes(state_machine)) if closed_production_run?(carton_id)

      carton_belongs_to_another_bay = carton_of_other_bay?(carton_id)
      if carton_belongs_to_another_bay
        carton_bay_name = palletizing_bay_attributes(repo.carton_palletizing_bay_state(carton_id))[:bay_name]
        return failed_response("Carton of bay #{carton_bay_name}", current_bay_attributes(state_machine))
        # confirm = {
        #   confirm_text: "Carton of bay: #{carton_bay_name}.Transfer carton?",
        #   confirm_url: URI.encode_www_form_component("#{AppConst::URL_BASE}/messcada/carton_palletizing/empty_bay_carton_transfer?device=#{params[:device]}&reader_id=#{params[:reader_id]}&identifier=#{params[:identifier]}"),
        #   cancel_url: 'noop'
        # }
        # repo.transaction do
        #   changeset = { last_carton_id: carton_id }
        #   repo.update_palletizing_bay_state(state_machine.target.id, changeset)
        #   log_transaction
        # end

      else
        confirm = {}
        res = nil
        repo.transaction do
          res = MesscadaApp::CreatePalletFromCarton.call(@user, carton_id, 1, palletizing_bay_state(state_machine.target.id)&.palletizing_bay_resource_id)
          # UPDATE carton with pallet_sequence_id & pallet_sequence with incentive contract_worker....

          changeset = { current_state: state_machine.current.to_s,
                        pallet_sequence_id: res.instance[:pallet_sequence_id],
                        determining_carton_id: carton_id,
                        last_carton_id: carton_id }
          repo.update_palletizing_bay_state(state_machine.target.id, changeset)
          log_transaction
        end
      end
      success_response('Ok', current_bay_attributes(state_machine, confirm))
    end

    def add_to_pallet(state_machine, params) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      return failed_response("Cannot add carton to pallet in #{state_machine.current} state", current_bay_attributes(state_machine)) unless state_machine.target.action == :add_carton

      carton_number = params[:carton_number]
      return failed_response("Carton:#{carton_number} doesn't exist", current_bay_attributes(state_machine)) unless carton_number_exists?(carton_number)

      carton_id = get_palletizing_carton(carton_number, state_machine.current.to_s, params[:identifier])
      return failed_response('Carton belongs to a completed pallet', current_bay_attributes(state_machine)) if completed_pallet?(carton_id)

      return failed_response('Carton belongs to a closed Run', current_bay_attributes(state_machine)) if closed_production_run?(carton_id)

      res = validate_pallet_mix_rules(state_machine, carton_id)
      return res unless res.success

      carton_belongs_to_another_bay = carton_of_other_bay?(carton_id)
      if carton_belongs_to_another_bay
        carton_bay_name = palletizing_bay_attributes(repo.carton_palletizing_bay_state(carton_id))[:bay_name]
        confirm = {
          confirm_text: "Carton of bay: #{carton_bay_name}.Transfer carton?",
          confirm_url: URI.encode_www_form_component("#{AppConst::URL_BASE}/messcada/carton_palletizing/transfer_carton?device=#{params[:device]}&reader_id=#{params[:reader_id]}&identifier=#{params[:identifier]}"),
          cancel_url: 'noop'
        }
        repo.transaction do
          changeset = { last_carton_id: carton_id }
          repo.update_palletizing_bay_state(state_machine.target.id, changeset)
          log_transaction
        end
      else
        res = nil
        repo.transaction do
          res = MesscadaApp::AddCartonToPallet.call(carton_id, palletizing_bay_state(state_machine.target.id)&.pallet_id)

          changeset = { pallet_sequence_id: res.instance[:pallet_sequence_id],
                        last_carton_id: carton_id }
          repo.update_palletizing_bay_state(state_machine.target.id, changeset)
          log_transaction
        end
        last_carton = last_carton?(current_bay_attributes(state_machine))
        confirm = if last_carton
                    {
                      confirm_text: "Pallet size reached. Complete pallet #{current_bay_attributes(state_machine)[:pallet_number]}?",
                      confirm_url: URI.encode_www_form_component("#{AppConst::URL_BASE}/messcada/carton_palletizing/complete_pallet?device=#{params[:device]}&reader_id=#{params[:reader_id]}&identifier=#{params[:identifier]}"),
                      cancel_url: 'noop'
                    }
                  else
                    {}
                  end
      end

      success_response('ok', current_bay_attributes(state_machine, confirm))
    end

    def validate_pallet_mix_rules(state_machine, carton_id) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      carton = mesc_repo.carton_attributes(carton_id)
      oldest_carton = mesc_repo.carton_attributes(palletizing_bay_state(state_machine.target.id)&.determining_carton_id)
      return success_response('ok', current_bay_attributes(state_machine)) unless oldest_carton

      rule = prod_repo.find_pallet_mix_rules_by_scope(AppConst::GLOBAL_PALLET_MIX)
      return failed_response('mix_rule error', { mix_rule_error: true, rule_column: 'TM GROUPS', new_value: carton[:target_market_group_name], old_value: oldest_carton[:target_market_group_name] }) if !rule[:allow_tm_mix] && (carton[:packed_tm_group_id] != oldest_carton[:packed_tm_group_id])
      return failed_response('mix_rule error', { mix_rule_error: true, rule_column: 'GRADES', new_value: carton[:grade_code], old_value: oldest_carton[:grade_code] }) if !rule[:allow_grade_mix] && (carton[:grade_id] != oldest_carton[:grade_id])
      return failed_response('mix_rule error', { mix_rule_error: true, rule_column: 'MARKS', new_value: carton[:mark_code], old_value: oldest_carton[:mark_code] }) if !rule[:allow_mark_mix] && (carton[:mark_id] != oldest_carton[:mark_id])
      return failed_response('mix_rule error', { mix_rule_error: true, rule_column: 'SIZE REFS', new_value: carton[:size_reference], old_value: oldest_carton[:size_reference] }) if !rule[:allow_size_ref_mix] && (carton[:fruit_size_reference_id] != oldest_carton[:fruit_size_reference_id])
      return failed_response('mix_rule error', { mix_rule_error: true, rule_column: 'PACKS', new_value: carton[:standard_pack_code], old_value: oldest_carton[:standard_pack_code] }) if !rule[:allow_pack_mix] && (carton[:standard_pack_code_id] != oldest_carton[:standard_pack_code_id])
      return failed_response('mix_rule error', { mix_rule_error: true, rule_column: 'STD COUNTS', new_value: carton[:size_count_value], old_value: oldest_carton[:size_count_value] }) if !rule[:allow_std_count_mix] && (carton[:std_fruit_size_count_id] != oldest_carton[:std_fruit_size_count_id])
      return failed_response('mix_rule error', { mix_rule_error: true, rule_column: 'INVENTORIES', new_value: carton[:inventory_code], old_value: oldest_carton[:inventory_code] }) if !rule[:allow_inventory_code_mix] && (carton[:inventory_code_id] != oldest_carton[:inventory_code_id])
      return failed_response('mix_rule error', { mix_rule_error: true, rule_column: 'CULTIVARS', new_value: carton[:cultivar_name], old_value: oldest_carton[:cultivar_name] }) if !rule[:allow_cultivar_mix] && (carton[:cultivar_id] != oldest_carton[:cultivar_id])
      return failed_response('mix_rule error', { mix_rule_error: true, rule_column: 'CULTIVAR GROUPS', new_value: carton[:cultivar_group_code], old_value: oldest_carton[:cultivar_group_code] }) if !rule[:allow_cultivar_group_mix] && (carton[:cultivar_group_id] != oldest_carton[:cultivar_group_id])

      success_response('ok', current_bay_attributes(state_machine))
    end

    def transfer_bay_carton(state_machine, params) # rubocop:disable Metrics/AbcSize
      return failed_response("Cannot transfer carton in #{state_machine.current} state", current_bay_attributes(state_machine)) unless state_machine.target.action == :add_carton

      carton_id = palletizing_bay_state(state_machine.target.id)&.last_carton_id
      res = validate_pallet_mix_rules(state_machine, carton_id)
      return res unless res.success

      res = nil
      repo.transaction do
        res = MesscadaApp::TransferBayCarton.call(carton_id, palletizing_bay_state(state_machine.target.id)&.pallet_id)

        changeset = { pallet_sequence_id: res.instance[:pallet_sequence_id],
                      last_carton_id: carton_id }
        repo.update_palletizing_bay_state(state_machine.target.id, changeset)
        log_transaction
      end
      last_carton = last_carton?(current_bay_attributes(state_machine))
      confirm = if last_carton
                  {
                    confirm_text: "Pallet size reached. Complete pallet #{current_bay_attributes(state_machine)[:pallet_number]}?",
                    confirm_url: URI.encode_www_form_component("#{AppConst::URL_BASE}/messcada/carton_palletizing/complete_pallet?device=#{params[:device]}&reader_id=#{params[:reader_id]}&identifier=#{params[:identifier]}"),
                    cancel_url: 'noop'
                  }
                else
                  {}
                end

      success_response('ok', current_bay_attributes(state_machine, confirm))
    end

    def return_pallet_to_bay(state_machine, params)  # rubocop:disable Metrics/AbcSize
      return failed_response("Cannot return pallet to bay. #{state_machine.current} state", current_bay_attributes(state_machine)) unless state_machine.target.action == :return_to_bay

      carton_number = params[:carton_number]
      return failed_response("Carton:#{carton_number} doesn't exist", current_bay_attributes(state_machine)) unless carton_number_exists?(carton_number)

      carton_id = carton_number_carton_id(carton_number)
      return failed_response("Carton:#{carton_number} is not valid", current_bay_attributes(state_machine)) unless valid_pallet_carton?(carton_id)

      pallet_id = carton_pallet(carton_id)
      oldest_carton = pallet_oldest_carton(pallet_id)

      repo.transaction do
        repo.log_status('pallets', pallet_id, AppConst::PALLET_RETURNED_TO_BAY)
        changeset = { current_state: state_machine.current.to_s,
                      pallet_sequence_id: oldest_carton[:pallet_sequence_id],
                      determining_carton_id: oldest_carton[:carton_id],
                      last_carton_id: carton_id }
        repo.update_palletizing_bay_state(state_machine.target.id, changeset)
        log_transaction
      end
      success_response('ok', current_bay_attributes(state_machine))
    end

    def mark_carton_for_qc(state_machine, params)
      carton_id = params[:carton_number]
      puts carton_id

      # VALIDATE that carton is on a pallet
      repo.transaction do
        state_machine.qc_checkout
        # prod_repo.increment_sequence(state_machine.target.pallet_sequence_id)
        # UPDATE carton with qc_flag (or add carton id to pseg?)

        changeset = { current_state: state_machine.current.to_s }
        repo.update_palletizing_bay_state(state_machine.target.id, changeset)
        log_transaction
      end
      success_response('ok', current_bay_attributes(state_machine))
    end

    def state_machine(params)
      fsm = repo.palletizing_bay_state_by_robot_scanner(params[:device], params[:reader_id])
      CartonPalletizingStates.new(fsm.fsm_target, initial: fsm.state)
    end

    def repo
      @repo ||= PalletizingRepo.new
    end

    def prod_repo
      @prod_repo = ProductionApp::ProductionRunRepo.new
    end

    def mesc_repo
      @mesc_repo = MesscadaApp::MesscadaRepo.new
    end

    def validate_params_input(params)
      check_res = validate_device_exists(params[:device])
      return check_res unless check_res.success

      check_res = validate_identifier_exists(params[:identifier])
      return check_res unless check_res.success

      ok_response
    end

    def validate_device_exists(resource_code)
      return failed_response("Resource Code:#{resource_code} not found") unless resource_code_exists?(resource_code)

      ok_response
    end

    def validate_identifier_exists(identifier)
      return failed_response("Identifier #{identifier} not found") unless identifier_exists?(identifier)

      ok_response
    end

    def resource_code_exists?(resource_code)
      mesc_repo.resource_code_exists?(resource_code)
    end

    def identifier_exists?(identifier)
      mesc_repo.identifier_exists?(identifier)
    end

    def carton_number_exists?(carton_number)
      mesc_repo.carton_label_exists?(carton_number)
    end

    def palletizing_bay_state(id)
      repo.find_palletizing_bay_state(id)
    end

    def get_palletizing_carton(carton_number, _bay_state, palletizer_identifier)
      MesscadaApp::CartonVerification.call(@user, { carton_number: carton_number }, palletizer_identifier) unless verified_carton_number?(carton_number)
      carton_number_carton_id(carton_number)
    end

    def verified_carton_number?(carton_number)
      mesc_repo.carton_label_carton_exists?(carton_number)
    end

    def carton_number_carton_id(carton_number)
      mesc_repo.carton_label_carton_id(carton_number)
    end

    def completed_pallet?(carton_id)
      repo.completed_pallet?(carton_id)
    end

    def closed_production_run?(carton_id)
      repo.closed_production_run?(carton_id)
    end

    def carton_of_other_bay?(carton_id)
      repo.carton_of_other_bay?(carton_id)
    end

    def last_carton?(instance)
      instance[:carton_quantity] == instance[:cartons_per_pallet]
    end

    def valid_pallet_carton?(carton_id)
      repo.valid_pallet_carton?(carton_id)
    end

    def carton_pallet(carton_id)
      repo.find_pallet_by_carton_id(carton_id)
    end

    def pallet_oldest_carton(pallet_id)
      repo.pallet_oldest_carton(pallet_id)
    end
  end
end
