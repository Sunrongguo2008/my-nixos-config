{
  description = "My Home Manager configuration";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    # 添加稳定版本
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-25.11";
    nix-cachyos-kernel.url = "github:xddxdd/nix-cachyos-kernel/release";
    matugen = {
      url = "github:/InioX/Matugen";
    };
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hyprland.url = "github:hyprwm/Hyprland";
    hyprland-plugins = {
      url = "github:hyprwm/hyprland-plugins";
      inputs.hyprland.follows = "hyprland";
    };
    hexecute.url = "github:ThatOtherAndrew/Hexecute";
    nix-wpsoffice-cn.url = "github:Beriholic/nix-wpsoffice-cn";
    nixos-grub-themes.url = "github:jeslie0/nixos-grub-themes";
    noctalia = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    dms = {
      url = "github:AvengeMedia/DankMaterialShell/stable";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    quickshell = {
      url = "git+https://git.outfoxxed.me/quickshell/quickshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    mangowm = {
      url = "github:mangowm/mango";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs =
    inputs@{
      self,
      nixpkgs,
      home-manager,
      hyprland-plugins,
      hyprland,
      nix-cachyos-kernel,
      mangowm,
      ...
    }:
    {

      nixosConfigurations = {
        my-nixos = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs; };
          modules = [
            ./configuration.nix
            mangowm.nixosModules.mango
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.s = import ./home.nix;
              # 使用 home-manager.extraSpecialArgs 自定义传递给 ./home.nix 的参数
              # 取消注释下面这一行，就可以在 home.nix 中使用 flake 的所有 inputs 参数了
              home-manager.extraSpecialArgs = { inherit inputs; };
            }
            (
              { ... }:
              {
                nixpkgs.overlays = [
                  # Use the exact kernel versions as defined in nix-cachyos-kernel.
                  # This avoids kernel/patch version mismatch warnings and ensures cache availability.
                  nix-cachyos-kernel.overlays.pinned
                ];

                # ... your other configs
              }
            )
          ];
        };
      };
    };
}
