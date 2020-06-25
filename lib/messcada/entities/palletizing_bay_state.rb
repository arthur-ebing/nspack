# frozen_string_literal: true

module MesscadaApp
  class PalletizingBayState < Dry::Struct
    attribute :id, Types::Integer
    attribute :palletizing_robot_code, Types::String
    attribute :scanner_code, Types::String
    attribute :palletizing_bay_resource_id, Types::Integer
    attribute :current_state, Types::Symbol
    attribute :pallet_sequence_id, Types::Integer
    attribute :determining_carton_id, Types::Integer
    attribute :last_carton_id, Types::Integer

    # When dryTypes gem is updated to 1.2, the current_state can be defined as Types::Coercible::Symbol
    # and this method will not be required.
    def state
      current_state.nil? ? current_state : current_state.to_sym
    end

    # Instance for use as FiniteMachine target.
    def fsm_target
      OpenStruct.new(id: id, state: state, action: nil)
    end
  end

  class PalletizingBayStateFlat < Dry::Struct
    attribute :id, Types::Integer
    attribute :palletizing_robot_code, Types::String
    attribute :scanner_code, Types::String
    attribute :palletizing_bay_resource_id, Types::Integer
    attribute :current_state, Types::Symbol
    attribute :pallet_sequence_id, Types::Integer
    attribute :determining_carton_id, Types::Integer
    attribute :last_carton_id, Types::Integer
    attribute :pallet_id, Types::Integer

    # When dryTypes gem is updated to 1.2, the current_state can be defined as Types::Coercible::Symbol
    # and this method will not be required.
    def state
      current_state.nil? ? current_state : current_state.to_sym
    end

    # Instance for use as FiniteMachine target.
    def fsm_target
      OpenStruct.new(id: id, state: state, action: nil)
    end
  end
end
