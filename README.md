# 🦞 OpenClaw Helm Chart

Helm chart for deploying [OpenClaw](https://github.com/openclaw/openclaw), a personal AI assistant.

This chart uses [bjw-s app-template](https://github.com/bjw-s-labs/helm-charts/tree/main/charts/other/app-template) as a base, providing a flexible and well-maintained foundation for Kubernetes deployments. For OpenClaw configuration options, see the [OpenClaw documentation](https://docs.openclaw.ai/). OpenClaw is designed for single-instance deployments only—do **not** deploy multiple replicas.

For a detailed walkthrough, see the [blog post](https://serhanekici.com/openclaw-helm.html).

## Quick Start

Add the Helm repository:

```bash
helm repo add openclaw https://serhanekicii.github.io/openclaw-helm
helm repo update
```

Install the chart:

```bash
helm install openclaw openclaw/openclaw -f values.yaml
```

## Browser Automation

The chart includes a headless Chromium sidecar for browser automation tasks. The agent connects via Chrome DevTools Protocol (CDP):

```yaml
app-template:
  configMaps:
    config:
      data:
        openclaw.json: |
          {
            "browser": {
              "enabled": true,
              "defaultProfile": "openclaw",
              "profiles": {
                "openclaw": {
                  "cdpUrl": "http://localhost:9222"
                }
              }
            }
          }
```

The Chromium container runs in the same pod, accessible on port 9222.

## Skills and Runtime Dependencies

OpenClaw supports skills from [ClawHub](https://clawhub.ai). The `init-skills` container provides a way to declaratively add skills and their runtime dependencies.

Example: Installing a Python-based skill with `uv`:

```yaml
app-template:
  controllers:
    main:
      initContainers:
        init-skills:
          command:
            - sh
            - -c
            - |
              # Install uv for Python-based skills
              mkdir -p /home/node/.openclaw/bin
              curl -LsSf https://astral.sh/uv/install.sh | env UV_INSTALL_DIR=/home/node/.openclaw/bin sh

              # Install skills from ClawHub
              cd /home/node/.openclaw/workspace
              mkdir -p skills
              npx -y clawhub install miniflux --no-input
      containers:
        main:
          env:
            PATH: /home/node/.openclaw/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
```

Configure skills in `openclaw.json` inside values.yaml:

```json
"skills": {
  "entries": {
    "miniflux": {
      "enabled": true,
      "env": {
        "MINIFLUX_URL": "${MINIFLUX_URL}",
        "MINIFLUX_API_KEY": "${MINIFLUX_API_KEY}"
      }
    }
  }
}
```

Browse available skills at https://www.clawhub.com/.

## Environment Secrets

API keys and sensitive values should be passed via a Kubernetes secret:

```yaml
app-template:
  controllers:
    main:
      containers:
        main:
          envFrom:
            - secretRef:
                name: openclaw-env-secret
```

Reference secrets in `openclaw.json` using `${ENV_VAR}` substitution:

```json
{
  "channels": {
    "telegram": {
      "botToken": "${TELEGRAM_BOT_TOKEN}"
    }
  }
}
```

## Skills Management

OpenClaw supports [ClawHub](https://clawhub.com) skills for extending agent capabilities. The chart includes an `init-skills` init container enabled by default for declarative skill management.

By default, the [hacker-news](https://clawhub.com/hacker-news) skill is installed.

### Customizing Skills

Edit the skill list in the `init-skills` container:

```yaml
app-template:
  controllers:
    main:
      initContainers:
        init-skills:
          # ... (uncomment from values.yaml)
```

### Runtime Dependencies

Some skills require additional runtimes (Python, Go, etc.). Install them in the `init-skills` container:

```yaml
# Example: Install uv for Python-based skills
mkdir -p /home/node/.openclaw/bin
curl -LsSf https://astral.sh/uv/install.sh | env UV_INSTALL_DIR=/home/node/.openclaw/bin sh
```

Then add the path to the main container's environment:

```yaml
env:
  PATH: /home/node/.openclaw/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
```

### Internal CA Trust

For skills that make HTTPS requests to internal services with private CAs, mount a CA bundle:

```yaml
persistence:
  ca-bundle:
    enabled: true
    type: configMap
    name: ca-bundle  # From trust-manager or similar
    advancedMounts:
      main:
        main:
          - path: /etc/ssl/certs/ca-bundle.crt
            subPath: ca-bundle.crt
            readOnly: true

env:
  REQUESTS_CA_BUNDLE: /etc/ssl/certs/ca-bundle.crt
```

## Browser Automation

A Chromium sidecar container is included by default for browser automation and web scraping. It exposes Chrome DevTools Protocol (CDP) on `localhost:9222`, which OpenClaw uses for browser-based skills.

The browser configuration in `openclaw.json`:

```json5
"browser": {
  "enabled": true,
  "defaultProfile": "default",
  "profiles": {
    "default": {
      "cdpUrl": "http://localhost:9222",
      "color": "#4285F4"
    }
  }
}
```

## Development

### Linting

```bash
helm lint charts/openclaw
```

### Template Validation

```bash
helm dependency update charts/openclaw
helm template test charts/openclaw
```

## License

MIT
