# kmscon 配置：仅在 tty5 / tty6 上以 kmscon 替代默认 agetty，其余 VT 不变。
#
# 实现要点：
#   - 不启用 services.kmscon（那会全局接管 tty2–tty6）。
#   - 不写 systemd.packages = [pkgs.kmscon]（避免引入上游模板的全局 autovt@ 别名）。
#   - 手写两个【具体实例】服务 kmsconvt@tty5 / kmsconvt@tty6，并各自给出
#     【具体实例别名】autovt@ttyN.service。logind 切到 VT5/VT6 时启动
#     autovt@ttyN.service，命中具体实例别名 → 拉起 kmscon；其余 VT 仍命中
#     getty 模块提供的模板别名 autovt@.service → getty@.service → agetty。
{ config, lib, pkgs, ... }:

let
  gettyCfg = config.services.getty;

  # kmscon 配置文件目录（--configdir 指向包含 kmscon.conf 的目录）
  kmsconConfig = pkgs.writeTextFile {
    name = "kmscon-config";
    destination = "/kmscon.conf";
    text = ''
      font-name=Maple Mono NF CN
      font-size=14
      # 如需开启硬件渲染，取消下面两行注释（需确认 DRM/GLES 可用）：
      # drm
      # hwaccel
    '';
  };

  # 生成单个具体实例服务，对应一个 tty。
  mkKmsconvt = tty: {
    description = "KMS System Console on ${tty}";
    documentation = [ "man:kmscon(1)" ];

    after = [
      "systemd-user-sessions.service"
      "plymouth-quit-wait.service"
      "rc-local.service"
    ];
    before = [ "getty.target" ];
    conflicts = [ "getty@${tty}.service" ];
    # kmscon 彻底失败时回退到 agetty，保证该 VT 不会变成黑屏不可登录。
    onFailure = [ "getty@${tty}.service" ];

    unitConfig = {
      IgnoreOnIsolate = true;
      ConditionPathExists = "/dev/tty0";
    };

    serviceConfig = {
      ExecStart = "${pkgs.kmscon}/bin/kmscon --configdir ${kmsconConfig} --vt=${tty} --no-switchvt --login -- ${gettyCfg.loginProgram} -p";
      UtmpIdentifier = tty;
      TTYPath = "/dev/${tty}";
      TTYReset = true;
      TTYVHangup = true;
      TTYVTDisallocate = true;
      Restart = "always";
      RestartSec = "1";   # 略大于 0，避免崩溃-重启风暴撞上 systemd start-limit
    };

    # 与官方 kmscon 模块一致：rebuild switch 时不要重启正在使用的 VT。
    restartIfChanged = false;

    # 关键：具体实例别名。logind 启动 autovt@ttyN.service 时命中此别名。
    aliases = [ "autovt@${tty}.service" ];
  };
in
{
  environment.systemPackages = [ pkgs.kmscon ];

  systemd.services."kmsconvt@tty5" = mkKmsconvt "tty5";
  systemd.services."kmsconvt@tty6" = mkKmsconvt "tty6";
}
