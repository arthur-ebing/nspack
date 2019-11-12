# frozen_string_literal: true

module FinishedGoodsApp
  class LoadTruckStep < BaseStep
    def initialize(user, ip)
      super(user, :load_truck, ip)
    end

    def scan_pallet(scanned_number) # rubocop:disable Metrics/AbcSize
      case scanned_number
      when *current_step[:allocated]
        current_step[:scanned] << current_step[:allocated].delete(scanned_number)
        form_state[:error_message] = nil
      when *current_step[:scanned]
        current_step[:allocated] << current_step[:scanned].delete(scanned_number)
        form_state[:error_message] = nil
      else
        form_state[:error_message] = "Pallet number '#{scanned_number}', not on load #{form_state[:load_id]}"
      end
      write(current_step)
    end

    def id
      form_state && form_state[:load_id]
    end

    def form_state
      current_step[:form_state]
    end

    def ready_to_load?
      current_step[:allocated].empty?
    end

    def error?
      !current_step[:error_message].nil?
    end

    def progress
      scanned = current_step[:scanned].empty? ? '' : "<br>Scanned Pallets<br>#{current_step[:scanned].join('<br>')}"
      <<~HTML
        Pallets still to scan<br>#{current_step[:allocated].join('<br>')}<br>
        #{scanned}
      HTML
    end

    private

    def current_step
      @current_step ||= read || {}
    end
  end
end
