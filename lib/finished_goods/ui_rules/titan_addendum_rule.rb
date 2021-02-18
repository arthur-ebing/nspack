# frozen_string_literal: true

module UiRules
  class TitanAddendumRule < Base
    def generate_rules
      @repo = FinishedGoodsApp::LoadRepo.new
      @titan_repo = FinishedGoodsApp::TitanRepo.new
      make_form_object
      apply_form_values

      set_show_fields
      add_controls
      form_name 'titan_addendum'
    end

    def set_show_fields
      fields[:load_id] = { renderer: :label, caption: 'Load' }
      fields[:request_type] = { renderer: :label, caption: 'Last Requested' }
      fields[:success] = { renderer: :label, as_boolean: true }
    end

    def make_form_object
      @form_object = FinishedGoodsApp::TitanRepo.new.find_titan_addendum(@options[:load_id])
      make_new_form_object if @form_object.nil?
    end

    def make_new_form_object
      @form_object = OpenStruct.new(load_id: @options[:load_id],
                                    request_type: {},
                                    success: nil)
    end

    def add_controls
      id = @options[:load_id]
      request = { control_type: :link,
                  text: 'Request Addendum ',
                  url: "/finished_goods/dispatch/loads/#{id}/titan_addendum/request",
                  icon: :checkon,
                  style: :action_button }
      status = { control_type: :link,
                 text: 'Request Addendum Status ',
                 url: "/finished_goods/dispatch/loads/#{id}/titan_addendum/status",
                 icon: :checkon,
                 style: :action_button }
      cancel = { control_type: :link,
                 text: 'Cancel Addendum',
                 url: "/finished_goods/dispatch/loads/#{id}/titan_addendum/cancel",
                 icon: :back,
                 style: :action_button }
      progress_controls = [request, status, cancel]
      @form_object = OpenStruct.new(@form_object.to_h.merge(progress_controls: progress_controls))
    end
  end
end
