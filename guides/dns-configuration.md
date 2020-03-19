# DNS Configurations

### Option 1 : Google Cloud DNS

1.  Go to `terraforming-$$$` directory

1.  Set GCP_DNS_ZONE_NAME environement variable

    ```bash
    export GCP_DNS_ZONE_NAME=runs-on-cf-zone
    ```

1.  Set PCF_DOMAIN environment variable

    ```bash
    export PCF_DOMAIN=$(terraform output ops_manager_dns | sed 's/^pcf.//')
    ```

1.  Configure parent hosted zone to point to new subdomain zone

    ```bash
    gcloud dns record-sets transaction start --zone=$GCP_DNS_ZONE_NAME
    gcloud dns record-sets transaction add $(terraform output env_dns_zone_name_servers | sed 's/,$//;s/\.$/$/;s/$/./' | tr "\n" " ") --name=${PCF_DOMAIN}. --ttl=300 --type=NS --zone=$
    gcloud dns record-sets transaction execute --zone=$GCP_DNS_ZONE_NAME
    ```

### AWS Route 53

_**WIP**_

### Azure

_**WIP**_
