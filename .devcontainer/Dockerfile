# For details, see https://github.com/devcontainers/images/tree/main/src/ruby
FROM mcr.microsoft.com/devcontainers/ruby:1-3.2-bullseye

# Install Rails
# RUN gem install rails webdrivers

# Default value to allow debug server to serve content over GitHub Codespace's port forwarding service
# The value is a comma-separated list of allowed domains
ENV RAILS_DEVELOPMENT_HOSTS=".githubpreview.dev,.preview.app.github.dev,.app.github.dev"

ARG NODE_VERSION="16"
RUN su vscode -c "source /usr/local/share/nvm/nvm.sh && nvm install ${NODE_VERSION} 2>&1"

RUN wget https://www.deb-multimedia.org/pool/main/d/deb-multimedia-keyring/deb-multimedia-keyring_2016.8.1_all.deb && \
    dpkg -i deb-multimedia-keyring_2016.8.1_all.deb && \
    rm deb-multimedia-keyring_2016.8.1_all.deb && \
    add-apt-repository http://www.deb-multimedia.org

RUN apt-get update && \
    export DEBIAN_FRONTEND=noninteractive && \
    apt-get -y install --no-install-recommends libicu-dev  \
        libidn11-dev \
        ffmpeg \
        imagemagick-7 \
        libpam-dev

RUN gem install foreman

RUN su vscode -c "source /usr/local/share/nvm/nvm.sh && npm install -g yarn" 2>&1

COPY welcome-message.txt /usr/local/etc/vscode-dev-containers/first-run-notice.txt
