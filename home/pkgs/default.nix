{
  inputs,
  config,
  pkgs,
  chaotic,
  ...
}:
{
  home.packages = with pkgs; [

    proton-vpn
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
