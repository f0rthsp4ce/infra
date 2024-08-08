from CloudFlare import CloudFlare
from librouteros import connect
from librouteros.exceptions import TrapError
from dataclasses import dataclass
from time import sleep
from os import environ


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
    except TrapError as e:
        print(f"Failed to connect to MikroTik: {e}")
        return []


def update_cloudflare_dns(devices: list[Device]):
    existing_records = cf.zones.dns_records.get(CLOUDFLARE_ZONE_ID, params={"per_page": 500})
    existing_hostnames = {rec["name"]: rec for rec in existing_records if rec["type"] == "A"}

    for device in devices:
        record_name = f"{device.name}.lo.f0rth.space"
        record_ip = device.address
        print(f"Processing {record_name}")

        if record_name in existing_hostnames:
            existing_record = existing_hostnames[record_name]
            if existing_record["content"] != record_ip:
                if not existing_record["comment"].startswith("@managed"):
                    print(f"Skipping DNS record {record_name}, reason: Not managed")
                    continue
                if existing_record["content"] == record_ip:
                    print(f"DNS record {record_name} not changed")
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
                print(f"Updated DNS record: {record_name} -> {record_ip}")
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
                print(f"Created DNS record: {record_name} -> {record_ip}")
            except Exception as e:
                print(f"Error: {e}")


def main():
    while True:
        try:
            devices = get_connected_devices()
            if devices:
                update_cloudflare_dns(devices)
            else:
                print("No devices found.")
        except Exception as e:
            print(f"Error: {e}")
        sleep(600)


if __name__ == "__main__":
    main()
