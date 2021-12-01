# frozen_string_literal: true

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
      copy_messerver_set_host

      copy_robot_config
      reboot

      AppConst::ROBOT_LOG.info('Provisioning complete.')
      duration = Time.now - start_time
      out << "* Took #{format('%.2f', duration / 60.0)} minutes to run." # rubocop:disable Style/FormatStringToken
      success_response("Device has been provisioned and is rebooting. Took #{format('%.2f', duration / 60.0)} minutes to run.", out) # rubocop:disable Style/FormatStringToken
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

    def reboot
      Net::SSH.start(network_ip, usr, password: pw) do |ssh|
        out << "* Reset user's sudo permission..."
        out << ssh.exec!(%(sudo rm /etc/sudoers.d/010_nspi-nopasswd))
        out << '* Reboot...'
        out << ssh.exec!(%(echo #{pw} | sudo -S reboot))
      end
    end

    def add_user # rubocop:disable Metrics/AbcSize
      Net::SSH.start(network_ip, 'pi', password: 'raspberry') do |ssh|
        out << "* Add nspi user and change the pi user's password"
        out << ssh.exec!(%(sudo useradd -s /bin/bash -d /home/nspi/ -m -G sudo,adm,lpadmin,gpio,tty,dialout,cdrom,audio,video,input,netdev,i2c,spi nspi))
        out << ssh.exec!(%(sudo usermod --password $(openssl passwd -1 '#{pw}') nspi))
        out << ssh.exec!(%(echo 'nspi ALL=(ALL) NOPASSWD: ALL' | sudo tee /etc/sudoers.d/010_nspi-nopasswd))
        out << ssh.exec!(%(sudo sed -i "s/autologin-user=pi/autologin-user=nspi/" /etc/lightdm/lightdm.conf))
        out << ssh.exec!(%(sudo usermod --password $(openssl passwd -1 '#{pw}') pi))
      end
    end

    def show_mac # rubocop:disable Metrics/AbcSize
      Net::SSH.start(network_ip, usr, password: pw) do |ssh|
        result = ssh.exec!(%(cat /sys/class/net/$(ip route show default | awk '/default/ {print $5}')/address))
        out << 'MAC address:'
        out << '-----------------'
        out << result.chomp
        out << '-----------------'

        out << '* Adding aliases to bashrc'
        ssh.exec!(%(echo "alias lsl='ls -lht | head'" >> .bashrc))
        ssh.exec!(%(echo "alias killmesserver='sudo pkill -f java\\.+messerver'" >> .bashrc))

        out << '* Remove the default pi startup script'
        ssh.exec!(%(sudo rm /etc/xdg/autostart/piwiz.desktop))
      end
    end

    def copy_splash
      Net::SCP.start(network_ip, usr, password: pw) do |scp|
        out << '* Copy NoSoft splash screen to device'
        if for_reterm
          scp.upload! "#{ENV['ROOT']}/device_provisioning/ns_splash_vert.png", '/home/nspi/ns_splash.png'
        else
          scp.upload! "#{ENV['ROOT']}/device_provisioning/ns_splash.png", '/home/nspi/ns_splash.png'
        end
      end
    end

    def config_splash_locale_autostart # rubocop:disable Metrics/AbcSize
      Net::SSH.start(network_ip, usr, password: pw) do |ssh| # rubocop:disable Metrics/BlockLength
        out << '* Tweak boot commandline (serial ports and tty)'
        # Remove serial0 as a login shell:
        out << ssh.exec!(%([ -f "/boot/cmdline.txt" ] && sudo sed -i "s/console=serial0,[0-9]\+ //" /boot/cmdline.txt))
        # Remove AMA0 as a login shell:
        out << ssh.exec!(%([ -f "/boot/cmdline.txt" ] && sudo sed -i "s/console=ttyAMA0,[0-9]\+ //" /boot/cmdline.txt))
        # Remove usage of tty1:
        out << ssh.exec!(%([ -f "/boot/cmdline.txt" ] && sudo sed -i "s/console=tty1 //" /boot/cmdline.txt))

        out << '* Disable WiFi && Bluetooth'
        ssh.exec!(%(echo 'dtoverlay=disable-wifi' | sudo tee -a /boot/config.txt))
        ssh.exec!(%(echo 'dtoverlay=disable-bt' | sudo tee -a /boot/config.txt))

        out << '* Enable serial port hardware:'
        # 1. Set existing value if present to 1:
        out << ssh.exec!(%(sudo sed -i "s/enable_uart=0/enable_uart=1/" /boot/cmdline.txt))
        # 2. Add the value if not currently present:
        ssh.exec!(%(grep -qxF 'enable_uart=1' /boot/config.txt || echo 'enable_uart=1' | sudo tee -a /boot/config.txt))

        # console=serial0,115200 console=tty1 root=PARTUUID=2bf9ad89-02 rootfstype=ext4 elevator=deadline fsck.repair=yes rootwait quiet splash plymouth.ignore-serial-consoles logo.nologo vt.global_cursor_default=0 console=tty3 loglevel=0

        out << '* Set up splash screen'
        if for_reterm
          # For reTerm
          ssh.exec!(%(cd /usr/share/plymouth/themes/seeed/))
          ssh.exec!(%(sudo mv splash_v.png splash_v.png.bk))
          ssh.exec!(%(sudo mv /home/nspi/ns_splash_vert.png /usr/share/plymouth/themes/seeed/splash_v.png))
          out << ssh.exec!(%(sudo sed -i "s/my_image/# my_image/" /usr/share/plymouth/themes/seeed/seeed.script))
          out << ssh.exec!(%(sudo sed -i "s/message_sprite/# message_sprite/g" /usr/share/plymouth/themes/seeed/seeed.script))
        else
          # For pi
          ssh.exec!(%(cd /usr/share/plymouth/themes/pix/))
          ssh.exec!(%(sudo mv splash.png splash.png.bk))
          ssh.exec!(%(sudo mv /home/nspi/ns_splash.png /usr/share/plymouth/themes/pix/splash.png))
          out << ssh.exec!(%(sudo sed -i "s/my_image/# my_image/" /usr/share/plymouth/themes/pix/pix.script))
          out << ssh.exec!(%(sudo sed -i "s/message_sprite/# message_sprite/g" /usr/share/plymouth/themes/pix/pix.script))
        end
        out << '* Make locale and date settings'
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
        ssh.exec!(%(sudo apt-get update -y))

        out << '* Install vim, minicom, losf and lshw'
        result = ssh.exec!(%(sudo apt-get install vim minicom lsof lshw -y))
        out << result
        if for_virtual_pi
          out << '* VM: skip install of java'
        else
          out << '* Install java'
          result = ssh.exec!(%(sudo apt-get install openjdk-8-jdk -y))
          out << result
        end
        out << '* Disable java assistive technologies'
        result = ssh.exec!(%(sudo sed -i -e '/^assistive_technologies=/s/^/#/' /etc/java-*-openjdk/accessibility.properties))
        out << result

        out << '* Disable ipv6'
        ssh.exec!(%(echo 'net.ipv6.conf.all.disable_ipv6 = 0' | sudo tee -a /etc/sysctl.conf))

        out << '* Set boot to wait for network:'
        ssh.exec!(%(sudo mkdir -p /etc/systemd/system/dhcpcd.service.d/))
        result = ssh.exec!(<<~STR)
          cat <<- EOF | sudo tee /etc/systemd/system/dhcpcd.service.d/wait.conf
          [Service]
          ExecStart=
          ExecStart=/usr/lib/dhcpcd5/dhcpcd -q -w
          EOF
        STR
        out << result

        out << '* Logrotate for MesServer'
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

        out << '* Autostart into kiosk mode'
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
      end
    end

    def copy_messerver_set_host # rubocop:disable Metrics/AbcSize
      Net::SCP.start(network_ip, usr, password: pw) do |scp|
        out << '* Copy MesServer zip file to device'
        scp.upload! "#{ENV['ROOT']}/device_provisioning/nosoft_messerver.zip", '/home/nspi/nosoft_messerver.zip'
      end

      Net::SSH.start(network_ip, usr, password: pw) do |ssh|
        out << '* Unzip messerver'
        out << ssh.exec!(%(unzip nosoft_messerver.zip))
        out << ssh.exec!(%(rm nosoft_messerver.zip))
        out << ssh.exec!(%(sed -i "s/^java /# java /" /home/nspi/nosoft/messerver/startMesServer.sh)) if for_virtual_pi
        out << ssh.exec!(%(sed -i "s/^# JAVA 11: //g" /home/nspi/nosoft/messerver/startMesServer.sh)) if for_virtual_pi

        out << '* Change the hostname and static ip address'
        out << ssh.exec!(%(echo 'ns-#{sys_mod.ip_address.tr('.', '')}' | sudo tee /etc/hostname))
        out << ssh.exec!(%(sudo sed -i "/127.0.1.1/c\\127.0.1.1\\tns-#{sys_mod.ip_address.tr('.', '')}" /etc/hosts))
        out << ssh.exec!(%(sudo hostnamectl set-hostname ns-#{sys_mod.ip_address.tr('.', '')}))
        out << ssh.exec!(%(echo 'static ip_address=#{network_ip}/24' | sudo tee -a /etc/dhcpcd.conf))
        out << ssh.exec!(%(echo 'static routers=#{server.extended_config['gateway']}' | sudo tee -a /etc/dhcpcd.conf))
        # out << ssh.exec!(%(echo 'static domain_name_servers=#{server.extended_config['gateway']}' | sudo tee -a /etc/dhcpcd.conf)) # TODO: set static domain_name_servers= ??? - maybe doesn't matter for these devices operating on ip addresses... (and VLAN gateway?)
      end
    end

    def update_usb_files # rubocop:disable Metrics/AbcSize
      # NOTE: These USB settings are correct for rPi3B+ and seeed reTerm.
      #       They should be checked before provisioning a newer model.
      Net::SSH.start(network_ip, usr, password: pw) do |ssh| # rubocop:disable Metrics/BlockLength
        out << '* Set up USB config'
        out << ssh.exec!(%([ -f "/etc/udev/rules.d/50-usb-permissions.rules" ] && sudo cp /etc/udev/rules.d/50-usb-permissions.rules /etc/udev/rules.d/50-usb-permissions.rules.bak))
        out << ssh.exec!(%([ -f "/etc/udev/rules.d/10-usb-serial.rules" ] && sudo cp /etc/udev/rules.d/10-usb-serial.rules /etc/udev/rules.d/10-usb-serial.rules.bak))
        out << ssh.exec!(%([ -f "/etc/udev/rules.d/99-com.rules" ] && sudo cp /etc/udev/rules.d/99-com.rules /etc/udev/rules.d/99-com.rules.bak))

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

        # 50:
        result = ssh.exec!(<<~STR)
          cat << EOF | sudo tee /etc/udev/rules.d/50-usb-permissions.rules
            SUBSYSTEM=="usb", ATTR{idVendor}=="0a5f",ATTR{idProduct}=="0080",MODE="0666",GROUP="users"
            SUBSYSTEM=="usb", ATTR{idVendor}=="0a5f",ATTR{idProduct}=="0120",MODE="0666",GROUP="users"
            SUBSYSTEM=="usb", ATTR{idVendor}=="0a5f",ATTR{idProduct}=="0166",MODE="0666",GROUP="users"
            SUBSYSTEM=="usb", ATTR{idVendor}=="1664",ATTR{idProduct}=="0d10",MODE="0666",GROUP="users"
            SUBSYSTEM=="usb", ATTR{idVendor}=="1664",ATTR{idProduct}=="0e10",MODE="0666",GROUP="users"
            SUBSYSTEM=="usb", ATTR{idVendor}=="05f9",ATTR{idProduct}=="221a",MODE="0666",GROUP="users"
          EOF
        STR
        out << result

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
      end
    end

    def limit_gui_context_menu
      Net::SSH.start(network_ip, usr, password: pw) do |ssh|
        out << '* Lock down GUI menu'
        out << ssh.exec!(%(mkdir -p .config/openbox))

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
  end
end
