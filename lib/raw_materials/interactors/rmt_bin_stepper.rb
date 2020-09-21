# frozen_string_literal: true

module RawMaterialsApp
  class RmtBinStep < BaseStep
    attr_reader :repo, :scanned_bin_number

    def initialize(step_key, user, ip)
      super(user, step_key, ip)
      @repo = RmtDeliveryRepo.new
    end

    def scan(scanned_bin_number)
      @scanned_bin_number = scanned_bin_number
      clear_notice
      setup if form_state.empty?

      unless bins.include? scanned_bin_number
        form_state[:error_message] = 'Bin number not on current deliveries'
        write(current_step)
        return
      end

      receive_remove
      write(current_step)
    end

    def receive_remove
      case scanned_bin_number
      when *to_scan
        scanned << scanned_bin_number
        message = "Received: #{scanned_bin_number}"
      else
        scanned.delete(scanned_bin_number)
        message = "Removed: #{scanned_bin_number} from received list."
      end
      form_state[:message] = message
      form_state[:entity] = entity
    end

    def setup
      rmt_delivery_id = repo.get_value(:rmt_bins, :rmt_delivery_id, bin_asset_number: scanned_bin_number)
      reference_number = repo.get_value(:rmt_deliveries, :reference_number, id: rmt_delivery_id)
      rmt_delivery_ids = repo.select_values(:rmt_deliveries, :id, received: false, reference_number: reference_number)
      bin_asset_numbers = repo.select_values(:rmt_bins, :bin_asset_number, rmt_delivery_id: rmt_delivery_ids).sort

      form_state = { reference_number: reference_number,
                     rmt_delivery_ids: rmt_delivery_ids }

      @current_step = { form_state: form_state, bin_asset_numbers: bin_asset_numbers }
    end

    def links
      links = []
      links << { caption: 'Complete Receiving', url: '/rmd/raw_materials/receive_bin/complete' } if to_scan.empty? && !scanned.empty?
      links << { caption: 'Cancel', url: '/rmd/raw_materials/receive_bin/cancel', prompt: 'Cancel receiving?' }
    end

    def form_state
      current_step[:form_state] ||= {}
    end

    def notes
      form_state[:message]
    end

    def clear_notice
      %i[message error_message].each { |k| form_state.delete(k) }
    end

    def bins
      current_step[:bin_asset_numbers] ||= []
    end

    def scanned
      current_step[:scanned] ||= []
    end

    def to_scan
      bins - scanned
    end

    def error?
      !form_state[:error_message].nil?
    end

    def complete
      form_state[:rmt_delivery_ids].each do |id|
        repo.update_rmt_delivery(id, date_delivered: Time.now, received: true)
      end
    end

    def progress
      return '' if (bins + scanned).empty?

      <<~HTML
        Bins to receive: #{to_scan.length}<br>#{to_scan.join('<br>')}<br><br>
        Scanned: #{scanned.length}<br>#{scanned.join('<br>')}
      HTML
    end

    private

    def current_step
      @current_step ||= read || {}
    end

    def entity
      return {} if scanned_bin_number.nil?

      id = repo.get_id(:rmt_bins, bin_asset_number: scanned_bin_number)
      repo.find_rmt_bin_flat(id).to_h
    end
  end
end
