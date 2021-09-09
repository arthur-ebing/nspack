# frozen_string_literal: true

# TODO: message to update value in grid row???? : grid id as channel, row_id, column_name, value
module Crossbeams
  module MessageBus
    # Broadcast a message to all users
    #
    # @param message [string] the message to be shown.
    # @param message_type [symbol] the type of message (:information, :success, :warning, :error)
    # @return [void]
    def broadcast(message, message_type: :information)
      send_bus_message(message, message_type: message_type)
    end

    # Send a message to all users or a targeted user
    #
    # @param message [string] the message to be shown.
    # @param message_type [symbol] the type of message (:information, :success, :warning, :error)
    # @param target_user [string] the user to receive the message (defaults to 'broadcast' - all users)
    # @return [void]
    def send_bus_message(message, message_type: :information, target_user: 'broadcast')
      ::MessageBus.publish('/terminus',
                           messageType: message_type,
                           targetUser: target_user || 'broadcast',
                           message: message)
    end

    def send_bus_message_to_page(actions, target_page, message: nil, message_type: :information)
      ::MessageBus.publish('/terminus',
                           messageType: message_type,
                           targetPage: target_page,
                           actions: actions,
                           message: message)
    end

    def send_bus_message_to_device(target_device, payload, message: nil, message_type: :information)
      ::MessageBus.publish('/terminus',
                           messageType: message_type,
                           targetDevice: target_device,
                           payload: payload,
                           message: message)
    end
  end
end
