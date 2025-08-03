{
  inputs,
  config,
  pkgs,
  chaotic,
  ...
}:
{
  home.packages = with pkgs; [

    protonvpn-gui
    #vscode
    # (vscode.overrideAttrs (oldAttrs: {
    #   postFixup =
    #     oldAttrs.postFixup or ""
    #     + ''
    #       wrapProgram $out/bin/code \
    #          --add-flags --ozone-platform=x11
    #     '';
    # }))
  ];
}
