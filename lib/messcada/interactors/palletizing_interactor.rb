# frozen_string_literal: true

module MesscadaApp
  class PalletizingInteractor < BaseInteractor # rubocop:disable Metrics/ClassLength
    def scan_carton(params)
      state_machine = state_machine(params)

      case state_machine.current
      when :empty
        start_new_pallet(state_machine, params)
      when :palletizing
        add_to_pallet(state_machine, params)
      when :return_to_bay
        return_pallet_to_bay(state_machine, params)
      when :qc_out
        mark_carton_for_qc(state_machine, params)
      end
    end

    def qc_out(params) # rubocop:disable Metrics/AbcSize
      state_machine = state_machine(params)
      if state_machine.cannot?(:prepare_qc)
        failed_response("Bay is in #{state_machine.current} state - cannot select a QC carton", current_bay_attributes(state_machine))
      else
        repo.transaction do
          state_machine.prepare_qc
          changeset = { current_state: state_machine.current.to_s }
          repo.update_palletizing_bay_state(state_machine.target.id, changeset)
          log_transaction
        end
        success_response('ok', current_bay_attributes(state_machine))
      end
    end

    def return_to_bay(params) # rubocop:disable Metrics/AbcSize
      state_machine = state_machine(params)
      if state_machine.cannot?(:prepare_return)
        failed_response("Bay is in #{state_machine.current} state - cannot return to bay", current_bay_attributes(state_machine))
      else
        repo.transaction do
          state_machine.prepare_return
          changeset = { current_state: state_machine.current.to_s }
          repo.update_palletizing_bay_state(state_machine.target.id, changeset)
          log_transaction
        end
        success_response('ok', current_bay_attributes(state_machine))
      end
    end

    def refresh(params) # rubocop:disable Metrics/AbcSize
      state_machine = state_machine(params)
      if state_machine.cannot?(:refresh)
        failed_response("Bay is in #{state_machine.current} state - cannot refresh", current_bay_attributes(state_machine))
      else
        repo.transaction do
          state_machine.refresh
          changeset = { current_state: state_machine.current.to_s }
          repo.update_palletizing_bay_state(state_machine.target.id, changeset)
          log_transaction
        end
        success_response('ok', current_bay_attributes(state_machine))
      end
    end

    def complete(params) # rubocop:disable Metrics/AbcSize
      state_machine = state_machine(params)
      if state_machine.cannot?(:complete)
        failed_response("Bay is in #{state_machine.current} state - cannot complete", current_bay_attributes(state_machine))
      else
        repo.transaction do
          state_machine.complete
          changeset = { current_state: state_machine.current.to_s }
          repo.update_palletizing_bay_state(state_machine.target.id, changeset)
          log_transaction
        end
        success_response('ok', current_bay_attributes(state_machine))
      end
    end

    def palletizing_robot_feedback(device, res) # rubocop:disable Metrics/AbcSize
      current_state = current_state_string(res.instance)
      if res.success
        orange = %w[qc_out return_to_bay].include?(res.instance[:current_state])
        MesscadaApp::RobotFeedback.new(device: device,
                                       status: true,
                                       orange: orange,
                                       line1: res.instance[:bay_name],
                                       line2: res.instance[:pallet_number],
                                       line3: current_state)
      else
        MesscadaApp::RobotFeedback.new(device: device,
                                       status: false,
                                       line1: res.instance[:bay_name],
                                       line2: unwrap_failed_response(res),
                                       line3: current_state)
      end
    end

    private

    def current_state_string(instance)
      if instance[:current_state] == 'empty'
        '[EMPTY]'
      else
        "[#{instance[:current_state].upcase}] #{instance[:carton_quantity]} / #{instance[:cartons_per_pallet]}"
      end
    end

    def current_bay_attributes(state_machine)
      repo.current_palletizing_bay_attributes(state_machine.target.id)
    end

    def start_new_pallet(state_machine, params) # rubocop:disable Metrics/AbcSize
      return failed_response("Cannot create pallet in #{state_machine.current_state} state", current_bay_attributes(state_machine)) if state_machine.cannot?(:create_pallet)

      carton_id = params[:carton_number]

      carton = prod_repo.find_carton_with_run_info(carton_id)
      return failed_response("Scanned Carton:#{carton_id} doesn't exist", current_bay_attributes(state_machine)) unless carton
      return failed_response('Scanned Carton Production Run is closed', current_bay_attributes(state_machine)) if carton[:production_run_closed]

      res = nil
      repo.transaction do
        res = MesscadaApp::CreatePalletFromCarton.call(@user, carton_id, 1)
        state_machine.create_pallet
        # UPDATE carton with pallet_sequence_id & pallet_sequence with incentive contract_worker....

        # pseq_id = prod_repo.first_sequence_id_from_pallet(res[:pallet])
        # pseq_id from res[pallet_id]
        # create/update bay with def carton & last ctn & new state
        changeset = { current_state: state_machine.current.to_s,
                      pallet_sequence_id: res.instance[:pallet_sequence_id],
                      determining_carton_id: carton_id,
                      last_carton_id: carton_id }
        repo.update_palletizing_bay_state(state_machine.target.id, changeset)
        log_transaction
      end
      success_response('ok...', current_bay_attributes(state_machine)) # provide lines for robot...
    end

    def add_to_pallet(state_machine, params)
      carton_id = params[:carton_number]

      # VALIDATE that carton has no pseq no (scanned already)
      # check if the pseq has changed
      # if yes, create new seq
      # else
      # increment carton qty
      repo.transaction do
        # state_machine.create_pallet
        prod_repo.increment_sequence(state_machine.target.pallet_sequence_id)
        # UPDATE carton with pallet_sequence_id & pallet_sequence with incentive contract_worker....

        changeset = { last_carton_id: carton_id }
        repo.update_palletizing_bay_state(state_machine.target.id, changeset)
        log_transaction
      end
      success_response('ok', current_bay_attributes(state_machine))
    end

    def return_pallet_to_bay(state_machine, params)
      carton_id = params[:carton_number]
      puts carton_id

      # VALIDATE that carton is on a pallet
      repo.transaction do
        state_machine.return_to_bay
        # Get pallet & 1st seq & 1st carton and update state

        changeset = { current_state: state_machine.current.to_s }
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
      sm = repo.palletizing_bay_state_by_robot_scanner(params[:device], params[:card_reader])
      CartonPalletizingStates.new(sm.fsm_target, initial: sm.state)
    end

    def repo
      @repo ||= PalletizingRepo.new
    end

    def prod_repo
      @prod_repo = ProductionApp::ProductionRunRepo.new
    end
  end
end
