#!/usr/bin/env bash
# Set these Environment variables
#  PROJ_DIR         : Project Directory. All tools will get install under PROJ_DIR/bin. (default: $HOME)
#  OM_PIVNET_TOKEN  : Pivotal Network Token (required) Its **NOT** ending with -r. It looks like DJHASLD7_HSDHA7 (default: none)
#  GITHUB_OPTIONS   : (Optional) Provide github userid and token for accessing API. (default: none)
#  TIMEZONE         : Timezone of the host (default:Asua/Singapore)
#  GIT_REPO         : Git repository to use for supporting items (default: yogendra/dotfiles)
#  DOTFILES_DIR     : Location to put dotfiles (default: $HOME/code/dotfiles)

# Run
# GIT_REPO=yogendra/dotfiles wget -qO- "https://raw.githubusercontent.com/${GIT_REPO}/master/scripts/jumpbox-init.sh?nocache"  | OM_PIVNET_TOKEN=DJHASLD7_HSDHA7 bash
# Or to put binaries at your preferred location (example: /usr/local/bin), provide PROD_DIR
# GIT_REPO=yogendra/dotfiles wget -qO- "https://raw.githubusercontent.com/${GIT_REPO}/master/scripts/jumpbox-init.sh?nocache" | OM_PIVNET_TOKEN=DJHASLD7_HSDHA7 PROJ_DIR=/usr/local bash


PROJ_DIR=${PROJ_DIR:-$HOME}
export PATH=${PATH}:${PROJ_DIR}/bin

OM_PIVNET_TOKEN=${OM_PIVNET_TOKEN}
[[ -z ${OM_PIVNET_TOKEN} ]] && echo "OM_PIVNET_TOKEN environment variable not set. See instructions at https://github.com/yogendra/dotfiles/blob/master/README-PCF-TOOLS.md" && exit 1
echo PROJ_DIR=${PROJ_DIR}
GITHUB_OPTIONS=${GITHUB_OPTIONS}
[[ -d ${PROJ_DIR}/bin ]]  || mkdir -p ${PROJ_DIR}/bin
GIT_REPO=${GIT_REPO:-yogendra/dotfiles}
DOTFILES_DIR=${DOTFILES_DIR:-$HOME/code/dotfiles}
TIMEZONE=${TIMEZONE:-Asia/Singapore}

sudo ln -fs /usr/share/zoneinfo/$TIMEZONE /etc/localtime

echo Install basic tools for the jumpbox
OS_TOOLS=(\
    apt-transport-https \
    build-essential \
    bzip2 \
    ca-certificates \
    coreutils \
    curl \
    dnsutils \
    file \
    git \
    gnupg2 \
    hping3 \
    httpie \
    iperf \
    iputils-ping \
    iputils-tracepath \
    jq \
    less \
    man \
    mosh \
    mtr \
    netcat \
    nmap \
    python2.7-minimal \
    python-pip \
    rclone \
    screen \
    shellcheck \
    software-properties-common \
    tcpdump \
    tmate \
    tmux \
    traceroute \
    unzip \
    vim \
    wamerican \
    wget \
    whois \
    )
sudo apt update && sudo apt install -qqy "${OS_TOOLS[@]}"
 
wget -qO- "https://raw.githubusercontent.com/${GIT_REPO}/master/scripts/dotfiles-init.sh?$RANDOM"| bash

VERSION_JSON=$(cat ${DOTFILES_DIR}/config/versions.json)
function asset_version {
  ASSET_NAME=$1
  echo ${VERSION_JSON} | jq -r ".[\"$ASSET_NAME\"]"
}

function github_asset {
    REPO=$1
    EXPRESSION="${2:-linux}"
    TAG="${3:-latest}"
    ASSET_URL="https://api.github.com/repos/${REPO}/releases/${TAG}"
    JQ_EXPR=".assets[] | select(.name|test(\"$EXPRESSION\"))|.browser_download_url"
    wget ${GITHUB_OPTIONS} -qO- ${ASSET_URL} | jq -r "${JQ_EXPR}"
}
set -e

# Get updated url at https://github.com/cloudfoundry/bosh-cli/releases/latest
URL="$(github_asset cloudfoundry/bosh-cli linux-amd64)"
echo Downloading: bosh from ${URL}
wget -q ${URL} -O ${PROJ_DIR}/bin/bosh
chmod a+x ${PROJ_DIR}/bin/bosh

# Get updated url at https://www.terraform.io/downloads.html
VERSION=$(asset_version terraform)
URL="https://releases.hashicorp.com/terraform/${VERSION}/terraform_${VERSION}_linux_amd64.zip"
echo Downloading: terraform from ${URL}
wget -q ${URL} -O /tmp/terraform.zip
gunzip -S .zip /tmp/terraform.zip
mv /tmp/terraform ${PROJ_DIR}/bin/terraform
chmod a+x ${PROJ_DIR}/bin/terraform

# Get updated url at https://github.com/cloudfoundry/bosh-bootloader/releases/latest
URL="$(github_asset cloudfoundry/bosh-bootloader linux_x86-64)"
echo Downloading: bbl from ${URL}
wget -q ${URL} -O ${PROJ_DIR}/bin/bbl
chmod a+x ${PROJ_DIR}/bin/bbl


# Get updated url at https://github.com/concourse/concourse/releases/latest
URL="$(github_asset concourse/concourse fly.\*linux-amd64.tgz\$)"
echo Downloading: fly from ${URL}
wget -q ${URL} -O- | tar -C ${PROJ_DIR}/bin -zx fly
chmod a+x ${PROJ_DIR}/bin/fly

# Get updated url at https://github.com/pivotal-cf/om/releases/latest
URL="$(github_asset pivotal-cf/om om-linux.\*tar.gz\$)"
echo Downloading: om from ${URL}
wget -q ${URL} -O- | tar -C ${PROJ_DIR}/bin -zx om
chmod a+x ${PROJ_DIR}/bin/om

# Get updated url at https://github.com/cloudfoundry-incubator/bosh-backup-and-restore/releases/latest
URL="$(github_asset cloudfoundry-incubator/bosh-backup-and-restore bbr-.\*-linux-amd64\$)"
echo Downloading: bbr from ${URL}
wget -q ${URL} -O ${PROJ_DIR}/bin/bbr
chmod a+x ${PROJ_DIR}/bin/bbr

# Always updated version :D
# Get updated url at https://github.com/cloudfoundry/cli/releases/latest
VERSION=$(asset_version cf)
URL="https://packages.cloudfoundry.org/stable?release=linux64-binary&version=${VERSION}&source=github-rel"
echo Downloading: cf from ${URL}
wget -q ${URL}  -O- | tar -C ${PROJ_DIR}/bin -zx cf
chmod a+x ${PROJ_DIR}/bin/cf

# Get updated url at https://github.com/cloudfoundry-incubator/credhub-cli/releases/latest
URL="$(github_asset cloudfoundry-incubator/credhub-cli credhub-linux-.\*.tgz\$)"
echo Downloading: credhub from ${URL}
wget -q ${URL} -O- | tar -C ${PROJ_DIR}/bin -xz  ./credhub
chmod a+x ${PROJ_DIR}/bin/credhub


# Always updated version :D
# Get updated url at https://storage.googleapis.com/kubernetes-release/release/stable.txt
URL="https://storage.googleapis.com/kubernetes-release/release/$(wget -q -O - https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl"
echo Downloading: kubectl from ${URL}
wget -q ${URL} -O ${PROJ_DIR}/bin/kubectl
chmod a+x ${PROJ_DIR}/bin/kubectl

# Get updated url at https://github.com/buildpacks/pack/releases/latest
URL="$(github_asset  buildpacks/pack pack-v.\*-linux.tgz\$)"
echo Downloading: pack from ${URL}
wget -q ${URL} -O- | tar -C ${PROJ_DIR}/bin -zx pack
chmod a+x ${PROJ_DIR}/bin/pack


# Get updated url at "https://github.com/pivotal-cf/texplate/releases/latest
URL="$(github_asset  pivotal-cf/texplate linux_amd64)"
echo Downloading: texplate from ${URL}
wget -q ${URL} -O ${PROJ_DIR}/bin/texplate
chmod a+x ${PROJ_DIR}/bin/texplate

# Get updated url at https://download.docker.com/linux/static/stable/x86_64/
VERSION=$(asset_version docker)
URL="https://download.docker.com/linux/static/stable/x86_64/docker-${VERSION}.tgz"
echo Downloading: docker from ${URL}
wget -q ${URL} -O- | tar -C /tmp -xz  docker/docker
mv /tmp/docker/docker ${PROJ_DIR}/bin/docker
chmod a+x ${PROJ_DIR}/bin/docker
rm -rf /tmp/docker

# Get updated url at https://github.com/docker/machine/releases/latest
URL="$(github_asset docker/machine $(uname -s)-$(uname -m))"
echo Downloading: docker-machine from ${URL}
wget -q ${URL}  -O ${PROJ_DIR}/bin/docker-machine
chmod a+x ${PROJ_DIR}/bin/docker-machine

# Get updated url at https://github.com/docker/compose/releases/latest
URL="$(github_asset docker/compose $(uname -s)-$(uname -m)\$)"
echo Downloading: docker-compose from ${URL}
wget -q ${URL} -O ${PROJ_DIR}/bin/docker-compose
chmod a+x ${PROJ_DIR}/bin/docker-compose

# Get updated url at https://github.com/projectriff/cli/releases/latest
VERSION=$(asset_version riff)
URL="$(github_asset projectriff/cli  linux-amd64 tags/${VERSION})"
echo Downloading: riff from ${URL}
wget -q ${URL} -O- | tar -C ${PROJ_DIR}/bin -xz ./riff
chmod a+x ${PROJ_DIR}/bin/riff

# Get updated url at https://github.com/cloudfoundry-incubator/uaa-cli/releases/latest
URL="$(github_asset cloudfoundry-incubator/uaa-cli linux-amd64)"
echo Downloading: uaa from ${URL}
wget -q ${URL} -O ${PROJ_DIR}/bin/uaa
chmod a+x ${PROJ_DIR}/bin/uaa


# Get updated url at https://github.com/pivotal-cf/pivnet-cli/releases/latest
URL="$(github_asset pivotal-cf/pivnet-cli linux-amd64)"
echo Downloading: pivnet from ${URL}
wget -q ${URL} -O ${PROJ_DIR}/bin/pivnet
chmod a+x ${PROJ_DIR}/bin/pivnet

# Get updated url at https://network.pivotal.io/products/pivotal-container-service/
VERSION=$(asset_version pivotal-container-service)
echo PivNet Download: PKS client ${VERSION}
om download-product -t "${OM_PIVNET_TOKEN}" -o /tmp -v "${VERSION}"  -p pivotal-container-service --pivnet-file-glob='pks-linux-amd64-*'
mv /tmp/pks-linux-amd64-* ${PROJ_DIR}/bin/pks
chmod a+x ${PROJ_DIR}/bin/pks

# Get updated url at https://network.pivotal.io/products/pivotal-function-service/
VERSION="$(asset_version pivotal-function-service)"
echo PivNet Download: PFS client ${VERSION}
om download-product -t "${OM_PIVNET_TOKEN}" -o /tmp -v "${VERSION}"  -p pivotal-function-service --pivnet-file-glob='pfs-cli-linux-amd64-*'
mv /tmp/pfs-cli-linux-amd64-* ${PROJ_DIR}/bin/pfs
chmod a+x ${PROJ_DIR}/bin/pfs

om download-product -t "${OM_PIVNET_TOKEN}" -o /tmp -v "${VERSION}" -p pivotal-function-service --pivnet-file-glob='duffle-linux-*'
mv /tmp/duffle-linux-* ${PROJ_DIR}/bin/duffle
chmod a+x ${PROJ_DIR}/bin/duffle

# Download build service client
VERSION="$(asset_version build-service)"
echo PivNet Download: Pivotal Build Service client ${VERSION}
om download-product -t "${OM_PIVNET_TOKEN}" -o /tmp -v "${VERSION}"  -p build-service --pivnet-file-glob="pb-${VERSION}-linux"
mv /tmp/pb-${VERSION}-linux ${PROJ_DIR}/bin/pb
chmod a+x ${PROJ_DIR}/bin/pb

om download-product -t "${OM_PIVNET_TOKEN}" -o /tmp -v "${VERSION}"  -p build-service --pivnet-file-glob="duffle-${VERSION}-linux"
mv /tmp/duffle-${VERSION}-linux ${PROJ_DIR}/bin/pb-duffle
chmod a+x ${PROJ_DIR}/bin/pb-duffle

# Get updated url at https://github.com/projectriff/riff/releases/latest
VERSION=$(asset_version riff)
URL="$(github_asset projectriff/cli  linux-amd64 tags/${VERSION})"
echo Downloading: riff from ${URL} ${VERSION}
wget -q ${URL} -O- | tar -C ${PROJ_DIR}/bin -xz ./riff
chmod a+x ${PROJ_DIR}/bin/riff

# Get updated url at https://github.com/sharkdp/bat/releases/latest
VERSION=$(asset_version bat)
URL="$(github_asset  sharkdp/bat x86_64-unknown-linux-gnu tags/${VERSION})"
echo Downloading: bat from ${URL}
wget -q  ${URL} -O- | tar -C /tmp -xz bat-${VERSION}-x86_64-unknown-linux-gnu/bat
mv /tmp/bat-${VERSION}-x86_64-unknown-linux-gnu/bat ${PROJ_DIR}/bin/bat
chmod a+x  ${PROJ_DIR}/bin/bat
rm -rf /tmp/bat-${VERSION}-x86_64-unknown-linux-gnu


# Get updated url at https://github.com/direnv/direnv/releases/latest
URL="$(github_asset direnv/direnv linux-amd64)"
echo Downloading: direnv from ${URL}
wget -q  ${URL} -O ${PROJ_DIR}/bin/direnv
chmod a+x ${PROJ_DIR}/bin/direnv

# Get updated url at https://network.pivotal.io/products/p-scheduler
VERSION=$(asset_version p-scheduler)
echo PivNet Download: Scheduler CF CLI Plugin ${VERSION}
om download-product -t "${OM_PIVNET_TOKEN}" -o /tmp -v "${VERSION}" -p p-scheduler --pivnet-file-glob=scheduler-for-pcf-cliplugin-linux64-binary-\*
cf install-plugin -f /tmp/scheduler-for-pcf-cliplugin-linux64-binary-*
rm /tmp/scheduler-for-pcf-cliplugin-linux64-binary-*

# Get updated url at https://network.pivotal.io/products/pcf-app-autoscaler
VERSION=$(asset_version pcf-app-autoscaler)
echo PivNet Download: App Autoscaler CF CLI Plugin ${VERSION}
om download-product -t "${OM_PIVNET_TOKEN}" -o /tmp -v "${VERSION}"  -p pcf-app-autoscaler --pivnet-file-glob=autoscaler-for-pcf-cliplugin-linux64-binary-\*
cf install-plugin -f /tmp/autoscaler-for-pcf-cliplugin-linux64-binary-*
rm /tmp/autoscaler-for-pcf-cliplugin-linux64-binary-*

# Get updated url at https://network.pivotal.io/products/p-event-alerts
VERSION=$(asset_version p-event-alerts)
echo PivNet Download: Event Alerts CF CLI Plugin ${VERSION}
om download-product -t "${OM_PIVNET_TOKEN}" -o /tmp -v "${VERSION}"  -p p-event-alerts --pivnet-file-glob=pcf-event-alerts-cli-plugin-linux64-binary-\*
cf install-plugin -f /tmp/pcf-event-alerts-cli-plugin-linux64-binary-*
rm /tmp/pcf-event-alerts-cli-plugin-linux64-binary-*

echo Installing Keybase cli
wget -q https://prerelease.keybase.io/keybase_amd64.deb -O /tmp/keybase_amd64.deb 
sudo apt install -qqy /tmp/keybase_amd64.deb
rm /tmp/keybase_amd64.deb 
run_keybase

echo Install google-cloud-sdk
# Add the Cloud SDK distribution URI as a package source
echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] http://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list

# Import the Google Cloud Platform public key
wget -qO- https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -

# Update the package list and install the Cloud SDK
sudo apt update
sudo apt -qqy install google-cloud-sdk


echo Install aws client
wget -q "https://d1vvhvl2y92vvt.cloudfront.net/awscli-exe-linux-x86_64.zip" -O "/tmp/awscliv2.zip"
unzip /tmp/awscliv2.zip -d $PROJ_DIR
rm -f /tmp/awscliv2.zip
sudo $PROJ_DIR/aws/install
rm -rf $PROJ_DIR/aws

echo Install  Azure client
wget -qO- https://aka.ms/InstallAzureCLIDeb | sudo bash


echo Created workspace directory
mkdir -p $PROJ_DIR/workspace/deployments
mkdir -p $PROJ_DIR/workspace/tiles


echo <<EOF
Create your SSH keys
===============================================================================
[[ ! -f ${HOME}/.ssh/id_rsa ]] && \
  ssh-keygen  -q -t rsa -N "" -f ${HOME}/.ssh/id_rsa && \
  cat ${HOME}/.ssh/id_rsa.pub >> ${HOME}/.ssh/authorized_keys

[[ ! -f ${HOME}/.ssh/id_dsa ]] && \
  ssh-keygen  -q -t dsa -N "" -f ${HOME}/.ssh/id_dsa && \
  cat ${HOME}/.ssh/id_dsa.pub  >> ${HOME}/.ssh/authorized_keys

EOF

echo Done
