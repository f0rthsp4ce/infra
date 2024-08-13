{ element-web-unwrapped, stdenv, gzip, brotli, jq, conf ? {
  default_server_config = {
    "m.homeserver".base_url = "https://matrix.f0rth.space";
    "m.homeserver".server_name = "f0rth.space";
    "m.identity_server".base_url = "https://disabled.f0rth.space";
  };
  integrations_ui_url = "https://disabled.f0rth.space/";
  integrations_rest_url = "https://disabled.f0rth.space/";
  integrations_widgets_urls = [ "https://disabled.f0rth.space/" ];
  jitsi.preferred_domain = "disabled.f0rth.space";
  element_call.url = "https://disabled.f0rth.space";
  map_style_url = "https://disabled.f0rth.space";
} }:

stdenv.mkDerivation {
  pname = "element-web-compressed";
  version = element-web-unwrapped.version;

  src = element-web-unwrapped;

  buildInputs = [ gzip brotli jq ];

  buildPhase = ''
    # add config
    rm config.json
    jq -s '.[0] * $conf' "${element-web-unwrapped}/config.json" --argjson "conf" '${
      builtins.toJSON conf
    }' > "config.json"

    # compress static
    find . -type f -print0 | xargs -0 -I{} -P $(nproc) \
      sh -c "gzip -c --best {} > {}.gz && brotli -c --best {} > {}.br"
  '';

  installPhase = ''
    cp -r . $out
  '';
}
