{ pkgs, ... }: {
  packages = [
    pkgs.qemu
    pkgs.virt-manager
    pkgs.xrdp
    pkgs.xfce.xfce4-session
  ];

  idx = {
    extensions = [];
    workspace = {
      onCreate = {};
      onStart = {};
    };
  };
}
