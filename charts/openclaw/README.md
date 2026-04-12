# 🦞 OpenClaw Helm Chart

[![Artifact Hub](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/openclaw-helm)](https://artifacthub.io/packages/helm/openclaw-helm/openclaw)
[![Helm 3](https://img.shields.io/badge/Helm-3.0+-0f1689?logo=helm&logoColor=white)](https://helm.sh/)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-1.26+-326ce5?logo=kubernetes&logoColor=white)](https://kubernetes.io/)
[![App Version](https://img.shields.io/static/v1?label=App+Version&message=2026.4.11&color=blue)](https://github.com/openclaw/openclaw)
[![Chart Version](https://img.shields.io/badge/Chart_Version-1.5.17-blue)](https://github.com/serhanekicii/openclaw-helm)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

Helm chart for deploying OpenClaw on Kubernetes — an AI assistant that connects to messaging platforms and executes tasks autonomously.

Built on [bjw-s app-template](https://github.com/bjw-s-labs/helm-charts). For a detailed walkthrough, see the [blog post](https://serhanekici.com/openclaw-helm.html).

---

## Architecture

OpenClaw runs as a single-instance deployment (cannot scale horizontally):

| Component | Port | Description |
|-----------|------|-------------|
| Gateway | 18789 | Main HTTP/WebSocket interface |
| Chromium | 9222 | Headless browser for automation (CDP, optional) |

**App Version:** 2026.4.11

---

## Installation

### Prerequisites

- Kubernetes `>=1.26.0-0`
- Helm 3.0+
- API key from a supported LLM provider (Anthropic, OpenAI, etc.)

### Steps

1. Add the repository:

```bash
helm repo add openclaw https://serhanekicii.github.io/openclaw-helm
helm repo update
```

2. Create namespace and secret:

```bash
kubectl create namespace openclaw
kubectl create secret generic openclaw-env-secret -n openclaw \
  --from-literal=ANTHROPIC_API_KEY=sk-ant-xxx \
  --from-literal=OPENCLAW_GATEWAY_TOKEN=your-token
```

3. Get default values:

```bash
helm show values openclaw/openclaw > values.yaml
```

4. Reference your secret in values.yaml:

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

5. Install:

```bash
helm install openclaw openclaw/openclaw -n openclaw -f values.yaml
```

6. Pair your device:

```bash
# Access the web UI
kubectl port-forward -n openclaw svc/openclaw 18789:18789
# Open http://localhost:18789, enter your Gateway Token, click Connect

# Approve the pairing request
kubectl exec -n openclaw deployment/openclaw -c main -- node dist/index.js devices list
kubectl exec -n openclaw deployment/openclaw -c main -- node dist/index.js devices approve <REQUEST_ID>
```

---

<details>
<summary><b>Using a Fork or Local Image</b></summary>

If you maintain a fork of OpenClaw or build your own image, point to your container registry:

```yaml
app-template:
  controllers:
    main:
      containers:
        main:
          image:
            repository: ghcr.io/your-org/openclaw-fork
            tag: "2026.4.11"
```

For images hosted in a private registry inside your cluster:

```yaml
app-template:
  controllers:
    main:
      containers:
        main:
          image:
            repository: registry.internal/openclaw
            tag: "2026.4.11"
            pullPolicy: Always
```

</details>

---

## Uninstall

```bash
helm uninstall openclaw -n openclaw
kubectl delete pvc -n openclaw -l app.kubernetes.io/name=openclaw  # optional: remove data
```

---

## Configuration

All values are nested under `app-template:`. See [values.yaml](values.yaml) for full reference.

<details>
<summary><b>Values Table</b></summary>

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| app-template.chromiumVersion | string | `"147.0.7727.56"` | Chromium sidecar image version |
| app-template.configMaps.config.data."openclaw.json" | string | `"{\n  // Gateway configuration\n  \"gateway\": {\n    \"port\": 18789,\n    \"mode\": \"local\",\n    // IMPORTANT: trustedProxies uses exact IP matching only\n    // - CIDR notation is NOT supported - list each proxy IP individually\n    // - IPv6 exact addresses may work but are untested\n    // - Recommend single-stack IPv4 deployments for simplicity\n    \"trustedProxies\": [\"10.0.0.1\"]\n  },\n\n  // Browser configuration (Chromium sidecar)\n  \"browser\": {\n    \"enabled\": true,\n    \"defaultProfile\": \"default\",\n    \"profiles\": {\n      \"default\": {\n        \"cdpUrl\": \"http://localhost:9222\",\n        \"color\": \"#4285F4\"\n      }\n    }\n  },\n\n  // Agent configuration\n  \"agents\": {\n    \"defaults\": {\n      \"workspace\": \"/home/node/.openclaw/workspace\",\n      \"model\": {\n        // Uses ANTHROPIC_API_KEY from environment\n        \"primary\": \"anthropic/claude-opus-4-6\"\n      },\n      \"userTimezone\": \"UTC\",\n      \"timeoutSeconds\": 600,\n      \"maxConcurrent\": 1\n    },\n    \"list\": [\n      {\n        \"id\": \"main\",\n        \"default\": true,\n        \"identity\": {\n          \"name\": \"OpenClaw\",\n          \"emoji\": \"🦞\"\n        }\n      }\n    ]\n  },\n\n  // Session management\n  \"session\": {\n    \"scope\": \"per-sender\",\n    \"store\": \"/home/node/.openclaw/sessions\",\n    \"reset\": {\n      \"mode\": \"idle\",\n      \"idleMinutes\": 60\n    }\n  },\n\n  // Logging\n  \"logging\": {\n    \"level\": \"info\",\n    \"consoleLevel\": \"info\",\n    \"consoleStyle\": \"compact\",\n    \"redactSensitive\": \"tools\"\n  },\n\n  // Tools configuration\n  \"tools\": {\n    \"profile\": \"full\",\n    \"web\": {\n      \"search\": {\n        \"enabled\": false\n      },\n      \"fetch\": {\n        \"enabled\": true\n      }\n    }\n  }\n\n  // Channel configuration can be added here:\n  // \"channels\": {\n  //   \"telegram\": {\n  //     \"botToken\": \"${TELEGRAM_BOT_TOKEN}\",\n  //     \"enabled\": true\n  //   },\n  //   \"discord\": {\n  //     \"token\": \"${DISCORD_BOT_TOKEN}\"\n  //   },\n  //   \"slack\": {\n  //     \"botToken\": \"${SLACK_BOT_TOKEN}\",\n  //     \"appToken\": \"${SLACK_APP_TOKEN}\"\n  //   }\n  // }\n}\n"` |  |
| app-template.configMaps.config.data.bash_aliases | string | `"alias openclaw='node /app/dist/index.js'\n"` |  |
| app-template.configMaps.config.enabled | bool | `true` |  |
| app-template.configMaps.scripts.data."init-config.sh" | string | `"log() { echo \"[$(date -Iseconds)] [init-config] $*\"; }\n\nlog \"Starting config initialization\"\nmkdir -p /home/node/.openclaw\nCONFIG_MODE=\"${CONFIG_MODE:-merge}\"\n\nif [ \"$CONFIG_MODE\" = \"merge\" ] && [ -f /home/node/.openclaw/openclaw.json ]; then\n  log \"Mode: merge - merging Helm config with existing config\"\n  if node -e \"\n    const fs = require('fs');\n    // Strip JSON5 single-line comments while preserving // inside strings (e.g. URLs)\n    const stripComments = (s) => {\n      let r = '', q = false, i = 0;\n      while (i < s.length) {\n        if (q) {\n          if (s[i] === '\\\\\\\\') { r += s[i] + s[i+1]; i += 2; continue; }\n          if (s[i] === '\\\"') q = false;\n          r += s[i++];\n        } else if (s[i] === '\\\"') {\n          q = true; r += s[i++];\n        } else if (s[i] === '/' && s[i+1] === '/') {\n          while (i < s.length && s[i] !== '\\n') i++;\n        } else { r += s[i++]; }\n      }\n      return r;\n    };\n    let existing;\n    try {\n      existing = JSON.parse(stripComments(fs.readFileSync('/home/node/.openclaw/openclaw.json', 'utf8')));\n    } catch (e) {\n      console.error('[init-config] Warning: existing config is not valid JSON, will overwrite');\n      process.exit(1);\n    }\n    const helm = JSON.parse(stripComments(fs.readFileSync('/config/openclaw.json', 'utf8')));\n    const deepMerge = (target, source) => {\n      for (const key of Object.keys(source)) {\n        if (source[key] && typeof source[key] === 'object' && !Array.isArray(source[key])) {\n          target[key] = target[key] || {};\n          deepMerge(target[key], source[key]);\n        } else {\n          target[key] = source[key];\n        }\n      }\n      return target;\n    };\n    const merged = deepMerge(existing, helm);\n    fs.writeFileSync('/home/node/.openclaw/openclaw.json', JSON.stringify(merged, null, 2));\n  \"; then\n    log \"Config merged successfully\"\n  else\n    log \"WARNING: Merge failed (existing config may not be valid JSON), falling back to overwrite\"\n    cp /config/openclaw.json /home/node/.openclaw/openclaw.json\n  fi\nelse\n  if [ ! -f /home/node/.openclaw/openclaw.json ]; then\n    log \"Fresh install - writing initial config\"\n  else\n    log \"Mode: overwrite - replacing config with Helm values\"\n  fi\n  cp /config/openclaw.json /home/node/.openclaw/openclaw.json\nfi\nlog \"Config initialization complete\"\n"` |  |
| app-template.configMaps.scripts.data."init-skills.sh" | string | `"log() { echo \"[$(date -Iseconds)] [init-skills] $*\"; }\n\nlog \"Starting skills initialization\"\n\n# ============================================================\n# Runtime Dependencies\n# ============================================================\n# Some skills require additional runtimes (Python, Go, etc.)\n# Install them here so they persist across pod restarts.\n#\n# Example: Install uv (Python package manager) for Python skills\n# mkdir -p /home/node/.openclaw/bin\n# if [ ! -f /home/node/.openclaw/bin/uv ]; then\n#   log \"Installing uv...\"\n#   curl -LsSf https://astral.sh/uv/install.sh | env UV_INSTALL_DIR=/home/node/.openclaw/bin sh\n# fi\n#\n# Example: Install pnpm and packages for interfaces (e.g., MS Teams)\n# The read-only filesystem and non-root UID prevent writing to default\n# pnpm paths (/usr/local/lib/node_modules, ~/.local/share/pnpm, etc.).\n# Redirect PNPM_HOME to the PVC so the binary persists across restarts.\n# The init container's HOME=/tmp ensures pnpm's cache, state, and config\n# writes land on /tmp (writable emptyDir). The store goes on the PVC so\n# hardlinks work (same filesystem as node_modules) and persist.\n# PNPM_HOME=/home/node/.openclaw/pnpm\n# mkdir -p \"$PNPM_HOME\"\n# if [ ! -f \"$PNPM_HOME/pnpm\" ]; then\n#   log \"Installing pnpm...\"\n#   curl -fsSL https://get.pnpm.io/install.sh | env PNPM_HOME=\"$PNPM_HOME\" SHELL=/bin/sh sh -\n# fi\n# export PATH=\"$PNPM_HOME:$PATH\"\n# log \"Installing interface dependencies...\"\n# cd /home/node/.openclaw\n# pnpm install <your-package> --store-dir /home/node/.openclaw/.pnpm-store\n\n# ============================================================\n# Skill Installation\n# ============================================================\n# Installs skills listed in SKILLS_TO_INSTALL (set via the top-level skills: [] value).\n# Set skills: [] in your values to skip skill installation entirely.\nmkdir -p /home/node/.openclaw/workspace/skills\ncd /home/node/.openclaw/workspace\ninstall_skill() {\n  skill=\"$1\"\n  SKILL_NAME=\"$(basename \"$skill\")\"\n  if [ -z \"$skill\" ]; then\n    return 0\n  fi\n  if [ -d \"skills/$SKILL_NAME\" ]; then\n    log \"Skill already installed: $skill\"\n    return 0\n  fi\n  log \"Installing skill: $skill\"\n  attempts=6\n  delay=5\n  for i in $(seq 1 \"$attempts\"); do\n    if npx -y clawhub install \"$skill\" --no-input; then\n      log \"Installed skill: $skill\"\n      return 0\n    fi\n    # Add a little jitter so concurrent pods don't retry in lockstep.\n    jitter=$((RANDOM % 5))\n    if [ \"$i\" -lt \"$attempts\" ]; then\n      log \"WARNING: Failed to install skill: $skill (attempt $i/$attempts). Retrying in $((delay + jitter))s...\"\n      sleep $((delay + jitter))\n      delay=$((delay * 2))\n    fi\n  done\n  log \"WARNING: Failed to install skill after $attempts attempts: $skill\"\n  return 1\n}\nfor skill in $SKILLS_TO_INSTALL; do\n  install_skill \"$skill\" || true\ndone\nlog \"Skills initialization complete\"\n"` |  |
| app-template.configMaps.scripts.enabled | bool | `true` |  |
| app-template.configMode | string | `"merge"` | Config mode: `merge` preserves runtime changes, `overwrite` for strict GitOps |
| app-template.controllers.main.containers.chromium | object | `{"enabled":true,"env":{"XDG_CACHE_HOME":"/tmp"},"image":{"repository":"chromedp/headless-shell","tag":"{{ .Values.chromiumVersion }}"},"probes":{"liveness":{"custom":true,"enabled":true,"spec":{"failureThreshold":6,"httpGet":{"path":"/json/version","port":9222},"initialDelaySeconds":10,"periodSeconds":30,"timeoutSeconds":5}},"readiness":{"custom":true,"enabled":true,"spec":{"httpGet":{"path":"/json/version","port":9222},"initialDelaySeconds":5,"periodSeconds":10}},"startup":{"custom":true,"enabled":true,"spec":{"failureThreshold":12,"httpGet":{"path":"/json/version","port":9222},"initialDelaySeconds":5,"periodSeconds":5,"timeoutSeconds":5}}},"resources":{"limits":{"cpu":"1000m","memory":"1Gi"},"requests":{"cpu":"100m","memory":"256Mi"}},"securityContext":{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"readOnlyRootFilesystem":true,"runAsGroup":1000,"runAsNonRoot":true,"runAsUser":1000}}` | Chromium sidecar for browser automation (CDP on port 9222) |
| app-template.controllers.main.containers.chromium.enabled | bool | `true` | Enable/disable the Chromium browser sidecar |
| app-template.controllers.main.containers.chromium.image.repository | string | `"chromedp/headless-shell"` | Chromium image repository |
| app-template.controllers.main.containers.chromium.image.tag | string | `"{{ .Values.chromiumVersion }}"` | Chromium image tag |
| app-template.controllers.main.containers.main | object | `{"args":["gateway","--bind","lan","--port","18789"],"command":["node","dist/index.js"],"env":{},"envFrom":[],"image":{"pullPolicy":"IfNotPresent","repository":"ghcr.io/openclaw/openclaw","tag":"{{ .Values.openclawVersion }}"},"probes":{"liveness":{"enabled":true,"spec":{"failureThreshold":3,"initialDelaySeconds":30,"periodSeconds":30,"tcpSocket":{"port":18789},"timeoutSeconds":5},"type":"TCP"},"readiness":{"enabled":true,"spec":{"failureThreshold":3,"initialDelaySeconds":10,"periodSeconds":10,"tcpSocket":{"port":18789},"timeoutSeconds":5},"type":"TCP"},"startup":{"enabled":true,"spec":{"failureThreshold":30,"initialDelaySeconds":5,"periodSeconds":5,"tcpSocket":{"port":18789},"timeoutSeconds":5},"type":"TCP"}},"resources":{"limits":{"cpu":"2000m","memory":"2Gi"},"requests":{"cpu":"200m","memory":"512Mi"}},"securityContext":{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"readOnlyRootFilesystem":true,"runAsGroup":1000,"runAsNonRoot":true,"runAsUser":1000}}` | Main OpenClaw container |
| app-template.controllers.main.containers.main.image.pullPolicy | string | `"IfNotPresent"` | Image pull policy |
| app-template.controllers.main.containers.main.image.repository | string | `"ghcr.io/openclaw/openclaw"` | Container image repository |
| app-template.controllers.main.containers.main.image.tag | string | `"{{ .Values.openclawVersion }}"` | Container image tag |
| app-template.controllers.main.containers.main.resources | object | `{"limits":{"cpu":"2000m","memory":"2Gi"},"requests":{"cpu":"200m","memory":"512Mi"}}` | Resource requests and limits |
| app-template.controllers.main.initContainers.init-config.command | list | `["sh","/scripts/init-config.sh"]` | Init-config startup script |
| app-template.controllers.main.initContainers.init-config.env.CONFIG_MODE | string | `"{{ .Values.configMode | default \"merge\" }}"` |  |
| app-template.controllers.main.initContainers.init-config.image.repository | string | `"ghcr.io/openclaw/openclaw"` |  |
| app-template.controllers.main.initContainers.init-config.image.tag | string | `"{{ .Values.openclawVersion }}"` |  |
| app-template.controllers.main.initContainers.init-config.securityContext.allowPrivilegeEscalation | bool | `false` |  |
| app-template.controllers.main.initContainers.init-config.securityContext.capabilities.drop[0] | string | `"ALL"` |  |
| app-template.controllers.main.initContainers.init-config.securityContext.readOnlyRootFilesystem | bool | `true` |  |
| app-template.controllers.main.initContainers.init-config.securityContext.runAsGroup | int | `1000` |  |
| app-template.controllers.main.initContainers.init-config.securityContext.runAsNonRoot | bool | `true` |  |
| app-template.controllers.main.initContainers.init-config.securityContext.runAsUser | int | `1000` |  |
| app-template.controllers.main.initContainers.init-skills.command | list | `["sh","/scripts/init-skills.sh"]` | Init-skills startup script |
| app-template.controllers.main.initContainers.init-skills.env.HOME | string | `"/tmp"` |  |
| app-template.controllers.main.initContainers.init-skills.env.NPM_CONFIG_CACHE | string | `"/tmp/.npm"` |  |
| app-template.controllers.main.initContainers.init-skills.env.SKILLS_TO_INSTALL | string | `"{{ .Values.skills | join \" \" }}"` |  |
| app-template.controllers.main.initContainers.init-skills.image.repository | string | `"ghcr.io/openclaw/openclaw"` |  |
| app-template.controllers.main.initContainers.init-skills.image.tag | string | `"{{ .Values.openclawVersion }}"` |  |
| app-template.controllers.main.initContainers.init-skills.securityContext.allowPrivilegeEscalation | bool | `false` |  |
| app-template.controllers.main.initContainers.init-skills.securityContext.capabilities.drop[0] | string | `"ALL"` |  |
| app-template.controllers.main.initContainers.init-skills.securityContext.readOnlyRootFilesystem | bool | `true` |  |
| app-template.controllers.main.initContainers.init-skills.securityContext.runAsGroup | int | `1000` |  |
| app-template.controllers.main.initContainers.init-skills.securityContext.runAsNonRoot | bool | `true` |  |
| app-template.controllers.main.initContainers.init-skills.securityContext.runAsUser | int | `1000` |  |
| app-template.controllers.main.replicas | int | `1` | Number of replicas (must be 1, OpenClaw doesn't support horizontal scaling) |
| app-template.controllers.main.strategy | string | `"Recreate"` | Deployment strategy |
| app-template.defaultPodOptions.securityContext | object | `{"fsGroup":1000,"fsGroupChangePolicy":"OnRootMismatch"}` | Pod security context |
| app-template.ingress.main.enabled | bool | `false` | Enable ingress resource creation |
| app-template.networkpolicies.main.controller | string | `"main"` |  |
| app-template.networkpolicies.main.enabled | bool | `false` | Enable network policy (default deny-all with explicit allow rules) |
| app-template.networkpolicies.main.policyTypes[0] | string | `"Ingress"` |  |
| app-template.networkpolicies.main.policyTypes[1] | string | `"Egress"` |  |
| app-template.networkpolicies.main.rules.egress[0].ports[0].port | int | `53` |  |
| app-template.networkpolicies.main.rules.egress[0].ports[0].protocol | string | `"UDP"` |  |
| app-template.networkpolicies.main.rules.egress[0].ports[1].port | int | `53` |  |
| app-template.networkpolicies.main.rules.egress[0].ports[1].protocol | string | `"TCP"` |  |
| app-template.networkpolicies.main.rules.egress[0].to[0].namespaceSelector.matchLabels."kubernetes.io/metadata.name" | string | `"kube-system"` |  |
| app-template.networkpolicies.main.rules.egress[0].to[0].podSelector.matchLabels.k8s-app | string | `"kube-dns"` |  |
| app-template.networkpolicies.main.rules.egress[1].to[0].ipBlock.cidr | string | `"0.0.0.0/0"` |  |
| app-template.networkpolicies.main.rules.egress[1].to[0].ipBlock.except[0] | string | `"10.0.0.0/8"` |  |
| app-template.networkpolicies.main.rules.egress[1].to[0].ipBlock.except[1] | string | `"172.16.0.0/12"` |  |
| app-template.networkpolicies.main.rules.egress[1].to[0].ipBlock.except[2] | string | `"192.168.0.0/16"` |  |
| app-template.networkpolicies.main.rules.egress[1].to[0].ipBlock.except[3] | string | `"169.254.0.0/16"` |  |
| app-template.networkpolicies.main.rules.egress[1].to[0].ipBlock.except[4] | string | `"100.64.0.0/10"` |  |
| app-template.networkpolicies.main.rules.ingress[0].from[0].namespaceSelector.matchLabels."kubernetes.io/metadata.name" | string | `"gateway-system"` |  |
| app-template.networkpolicies.main.rules.ingress[0].ports[0].port | int | `18789` |  |
| app-template.networkpolicies.main.rules.ingress[0].ports[0].protocol | string | `"TCP"` |  |
| app-template.openclawVersion | string | `"2026.4.11"` | OpenClaw image version (used by all OpenClaw containers) |
| app-template.persistence.bash-aliases.advancedMounts.main.main[0].path | string | `"/home/node/.bash_aliases"` |  |
| app-template.persistence.bash-aliases.advancedMounts.main.main[0].readOnly | bool | `true` |  |
| app-template.persistence.bash-aliases.advancedMounts.main.main[0].subPath | string | `"bash_aliases"` |  |
| app-template.persistence.bash-aliases.enabled | bool | `true` |  |
| app-template.persistence.bash-aliases.identifier | string | `"config"` |  |
| app-template.persistence.bash-aliases.type | string | `"configMap"` |  |
| app-template.persistence.config.advancedMounts.main.init-config[0].path | string | `"/config"` |  |
| app-template.persistence.config.advancedMounts.main.init-config[0].readOnly | bool | `true` |  |
| app-template.persistence.config.enabled | bool | `true` |  |
| app-template.persistence.config.identifier | string | `"config"` |  |
| app-template.persistence.config.type | string | `"configMap"` |  |
| app-template.persistence.data.accessMode | string | `"ReadWriteOnce"` | PVC access mode |
| app-template.persistence.data.advancedMounts.main.init-config[0].path | string | `"/home/node/.openclaw"` |  |
| app-template.persistence.data.advancedMounts.main.init-skills[0].path | string | `"/home/node/.openclaw"` |  |
| app-template.persistence.data.advancedMounts.main.main[0].path | string | `"/home/node/.openclaw"` |  |
| app-template.persistence.data.enabled | bool | `true` |  |
| app-template.persistence.data.size | string | `"5Gi"` | PVC storage size |
| app-template.persistence.data.type | string | `"persistentVolumeClaim"` |  |
| app-template.persistence.scripts.advancedMounts.main.init-config[0].path | string | `"/scripts"` |  |
| app-template.persistence.scripts.advancedMounts.main.init-config[0].readOnly | bool | `true` |  |
| app-template.persistence.scripts.advancedMounts.main.init-skills[0].path | string | `"/scripts"` |  |
| app-template.persistence.scripts.advancedMounts.main.init-skills[0].readOnly | bool | `true` |  |
| app-template.persistence.scripts.enabled | bool | `true` |  |
| app-template.persistence.scripts.identifier | string | `"scripts"` |  |
| app-template.persistence.scripts.type | string | `"configMap"` |  |
| app-template.persistence.tmp.advancedMounts.main.chromium[0].path | string | `"/tmp"` |  |
| app-template.persistence.tmp.advancedMounts.main.init-config[0].path | string | `"/tmp"` |  |
| app-template.persistence.tmp.advancedMounts.main.init-skills[0].path | string | `"/tmp"` |  |
| app-template.persistence.tmp.advancedMounts.main.main[0].path | string | `"/tmp"` |  |
| app-template.persistence.tmp.enabled | bool | `true` |  |
| app-template.persistence.tmp.type | string | `"emptyDir"` |  |
| app-template.service.main.controller | string | `"main"` |  |
| app-template.service.main.ipFamilies[0] | string | `"IPv4"` |  |
| app-template.service.main.ipFamilyPolicy | string | `"SingleStack"` | IPv4-only (see trustedProxies note in gateway config) |
| app-template.service.main.ports.http.port | int | `18789` | Gateway service port |
| app-template.skills | list | `["weather","gog"]` | ClawHub skills to install on startup. Set to [] to skip skill installation. |

</details>

### Config Mode

The `configMode` setting controls how Helm-managed config merges with runtime changes:

| Mode | Behavior |
|------|----------|
| `merge` (default) | Helm values are deep-merged with existing config. Runtime changes (e.g., paired devices, UI settings) are preserved. |
| `overwrite` | Helm values completely replace existing config. Use for strict GitOps where config should match values.yaml exactly. |

```yaml
app-template:
  configMode: overwrite  # or "merge" (default)
```

<details>
<summary><b>ArgoCD with Config Merge</b></summary>

When using `configMode: merge` with ArgoCD, prevent ArgoCD from overwriting runtime config changes by ignoring the ConfigMap:

```yaml
# Application manifest
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: openclaw
spec:
  ignoreDifferences:
    - group: ""
      kind: ConfigMap
      name: openclaw
      jsonPointers:
        - /data
```

This allows:
- ArgoCD manages deployments, services, etc.
- Runtime config changes (paired devices, UI settings) persist on PVC
- Helm values still merge on pod restart

</details>

### Security

The chart follows security best practices:

- All containers run as non-root (UID 1000)
- Read-only root filesystem on all containers
- All capabilities dropped
- Privilege escalation disabled
- Network policies available for workload isolation

> **Important:** OpenClaw has shell access and processes untrusted input. Use network policies and limit exposure. See the [OpenClaw Security Guide](https://docs.openclaw.ai/gateway/security) for best practices.

### Network Policy

Network policies isolate OpenClaw from internal cluster services, limiting blast radius if compromised:

```yaml
app-template:
  networkpolicies:
    main:
      enabled: true
```

Default policy allows:
- Ingress from `gateway-system` namespace on port 18789
- Egress to kube-dns
- Egress to public internet (blocks private/reserved ranges)

Requires a CNI with NetworkPolicy support (Calico, Cilium).

<details>
<summary><b>Allowing Internal Services</b></summary>

To allow OpenClaw to reach internal services (e.g., Vault, Ollama), add egress rules:

```yaml
app-template:
  networkpolicies:
    main:
      enabled: true
      rules:
        egress:
          # DNS (required)
          - to:
              - namespaceSelector:
                  matchLabels:
                    kubernetes.io/metadata.name: kube-system
                podSelector:
                  matchLabels:
                    k8s-app: kube-dns
            ports:
              - protocol: UDP
                port: 53
          # Public internet (blocks RFC1918)
          - to:
              - ipBlock:
                  cidr: 0.0.0.0/0
                  except:
                    - 10.0.0.0/8
                    - 172.16.0.0/12
                    - 192.168.0.0/16
          # Vault
          - to:
              - namespaceSelector:
                  matchLabels:
                    kubernetes.io/metadata.name: vault
            ports:
              - protocol: TCP
                port: 8200
          # Ollama
          - to:
              - namespaceSelector:
                  matchLabels:
                    kubernetes.io/metadata.name: ollama
            ports:
              - protocol: TCP
                port: 11434
```

</details>

### Browser Automation

Chromium sidecar provides headless browser via CDP on port 9222.

To disable:

```yaml
app-template:
  controllers:
    main:
      containers:
        chromium:
          enabled: false
```

### Skills

The `init-skills` container provides declarative skill management from [ClawHub](https://clawhub.com):

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
              cd /home/node/.openclaw/workspace && mkdir -p skills
              for skill in weather; do
                if ! npx -y clawhub install "$skill" --no-input; then
                  echo "WARNING: Failed to install skill: $skill"
                fi
              done
```

### Runtime Dependencies

Some features (interfaces, skills) require additional runtimes or packages not included in the base image. The `init-skills` init container handles this -- install extra tooling to the PVC at `/home/node/.openclaw` so it persists across pod restarts and is available at runtime.

This approach is necessary because all containers run with a **read-only root filesystem** as non-root (UID 1000). Default package manager paths (e.g., `/usr/local/lib/node_modules`) are not writable. Redirecting install paths to the PVC solves this.

<details>
<summary><b>pnpm (e.g., MS Teams interface)</b></summary>

Interfaces like MS Teams require pnpm packages. The read-only root filesystem prevents writing to default pnpm paths (`/usr/local/lib/node_modules`, `~/.local/share/pnpm`, etc.). The fix is to install pnpm to the PVC and redirect its directories to writable mounts.

The `init-skills` container already sets `HOME=/tmp`, so pnpm's cache, state, and config writes land on `/tmp` (writable emptyDir). The content-addressable store goes on the PVC so that hardlinks work (same filesystem as `node_modules`) and persist across restarts.

**1. Install pnpm and packages in `init-skills`:**

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
              PNPM_HOME=/home/node/.openclaw/pnpm
              mkdir -p "$PNPM_HOME"
              if [ ! -f "$PNPM_HOME/pnpm" ]; then
                echo "Installing pnpm..."
                curl -fsSL https://get.pnpm.io/install.sh | env PNPM_HOME="$PNPM_HOME" SHELL=/bin/sh sh -
              fi
              export PATH="$PNPM_HOME:$PATH"
              echo "Installing interface dependencies..."
              cd /home/node/.openclaw
              pnpm install <your-package> --store-dir /home/node/.openclaw/.pnpm-store
```

**2. Expose pnpm to the main container:**

```yaml
app-template:
  controllers:
    main:
      containers:
        main:
          env:
            PATH: /home/node/.openclaw/pnpm:/home/node/.openclaw/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
            PNPM_HOME: /home/node/.openclaw/pnpm
            PNPM_STORE_DIR: /home/node/.openclaw/.pnpm-store
```

</details>

<details>
<summary><b>uv (Python package manager)</b></summary>

For skills that require Python:

**1. Install uv in `init-skills`:**

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
              mkdir -p /home/node/.openclaw/bin
              if [ ! -f /home/node/.openclaw/bin/uv ]; then
                echo "Installing uv..."
                curl -LsSf https://astral.sh/uv/install.sh | env UV_INSTALL_DIR=/home/node/.openclaw/bin sh
              fi
```

**2. Add to PATH in main container:**

```yaml
app-template:
  controllers:
    main:
      containers:
        main:
          env:
            PATH: /home/node/.openclaw/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
```

</details>

### Automatic Rollouts on ConfigMap/Secret Changes

For automatic pod restarts when ConfigMap/Secret changes, use [Stakater Reloader](https://github.com/stakater/Reloader) or [ArgoCD](https://argo-cd.readthedocs.io/). See the [blog post](https://serhanekici.com/openclaw-helm.html) for detailed setup.

```yaml
app-template:
  defaultPodOptions:
    annotations:
      reloader.stakater.com/auto: "true"
```

### Persistence

Persistent storage is enabled by default (5Gi).

To disable (data lost on restart):

```yaml
app-template:
  persistence:
    data:
      enabled: false
```

<details>
<summary><b>Ingress</b></summary>

```yaml
app-template:
  ingress:
    main:
      enabled: true
      className: your-ingress-class
      hosts:
        - host: openclaw.example.com
          paths:
            - path: /
              pathType: Prefix
              service:
                identifier: main
                port: http
      tls:
        - secretName: openclaw-tls
          hosts:
            - openclaw.example.com
```

</details>

<details>
<summary><b>Internal CA Trust</b></summary>

For HTTPS to internal services with private CAs:

```yaml
app-template:
  persistence:
    ca-bundle:
      enabled: true
      type: configMap
      name: ca-bundle
      advancedMounts:
        main:
          main:
            - path: /etc/ssl/certs/ca-bundle.crt
              subPath: ca-bundle.crt
              readOnly: true
  controllers:
    main:
      containers:
        main:
          env:
            REQUESTS_CA_BUNDLE: /etc/ssl/certs/ca-bundle.crt
```

</details>

<details>
<summary><b>Resource Limits</b></summary>

Default resources for main container:

```yaml
app-template:
  controllers:
    main:
      containers:
        main:
          resources:
            requests:
              cpu: 200m
              memory: 512Mi
            limits:
              cpu: 2000m
              memory: 2Gi
```

</details>

---

## Troubleshooting

<details>
<summary><b>Debug Commands</b></summary>

```bash
# Pod status
kubectl get pods -n openclaw

# Logs
kubectl logs -n openclaw deployment/openclaw

# Port forward
kubectl port-forward -n openclaw svc/openclaw 18789:18789
```

</details>

---

## Development

```bash
helm lint charts/openclaw
helm dependency update charts/openclaw
helm template test charts/openclaw --debug
```

---

## Dependencies

| Repository | Name | Version |
|------------|------|---------|
| https://bjw-s-labs.github.io/helm-charts/ | app-template | 4.6.2 |

## License

MIT
