{ pkgs, ... }: {
  packages = [
    pkgs.qemu
    pkgs.cloud-image-utils
    pkgs.wget
    pkgs.nodejs_22
    pkgs.git
  ];

  idx = {
    extensions = [];
    workspace = {
      onCreate = {};
      onStart = {};
    };
  };
}
