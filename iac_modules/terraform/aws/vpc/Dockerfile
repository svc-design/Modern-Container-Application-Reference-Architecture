FROM hashicorp/terraform:1.2.1 
LABEL maintainer="Haitao Pan <xz@onwalk.net>"

ARG GLIBC_VERSION=2.34-r0
ARG AWSCLI_VERSION=2.6.1

RUN apk add --update --no-cache bash wget make curl jq py3-pip unzip zip && mkdir -pv /root/.terraform.d/plugin-cache && pip3 install jinja2 hvac python-hcl2
RUN wget https://mirrors.onwalk.net/tools/linux-amd64/gauth.tar.gz && tar -xvpf gauth.tar.gz -C /usr/bin/ && chmod 755 /usr/bin/gauth
RUN wget https://mirrors.onwalk.net/tools/linux-amd64/gitleaks_8.8.5_linux_x64.tar.gz && tar -xvpf gitleaks_8.8.5_linux_x64.tar.gz && cp gitleaks /usr/bin/ && chmod 755 /usr/bin/gitleaks

# install glibc compatibility for alpine
RUN apk --no-cache add \
        binutils \
        curl \
    && curl -sL https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub -o /etc/apk/keys/sgerrand.rsa.pub \
    && curl -sLO https://github.com/sgerrand/alpine-pkg-glibc/releases/download/${GLIBC_VERSION}/glibc-${GLIBC_VERSION}.apk \
    && curl -sLO https://github.com/sgerrand/alpine-pkg-glibc/releases/download/${GLIBC_VERSION}/glibc-bin-${GLIBC_VERSION}.apk \
    && curl -sLO https://github.com/sgerrand/alpine-pkg-glibc/releases/download/${GLIBC_VERSION}/glibc-i18n-${GLIBC_VERSION}.apk \
    && apk add --no-cache \
        glibc-${GLIBC_VERSION}.apk \
        glibc-bin-${GLIBC_VERSION}.apk \
        glibc-i18n-${GLIBC_VERSION}.apk \
    && /usr/glibc-compat/bin/localedef -i en_US -f UTF-8 en_US.UTF-8 \
    && curl -sL https://awscli.amazonaws.com/awscli-exe-linux-x86_64-${AWSCLI_VERSION}.zip -o awscliv2.zip \
    && unzip awscliv2.zip \
    && aws/install \
    && rm -rf \
        awscliv2.zip \
        aws \
        /usr/local/aws-cli/v2/current/dist/aws_completer \
        /usr/local/aws-cli/v2/current/dist/awscli/data/ac.index \
        /usr/local/aws-cli/v2/current/dist/awscli/examples \
        glibc-*.apk \
    && find /usr/local/aws-cli/v2/current/dist/awscli/botocore/data -name examples-1.json -delete \
    && apk --no-cache del \
        binutils \
        curl \
    && rm -rf /var/cache/apk/*

COPY .terraformrc /root/
COPY ./ .
RUN terraform init

ENTRYPOINT ["terraform"]
