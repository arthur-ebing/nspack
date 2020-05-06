require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestCartonPalletizingStates < Minitest::Test
    def empty_state
      OpenStruct.new(state: :empty)
    end

    def palletizing_state
      OpenStruct.new(state: :palletizing)
    end

    def qc_checkout_state
      OpenStruct.new(state: :qc_checkout)
    end

    def return_to_bay_state
      OpenStruct.new(state: :return_to_bay)
    end

    def test_empty_state
      state = empty_state
      machine = CartonPalletizingStates.new(state, initial: :empty)
      assert machine.cannot?(:qc_checkout), 'Should not be able to QC checkout'
      assert machine.cannot?(:complete), 'Should not be able to complete'
      assert machine.can?(:return_to_bay), 'Should be able to return to bay'
      assert machine.can?(:refresh), 'Should be able to refresh'
      assert machine.can?(:scan), 'Should be able to scan'
      machine.scan
      assert_equal :palletizing, machine.current
      assert_equal :create_pallet, state.action
      machine.scan
      assert_equal :palletizing, machine.current
      assert_equal :add_carton, state.action
      machine.complete
      assert_equal :empty, machine.current
      assert_equal :complete_pallet, state.action
    end

    def test_empty_state_refresh
      state = empty_state
      machine = CartonPalletizingStates.new(state, initial: :empty)
      machine.refresh
      assert_equal :empty, machine.current
      assert_equal :refresh, state.action
    end

    def test_empty_state_complete
      state = empty_state
      machine = CartonPalletizingStates.new(state, initial: :empty)
      assert machine.cannot?(:complete), 'Should not be able to complete'
      machine.complete
      assert_equal :empty, machine.current
      assert_nil state.action
      refute_equal :complete, state.action
    end

    def test_palletizing_state
      state = palletizing_state
      machine = CartonPalletizingStates.new(state, initial: :palletizing)
      assert machine.can?(:qc_checkout), 'Should be able to QC checkout'
      assert machine.can?(:complete), 'Should be able to complete'
      assert machine.cannot?(:return_to_bay), 'Should not be able to return to bay'
      assert machine.can?(:refresh), 'Should be able to refresh'
      assert machine.can?(:scan), 'Should be able to scan'
      machine.scan
      assert_equal :palletizing, machine.current
      assert_equal :add_carton, state.action
      machine.complete
      assert_equal :empty, machine.current
      assert_equal :complete_pallet, state.action
    end

    def test_palletizing_state_refresh
      state = palletizing_state
      machine = CartonPalletizingStates.new(state, initial: :palletizing)
      machine.refresh
      assert_equal :palletizing, machine.current
      assert_equal :refresh, state.action
    end

    def test_palletizing_state_return_to_bay
      state = palletizing_state
      machine = CartonPalletizingStates.new(state, initial: :palletizing)
      assert machine.cannot?(:return_to_bay), 'Should not be able to return to bay'
      machine.return_to_bay
      assert_equal :palletizing, machine.current
      assert_nil state.action
    end

    def test_palletizing_state_qc_checkout
      state = palletizing_state
      machine = CartonPalletizingStates.new(state, initial: :palletizing)
      assert machine.can?(:qc_checkout), 'Should be able to checkout'
      machine.qc_checkout
      assert_equal :qc_checkout, machine.current
      assert_equal :prepare_qc, state.action
    end

    def test_palletizing_state_complete
      state = palletizing_state
      machine = CartonPalletizingStates.new(state, initial: :palletizing)
      assert machine.can?(:complete), 'Should be able to complete'
      machine.complete
      assert_equal :empty, machine.current
      assert_equal :complete_pallet, state.action
    end

    def test_qc_checkout_state
      state = qc_checkout_state
      machine = CartonPalletizingStates.new(state, initial: :qc_checkout)
      assert machine.cannot?(:qc_checkout), 'Should not be able to QC checkout'
      assert machine.cannot?(:complete), 'Should not be able to complete'
      assert machine.cannot?(:return_to_bay), 'Should not be able to return to bay'
      assert machine.can?(:refresh), 'Should be able to refresh'
      assert machine.can?(:scan), 'Should be able to scan'
      machine.scan
      assert_equal :palletizing, machine.current
      assert_equal :mark_qc_carton, state.action
    end

    def test_return_to_bay_state
      state = return_to_bay_state
      machine = CartonPalletizingStates.new(state, initial: :return_to_bay)
      assert machine.cannot?(:qc_checkout), 'Should not be able to QC checkout'
      assert machine.cannot?(:complete), 'Should not be able to complete'
      assert machine.cannot?(:return_to_bay), 'Should not be able to return to bay'
      assert machine.can?(:refresh), 'Should be able to refresh'
      assert machine.can?(:scan), 'Should be able to scan'
      machine.scan
      assert_equal :palletizing, machine.current
      assert_equal :return_to_bay, state.action
    end

    def test_scan_sequence
      state = empty_state
      machine = CartonPalletizingStates.new(state, initial: :empty)

      machine.scan
      assert_equal :palletizing, machine.current
      assert_equal :create_pallet, state.action

      machine.scan
      assert_equal :palletizing, machine.current
      assert_equal :add_carton, state.action

      state = qc_checkout_state
      machine = CartonPalletizingStates.new(state, initial: :qc_checkout)
      machine.scan
      assert_equal :palletizing, machine.current
      assert_equal :mark_qc_carton, state.action

      machine.complete
      assert_equal :empty, machine.current
      assert_equal :complete_pallet, state.action

      state = return_to_bay_state
      machine = CartonPalletizingStates.new(state, initial: :return_to_bay)
      machine.scan
      assert_equal :palletizing, machine.current
      assert_equal :return_to_bay, state.action
    end
  end
end
