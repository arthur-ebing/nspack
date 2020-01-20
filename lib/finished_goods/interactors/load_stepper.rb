# frozen_string_literal: true

module FinishedGoodsApp
  class LoadStep < BaseStep
    def initialize(step_key, user, ip)
      super(user, step_key, ip)
    end

    def allocate_pallet(scanned_number)
      case scanned_number
      when *current_step[:allocated]
        current_step[:allocated].delete(scanned_number)
      else
        current_step[:allocated] << scanned_number
      end
      write(current_step)
    end

    def load_pallet(scanned_number) # rubocop:disable Metrics/AbcSize
      case scanned_number
      when *current_step[:allocated]
        current_step[:scanned] << current_step[:allocated].delete(scanned_number)
        form_state[:error_message] = nil
      when *current_step[:scanned]
        current_step[:allocated] << current_step[:scanned].delete(scanned_number)
        form_state[:error_message] = nil
      else
        form_state[:error_message] = "Pallet number: #{scanned_number}, not on load: #{form_state[:load_id]}"
      end
      write(current_step)
    end

    def setup_load(load_id)
      load_flat = LoadRepo.new.find_load_flat(load_id)
      initial_count = LoadRepo.new.all_hash(:pallets, load_id: load_id).length

      raise 'Setup Load called without load_id' if load_flat.nil?

      form_state = { load_id: load_id,
                     voyage_code: load_flat.voyage_code,
                     vehicle_number: load_flat.vehicle_number,
                     container_code: load_flat.container_code,
                     allocation_count: initial_count }
      allocated = LoadRepo.new.find_pallet_numbers_from(load_id: load_id)

      write(form_state: form_state, allocated: allocated, initial_allocated: allocated.clone, scanned: [])
    end

    def id
      form_state && form_state[:load_id]
    end

    def form_state
      current_step[:form_state] ||= {}
    end

    def allocated
      current_step[:allocated] ||= []
    end

    def initial_allocated
      current_step[:initial_allocated] ||= []
    end

    def scanned
      current_step[:scanned] ||= []
    end

    def ready_to_ship?
      current_step[:allocated].empty?
    end

    def error?
      !form_state[:error_message].nil?
    end

    def progress_count
      current_step[:allocated].length
    end

    def allocation_progress
      current_step[:allocated].nil_or_empty? ? nil : "Pallets allocated: #{progress_count}<br>#{current_step[:allocated].join('<br>')}"
    end

    def progress
      return '' if current_step.nil?

      scanned = current_step[:scanned].nil_or_empty? ? '' : "<br>Scanned Pallets<br>#{current_step[:scanned].join('<br>')}"
      <<~HTML
        Pallets to scan: #{progress_count}<br>#{current_step[:allocated].join('<br>')}<br>
        #{scanned}
      HTML
    end

    private

    def current_step
      @current_step ||= read || {}
    end
  end
end
