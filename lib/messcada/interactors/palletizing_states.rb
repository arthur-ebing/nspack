class PalletizingStates < FiniteMachine::Definition
  initial :empty

  event :create_pallet,  empty:         :palletizing

  event :prepare_return, empty:         :return_to_bay
  event :return_to_bay,  return_to_bay: :palletizing

  event :prepare_qc,     palletizing:   :qc_out
  event :qc_checkout,    qc_out:        :palletizing

  event :refresh,        empty:         :empty
  event :refresh,        palletizing:   :palletizing
  event :refresh,        qc_out:        :palletizing
  event :refresh,        return_to_bay: :empty

  # These two could replace the return_to_bay and qc_checkout events...
  # event :scan,           qc_out:        :palletizing, if: ->(context, want) { context.state == :qc_out && want == :qc_checkout }
  # event :scan,           return_to_bay: :palletizing, if: ->(context, want) { context.state == :return_to_bay && want == :return_to_bay }
  #  scan, palletizing: :palletizing
  #  scan, empty:       :palletizing
  #  on_enter(:scan) { |e| if e.from == :return... if :palletize (add carton), if :empty (add pallet, seq, ctn)

  event :complete,       palletizing:   :empty

  # on_enter(:palletizing) { |event| puts "++ #{event.name} - from: #{event.from} - to: #{event.to}."; target.state = :palletizing; }
  # on_enter(:empty) { target.state = :empty }
  # on_enter(:return_to_bay) { target.state = :return_to_bay }
  # on_enter(:qc_out) { target.state = :qc_out }
end
