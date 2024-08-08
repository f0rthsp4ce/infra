import requests
import time
from CloudFlare import CloudFlare
from os import environ

# Your Cloudflare credentials and zone information
api_token = environ['CLOUDFLARE_API_TOKEN']
zone_id = environ['CLOUDFLARE_ZONE_ID']
dns_record_id = environ['CLOUDFLARE_DNS_RECORD_ID']
record_name = environ['CLOUDFLARE_RECORD_NAME']

# Initialize Cloudflare client
cf = CloudFlare(token=api_token)

def get_public_ip():
    """Fetches public IP address from eth0.me"""
    response = requests.get('https://eth0.me')
    return response.text.strip()

def update_dns_record(ip_address):
    """Updates the DNS A record on Cloudflare with the new IP address"""
    data = {
        'type': 'A',
        'name': record_name,
        'content': ip_address,
        'ttl': 120  # Time to live in seconds
    }
    response = cf.zones.dns_records.put(zone_id, dns_record_id, data=data)
    return response

def main():
    while True:
        try:
            current_ip = get_public_ip()
            update_response = update_dns_record(current_ip)
            print(f"DNS record updated with IP {current_ip}: {update_response}")
        except Exception as e:
            print(f"Failed to update DNS record: {e}")
        time.sleep(600)  # Sleep for 10 minutes

if __name__ == "__main__":
    main()
