# frozen_string_literal: true

module ProductionApp
  class PackingSpecificationWizardStepper < BaseStep # rubocop:disable Metrics/ClassLength
    include Crossbeams::Responses

    def initialize(step_key, user, ip_address)
      super(user, step_key, ip_address)
    end

    def setup(opts = {}) # rubocop:disable Metrics/AbcSize
      clear
      form_state = opts
      form_state[:mode] ||= :new
      form_state[:mode] = form_state[:mode].to_sym
      form_state[:rebin] = form_state[:rebin] == 'true'
      form_state.merge!(ProductionApp::ProductSetupRepo.new.find_product_setup(form_state[:product_setup_id]).to_h)
      form_state.merge!(ProductionApp::PackingSpecificationRepo.new.find_packing_specification_item(form_state[:packing_specification_item_id]).to_h)

      form_state[:step] ||= 0
      form_state[:steps] = %w[Fruit Marketing Treatments Pallet]
      form_state[:steps] << 'Packaging' if AppConst::CR_PROD.use_packing_specifications? && !form_state[:rebin]
      write(form_state)
    end

    def referer
      form_state[:referer]
    end

    def cancel
      clear
    end

    def step
      [form_state[:step], max_step].min
    end

    def max_step
      form_state[:steps].length - 1
    end

    def current(opts = {})
      form_state.merge!(opts.to_h)
      form_state[:compact_header] = compact_header
      res
    end

    def previous
      form_state[:step] = step - 1
      action
      write(form_state)
    end

    def next
      form_state[:step] = step + 1
      action
      write(form_state)
    end

    def form_state
      @form_state ||= read || {}
    end

    def form
      forms = [
        Production::PackingSpecifications::PackingSpecification::WizardFruit,
        Production::PackingSpecifications::PackingSpecification::WizardMarketing,
        Production::PackingSpecifications::PackingSpecification::WizardTreatment,
        Production::PackingSpecifications::PackingSpecification::WizardPackaging,
        Production::PackingSpecifications::PackingSpecification::WizardPackingSpecification
      ]
      forms[step]
    end

    private

    def res # rubocop:disable Metrics/AbcSize
      extend_form_state if step == max_step

      contracts = [
        ProductSetupWizardFruitContract,
        ProductSetupWizardMarketingContract,
        ProductSetupWizardTreatmentContract,
        ProductSetupWizardPackagingContract,
        ProductSetupWizardPackingSpecificationContract
      ]
      res = contracts[step].new.call(form_state)
      form_state.merge!(res.to_h)

      if res.success?
        res = success_response('Validation passed', form_state)
      else
        res = validation_failed_response(res)
        res[:instance] = form_state
      end
      write(form_state)
      res
    end

    def action
      if step == max_step
        form_state[:action] = "/production/packing_specifications/wizard/#{form_state[:mode]}"
        form_state[:submit_caption] = 'Finish'
      else
        form_state[:action] = '/production/packing_specifications/wizard'
        form_state[:submit_caption] = 'Next'
      end
    end

    def compact_header
      columns = %i[product_setup_template cultivar_group cultivar]
      if step >= 1
        columns += %i[commodity marketing_variety std_fruit_size_count basic_pack
                      fruit_actual_counts_for_pack standard_pack fruit_size_reference class grade]
      end
      if step >= 2
        columns += %i[marketing_org packed_tm_group target_market target_customer sell_by_code mark product_chars
                      inventory_code customer_variety client_product_code client_size_reference
                      marketing_order_number]
      end
      columns += %i[treatments] if step >= 3
      columns += %i[pallet_base pallet_stack_type pallet_format pallet_label cartons_per_pallet] if step >= 4

      { columns: columns, display_columns: 4, header_captions: { packed_tm_group: 'Packed TM Group' } }
    end

    def extend_form_state
      form_state[:fruit_sticker_ids] ||= []
      form_state[:tu_sticker_ids] ||= []
      form_state[:ru_sticker_ids] ||= []
      form_state[:pm_bom_id] ||= nil
      form_state[:pm_mark_id] ||= nil
    end
  end
end
