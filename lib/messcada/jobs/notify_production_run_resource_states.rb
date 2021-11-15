# frozen_string_literal: true

module MesscadaApp
  module Job
    class NotifyProductionRunResourceStates < BaseQueJob # rubocop:disable Metrics/ClassLength
      attr_reader :production_run_id, :xml, :repo

      def run(production_run_id, user_name)
        @production_run_id = production_run_id
        @repo = ProductionApp::ProductionRunRepo.new
        res = send_notification_for_resource_states

        unless res.success
          msg = <<~STR
            The response from MesServer call: #{res.message}

            The instance returned was:
            #{res.instance.inspect}
          STR
          ErrorMailer.send_error_email(subject: "#{self.class.name} failed to set button captions",
                                       message: msg)

          send_message_bus_err(user_name, res)
        end
        finish
      end

      private

      def send_message_bus_err(user_name, res)
        login_name = @repo.get_value(:users, :login_name, user_name: user_name)

        err = if res.instance[:refused]
                'Robot button captions could not be set. The connection was refused'
              else
                "Robot button captions could not be set. The response from MesServer call: #{res.message}"
              end

        send_bus_message(err, message_type: :error, target_user: login_name)
      end

      def send_notification_for_resource_states
        # send_to_browser_robots
        build_xml
        send_xml
      end

      def send_to_browser_robots
        modules_for_lbl = clm_modules # do for browser robots only...
        modules_for_lbl.each do |mod, buttons|
          btns = []
          buttons.each do |rec|
            btns << { button: rec[:button],
                      button_id: rec[:id],
                      enabled: !rec[:product_setup_id].nil? && !rec[:label_template_id].nil?,
                      caption: build_caption(rec) }
          end
          send_bus_message_to_device(mod.first, btns)
        end
      end

      def build_caption(rec)
        return 'Not in use' if rec[:product_setup_id].nil_or_empty?
        return 'No template' if rec[:label_template_id].nil_or_empty?

        # ar = AppConst::CLM_BUTTON_CAPTION_FORMAT.split('$')
        ar = AppConst::CR_PROD.button_caption_spec.split('$')
        ar.map { |s| s.start_with?(':') ? rec[s.delete_prefix(':').to_sym] : s }.compact.join
      end

      def build_xml # rubocop:disable Metrics/AbcSize
        modules_for_lbl = clm_modules
        modules_for_bvm = bvm_modules

        builder = Nokogiri::XML::Builder.new do |xml| # rubocop:disable Metrics/BlockLength
          xml.module_buttons do # rubocop:disable Metrics/BlockLength
            xml.modules do # rubocop:disable Metrics/BlockLength
              unless modules_for_lbl.empty?
                modules_for_lbl.each do |mod, buttons|
                  xml.module do
                    xml.name mod.first
                    xml.alias mod.last
                    xml.buttons do
                      buttons.each do |rec|
                        xml.button do
                          xml.name rec[:button]
                          xml.caption build_caption(rec)
                          xml.enabled !rec[:product_setup_id].nil? && !rec[:label_template_id].nil?
                        end
                      end
                    end
                  end
                end
              end
              unless modules_for_bvm.empty?
                modules_for_bvm.each do |mod, buttons|
                  xml.module do
                    xml.name mod.first
                    xml.alias mod.last
                    xml.buttons do
                      buttons.each do |name, tare|
                        xml.button do
                          xml.name name
                          xml.caption tare.nil? ? 'Not in use' : tare.to_s('F')
                          xml.enabled !tare.nil?
                        end
                      end
                    end
                  end
                end
              end
            end
          end
        end
        @xml = builder.to_xml
      end

      def clm_modules
        # return {} unless AppConst::CLM_BUTTON_CAPTION_FORMAT
        return {} unless AppConst::CR_PROD.button_caption_spec

        lbl_modules = repo.button_allocations(production_run_id)
        lbl_modules.group_by { |r| [r[:module], r[:alias]] }
      end

      def bvm_modules
        # return {} unless AppConst::PROVIDE_PACK_TYPE_AT_VERIFICATION
        return {} unless AppConst::CR_PROD.provide_pack_type_at_carton_verification?

        repo.bin_verification_settings(production_run_id)
      end

      def send_xml
        http = Crossbeams::HTTPCalls.new
        http.xml_post("#{AppConst::LABEL_SERVER_URI}SetModuleRobotButtonStates", xml)
      end
    end
  end
end
