FROM debian:trixie-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get upgrade -y && apt-get install -y --no-install-recommends \
        bash-completion \
        build-essential \
        ca-certificates \
        curl \
        fd-find \
        git \
        jq \
        less \
        locales \
        nano \
        openssh-client \
        pkg-config \
        procps \
        python3 \
        python3-pip \
        python3-venv \
        ripgrep \
        sudo \
        tmux \
        tree \
        unzip \
        vim-tiny \
        wget \
        xz-utils \
        zip \
        zsh \
    && rm -rf /var/lib/apt/lists/*

# Node.js 24 (latest 24.x official binary, checksum-verified) into /usr/local
ARG NODE_MAJOR=24
RUN set -eux; \
    case "$(dpkg --print-architecture)" in \
        amd64) node_arch=x64 ;; \
        arm64) node_arch=arm64 ;; \
        *) echo "unsupported architecture" >&2; exit 1 ;; \
    esac; \
    base="https://nodejs.org/dist/latest-v${NODE_MAJOR}.x"; \
    cd /tmp; \
    curl -fsSLO "$base/SHASUMS256.txt"; \
    file="$(grep -o "node-v[0-9.]*-linux-${node_arch}\.tar\.xz" SHASUMS256.txt | head -n1)"; \
    curl -fsSLO "$base/$file"; \
    grep " ${file}\$" SHASUMS256.txt | sha256sum -c -; \
    tar -xJf "$file" -C /usr/local --strip-components=1 --no-same-owner \
        --exclude='*.md' --exclude=LICENSE; \
    rm -f "$file" SHASUMS256.txt; \
    node --version; npm --version

# Install agents globally (outside /home so the home mount does not hide them)
RUN npm install -g --allow-scripts=@anthropic-ai/claude-code,opencode-ai @anthropic-ai/claude-code opencode-ai \
    && npm cache clean --force

# oh-my-zsh + spaceship prompt, installed system-wide (the home mount would hide a per-user install)
RUN git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git /opt/oh-my-zsh \
    && git clone --depth=1 https://github.com/spaceship-prompt/spaceship-prompt.git /opt/oh-my-zsh/custom/themes/spaceship-prompt \
    && ln -s /opt/oh-my-zsh/custom/themes/spaceship-prompt/spaceship.zsh-theme /opt/oh-my-zsh/custom/themes/spaceship.zsh-theme \
    && rm -rf /opt/oh-my-zsh/.git /opt/oh-my-zsh/custom/themes/spaceship-prompt/.git
COPY zshrc /etc/zsh/zshrc
# Create an empty ~/.zshrc on first run so zsh skips its new-user setup wizard
RUN printf '%s\n' '[[ -o interactive && ! -e "$HOME/.zshrc" ]] && : > "$HOME/.zshrc" 2>/dev/null' >> /etc/zsh/zshenv

# Non-root user; UID/GID can be overridden at build time to match the host user
ARG USER_UID=1000
ARG USER_GID=1000
RUN (getent group ${USER_GID} && groupmod -n agent $(getent group ${USER_GID} | cut -d: -f1) || groupadd -g ${USER_GID} agent) \
    && (id -u ${USER_UID} >/dev/null 2>&1 && userdel -r $(id -nu ${USER_UID}) || true) \
    && useradd -m -u ${USER_UID} -g ${USER_GID} -s /usr/bin/zsh agent

USER agent
ENV HOME=/home/agent
WORKDIR /workspace

# Mounted at runtime:
#   ./home       -> /home/agent
#   $WORKSPACE   -> /workspace
VOLUME ["/home/agent", "/workspace"]

ENV SHELL=/usr/bin/zsh
CMD ["zsh"]
