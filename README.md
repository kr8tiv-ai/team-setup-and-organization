# KR8TIV AI Team Setup & Organization

**Enterprise-grade infrastructure for AI agent teams.**

This repository contains the complete infrastructure setup, monitoring, and organization patterns used by KR8TIV AI to run a team of autonomous AI agents with 99.9% uptime.

---

## 🎯 What This Solves

**The Problem:**
- AI agent containers crash and stay down
- No visibility when services fail
- Scattered logs make debugging slow
- No disaster recovery plan
- Manual intervention required for everything

**Our Solution:**
- ✅ Auto-restart on all crashes (seconds, not hours)
- ✅ Real-time health monitoring with alerts
- ✅ Centralized logging dashboard
- ✅ Automated daily backups with 7-day retention
- ✅ Enterprise-grade security (encrypted, isolated, monitored)

---

## 📊 Infrastructure Overview

```
┌─────────────────────────────────────────────────────────┐
│                    KR8TIV AI Stack                      │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌────────┐ │
│  │  Friday  │  │ Arsenal  │  │  EDITH   │  │Jocasta │ │
│  │  (CMO)   │  │  (COO)   │  │ (Creative)│  │ (CTO) │ │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └───┬────┘ │
│       │             │              │             │      │
│       └─────────────┴──────────────┴─────────────┘      │
│                          │                              │
│              ┌───────────▼───────────┐                  │
│              │  Mission Control API  │                  │
│              │    (Task Router)      │                  │
│              └───────────┬───────────┘                  │
│                          │                              │
│        ┌─────────────────┼─────────────────┐            │
│        │                 │                 │            │
│   ┌────▼────┐      ┌─────▼─────┐    ┌─────▼─────┐     │
│   │PostgreSQL│      │   Redis   │    │  Webhook  │     │
│   │   DB     │      │   Queue   │    │  Worker   │     │
│   └──────────┘      └───────────┘    └───────────┘     │
│                                                         │
├─────────────────────────────────────────────────────────┤
│                  Monitoring Layer                       │
├─────────────────────────────────────────────────────────┤
│                                                         │
│   ┌──────────────┐         ┌──────────────┐            │
│   │ Uptime Kuma  │         │   Dozzle     │            │
│   │  (Monitoring)│         │    (Logs)    │            │
│   │  Port 3001   │         │  Port 9999   │            │
│   └──────────────┘         └──────────────┘            │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

---

## 🚀 Quick Start

### Prerequisites
- Ubuntu 24.04 LTS
- Docker & Docker Compose
- Root or sudo access

### 1. Install Core Infrastructure

```bash
# Clone this repo
git clone https://github.com/kr8tiv-ai/team-setup-and-organization.git
cd team-setup-and-organization

# Run setup script
sudo bash scripts/setup-infrastructure.sh
```

This installs:
- Docker auto-restart policies
- Uptime Kuma (monitoring)
- Dozzle (log aggregation)
- Automated backup system

### 2. Configure Monitoring

Visit `http://YOUR_SERVER_IP:3001` to set up Uptime Kuma:
1. Create admin account
2. Add monitors for each service endpoint
3. Configure Telegram/Slack notifications

### 3. Access Logs

Visit `http://YOUR_SERVER_IP:9999` for real-time container logs.

---

## 📁 Repository Structure

```
team-setup-and-organization/
├── README.md                          # This file
├── docs/
│   ├── INFRASTRUCTURE.md              # Detailed infrastructure guide
│   ├── MONITORING.md                  # Uptime Kuma setup
│   ├── CLOUDFLARE-TUNNEL.md          # Secure access setup
│   └── DISASTER-RECOVERY.md           # Backup & restore procedures
├── scripts/
│   ├── setup-infrastructure.sh        # One-click setup
│   ├── backup-containers.sh           # Automated backup script
│   └── restore-from-backup.sh         # Disaster recovery
├── docker-templates/
│   ├── agent-template.yml             # Standard agent container config
│   └── mission-control.yml            # Mission Control stack
└── .github/
    └── workflows/
        └── validate-configs.yml       # CI/CD validation
```

---

## 🛠 Features

### Auto-Restart on Crash
All containers configured with `restart: unless-stopped`. If any service crashes, Docker automatically restarts it within seconds.

### Health Checks
Every service has active health monitoring:
- PostgreSQL: `pg_isready` checks
- Redis: `PING` checks
- API services: `/healthz` endpoint checks
- Frontend: HTTP response checks

### Centralized Logging
Dozzle provides a web UI for all container logs:
- Real-time streaming
- Search & filter
- Multi-container view
- Zero configuration needed

### Automated Backups
Daily backups at 2 AM:
- All agent data volumes
- Mission Control database
- 7-day retention
- Compressed archives

### Monitoring Dashboard
Uptime Kuma tracks all services:
- HTTP/HTTPS endpoint monitoring
- TCP port monitoring
- Real-time status
- Alert notifications (Telegram, Slack, Discord, Email)

---

## 📖 Documentation

### Core Guides
- [Infrastructure Setup](docs/INFRASTRUCTURE.md) - Complete infrastructure walkthrough
- [Monitoring Configuration](docs/MONITORING.md) - Uptime Kuma setup & alerts
- [Cloudflare Tunnel](docs/CLOUDFLARE-TUNNEL.md) - Secure HTTPS access
- [Disaster Recovery](docs/DISASTER-RECOVERY.md) - Backup & restore procedures

### Templates
- [Agent Container Template](docker-templates/agent-template.yml) - Standard agent config
- [Mission Control Template](docker-templates/mission-control.yml) - Full stack config

---

## 🔐 Security

### What We Do
✅ Containers run in isolated networks  
✅ Secrets encrypted at rest  
✅ Health checks prevent zombie processes  
✅ Daily encrypted backups  
✅ No exposed credentials in configs  

### What We Recommend
⚠️ Use Cloudflare Tunnel instead of exposing ports  
⚠️ Enable firewall (UFW) on all non-tunnel ports  
⚠️ Rotate API keys regularly  
⚠️ Store secrets in encrypted vaults, not environment files  

---

## 💡 Why We Built This

**Context:** We run a team of 4 autonomous AI agents (Friday, Arsenal, EDITH, Jocasta) coordinating through Mission Control to manage a multi-venture business.

**The Challenge:** Traditional infrastructure wasn't built for AI agent teams. Containers would crash, stay down for hours, and we'd only find out when a customer complained.

**Our Approach:** Build enterprise-grade infrastructure that treats AI agents like critical production services — because they are.

**The Result:** 
- 99.9% uptime
- Auto-recovery from crashes
- Real-time visibility into all services
- Disaster recovery in minutes

---

## 🤝 Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

**Areas we're actively improving:**
- Kubernetes migration guide
- Multi-region deployment
- Advanced monitoring (Prometheus/Grafana)
- CI/CD pipelines for agent updates

---

## 📄 License

MIT License - see [LICENSE](LICENSE) for details.

---

## 🔗 Links

- **Website:** [kr8tiv.ai](https://kr8tiv.ai)
- **Blog:** [kr8tiv.ai/blog](https://kr8tiv.ai/blog)
- **Twitter:** [@kr8tivai](https://twitter.com/kr8tivai)
- **Discord:** [Join our community](https://discord.gg/kr8tiv)

---

## ⚡ Built With

- [OpenClaw](https://openclaw.ai) - AI agent framework
- [Docker](https://docker.com) - Containerization
- [Uptime Kuma](https://github.com/louislam/uptime-kuma) - Monitoring
- [Dozzle](https://dozzle.dev) - Log aggregation
- [Cloudflare Tunnel](https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/) - Secure access

---

**Made with 🔥 by the KR8TIV AI team**
