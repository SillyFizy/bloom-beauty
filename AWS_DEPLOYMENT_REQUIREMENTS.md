# AWS Deployment Requirements - Joulina Beauty Backend
## Cost-Optimized Deployment for Iraq Operations

### System Overview
- **Application**: Django 4.2.7 REST API Backend
- **Database**: PostgreSQL 15
- **Target Region**: Middle East/Europe (for Iraq operations)
- **Architecture**: Single-tier web application with database
- **Primary Focus**: **COST OPTIMIZATION** with adequate performance

---

## 🏗️ Backend System Architecture

### Current Technology Stack
```
├── Django Framework 4.2.7
├── Django REST Framework 3.14.0
├── PostgreSQL Database
├── JWT Authentication
├── Media File Storage
├── Multiple Apps:
│   ├── Products Management
│   ├── User Authentication
│   ├── Orders & Payments
│   ├── Cart Management
│   ├── Celebrity Picks
│   └── Categories Management
```

### System Requirements Analysis
- **CPU**: Moderate (Django app + API requests)
- **Memory**: 2-4GB (Django + PostgreSQL)
- **Storage**: 20-50GB (application + media files)
- **Network**: Standard web traffic
- **Database**: Small to medium PostgreSQL instance

---

## 💰 COST-OPTIMIZED AWS EC2 SPECIFICATIONS

### 🎯 **RECOMMENDED INSTANCE TYPE: t3.small**
**Primary Choice for Maximum Cost Efficiency**

```yaml
Instance Type: t3.small
vCPUs: 2
Memory: 2 GiB
Network Performance: Up to 5 Gigabit
Storage: EBS-Only
Baseline CPU Performance: 20%
```

**Pricing Estimate (On-Demand)**:
- **US East (N. Virginia)**: ~$16.80/month
- **EU West (Ireland)**: ~$18.50/month
- **ME South (Bahrain)**: ~$20.50/month

### 🏆 **ALTERNATIVE: t3a.small (AMD-based - 10% cheaper)**
```yaml
Instance Type: t3a.small
vCPUs: 2
Memory: 2 GiB
Network Performance: Up to 5 Gigabit
Cost Savings: ~10% less than t3.small
Monthly Cost: ~$15.12/month (US East)
```

### 📈 **SCALING OPTIONS**

**For Growth/Higher Traffic:**
```yaml
Next Tier: t3.medium
vCPUs: 2
Memory: 4 GiB
Cost: ~$33.60/month (US East)
Use Case: When 2GB RAM becomes insufficient
```

**For Budget Constraints:**
```yaml
Minimum Tier: t3.micro
vCPUs: 2
Memory: 1 GiB
Cost: ~$8.40/month (US East)
Use Case: Development/testing only
```

---

## 💡 **COST OPTIMIZATION STRATEGIES**

### 1. **Reserved Instances (Up to 75% savings)**
```yaml
Option 1: 1-Year No Upfront
Savings: ~40% off on-demand pricing
t3.small: ~$10.08/month

Option 2: 1-Year All Upfront
Savings: ~42% off on-demand pricing
t3.small: ~$118/year ($9.83/month)

Option 3: 3-Year All Upfront
Savings: ~60% off on-demand pricing
t3.small: ~$302/3 years ($8.39/month)
```

### 2. **Spot Instances (Up to 90% savings)**
```yaml
Spot Instance Pricing: t3.small
Average Cost: $2-5/month (varies by demand)
Risk: Can be terminated with 2-minute notice
Best For: Development/testing environments
```

### 3. **Savings Plans**
```yaml
Compute Savings Plans: 1-Year
Discount: Up to 66% off on-demand
Flexibility: Can change instance types
Commitment: $X/hour for 1 year
```

---

## 🌍 **OPTIMAL AWS REGIONS FOR IRAQ**

### **Primary Recommendation: EU-West-1 (Ireland)**
```yaml
Latency to Iraq: ~80-120ms
Pricing: Moderate
Data Compliance: GDPR compliant
Services: Full AWS service availability
Monthly Cost (t3.small): ~$18.50
```

### **Alternative: ME-South-1 (Bahrain)**
```yaml
Latency to Iraq: ~20-40ms (BEST)
Pricing: ~15% higher than US regions
Local Presence: Middle East
Monthly Cost (t3.small): ~$20.50
Benefits: Lowest latency, regional compliance
```

### **Budget Option: US-East-1 (N. Virginia)**
```yaml
Latency to Iraq: ~180-250ms
Pricing: CHEAPEST globally
Monthly Cost (t3.small): ~$16.80
Trade-off: Higher latency for users
```

---

## 💾 **STORAGE OPTIMIZATION**

### **EBS Volume Configuration**
```yaml
Root Volume:
  Type: gp3 (General Purpose SSD)
  Size: 20 GB
  Cost: ~$1.60/month
  
Application Data:
  Type: gp3
  Size: 20 GB
  Cost: ~$1.60/month
  
Media Files:
  Type: gp3 or S3 Standard-IA
  Size: Variable
  Cost: $0.0125/GB/month (S3 IA)
```

### **Database Storage**
```yaml
PostgreSQL on Same Instance:
  Included in instance cost
  Backup: EBS Snapshots ($0.05/GB/month)

Alternative - RDS PostgreSQL:
  db.t3.micro: ~$12.50/month
  Additional Cost: ~$12.50/month
  Benefits: Managed, automated backups
```

---

## 🔒 **NETWORK & SECURITY (Cost-Effective)**

### **Load Balancer**
```yaml
Application Load Balancer (ALB):
  Cost: ~$16.20/month + data processing
  Alternative: Use CloudFlare (Free tier)
  Nginx Reverse Proxy: $0 (configure on instance)
```

### **SSL Certificate**
```yaml
AWS Certificate Manager: FREE
Let's Encrypt: FREE
Self-managed: FREE
```

### **Security Groups**
```yaml
Cost: FREE
Configuration: Restrict to necessary ports
Ports: 80 (HTTP), 443 (HTTPS), 22 (SSH)
```

---

## 📊 **TOTAL MONTHLY COST BREAKDOWN**

### **Minimum Viable Setup**
```yaml
Instance (t3.small): $16.80
EBS Storage (40GB): $3.20
Data Transfer: $1.00
Total: ~$21/month
```

### **Recommended Production Setup**
```yaml
Instance (t3.small): $16.80
EBS Storage (60GB): $4.80
S3 Storage (50GB): $1.15
Data Transfer: $2.00
CloudFront CDN: $1.00
Total: ~$25.75/month
```

### **With Reserved Instance (1-year)**
```yaml
Instance (t3.small Reserved): $10.08
EBS Storage: $4.80
S3 Storage: $1.15
Other Services: $3.00
Total: ~$19/month (24% savings)
```

---

## 🚀 **DEPLOYMENT ARCHITECTURE**

### **Single Instance Setup (Most Cost-Effective)**
```
┌─────────────────────────────────────┐
│           EC2 t3.small              │
├─────────────────────────────────────┤
│ ┌─────────────┐ ┌─────────────────┐ │
│ │   Django    │ │   PostgreSQL    │ │
│ │   App       │ │   Database      │ │
│ │   + Nginx   │ │                 │ │
│ └─────────────┘ └─────────────────┘ │
├─────────────────────────────────────┤
│         EBS Storage (40GB)          │
└─────────────────────────────────────┘
```

### **Application Stack**
```yaml
Web Server: Nginx (Reverse Proxy)
Application: Django + Gunicorn
Database: PostgreSQL 15
Process Manager: Systemd
Monitoring: CloudWatch (Basic - FREE tier)
```

---

## 🛠️ **SYSTEM REQUIREMENTS**

### **Operating System**
```yaml
Recommended: Ubuntu 22.04 LTS (FREE)
Alternative: Amazon Linux 2023 (FREE)
Benefits: Long-term support, security updates
```

### **Software Stack**
```yaml
Python: 3.11
Django: 4.2.7
PostgreSQL: 15
Nginx: Latest
Redis: 7.x (for caching - optional)
```

### **Memory Allocation**
```yaml
Django Application: ~800MB
PostgreSQL: ~512MB
Operating System: ~400MB
Buffer: ~308MB
Total: 2GB (fits t3.small perfectly)
```

---

## 📈 **PERFORMANCE OPTIMIZATIONS**

### **T3 Burstable Performance**
```yaml
Baseline: 20% CPU utilization
Burst: Up to 100% when needed
Credits: Accumulate during low usage
Monitoring: CloudWatch CPU Credit Balance
```

### **Database Optimization**
```yaml
PostgreSQL Configuration:
  shared_buffers: 256MB
  effective_cache_size: 1GB
  work_mem: 4MB
  maintenance_work_mem: 64MB
```

### **Application Optimization**
```yaml
Gunicorn Workers: 2-3 (for 2 vCPU)
Django Settings:
  DEBUG: False
  ALLOWED_HOSTS: Configured
  Static Files: Served by Nginx
  Media Files: S3 + CloudFront
```

---

## 🔄 **BACKUP & DISASTER RECOVERY**

### **Automated Backups**
```yaml
EBS Snapshots:
  Frequency: Daily
  Retention: 7 days
  Cost: ~$1.50/month
  
Database Backup:
  pg_dump: Daily to S3
  Cost: ~$0.50/month
```

### **Disaster Recovery**
```yaml
RTO: 30 minutes (manual restore)
RPO: 24 hours (daily backups)
Process: Launch new instance + restore from snapshot
```

---

## 📊 **MONITORING & COST CONTROL**

### **AWS Cost Management**
```yaml
Billing Alerts: Set at $30/month
Cost Budgets: Monthly budget alerts
Reserved Instance Utilization: Monitor usage
Spot Instance Advisor: Track savings opportunities
```

### **Performance Monitoring**
```yaml
CloudWatch Basic: FREE
Custom Metrics: $0.30/metric/month
Log Insights: Pay per query
Application Monitoring: Django Debug Toolbar (FREE)
```

---

## 🚦 **TRAFFIC EXPECTATIONS & SCALING**

### **t3.small Capacity**
```yaml
Concurrent Users: 50-100
Requests/second: 10-20
Database Connections: 20-50
API Responses: <200ms average
```

### **Scaling Triggers**
```yaml
CPU > 70% for 10 minutes: Scale to t3.medium
Memory > 85%: Add swap or scale up
Database CPU > 80%: Consider RDS migration
```

---

## 💳 **BILLING OPTIMIZATION CHECKLIST**

### **Daily Monitoring**
- [ ] Check instance utilization
- [ ] Monitor data transfer costs
- [ ] Review storage usage
- [ ] Track CPU credits

### **Weekly Reviews**
- [ ] Analyze cost reports
- [ ] Check for unused resources
- [ ] Review backup storage costs
- [ ] Optimize Reserved Instance usage

### **Monthly Actions**
- [ ] Right-size instances based on metrics
- [ ] Clean up old snapshots
- [ ] Review and adjust budgets
- [ ] Evaluate Savings Plans opportunities

---

## 🎯 **DEPLOYMENT CHECKLIST**

### **Pre-Deployment**
- [ ] Choose region (EU-West-1 recommended)
- [ ] Set up billing alerts
- [ ] Create security groups
- [ ] Generate SSH key pairs
- [ ] Plan backup strategy

### **Initial Setup**
- [ ] Launch t3.small instance
- [ ] Configure security groups
- [ ] Set up EBS volumes
- [ ] Install required software
- [ ] Deploy Django application
- [ ] Configure database

### **Post-Deployment**
- [ ] Set up monitoring
- [ ] Configure automated backups
- [ ] Test application functionality
- [ ] Set up SSL certificate
- [ ] Configure domain name

---

## 📞 **SUPPORT & MAINTENANCE**

### **AWS Support Plan**
```yaml
Basic Support: FREE
- 24/7 access to customer service
- Documentation and whitepapers
- Community forums

Developer Support: $29/month
- Business hours email support
- General guidance
- Best practices
```

### **Estimated Monthly Total Costs**

#### **Startup Phase (Minimal)**
```yaml
Instance (t3.small): $16.80
Storage: $3.20
Data Transfer: $1.00
TOTAL: ~$21/month
```

#### **Production Ready**
```yaml
Instance (t3.small): $16.80
Storage & Backup: $5.30
CDN & Transfer: $2.50
Monitoring: $1.00
TOTAL: ~$25.60/month
```

#### **Optimized (1-Year Reserved)**
```yaml
Instance (Reserved): $10.08
Other Services: $8.52
TOTAL: ~$18.60/month
```

---

**🎉 RECOMMENDATION: Start with t3.small on-demand for 3 months, then purchase 1-year Reserved Instance for maximum savings while maintaining flexibility.**

---

*This configuration provides a robust, scalable, and cost-effective foundation for your beauty e-commerce backend serving customers in Iraq, with total monthly costs under $26 and optimization potential down to $19/month.* 