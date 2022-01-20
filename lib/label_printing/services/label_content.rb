# frozen_string_literal: true

module LabelPrintingApp
  module LabelContent
    def label_date_for_functions
      @label_date_for_functions ||= @supporting_data[:packed_date] || Date.today
    end

    def label_date_time_for_functions
      @label_date_time_for_functions ||= Time.now
    end

    # Built-in functions - can't be private!
    def iso_day
      label_date_for_functions.strftime('%j')
    end

    def iso_week
      label_date_for_functions.strftime('%V')
    end

    def iso_week_day
      label_date_for_functions.strftime('%u')
    end

    def current_date
      label_date_for_functions.strftime('%Y-%m-%d')
    end

    def current_date_time
      label_date_time_for_functions.strftime('%Y-%m-%d %H:%M:%S')
    end

    def sequence_table(pallet_id)
      id = instance[pallet_id.to_sym]

      body = AppConst::CR_PROD.sequences_label_variable_for_pallet(id).join(';')
      return body if body.empty?

      "{NL}#{body}"
    end

    private

    # Take a field and format it for barcode printing.
    #
    # @param instance [Hash, DryType, OpenStruct] - the entity or hash that contains required values.
    # @param field [string] - the field to be formatted.
    # @return [string] - the formatted barcode string ready for printing.
    def make_barcode(field)
      fmt_str = AppConst::BARCODE_PRINT_RULES[field.to_sym][:format]
      raise Crossbeams::FrameworkError, "There is no BARCODE PRINT RULE for #{field}" if fmt_str.nil?

      fields = AppConst::BARCODE_PRINT_RULES[field.to_sym][:fields]
      vals = fields.map { |f| instance[f] }
      assert_no_nil_fields!(field, vals, fields)

      format(fmt_str, *vals)
    end

    def assert_no_nil_fields!(field, vals, fields)
      return unless vals.any?(&:nil?)

      in_err = vals.zip(fields).select { |v, _| v.nil? }.map(&:last)

      raise Crossbeams::FrameworkError, "Make BCD barcode: this instance does not have a value for: #{in_err.join(', ')}. Column value is required for BARCODE_PRINT_RULES[:#{field}]."
    end

    def values_from(lbl_required)
      vars = {}
      lbl_required.each_with_index do |resolver, index|
        vars["F#{index + 1}".to_sym] = value_from(resolver)
      end
      vars
    end

    def value_from(resolver)
      case resolver
      when /\ABCD:/
        make_barcode(resolver.delete_prefix('BCD:'))
      when /\AFNC:/
        make_function(resolver.delete_prefix('FNC:'))
      when /\ACMP:/
        make_composite(resolver.delete_prefix('CMP:'))
      else
        format_print_str(instance[resolver.to_sym])
      end
    end

    def make_function(resolver)
      args = resolver.split(',')
      func = args.shift
      raise Crossbeams::FrameworkError, "Label print function '#{func}' is not implemented" unless respond_to?(func.to_sym)

      if args.empty?
        send(func.to_sym)
      else
        send(func.to_sym, *args)
      end
    end

    def make_composite(resolver)
      # Example: 'CMP:x:${Location Long Code} - ${Location Short Code} / ${FNC:some_function,Location Long Code}'
      tokens = resolver.scan(/\$\{(.+?)\}/)
      output = resolver
      tokens.flatten.each { |token| output.gsub!("${#{token}}", value_from(token).to_s) }
      output
    end

    def fields_for_label # rubocop:disable Metrics/AbcSize
      repo = MasterfilesApp::LabelTemplateRepo.new
      label_template = repo.find_label_template_by_name(label_name)
      raise Crossbeams::FrameworkError, "There is no label template named \"#{label_name}\"." if label_template.nil?

      return [] if label_template.variable_rules.nil?

      label_template.variable_rules['variables'].map do |var|
        raise Crossbeams::FrameworkError, "Variable \"#{var.keys.first}\" on label \"#{label_name}\" has no resolver (Perhaps an incompatible variable set was used)." if var.values.first.nil?

        var.values.first['resolver']
      end
    end

    # Go through the list of fields for a label and record which are
    # special fields and the positions in which they occur.
    def special_field_positions(fields, special_fields)
      Hash[fields.each_with_index.select { |a, _| special_fields.include?(a) }.map { |n, i| [i, n] }]
    end

    # If a resolver needs to be swapped out on the fly, we place a token instead of the value
    # in the label field.
    # This method takes "carton_label_id" and returns "$:carton_label_id$"
    # and takes "BCD:carton_label_id" and returns "BCD:$:carton_label_id$"
    def format_special_field(field_name)
      if field_name.include?(':')
        parts = field_name.split(':')
        "$:#{parts.first}:#{parts.last}$"
      else
        "$:#{field_name}$"
      end
    end

    # Reformat BigDecimal to avoid printing scientific notation.
    def format_print_str(value)
      return value.to_s('F') if value.is_a?(BigDecimal)

      value
    end
  end
end
