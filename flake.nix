{
  description = "My Home Manager configuration";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nix-cachyos-kernel = {
      url = "github:xddxdd/nix-cachyos-kernel/release";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    matugen = {
      url = "github:/InioX/Matugen";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hexecute = {
      url = "github:ThatOtherAndrew/Hexecute";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-wpsoffice-cn = {
      url = "github:Beriholic/nix-wpsoffice-cn";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-grub-themes = {
      url = "github:jeslie0/nixos-grub-themes";
      inputs.nixpkgs.follows = "nixpkgs";
    };
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
                  # 仅对 32 位 openldap 跳过 flaky 测试 test017-syncreplication-refresh
                  # （lutris 多架构会拉 i686 openldap）。不动 x86_64，避免连锁重编。
                  (_final: prev: {
                    pkgsi686Linux = prev.pkgsi686Linux.extend (
                      _f: p: {
                        openldap = p.openldap.overrideAttrs (_: { doCheck = false; });
                      }
                    );
                  })
                ];

                # ... your other configs
              }
            )
          ];
        };
      };
    };
}
