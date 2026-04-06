{ pkgs, ... }: {
  packages = [
    pkgs.qemu
    pkgs.cloud-utils
    pkgs.wget
    pkgs.git
    pkgs.nodejs_22
    pkgs.curl
  ];

  idx = {
    extensions = [];

    workspace = {
      onCreate = {};
      onStart = {};
    };
  };
}
