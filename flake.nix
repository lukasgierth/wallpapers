{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs = { self, nixpkgs }:
    let
      lib = nixpkgs.lib;
      pkgs = nixpkgs.legacyPackages."x86_64-linux"; # nur für runCommand-cp; Inhalt systemunabhängig
      src = self.outPath;

      typeOf = v: if builtins.isString v then v else v.type; # Nix < 2.34 Shim
      isImg = n:
        lib.hasSuffix ".png" n || lib.hasSuffix ".jpg" n || lib.hasSuffix ".jpeg" n;

      namesOfType = dir: kind: lib.attrNames (
        lib.filterAttrs (_n: t: typeOf t == kind) (builtins.readDir dir)
      );

      # Sammlung (genau 1 Ebene) -> [ Bilddateien ]; leere Ordner fallen raus
      images = lib.filterAttrs (_c: fs: fs != [ ])
        (lib.genAttrs (namesOfType src "directory")
          (c: lib.filter isImg (namesOfType (src + "/${c}") "regular")));

      # "<Sammlung>/<Datei>"
      names = lib.concatMap (c: map (f: "${c}/${f}") images.${c}) (lib.attrNames images);

      parse = n:
        let p = lib.splitString "/" n; in
        { collection = builtins.head p; file = lib.concatStringsSep "/" (builtins.tail p); };
      extOf = f: builtins.elemAt (builtins.match ".*(\\.(png|jpg|jpeg))" f) 0;
      stemOf = f: lib.removeSuffix (extOf f) f;
      idOf = e: "${e.collection}-${stemOf e.file}";
      # Store-Namen dürfen nur [A-Za-z0-9._+-] enthalten
      safeName = s: builtins.concatStringsSep "" (
        builtins.filter (c: builtins.match "[A-Za-z0-9._+-]" c != null) (lib.stringToCharacters s)
      );

      wallpapers = lib.mapAttrs (c: fs:
        lib.genAttrs fs (f:
          pkgs.runCommand "wallpaper-${safeName "${c}-${f}"}" { } ''
            cp "${src}/${c}/${f}" "$out"
          '')) images;

      hmModules.wallpapers = { config, ... }:
        let
          cfg = config.wallpapers;
          homeDir = config.home.homeDirectory;
          chosen = map parse cfg.pick;
          fileAttrs = es: f: builtins.foldl' (acc: e: acc // f e) { } es;
        in
        {
          options.wallpapers.pick = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = names;
            description = "Zu installierende Wallpaper als \"<Sammlung>/<Datei>\" (Default: alle)";
          };

          config.home.file =
            # GNOME: rohe Bilder, Endung erhalten
            fileAttrs chosen (e: {
              "${homeDir}/.local/share/backgrounds/${e.collection}-${e.file}" = {
                source = wallpapers.${e.collection}.${e.file};
              };
            })
            # KDE: KWallet-Bild
            // fileAttrs chosen (e: {
              "${homeDir}/.local/share/wallpapers/${idOf e}/contents/image${extOf e.file}" = {
                source = wallpapers.${e.collection}.${e.file};
              };
            })
            # KDE: KWallet-Metadaten
            // fileAttrs chosen (e: {
              "${homeDir}/.local/share/wallpapers/${idOf e}/metadata.json" = {
                text = builtins.toJSON {
                  KPackageStructure = "Plasma/Wallpaper";
                  KPlugin = { Id = "wallpapers.${idOf e}"; Name = idOf e; };
                };
              };
            });
        };
    in
    {
      wallpapersTree = src;
      inherit wallpapers hmModules;
      wallpaperFiles = images;
      wallpaperNames = names;
    };
}
