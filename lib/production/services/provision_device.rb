# frozen_string_literal: true

# rubocop:disable Style/IdenticalConditionalBranches
module ProductionApp
  class ProvisionDevice < BaseService # rubocop:disable Metrics/ClassLength
    attr_reader :id, :repo, :network_ip, :usr, :pw, :out, :use_network_ip, :sys_mod, :server

    def initialize(id, network_ip, use_network_ip)
      @id = id
      @network_ip = network_ip
      @use_network_ip = use_network_ip
      @repo = ResourceRepo.new
      @usr = 'nspi'
      @pw = AppConst::PROVISION_PW
      @out = []
    end

    def call # rubocop:disable Metrics/AbcSize
      start_time = Time.now

      @sys_mod = repo.find_system_resource_flat(id)
      out << "PROVISIONING #{sys_mod.system_resource_code} ip: #{sys_mod.ip_address}"
      out << "---------------------------------------\n"
      AppConst::ROBOT_LOG.info('Starting provisioning of a device')
      AppConst::ROBOT_LOG.info("PROVISIONING #{sys_mod.system_resource_code} ip: #{sys_mod.ip_address}")
      res = check_for_previously_provisioned
      AppConst::ROBOT_LOG.info('Provisioning aborted - already run for this device') unless res.success
      return res unless res.success

      @server = repo.find_mes_server
      raise Crossbeams::InfoError, 'There is no plant resource defined as a MesServer' if server.nil?

      add_user
      show_mac
      copy_splash
      config_splash_locale_autostart
      update_usb_files
      limit_gui_context_menu
      copy_messerver
      copy_robot_config
      serial_and_wifi
      hostname
      reboot

      AppConst::ROBOT_LOG.info('Provisioning complete.')
      duration = Time.now - start_time
      out << "* Took #{format('%.2f', duration / 60.0)} minutes to run." # rubocop:disable Style/FormatStringToken
      success_response("Device has been provisioned and is rebooting. Took #{format('%.2f', duration / 60.0)} minutes to run.", out) # rubocop:disable Style/FormatStringToken
    rescue StandardError => e
      duration = Time.now - start_time
      out.unshift("This process failed after #{format('%.2f', duration / 60.0)} minutes - with error: #{e.message}") # rubocop:disable Style/FormatStringToken
      puts e.backtrace.join("\n")
      ErrorMailer.send_exception_email(e, subject: self.class.name, message: out.join("\n"))
      failed_response("An error occurred: #{e.message}", out)
    end

    private

    def for_virtual_pi
      @for_virtual_pi ||= sys_mod.extended_config['distro_type'] == Crossbeams::Config::ResourceDefinitions::MODULE_DISTRO_TYPE_VM
    end

    def for_reterm
      @for_reterm ||= sys_mod.extended_config['distro_type'] == Crossbeams::Config::ResourceDefinitions::MODULE_DISTRO_TYPE_RETERM
    end

    def copy_robot_config
      res = if use_network_ip
              ProductionApp::BuildModuleConfigXml.call(id, alternate_ip: network_ip)
            else
              ProductionApp::BuildModuleConfigXml.call(id)
            end

      Net::SCP.start(network_ip, usr, password: pw) do |scp|
        scp.upload! StringIO.new(res.instance[:xml]), '/home/nspi/nosoft/messerver/config/config.xml'
        out << '* Config.xml copied to device'
      end
    end

    def hostname # rubocop:disable Metrics/AbcSize
      Net::SSH.start(network_ip, usr, password: pw) do |ssh|
        out << '* Change the hostname and static ip address'
        log
        out << ssh.exec!(%(echo 'ns-#{sys_mod.ip_address.tr('.', '')}' | sudo tee /etc/hostname))
        log
        out << ssh.exec!(%(sudo sed -i "/127.0.1.1/c\\127.0.1.1\\tns-#{sys_mod.ip_address.tr('.', '')}" /etc/hosts))
        log
        out << ssh.exec!(%(sudo hostnamectl set-hostname ns-#{sys_mod.ip_address.tr('.', '')}))
        log
        out << ssh.exec!(%(echo 'static ip_address=#{sys_mod.ip_address}/24' | sudo tee -a /etc/dhcpcd.conf))
        log
        out << ssh.exec!(%(echo 'static routers=#{server.extended_config['gateway']}' | sudo tee -a /etc/dhcpcd.conf))
        log
        # out << ssh.exec!(%(echo 'static domain_name_servers=#{server.extended_config['gateway']}' | sudo tee -a /etc/dhcpcd.conf)) # TODO: set static domain_name_servers= ??? - maybe doesn't matter for these devices operating on ip addresses... (and VLAN gateway?)
      end
    end

    def reboot # rubocop:disable Metrics/AbcSize
      Net::SSH.start(network_ip, usr, password: pw) do |ssh|
        out << "* Reset user's sudo permission..."
        log
        out << ssh.exec!(%(sudo rm /etc/sudoers.d/010_nspi-nopasswd))
        log
        out << '* Reboot...'
        log
        out << ssh.exec!(%(echo #{pw} | sudo -S reboot))
        log
      end
    end

    def add_user # rubocop:disable Metrics/AbcSize
      Net::SSH.start(network_ip, 'pi', password: 'raspberry') do |ssh|
        out << "* Add nspi user and change the pi user's password"
        log
        out << ssh.exec!(%(sudo useradd -s /bin/bash -d /home/nspi/ -m -G sudo,adm,lpadmin,gpio,tty,dialout,cdrom,audio,video,input,netdev,i2c,spi nspi))
        log
        out << ssh.exec!(%(sudo usermod --password $(openssl passwd -1 '#{pw}') nspi))
        log
        out << ssh.exec!(%(echo 'nspi ALL=(ALL) NOPASSWD: ALL' | sudo tee /etc/sudoers.d/010_nspi-nopasswd))
        log
        out << ssh.exec!(%(sudo sed -i "s/autologin-user=pi/autologin-user=nspi/" /etc/lightdm/lightdm.conf))
        log
        out << ssh.exec!(%(sudo usermod --password $(openssl passwd -1 '#{pw}') pi))
        log
      end
    end

    def show_mac # rubocop:disable Metrics/AbcSize
      Net::SSH.start(network_ip, usr, password: pw) do |ssh|
        result = ssh.exec!(%(cat /sys/class/net/$(ip route show default | awk '/default/ {print $5}')/address))
        out << 'MAC address:'
        log
        out << '-----------------'
        log
        out << result.chomp
        log
        out << '-----------------'
        log

        out << '* Adding aliases to bashrc'
        log
        ssh.exec!(%(echo "alias lsl='ls -lht | head'" >> .bashrc))
        ssh.exec!(%(echo "alias killmesserver='sudo pkill -f java\\.+messerver'" >> .bashrc))

        out << '* Remove the default pi startup script'
        log
        ssh.exec!(%(sudo rm /etc/xdg/autostart/piwiz.desktop))
      end
    end

    def copy_splash
      Net::SCP.start(network_ip, usr, password: pw) do |scp|
        out << '* Copy NoSoft splash screen to device'
        log
        if for_reterm
          scp.upload! "#{ENV['ROOT']}/device_provisioning/ns_splash_vert.png", '/home/nspi/ns_splash.png'
        else
          scp.upload! "#{ENV['ROOT']}/device_provisioning/ns_splash.png", '/home/nspi/ns_splash.png'
        end
      end
    end

    def serial_and_wifi # rubocop:disable Metrics/AbcSize
      Net::SSH.start(network_ip, usr, password: pw) do |ssh|
        out << '* Enable serial port hardware:'
        log
        # 1. Set existing value if present to 1:
        out << ssh.exec!(%(sudo sed -i "s/enable_uart=0/enable_uart=1/" /boot/config.txt))
        log
        # 2. Add the value if not currently present:
        ssh.exec!(%(grep -qxF 'enable_uart=1' /boot/config.txt || echo 'enable_uart=1' | sudo tee -a /boot/config.txt))

        out << '* Tweak boot commandline (serial ports and tty)'
        log
        # Remove serial0 as a login shell:
        out << ssh.exec!(%([ -f "/boot/cmdline.txt" ] && sudo sed -i "s/console=serial0,[0-9]\+ //" /boot/cmdline.txt))
        log
        # Remove AMA0 as a login shell:
        out << ssh.exec!(%([ -f "/boot/cmdline.txt" ] && sudo sed -i "s/console=ttyAMA0,[0-9]\+ //" /boot/cmdline.txt))
        log
        # Remove usage of tty1:
        out << ssh.exec!(%([ -f "/boot/cmdline.txt" ] && sudo sed -i "s/console=tty1 //" /boot/cmdline.txt))
        log

        out << '* Disable WiFi && Bluetooth'
        log
        ssh.exec!(%(echo 'dtoverlay=disable-wifi' | sudo tee -a /boot/config.txt))
        ssh.exec!(%(echo 'dtoverlay=disable-bt' | sudo tee -a /boot/config.txt))

        # console=serial0,115200 console=tty1 root=PARTUUID=2bf9ad89-02 rootfstype=ext4 elevator=deadline fsck.repair=yes rootwait quiet splash plymouth.ignore-serial-consoles logo.nologo vt.global_cursor_default=0 console=tty3 loglevel=0
      end
    end

    def config_splash_locale_autostart # rubocop:disable Metrics/AbcSize
      Net::SSH.start(network_ip, usr, password: pw) do |ssh| # rubocop:disable Metrics/BlockLength
        out << '* Set up splash screen'
        log
        if for_reterm
          # For reTerm
          ssh.exec!(%(cd /usr/share/plymouth/themes/seeed/))
          ssh.exec!(%(sudo mv splash_v.png splash_v.png.bk))
          ssh.exec!(%(sudo mv /home/nspi/ns_splash.png /usr/share/plymouth/themes/seeed/splash_v.png))
          out << ssh.exec!(%(sudo sed -i "s/my_image/# my_image/" /usr/share/plymouth/themes/seeed/seeed.script))
          log
          out << ssh.exec!(%(sudo sed -i "s/message_sprite/# message_sprite/g" /usr/share/plymouth/themes/seeed/seeed.script))
          log
        else
          # For pi
          ssh.exec!(%(cd /usr/share/plymouth/themes/pix/))
          ssh.exec!(%(sudo mv splash.png splash.png.bk))
          ssh.exec!(%(sudo mv /home/nspi/ns_splash.png /usr/share/plymouth/themes/pix/splash.png))
          out << ssh.exec!(%(sudo sed -i "s/my_image/# my_image/" /usr/share/plymouth/themes/pix/pix.script))
          log
          out << ssh.exec!(%(sudo sed -i "s/message_sprite/# message_sprite/g" /usr/share/plymouth/themes/pix/pix.script))
          log
        end
        out << '* Make locale and date settings'
        log
        ssh.exec!(%(sudo cp /etc/locale.gen /etc/locale.gen.dist))
        ssh.exec!(%(sudo sed -i -e "/^[^#]/s/^/# /" -e "/en_ZA.UTF-8/s/^# //" /etc/locale.gen))
        ssh.exec!(%(sudo cp /var/cache/debconf/config.dat /var/cache/debconf/config.dat.dist))
        ssh.exec!(%(sudo sed -i -e "/^Value: en_GB.UTF-8/s/en_GB/en_ZA/" -e "/^ locales = en_GB.UTF-8/s/en_GB/en_ZA/" /var/cache/debconf/config.dat))
        ssh.exec!(%(sudo locale-gen))
        ssh.exec!(%(sudo update-locale LANG=en_ZA.UTF-8))
        ssh.exec!(%(sudo update-locale LANGUAGE=en_ZA.UTF-8))
        ssh.exec!(%(sudo timedatectl set-timezone Africa/Johannesburg))
        ssh.exec!(%(sudo cp /etc/default/keyboard /etc/default/keyboard.dist))
        ssh.exec!(%(sudo sed -i -e "/XKBLAYOUT=/s/gb/us/" /etc/default/keyboard))
        ssh.exec!(%(sudo service keyboard-setup restart))

        out << '* Update apt'
        log
        ssh.exec!(%(sudo apt-get update -y))

        out << '* Install vim, minicom, losf and lshw'
        log
        result = ssh.exec!(%(sudo apt-get install vim minicom lsof lshw -y))
        out << result
        log
        if for_virtual_pi
          out << '* VM: skip install of java'
          log
        else
          out << '* Install java'
          log
          result = ssh.exec!(%(sudo apt-get install openjdk-8-jdk -y))
          out << result
          log
        end
        out << '* Disable java assistive technologies'
        log
        result = ssh.exec!(%(sudo sed -i -e '/^assistive_technologies=/s/^/#/' /etc/java-*-openjdk/accessibility.properties))
        out << result
        log

        out << '* Disable ipv6'
        log
        ssh.exec!(%(echo 'net.ipv6.conf.all.disable_ipv6 = 0' | sudo tee -a /etc/sysctl.conf))

        out << '* Set boot to wait for network:'
        log
        ssh.exec!(%(sudo mkdir -p /etc/systemd/system/dhcpcd.service.d/))
        result = ssh.exec!(<<~STR)
          cat <<- EOF | sudo tee /etc/systemd/system/dhcpcd.service.d/wait.conf
          [Service]
          ExecStart=
          ExecStart=/usr/lib/dhcpcd5/dhcpcd -q -w
          EOF
        STR
        out << result
        log

        out << '* Logrotate for MesServer'
        log
        result = ssh.exec!(<<~STR)
          cat << EOF | sudo tee /etc/logrotate.d/messerver
          /home/nspi/nosoft/messerver/logs/stdoutlog.log {
            daily
            missingok
            rotate 3
            compress
            copytruncate
            delaycompress
          }
          EOF
        STR
        out << result
        log

        out << '* Autostart into kiosk mode'
        log
        # 1. Comment out all existing lines:
        ssh.exec!(%(sudo sed -i 's/^\\([^#]\\)/# \\1/g' /etc/xdg/lxsession/LXDE-pi/autostart))
        # 2. Add kiosk-enabling lines
        result = ssh.exec!(<<~STR)
          cat << EOF | sudo tee -a /etc/xdg/lxsession/LXDE-pi/autostart
          @xset s 0 0
          @xset s noblank
          @xset s noexpose
          @xset dpms 0 0 600
          # Kiosk mode: Start only the java app:
          @/home/nspi/nosoft/messerver/startMesServer.sh
          EOF
        STR
        out << result
        log
      end
    end

    def copy_messerver # rubocop:disable Metrics/AbcSize
      Net::SCP.start(network_ip, usr, password: pw) do |scp|
        out << '* Copy MesServer zip file to device'
        log
        scp.upload! "#{ENV['ROOT']}/device_provisioning/nosoft_messerver.zip", '/home/nspi/nosoft_messerver.zip'
      end

      Net::SSH.start(network_ip, usr, password: pw) do |ssh|
        out << '* Unzip messerver'
        log
        out << ssh.exec!(%(unzip nosoft_messerver.zip))
        log
        out << ssh.exec!(%(rm nosoft_messerver.zip))
        log
        out << ssh.exec!(%(sed -i "s/^java /# java /" /home/nspi/nosoft/messerver/startMesServer.sh)) if for_virtual_pi
        log
        out << ssh.exec!(%(sed -i "s/^# JAVA 11: //g" /home/nspi/nosoft/messerver/startMesServer.sh)) if for_virtual_pi
        log
      end
    end

    def update_usb_files # rubocop:disable Metrics/AbcSize
      # NOTE: These USB settings are correct for rPi3B+ and seeed reTerm.
      #       They should be checked before provisioning a newer model.
      Net::SSH.start(network_ip, usr, password: pw) do |ssh| # rubocop:disable Metrics/BlockLength
        out << '* Set up USB config'
        log
        out << ssh.exec!(%([ -f "/etc/udev/rules.d/50-usb-permissions.rules" ] && sudo cp /etc/udev/rules.d/50-usb-permissions.rules /etc/udev/rules.d/50-usb-permissions.rules.bak))
        log
        out << ssh.exec!(%([ -f "/etc/udev/rules.d/10-usb-serial.rules" ] && sudo cp /etc/udev/rules.d/10-usb-serial.rules /etc/udev/rules.d/10-usb-serial.rules.bak))
        log
        out << ssh.exec!(%([ -f "/etc/udev/rules.d/99-com.rules" ] && sudo cp /etc/udev/rules.d/99-com.rules /etc/udev/rules.d/99-com.rules.bak))
        log

        # 10:
        result = ssh.exec!(<<~STR)
          cat << EOF | sudo tee /etc/udev/rules.d/10-usb-serial.rules
            KERNEL=="ttyACM*", KERNELS=="1-1.1.2", SYMLINK+="ttyACM_DEVICE0"
            KERNEL=="ttyACM*", KERNELS=="1-1.1.3", SYMLINK+="ttyACM_DEVICE1"
            KERNEL=="ttyACM*", KERNELS=="1-1.2", SYMLINK+="ttyACM_DEVICE2"
            KERNEL=="ttyACM*", KERNELS=="1-1.3", SYMLINK+="ttyACM_DEVICE3"
          EOF
        STR
        out << result
        log

        # 50: List of usb devices vendor and product keys (run lsusb when device plugged in to find these codes)
        result = ssh.exec!(<<~STR)
          cat << EOF | sudo tee /etc/udev/rules.d/50-usb-permissions.rules
            # Zebra printer (zebra:gk420d)
            SUBSYSTEM=="usb", ATTR{idVendor}=="0a5f",ATTR{idProduct}=="0080",MODE="0666",GROUP="users"
            # Zebra printer (zebra:zd420)
            SUBSYSTEM=="usb", ATTR{idVendor}=="0a5f",ATTR{idProduct}=="0120",MODE="0666",GROUP="users"
            # Zebra printer (zebra:zd230)
            SUBSYSTEM=="usb", ATTR{idVendor}=="0a5f",ATTR{idProduct}=="0166",MODE="0666",GROUP="users"
            # Argox printer (argox:ar-o4-250)
            SUBSYSTEM=="usb", ATTR{idVendor}=="1664",ATTR{idProduct}=="0d10",MODE="0666",GROUP="users"
            # Argox printer (argox:ar-d4-250)
            SUBSYSTEM=="usb", ATTR{idVendor}=="1664",ATTR{idProduct}=="0e10",MODE="0666",GROUP="users"
            # Datalogic cordless keyboard wegde (psc:datalogic / datalogic:bc2030)
            SUBSYSTEM=="usb", ATTR{idVendor}=="05f9",ATTR{idProduct}=="221a",MODE="0666",GROUP="users"
            # GUSS Manufacturing Fruit Texture Analyser (guss:fta)
            SUBSYSTEM=="usb", ATTR{idVendor}=="6017",ATTR{idProduct}=="3430",MODE="0666",GROUP="users"
          EOF
        STR
        out << result
        log

        # 99:
        result = ssh.exec!(<<~STR)
          cat << EOF | sudo tee /etc/udev/rules.d/99-com.rules
            SUBSYSTEM=="input", GROUP="input", MODE="0660"
            SUBSYSTEM=="i2c-dev", GROUP="i2c", MODE="0660"
            SUBSYSTEM=="spidev", GROUP="spi", MODE="0660"
            SUBSYSTEM=="bcm2835-gpiomem", GROUP="gpio", MODE="0660"
            SUBSYSTEM=="argon-*", GROUP="video", MODE="0660"
            SUBSYSTEM=="rpivid-*", GROUP="video", MODE="0660"

            SUBSYSTEM=="gpio", GROUP="gpio", MODE="0660"
            SUBSYSTEM=="gpio*", PROGRAM="/bin/sh -c '\
              chown -R root:gpio /sys/class/gpio && chmod -R 770 /sys/class/gpio;\
              chown -R root:gpio /sys/devices/virtual/gpio && chmod -R 770 /sys/devices/virtual/gpio;\
              chown -R root:gpio /sys$devpath && chmod -R 770 /sys$devpath\
            '"

            KERNEL=="ttyAMA[01]", PROGRAM="/bin/sh -c '\
              ALIASES=/proc/device-tree/aliases; \
              if cmp -s $ALIASES/uart0 $ALIASES/serial0; then \
                echo 0;\
              elif cmp -s $ALIASES/uart0 $ALIASES/serial1; then \
                echo 1; \
              else \
                exit 1; \
              fi\
            '", SYMLINK+="serial%c"

            KERNEL=="ttyS0", PROGRAM="/bin/sh -c '\
              ALIASES=/proc/device-tree/aliases; \
              if cmp -s $ALIASES/uart1 $ALIASES/serial0; then \
                echo 0; \
              elif cmp -s $ALIASES/uart1 $ALIASES/serial1; then \
                echo 1; \
              else \
                exit 1; \
              fi \
            '", SYMLINK+="serial%c"
          EOF
        STR
        out << result
        log
      end
    end

    def limit_gui_context_menu
      Net::SSH.start(network_ip, usr, password: pw) do |ssh|
        out << '* Lock down GUI menu'
        log
        out << ssh.exec!(%(mkdir -p .config/openbox))
        log

        # Reduce menu options for openbox window manager
        result = ssh.exec!(<<~STR)
          cat << EOF > .config/openbox/menu.xml
            <?xml version="1.0" encoding="UTF-8"?>

            <openbox_menu xmlns="http://openbox.org/"
                    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                    xsi:schemaLocation="http://openbox.org/
                            file:///usr/share/openbox/menu.xsd">

            <menu id="root-menu" label="Openbox 3">
              <item label="Terminal emulator">
                <action name="Execute"><execute>x-terminal-emulator</execute></action>
              </item>
              <separator />
              <item label="Exit">
                <action name="Exit" />
              </item>
            </menu>

            </openbox_menu>
          EOF
        STR
        out << result
        log
      end
    end

    def check_for_previously_provisioned
      Net::SSH.start(network_ip, 'pi', password: 'raspberry', non_interactive: true) do |ssh|
        ssh.exec!('ls -l')
      end
      ok_response
    rescue Net::SSH::AuthenticationFailed
      failed_response('This device has already been provisioned', ['Unable to re-provision device'])
    end

    def log
      puts out.last
    end
  end
end
# rubocop:enable Style/IdenticalConditionalBranches
