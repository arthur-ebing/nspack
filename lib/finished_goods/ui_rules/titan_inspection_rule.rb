# frozen_string_literal: true

module UiRules
  class TitanInspectionRule < Base
    def generate_rules
      @repo = FinishedGoodsApp::GovtInspectionRepo.new
      @titan_repo = FinishedGoodsApp::TitanRepo.new
      make_form_object
      apply_form_values

      add_controls

      set_show_fields
      form_name 'titan_inspection'
    end

    def set_show_fields
      fields[:govt_inspection_sheet_id] = { renderer: :label, caption: 'Govt Inspection Sheet' }
      fields[:request_type] = { renderer: :label, caption: 'Last Requested' }
      fields[:success] = { renderer: :label, as_boolean: true }
    end

    def make_form_object
      hash = FinishedGoodsApp::TitanRepo.new.find_titan_inspection(@options[:govt_inspection_sheet_id]).to_h
      hash[:progress_controls] = []
      hash[:govt_inspection_sheet_id] = @options[:govt_inspection_sheet_id]
      @form_object = OpenStruct.new(hash)
    end

    private

    def add_controls # rubocop:disable Metrics/AbcSize
      id = @options[:govt_inspection_sheet_id]
      inspect = { control_type: :link, text: 'Request Inspection',
                  url: "/finished_goods/inspection/govt_inspection_sheets/#{id}/titan_inspection/request_inspection",
                  visible: !@form_object.validated,
                  style: :action_button }
      update = { control_type: :link, text: 'Update',
                 url: "/finished_goods/inspection/govt_inspection_sheets/#{id}/titan_inspection/update_inspection",
                 visible: @form_object.validated,
                 style: :action_button }
      validate = { control_type: :link, text: 'Validate',
                   url: "/finished_goods/inspection/govt_inspection_sheets/#{id}/titan_inspection/validate",
                   visible: @form_object&.inspection_message_id,
                   style: :action_button }
      validate_cons = { control_type: :link, text: 'Validate by Consignment',
                        url: "/finished_goods/inspection/govt_inspection_sheets/#{id}/titan_inspection/validate_consignment",
                        visible: !@form_object.validated && !@form_object&.inspection_message_id && !@form_object.request_type.nil?,
                        style: :action_button }
      results = { control_type: :link, text: 'Get Results',
                  url: "/finished_goods/inspection/govt_inspection_sheets/#{id}/titan_inspection/results",
                  visible: @form_object.validated,
                  style: :action_button }
      delete = { control_type: :link, text: 'Delete',
                 url: "/finished_goods/inspection/govt_inspection_sheets/#{id}/titan_inspection/delete",
                 style: :action_button,
                 visible: @form_object&.inspection_message_id }
      reinspect = { control_type: :link, text: 'Request Re-Inspection ',
                    url: "/finished_goods/inspection/govt_inspection_sheets/#{id}/titan_inspection/request_reinspection",
                    visible: !@form_object.validated,
                    style: :action_button }
      update_reinspection = { control_type: :link, text: 'Update Re-Inspection',
                              url: "/finished_goods/inspection/govt_inspection_sheets/#{id}/titan_inspection/update_reinspection",
                              visible: @form_object.validated,
                              style: :action_button }
      progress_controls = [inspect, update, validate, validate_cons, results, delete]
      progress_controls = [reinspect, update_reinspection, validate, validate_cons, results, delete] if @form_object.reinspection
      @form_object.progress_controls = progress_controls unless @repo.get(:govt_inspection_sheets, :inspected, @options[:govt_inspection_sheet_id])
    end
  end
end
