# Install PKS on AWS

## Pre-requisite

1.  AWS account with privileges as per [documentation][pcf-opsman-aws]
1.  Use an Ubuntu jumpbox initialize with [my script][pcf-jumpbox].

    - It will install all tools (git/curl/bosh/om/pivnet/etc)
    - All instruction should be run on this jumpbox

1.  Domain suffix for the platform
    Example: In this document domain suffix is `demo.runs-on.cf`, hence:
    PKS API : api.pks.demo.runs-on.cf

    | Cluster | K8s API Address            | Ingress Suffix         |
    | ------- | -------------------------- | ---------------------- |
    | Apps    | apps-k8s.demo.runs-on.cf   | apps.demo.runs-on.cf   |
    | Devops  | devops-k8s.demo.runs-on.cf | devops.demo.runs-on.cf |
    | System  | system-k8s.demo.runs-on.cf | system.demo.runs-on.cf |

1.  SSL certificates for the platform. Goto [Certificates Setup](ssl-certificate)

    - Certificate should be kept at `PROJECT_DIR/.config/ssl-certificate.pem`
    - Private key should be kept at `PROJECT_DIR/.config/ssl-private-key.pem`
    - CA certificate should be kept at `PROJECT_DIR/.config/ca_cert.pem`

## Install PKS on AWS

1.  Record Ops Manager password

    ```bash
    echo -n "Ops Manager Password: "; read -s OM_PASSWORD
    export OM_PASSWORD
    ```

1.  Configure PivNet Tokens. Get the values from [Tanzu Network - Edit Profile][tanzu-profile-edit-profile]

    ```bash
    echo -n "PivNet Legacy Token (ends w/o -r): "; read -s PIVNET_LEGACY_TOKEN
    echo -n "PivNet API Token (ends with -r): "; read -s PIVNET_API_TOKEN
    export PIVNET_API_TOKEN  \
        PIVNET_TOKEN=$PIVNET_TOKEN \
        OM_PIVNET_TOKEN=$PIVNET_LEGACY_TOKEN \
        PIVNET_LEGACY_TOKEN
    ```

1.  Log in to PivNet

    ```bash
    pivnet login --api-token="$PIVNET_API_TOKEN"
    ```

1.  Clone this repository into a project directory. Lets call it project root.

    ```bash
    git clone https://github.com/yogendra/terraforming-aws.git demo
    ```

1.  Go to the cloned directory

    ```bash
    cd demo
    ```

1.  Go to `terraformming-pks`

    ```bash
    cd terraforming-pks
    ```

1.  Prepare `terraform.tfvar` as below:

    ```yaml
    env_name = "demo"

    access_key = "YOUR-AWS-ACCESS-KEY"

    secret_key = "YOUR-AWS-SECRET-KEY"

    region = "us-east-1"

    availability_zones = ["us-east-1a"]

    # Goto https://network.pivotal.io/products/ops-manager
    # Download "Ops Manager YAML for AWS - ...."
    # Find the correct ami for your region
    ops_manager_ami = "ami-0aac5f23906ab0036"

    dns_suffix = "runs-on.cf"

    vpc_cidr = "10.0.0.0/16"

    use_route53 = true

    enable_harbor = true

    ssl_cert = <<EOF
    PUT YOUR CERTIFICATE HERE HERE
    On Mac Copy using : cat $PROJECT_DIR/.config/ssl-certificate.pem | pbcopy
    EOF

    ssl_private_key = <<EOF
    PUT YOUR PRIVATE KEY HERE
    On Mac Copy using : cat $PROJECT_DIR/.config/ssl-private-key.pem | pbcopy
    EOF

    tags = {
    "Environment"    = "Demo"
    }
    ```

1.  Initialize terraform

    ```bash
    terraform init
    ```

1.  Prepare plan

    ```bash
    terraform plan -out create.tfplan
    ```

1.  Apply plan

    ```bash
    terraform apply create.tfplan
    ```

1.  Update yout parent DNS zone

    1.  Terraform earlier step creates a new Hosted Zone

    1.  Nameservers of the hosted zone are under the `env_dns_zone_name_servers` key in terraform

        ```bash
        terraform output env_dns_zone_name_servers
        ```

    1.  Create a new `NS` record in the parent Hosted zone
        - Name: demo.runs-on.cf
        - Type: NS
        - Value: _Output from earlier step_
    1.  See [DNS Configuration](dns-configuration)

1.  Setup shell to connect to Ops Manager

    ```bash
    export PCF_DOMAIN=$(terraform output ops_manager_dns | sed 's/^pcf.//')
    export PCF_IAAS=aws
    export PCF_TILES_DIR=$PROJECT_DIR/tiles
    export OM_TARGET=$(terraform output ops_manager_dns)
    export OM_SKIP_SSL_VALIDATION=true
    export OM_USERNAME=admin
    export OM_DECRYPTION_PASSPHRASE=$OM_PASSWORD
    mkdir -p $PCF_TILES_DIR
    ```

1.  Goto project root

    ```bash
    cd ..
    ```

1.  Set `CA_CERT` environment variable

    ```bash
    export CA_CERT="$(cat $PROJECT_DIR/.config/ca_cert.pem)"
    ```

1.  Configure Director

    ```bash
    scripts/configure-director terraforming-pks $OM_PASSWORD
    ```

1.  Update Ops Manager SSL Certificate

    ```bash
    om update-ssl-certificate \
        --certificate-pem "$(< $PROJECT_DIR/.config/ssl-certificate.pem)" \
        --private-key-pem "$(< $PROJECT_DIR/.config/ssl-private-key.pem)"
    ```

1.  Create VM extension for pks

    ```bash
    om -k create-vm-extension -n pks-api-lb-security-groups \
        -cp '{ "security_groups": ["pks_api_lb_security_group"] }'
    ```

1.  Create VM extension for harbor

    ```bash
    om -k create-vm-extension -n harbor-lb-security-groups \
        -cp "{ \"security_groups\": [\"harbor_lb_security_group\"] }"
    ```

1.  Upload PKS

    ```bash
    scripts/om-install pivotal-container-service \*pivotal 1.6.1
    ```

1.  Configure PKS

    ```bash
    scripts/configure-product terraforming-pks pks $OM_PASSWORD
    ```

1.  Upload Harbor

    ```bash
    scripts/om-install harbor-container-registry \*pivotal 1.10.1
    ```

1.  Configure Harbor

    ```bash
    scripts/configure-product terraforming-pks harbor $OM_PASSWORD
    ```

1.  Apply Changes

    ```bash
    om apply-changes
    ```

1.  Configure local workspace

    ```bash
    scripts/configure-workspace terraforming-pks $OM_PASSWORD $PIVNET_API_TOKEN $PIVNET_LEGACY_TOKEN
    ```

[pcf-jumpbox]: https://github.com/yogendra/dotfiles/blob/master/scripts/pcf-jumpbox-init.sh
[pcf-opsman-aws]: https://docs.pivotal.io/platform/ops-manager/2-8/aws/prepare-env-terraform.html#prereqs
[tanzu-network-edit-profile]: https://network.pivotal.io/users/dashboard/edit-profile
