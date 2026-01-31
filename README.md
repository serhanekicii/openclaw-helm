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
