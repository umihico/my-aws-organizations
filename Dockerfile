FROM amazonlinux:latest

# yum update & install
RUN yum update -y && \
  yum install -y \
  tar \
  wget \
  jq \
  which && \
  yum groupinstall "Development Tools" -y && \
  yum clean all

ARG TARGETARCH

# install aws cli v2
RUN if [ "$TARGETARCH" = "amd64" ]; then curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"; fi; \
  if [ "$TARGETARCH" = "arm64" ]; then curl "https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip" -o "awscliv2.zip"; fi; \
  unzip awscliv2.zip && \
  ./aws/install && \
  aws --version

# install terraform (armだとパッケージマネージャー経由でインストールできないっぽいので、直接バイナリをダウンロード)
RUN export TERRAFORM_VERSION=$(curl https://api.github.com/repos/hashicorp/terraform/releases/latest | jq '.name[1:]' -r) && \
  wget https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_${TARGETARCH}.zip -O terraform.zip && \
  unzip terraform.zip -d /tmp && \
  rm terraform.zip && \
  mv /tmp/terraform /usr/bin/terraform && \
  terraform --version

# install terragrunt
RUN wget $(curl -s https://api.github.com/repos/gruntwork-io/terragrunt/releases/latest | \
  jq -r --arg targetarch "$TARGETARCH" '.assets[] | select(.name == ("terragrunt_linux_" + $targetarch)) | .browser_download_url') -O /usr/local/bin/terragrunt && \
  chmod +x /usr/local/bin/terragrunt && \
  terragrunt --version

# install sops
RUN wget -L $(curl https://api.github.com/repos/mozilla/sops/releases/latest | \
  jq -r --arg targetarch "$TARGETARCH" '.assets[] | select(.name | endswith(".linux." + $targetarch)) | .browser_download_url') -O /usr/bin/sops && \
  chmod +x /usr/bin/sops && \
  sops --version

# install yq
RUN wget $(curl -s https://api.github.com/repos/mikefarah/yq/releases/latest | \
  jq -r --arg targetarch "$TARGETARCH" '.assets[] | select(.name == ("yq_linux_" + $targetarch)) | .browser_download_url') -O /usr/bin/yq && \
  chmod +x /usr/bin/yq && \
  yq --version

WORKDIR /app
