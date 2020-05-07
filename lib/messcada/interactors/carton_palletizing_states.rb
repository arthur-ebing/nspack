class CartonPalletizingStates < FiniteMachine::Definition
  initial :empty

  event :return_to_bay,  empty:         :return_to_bay
  event :qc_checkout,    palletizing:   :qc_checkout

  event :scan,           qc_checkout:   :palletizing, if: ->(context) { context.state == :qc_checkout }
  event :scan,           return_to_bay: :palletizing, if: ->(context) { context.state == :return_to_bay }
  event :scan,           empty:         :palletizing
  event :scan,           palletizing:   :palletizing

  event :complete,       palletizing:   :empty

  event :refresh,        empty:         :empty
  event :refresh,        palletizing:   :palletizing
  event :refresh,        qc_checkout:   :palletizing
  event :refresh,        return_to_bay: :empty

  on_enter(:palletizing) do |event|
    target.action = if event.name == :scan
                      case event.from
                      when :empty
                        :create_pallet
                      when :palletizing
                        :add_carton
                      when :return_to_bay
                        :return_to_bay
                      when :qc_checkout
                        :mark_qc_carton
                      else
                        :error_event
                      end
                    elsif event.name == :refresh
                      :refresh
                    else
                      :error_event
                    end
    target.state = :palletizing
  end

  on_enter(:empty) do |event|
    case event.name
    when :complete
      target.action = :complete_pallet
    when :refresh
      target.action = :refresh
    end
    target.state = :empty
  end

  on_enter(:return_to_bay) do
    target.action = :prepare_return
    target.state = :return_to_bay
  end

  on_enter(:qc_checkout) do
    target.action = :prepare_qc
    target.state = :qc_checkout
  end
end
