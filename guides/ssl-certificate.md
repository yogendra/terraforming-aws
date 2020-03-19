# SSL Certificate Setup

## Option 1: Let's Encypt

You can use acme_cert_domain module to generate cert. Here are raw commands:

1.  Go to the checkedout and switch directory for this repo. if you have not done so already

    ```bash
     git clone https://github.com/yogendra/terraforming-aws.git demo
     cd demo
    ```

1.  Set environment for terraform to run

    ```bash
    source .envrc
    ```

1.  Create local config directory

    ```bash
    mkdir -p $PROJECT_DIR/.config
    ```

1.  Set `DOMAIN_SUFFIX` environment variable to generate common name and san on the certificates

    ```bash
    export DOMAIN_SUFFIX=demo.runs-on.cf
    ```

1.  Set AWS enviroment details

    ```bash
    export TF_VAR_access_key=AKsdasdas
    export TF_VAR_secret_key=asdasdasdasd
    export TF_VAR_aws_hosted_zone=ZCSDBFJK123
    ```

1.  Go to `acme_cert` module

    ```bash
    cd modules/acme_cert
    ```

1.  Plan and execute terraform

    ```bash

    D=$DOMAIN_SUFFIX terraform plan \
        -out create.tfplan \
        -var "registration_email=YOUR_EMAIL" \
        -var "root_domain=$D" \
        -var "san=[\"*.$D\",\"*.pks.$D\",\"*.harbor.$D\",\"*.apps.$D\",\"*.system.$D\",\"*.devops.$D\",\"*.devops-k8s.$D\",\"*.apps-k8s.$D\",\"*.system-k8s.$D\"]"

    terraform apply create.tfplan

    ```

1.  Extract generated certs into config directory

    ```bash
    terraform output cert_pem > $PROJECT_DIR/.config/ssl-certificate.pem
    terraform output issuer_pem > $PROJECT_DIR/.config/ca_cert.pem
    terraform output private_key_pem > $PROJECT_DIR/.config/ssl-private-key.pem
    ```

1.  Go back to project root

    ```bash
    cd $PROJECT_DIR
    ```

## Option 2: Create Self signed certificate using mkcert

1.  Go to the checkedout and switch directory for this repo. if you have not done so already

    ```bash
     git clone https://github.com/yogendra/terraforming-aws.git demo
     cd demo
    ```

1.  Set environment for terraform to run

    ```bash
    source .envrc
    ```

1.  Create local config directory

    ```bash
    mkdir -p $PROJECT_DIR/.config
    ```

1.  Set `DOMAIN_SUFFIX` environment variable to generate common name and san on the certificates

    ```bash
    export DOMAIN_SUFFIX=demo.runs-on.cf

    ```

1.  Generate certificate
    ```bash
    D=$DOMAIN_SUFFIX mkcert \
          -cert-file $PROJECT_DIR/.config/ssl-certificate.pem \
          -key-file $PROJECT_DIR/.config/ssl-private-key.pem \
          $D \
          \*.$D \
          \*.pks.$D \
          \*.system.$D \
          \*.system-k8s.$D \
          \*.devops.$D \
          \*.devops-k8s.$D \
          \*.apps.$D \
          \*.apps-k8s.$D
      cp "`mkcert -CAROOT`/rootCA.pem" "$PROJECT_DIR/.config/ca_cert.pem"
    ```
