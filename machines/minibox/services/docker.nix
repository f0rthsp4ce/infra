{ ... }:

{
  virtualisation.docker.enable = true;
  services.proxmox-backup.jobs.daily.paths = [{
    name = "docker-volumes";
    path = "/var/lib/docker/volumes";
  }];
}
