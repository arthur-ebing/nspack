# frozen_string_literal: true

module RawMaterialsApp
  class BinLoadStep < BaseStep
    include Crossbeams::Responses

    def initialize(step_key, user, ip)
      super(user, step_key, ip)
    end

    def setup_load(bin_load_id)
      @bin_load_id = bin_load_id
      bin_load_flat = repo.find_bin_load_flat(bin_load_id)
      raise 'Setup Bin Load called without bin_load_id' if bin_load_flat.nil?

      form_state = { bin_load_id: bin_load_id,
                     customer: bin_load_flat.customer,
                     transporter: bin_load_flat.transporter,
                     dest_depot: bin_load_flat.dest_depot,
                     qty_bins: bin_load_flat.qty_bins }
      write(bin_load_id: bin_load_id, form_state: form_state)
    end

    def bin_load_id
      current_step[:bin_load_id] ||= @bin_load_id
    end

    def form_state
      current_step[:form_state] ||= {}
    end

    def loaded
      current_step[:loaded] ||= []
    end

    def ready_to_ship?
      current_step[:loaded].length == current_step[:form_state][:qty_bins]
    end

    def error?
      !form_state[:error_message].nil?
    end

    def message
      form_state[:message]
    end

    def warning_message
      form_state[:warning_message]
    end

    def allocate(bin_asset_number) # rubocop:disable Metrics/AbcSize
      bin_load_product_ids = repo.rmt_bins_matching_bin_load(:bin_load_product_id, bin_load_id: bin_load_id, bin_asset_number: bin_asset_number)
      return form_state[:error] = "Bin:#{bin_asset_number} does not match a product on this load" if bin_load_product_ids.empty?

      # Unallocate
      index = loaded.index { |_, y| bin_asset_number.include?(y) }
      return load_bin(loaded[index][0], bin_asset_number) unless index.nil?

      bin_load_product_ids.each do |bin_load_product_id|
        qty_bins = repo.get(:bin_load_products, bin_load_product_id, :qty_bins)
        qty_loaded = loaded_bins(loaded, bin_load_product_id).length
        next if qty_loaded >= qty_bins

        return load_bin(bin_load_product_id, bin_asset_number)
      end

      form_state[:warning_message] = "All matching Bin Products fully allocated. Bin:#{bin_asset_number} not added."
    end

    def load_bin(bin_load_product_id, bin_asset_number) # rubocop:disable Metrics/AbcSize
      qty_bins = repo.get(:bin_load_products, bin_load_product_id, :qty_bins)
      qty_loaded = loaded_bins(loaded, bin_load_product_id).length

      product_bin = [bin_load_product_id, bin_asset_number]
      case product_bin
      when *current_step[:loaded]
        current_step[:loaded].delete(product_bin)
        message = "Removed: #{bin_asset_number}"
      else
        return form_state[:warning_message] = "Bin Product fully allocated. Bin:#{bin_asset_number} not allocated." if qty_loaded >= qty_bins

        current_step[:loaded] << product_bin
        message = "Added: #{bin_asset_number}"
      end
      write(current_step)
      form_state[:message] = message
    end

    def loaded_bins(loaded, bin_load_product_id)
      loaded_bins = []
      loaded.each do  |product_bin|
        loaded_bins << product_bin[1] if product_bin[0] == bin_load_product_id
      end
      loaded_bins
    end

    def progress # rubocop:disable Metrics/AbcSize
      return '' if current_step.nil?

      progress_text = ''
      bin_load_product_ids = repo.rmt_bins_matching_bin_load(:bin_load_product_id, bin_load_id: bin_load_id)
      bin_load_product_ids.each do |bin_load_product_id|
        product_entity = repo.find_bin_load_product_flat(bin_load_product_id)
        loaded_bins = loaded_bins(loaded, bin_load_product_id)
        progress_text = "#{progress_text}Loaded: #{loaded_bins.length} of #{product_entity.qty_bins} #{product_entity.product_code}<br>"
        progress_text = "#{progress_text}#{loaded_bins.sort.join(', ')}<br>"

        # bin_asset_numbers = repo.rmt_bins_matching_bin_load(:bin_asset_number, bin_load_product_id: bin_load_product_id) - loaded_bins
        # progress_text = "#{progress_text}<br>-- Available Bins: #{bin_asset_numbers.first(5).join(', ')}<br><br>"
      end
      progress_text
    end

    private

    def repo
      @repo ||= BinLoadRepo.new
    end

    def current_step
      @current_step ||= read || {}
    end
  end
end
