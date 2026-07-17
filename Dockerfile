FROM ubuntu:24.04

ARG TARGETARCH
ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    ca-certificates \
    curl \
    dnsutils \
    fontconfig \
    fonts-noto-cjk \
    git \
    jq \
    less \
    libfontconfig1 \
    libfreetype6-dev \
    libjpeg-dev \
    libldap2-dev \
    libpq-dev \
    libsasl2-dev \
    libssl-dev \
    libxml2-dev \
    libxslt1-dev \
    net-tools \
    npm \
    postgresql-client \
    procps \
    python3.12 \
    python3.12-dev \
    python3.12-venv \
    python3-pip \
    sudo \
    tmux \
    vim \
    zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    && npm install -g rtlcss \
    && rm -rf /var/lib/apt/lists/*

RUN apt-get update && apt-get install -y --no-install-recommends \
    libasound2t64 \
    libatk-bridge2.0-0t64 \
    libatk1.0-0t64 \
    libatspi2.0-0t64 \
    libcairo2 \
    libcups2t64 \
    libdbus-1-3 \
    libdrm2 \
    libgbm1 \
    libnspr4 \
    libnss3 \
    libpango-1.0-0 \
    libxcomposite1 \
    libxdamage1 \
    libxfixes3 \
    libxkbcommon0 \
    libxrandr2 \
    && rm -rf /var/lib/apt/lists/*

RUN WKHTML_ARCH=$([ "$TARGETARCH" = "arm64" ] && echo "arm64" || echo "amd64") \
    && curl -fsSL -o /tmp/wkhtmltox.deb \
       "https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6.1-3/wkhtmltox_0.12.6.1-3.jammy_${WKHTML_ARCH}.deb" \
    && apt-get update && apt-get install -y --no-install-recommends /tmp/wkhtmltox.deb \
    && rm -f /tmp/wkhtmltox.deb && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://astral.sh/uv/install.sh | env UV_INSTALL_DIR=/usr/local/bin sh

RUN npm install -g @anthropic-ai/claude-code \
    && npm install -g @modelcontextprotocol/server-sequential-thinking

RUN useradd -m -s /bin/bash claude \
    && echo "claude ALL=(ALL) NOPASSWD: /usr/local/bin/pkg-install" > /etc/sudoers.d/claude \
    && chmod 440 /etc/sudoers.d/claude

COPY scripts/pkg-install.sh /usr/local/bin/pkg-install
RUN chown root:root /usr/local/bin/pkg-install && chmod 755 /usr/local/bin/pkg-install

USER claude
WORKDIR /home/claude

RUN uv tool install serena-agent

RUN python3.12 -m venv /home/claude/odoo-venv

ENV PATH="/home/claude/odoo-venv/bin:/home/claude/.local/bin:${PATH}"
ENV VIRTUAL_ENV="/home/claude/odoo-venv"

RUN pip install --no-cache-dir \
    Babel \
    click-odoo \
    click-odoo-contrib \
    coverage \
    debugpy \
    decorator \
    docutils \
    gevent \
    greenlet \
    ipython \
    Jinja2 \
    libsass \
    lxml \
    MarkupSafe \
    num2words \
    ofxparse \
    passlib \
    Pillow \
    polib \
    psutil \
    psycopg2-binary \
    pydot \
    pylint \
    pylint-odoo \
    pyopenssl \
    PyPDF2 \
    python-dateutil \
    python-stdnum \
    pytz \
    qrcode \
    reportlab \
    requests \
    urllib3 \
    vobject \
    watchdog \
    Werkzeug \
    xlrd \
    xlsxwriter \
    zeep

USER root

COPY scripts/git-wrapper.sh /usr/local/bin/git-wrapper
RUN chmod +x /usr/local/bin/git-wrapper \
    && mkdir -p /usr/local/lib/git-bin \
    && cp /usr/bin/git /usr/local/lib/git-bin/git \
    && rm /usr/bin/git \
    && ln -s /usr/local/bin/git-wrapper /usr/bin/git

COPY config/managed-settings.json /etc/claude-code/managed-settings.json
RUN chown root:root /etc/claude-code/managed-settings.json \
    && chmod 444 /etc/claude-code/managed-settings.json

RUN mkdir -p /home/claude/.config/git-hooks
COPY scripts/pre-push /home/claude/.config/git-hooks/pre-push
RUN chmod +x /home/claude/.config/git-hooks/pre-push \
    && chown -R claude:claude /home/claude/.config/git-hooks

RUN chown root:root /home/claude/.config/git-hooks/pre-push \
    && chmod 444 /home/claude/.config/git-hooks/pre-push

USER claude

RUN /usr/local/lib/git-bin/git config --global core.hooksPath /home/claude/.config/git-hooks

RUN mkdir -p /home/claude/.claude
COPY --chown=claude:claude config/claude-settings.json /home/claude/.claude/settings.json

USER root
RUN mkdir -p /var/lib/odoo && chown claude:claude /var/lib/odoo
RUN mkdir -p /workspace && chown claude:claude /workspace

RUN mkdir -p /config
COPY config/CLAUDE.md /config/CLAUDE.md
COPY config/skills/ /config/skills/

RUN echo "alias claude='claude --dangerously-skip-permissions'" >> /home/claude/.bashrc

COPY scripts/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

USER root
WORKDIR /workspace

EXPOSE 8069 8072

ENTRYPOINT ["/entrypoint.sh"]
