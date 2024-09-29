{ pkgs, inputs, config, lib, ... }:
let
  rfid-reader = (pkgs.callPackage ./rfid-reader {});
in
{
  systemd.services.doorbot = let
    script = pkgs.writeShellScript "doorbot.sh" ''
      while true
      do
        ${pkgs.ripgrep}/bin/rg -i -f <(${rfid-reader}/bin/rfid-reader \
        | ${pkgs.gawk}/bin/awk -F 'Data: ' '{gsub(/;/, "", $2); print $2}' \
        | ${pkgs.coreutils}/bin/tr -d '\n') ${inputs.doorbots-config}/_config.yaml
        exit_code=$?
        if [ $exit_code -eq 0 ]; then
          echo "Match found!"
          set -x
          ${pkgs.libgpiod_1}/bin/gpioset --mode=time --sec=3 gpiochip0 25=1
          set +x
        fi
        sleep 0.1
      done

    '';
  in {
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      User = "root";
      Restart = "on-failure";
      RestartSec = 5;
      Group = "users";
      ExecStart = script;
    };
  };
  zramSwap.enable = true;
  environment.systemPackages = with pkgs; [
    vim
    git
    libgpiod
    i2c-tools
    rfid-reader
    ripgrep
  ];
  services.openssh.enable = true;
  networking.hostName = "doorbot-nixos";
  users = {
    users.default = {
      password = "default";
      isNormalUser = true;
      extraGroups = [ "wheel" ];
    };
  };
  networking = {
    useDHCP = true;
    wireless = {
      enable = true;
      networks = {
        DoESLiverpool.psk = "decafbad00";
      };
    };
  };
  services.avahi = {
    openFirewall = true;
    nssmdns4 = true; # Allows software to use Avahi to resolve.
    enable = true;
    publish = {
      userServices = true;
      enable = true;
      addresses = true;
      workstation = true;
    };
  };
  boot.initrd.availableKernelModules = [ "usbhid" "usb_storage" "vc4" "bcm2835_dma" "i2c_bcm2835" ];
  hardware.enableRedistributableFirmware = true;
}
