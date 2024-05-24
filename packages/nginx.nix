{ lib, nginxQuic, nginxModules }:

nginxQuic.override {
  modules =
    lib.unique (nginxQuic.modules ++ [ nginxModules.brotli nginxModules.zstd ]);
}
