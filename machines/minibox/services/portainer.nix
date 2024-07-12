{ pkgs, config, ... }:

{
  virtualisation.oci-containers.containers.portainer = {
    image = "portainer-ce";
    imageFile = pkgs.dockerTools.pullImage {
      imageName = "portainer/portainer-ce";
      imageDigest =
        "sha256:4a1ceadd7f7898d9190ee0a6d22234c4323aefd80e796e84f5e57127f74370f1";
      finalImageName = "portainer-ce";
      sha256 = "sha256-1bmJYwNs4NM/JoO7eWRtEwgzgdz9h6h489a01NqwD3g=";
    };
    volumes =
      [ "/var/run/docker.sock:/var/run/docker.sock" "portainer_data:/data" ];
    ports = [ "127.0.0.1:9443:9443" ];
  };
}
