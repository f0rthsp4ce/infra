{ ... }:

{
  services.cron = {
    enable = true;
    systemCronJobs = [
      # Every minute, ping the uptime monitor
      # I know that here is exposed the API key, but it's not a big deal
      "* * * * *      root    curl https://status.f0rth.space/api/push/QaxImLRV0X?status=up&msg=OK&ping="
    ];
  };
}
