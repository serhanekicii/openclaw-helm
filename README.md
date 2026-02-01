# 🦞 OpenClaw Helm Chart

Helm chart for deploying [OpenClaw](https://github.com/openclaw/openclaw), a personal AI assistant.

For a detailed walkthrough, see the [blog post](https://serhanekici.com/openclaw-helm.html).

## Usage

Add the Helm repository:

```bash
helm repo add openclaw https://serhanekicii.github.io/openclaw-helm
helm repo update
```

Install the chart:

```bash
helm install openclaw openclaw/openclaw -f values.yaml
```

## Chart Information

This chart uses [bjw-s app-template](https://github.com/bjw-s-labs/helm-charts/tree/main/charts/other/app-template) as a base, providing a flexible and well-maintained foundation for Kubernetes deployments.

The OpenClaw application config is defined in `app-template.configMaps.config.data` as JSON5. For configuration options, see the [OpenClaw documentation](https://docs.openclaw.ai/).

### Environment Secrets

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

## Architecture Constraints

OpenClaw is designed for single-instance deployments only and cannot scale horizontally.

- Do **not** deploy multiple replicas
- The chart enforces `replicas: 1` by default

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
