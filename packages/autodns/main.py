from CloudFlare import CloudFlare
from librouteros import connect
from librouteros.exceptions import TrapError
from dataclasses import dataclass
from time import sleep
from os import environ
from logging import basicConfig, getLogger

basicConfig(level=environ.get("LOG_LEVEL", "INFO"))
logger = getLogger(__name__)


@dataclass
class Device:
    name: str
    address: str


# MikroTik Router Configuration
MIKROTIK_HOST = environ["MIKROTIK_HOST"]
MIKROTIK_USERNAME = environ["MIKROTIK_USERNAME"]
MIKROTIK_PASSWORD = environ["MIKROTIK_PASSWORD"]

# Cloudflare Configuration
CLOUDFLARE_API_TOKEN = environ["CLOUDFLARE_API_TOKEN"]
CLOUDFLARE_ZONE_ID = environ["CLOUDFLARE_ZONE_ID"]

# Initialize Cloudflare client
cf = CloudFlare(token=CLOUDFLARE_API_TOKEN)


# Connect to MikroTik Router
def get_connected_devices() -> list[Device]:
    try:
        api = connect(username=MIKROTIK_USERNAME, password=MIKROTIK_PASSWORD, host=MIKROTIK_HOST)
        devices = []
        device_names = []
        for device in api.path("/ip/dhcp-server/lease"):
            if device.get("server") != "dhcp2_devices":
                continue
            if device.get("host-name") is None:
                continue
            if device.get("expires-after") is None:
                continue
            name = device["host-name"].lower().strip()
            if name in device_names:
                continue
            device_names.append(name)
            devices.append(Device(name=name, address=device["address"]))
        return devices
    except TrapError:
        logger.exception("Failed to connect to MikroTik")
        return []


def update_cloudflare_dns(devices: list[Device]):
    existing_records = cf.zones.dns_records.get(CLOUDFLARE_ZONE_ID, params={"per_page": 500})
    existing_hostnames = {rec["name"]: rec for rec in existing_records if rec["type"] == "A"}

    for device in devices:
        record_name = f"{device.name}.lo.f0rth.space"
        record_ip = device.address
        logger.debug(f"Processing {record_name}")

        if record_name in existing_hostnames:
            existing_record = existing_hostnames[record_name]
            if existing_record["content"] != record_ip:
                comment = existing_record.get("comment")
                if not isinstance(comment, str):
                    logger.debug(f"Skipping DNS record {record_name}, reason: No comment")
                    continue
                if not comment.startswith("@managed"):
                    logger.debug(f"Skipping DNS record {record_name}, reason: Not managed")
                    continue
                if existing_record["content"] == record_ip:
                    logger.debug(f"DNS record {record_name} not changed")
                # Update the record if the IP has changed
                cf.zones.dns_records.put(
                    CLOUDFLARE_ZONE_ID,
                    existing_record["id"],
                    data={
                        "type": "A",
                        "name": record_name,
                        "content": record_ip,
                        "ttl": 300,
                        "comment": "@managed by auto-update script",
                    },
                )
                logger.info(f"Updated DNS record: {record_name} -> {record_ip}")
        else:
            # Create a new record if it doesn't exist
            try:
                cf.zones.dns_records.post(
                    CLOUDFLARE_ZONE_ID,
                    data={
                        "type": "A",
                        "name": record_name,
                        "content": record_ip,
                        "ttl": 300,
                        "comment": "@managed by auto-update script",
                    },
                )
                logger.info(f"Created DNS record: {record_name} -> {record_ip}")
            except Exception:
                logger.exception(f"Failed to create DNS record: {record_name} -> {record_ip}")


def main():
    while True:
        try:
            devices = get_connected_devices()
            if devices:
                update_cloudflare_dns(devices)
            else:
                logger.warn("No devices found.")
        except Exception:
            logger.exception("An error occurred")
        sleep(600)


if __name__ == "__main__":
    main()
