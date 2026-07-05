# TravelMemory MERN Application — AWS Cloud Deployment Documentation

**Project:** Travel Memory Application Deployment
**Stack:** MongoDB, Express, React, Node.js (MERN)
**Repository:** https://github.com/UnpredictablePrashant/TravelMemory

> How to use this document: it is written as a runbook. Follow it in order on your own AWS account. Every section has a `📸 Screenshot:` marker — take that screenshot on your machine/console and paste it in that spot before you submit. Replace all `<placeholders>` with your real values (IPs, domain name, key names).

---

## Table of Contents
1. Architecture Overview
2. Prerequisites
3. Step 1 — Launch EC2 Instances
4. Step 2 — Backend Setup (Node.js + MongoDB + PM2 + Nginx reverse proxy)
5. Step 3 — Frontend Setup (React build + urls.js + Nginx)
6. Step 4 — Verify Frontend↔Backend Communication
7. Step 5 — Scaling: AMIs, Multiple Instances, Target Groups, Load Balancer
8. Step 6 — Domain Setup with Cloudflare (CNAME + A record)
9. Step 7 — Security Best Practices
10. Step 8 — Architecture Diagram (draw.io)
11. Troubleshooting
12. Submission Checklist

---

## 1. Architecture Overview

```
                         Internet Users
                               │
                               ▼
                     ┌───────────────────┐
                     │     Cloudflare     │  (DNS + CDN/Proxy)
                     │  A record → FE IP  │
                     │ CNAME → ALB DNS    │
                     └─────────┬─────────┘
                               │
                 ┌─────────────┴─────────────┐
                 ▼                           ▼
        Frontend EC2 (Nginx,          Application Load Balancer
        serves React build,                    │
        port 80)                ┌──────────────┴──────────────┐
                                 ▼                             ▼
                        Backend EC2 #1                 Backend EC2 #2
                        Nginx reverse proxy             Nginx reverse proxy
                        → Node.js app :3000             → Node.js app :3000
                                 │                             │
                                 └──────────────┬──────────────┘
                                                ▼
                                        MongoDB Atlas
                                     (managed, external DB)
```

- **Frontend**: React app built as static files, served by Nginx on one or more EC2 instances.
- **Backend**: Node/Express API on port 3000, fronted by an Nginx reverse proxy (port 80 → 3000), running on 2+ EC2 instances behind an Application Load Balancer (ALB).
- **Database**: MongoDB Atlas (recommended, free tier, avoids self-managing Mongo on EC2).
- **DNS/Domain**: Cloudflare — A record for the frontend, CNAME for the ALB.

---

## 2. Prerequisites

- AWS account with permission to create EC2, ALB, Target Groups, Security Groups.
- A domain name added to a Cloudflare account (can be bought cheaply from Namecheap/Google Domains, or use a free subdomain provider).
- MongoDB Atlas account (free M0 cluster) — or a MongoDB instance on a separate EC2.
- SSH client (PuTTY on Windows, or native terminal on Mac/Linux).
- Basic familiarity with Linux commands.

📸 **Screenshot:** AWS console home page showing your account/region.

---

## 3. Step 1 — Launch EC2 Instances

You will need **at least 3 EC2 instances** for a proper scaled deployment:
- `backend-1`, `backend-2` — run the Node.js API
- `frontend-1` (and optionally `frontend-2`) — serve the React build

### 3.1 Launch instance
1. EC2 Console → **Launch Instance**.
2. Name: `travelmemory-backend-1`.
3. AMI: **Ubuntu Server 22.04 LTS**.
4. Instance type: `t2.micro` (free tier eligible).
5. Key pair: create new, e.g. `travelmemory-key.pem` — download and keep safe (`chmod 400 travelmemory-key.pem`).
6. Network settings → create/select a **Security Group** with these inbound rules:
   | Type | Port | Source |
   |---|---|---|
   | SSH | 22 | Your IP only |
   | HTTP | 80 | 0.0.0.0/0 |
   | Custom TCP | 3000 | Security group of ALB / or 0.0.0.0/0 for testing |
7. Launch. Repeat for `backend-2`, `frontend-1` (for frontend open port 80 to 0.0.0.0/0, no need for 3000).

📸 **Screenshot:** EC2 "Launch an instance" summary page.
📸 **Screenshot:** Security group inbound rules table.
📸 **Screenshot:** EC2 instances list showing all instances in "running" state with their public IPs.

### 3.2 Connect via SSH
```bash
ssh -i travelmemory-key.pem ubuntu@<EC2_PUBLIC_IP>
```

📸 **Screenshot:** Terminal showing successful SSH login banner.

---

## 4. Step 2 — Backend Setup

Run this on **each backend instance** (`backend-1`, `backend-2`).

### 4.1 Install Node.js, npm, git, Nginx
```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y nodejs npm nginx git
node -v
npm -v
```
(If the Ubuntu repo Node version is too old, install via NodeSource:)
```bash
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs
```

### 4.2 Clone the repository
```bash
git clone https://github.com/UnpredictablePrashant/TravelMemory.git
cd TravelMemory/backend
npm install
```

📸 **Screenshot:** Terminal output of `npm install` completing without errors.

### 4.3 Configure the `.env` file
Create/edit the `.env` file in the backend directory:
```bash
nano .env
```
Add:
```
MONGO_URI=mongodb+srv://<username>:<password>@<cluster-url>/travelmemory?retryWrites=true&w=majority
PORT=3000
```
- Get `MONGO_URI` from MongoDB Atlas → Database → Connect → "Connect your application".
- Confirm in `backend/index.js` (or `app.js`) that it reads `process.env.PORT` and `process.env.MONGO_URI`.

📸 **Screenshot:** MongoDB Atlas connection string page (blur/redact password).
📸 **Screenshot:** `.env` file contents (redact password before screenshot).

### 4.4 Run the backend with PM2 (keeps it alive, restarts on crash/reboot)
```bash
sudo npm install -g pm2
pm2 start index.js --name travelmemory-backend
pm2 startup
pm2 save
```
Verify it's running:
```bash
pm2 status
curl http://localhost:3000/
```

📸 **Screenshot:** `pm2 status` showing the process online.
📸 **Screenshot:** `curl` response from the backend root endpoint.

### 4.5 Configure Nginx as a reverse proxy (port 80 → 3000)
```bash
sudo nano /etc/nginx/sites-available/travelmemory-backend
```
Paste:
```nginx
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```
Enable and test:
```bash
sudo ln -s /etc/nginx/sites-available/travelmemory-backend /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl restart nginx
sudo systemctl enable nginx
```
Test from your own machine (not the EC2):
```bash
curl http://<BACKEND_PUBLIC_IP>/
```

📸 **Screenshot:** `sudo nginx -t` showing "syntax is ok" / "test is successful".
📸 **Screenshot:** Browser hitting `http://<BACKEND_PUBLIC_IP>/` and getting a response (JSON or "Cannot GET /" is fine — it proves the proxy reached Node).

**Repeat all of Section 4 on `backend-2`.**

---

## 5. Step 3 — Frontend Setup

Run this on **each frontend instance** (`frontend-1`).

### 5.1 Install Node/npm/Nginx (same as 4.1)

### 5.2 Clone repo and configure API URL
```bash
git clone https://github.com/UnpredictablePrashant/TravelMemory.git
cd TravelMemory/frontend/src
nano url.js
```
Update the base URL to point at your backend load balancer (set this up in Step 5 below) or, for initial testing, directly at one backend instance:
```javascript
export const baseUrl = "http://<BACKEND_PUBLIC_IP_OR_ALB_DNS>";
```
> Once your ALB is live, replace this with the ALB DNS name (or better, an API subdomain like `api.yourdomain.com` once Cloudflare is configured) and rebuild.

📸 **Screenshot:** `url.js` file contents showing the updated base URL.

### 5.3 Build the React app
```bash
cd ../
npm install
npm run build
```
This produces a `build/` folder with static files.

📸 **Screenshot:** Terminal showing `npm run build` completing with the "The build folder is ready to be deployed" message.

### 5.4 Serve the build with Nginx
```bash
sudo cp -r build/* /var/www/html/
```
(Or point Nginx's `root` directly at your build folder.) Edit Nginx default config:
```bash
sudo nano /etc/nginx/sites-available/default
```
Ensure:
```nginx
server {
    listen 80;
    server_name _;
    root /var/www/html;
    index index.html;

    location / {
        try_files $uri /index.html;
    }
}
```
```bash
sudo nginx -t
sudo systemctl restart nginx
```

📸 **Screenshot:** Browser showing the TravelMemory homepage loaded at `http://<FRONTEND_PUBLIC_IP>/`.

---

## 6. Step 4 — Verify Frontend↔Backend Communication

1. Open `http://<FRONTEND_PUBLIC_IP>/` in a browser.
2. Try an action that hits the API (e.g., viewing/adding a trip memory).
3. Open browser DevTools → Network tab → confirm API calls go to your backend URL and return 200 responses.

📸 **Screenshot:** DevTools Network tab showing a successful API call (status 200) to the backend.
📸 **Screenshot:** The application successfully displaying data fetched from the backend (e.g., a trip added and shown).

If calls fail, check:
- CORS is enabled in the backend (Express `cors()` middleware).
- Security group allows the traffic.
- `url.js` points to the correct address and app was rebuilt after edits.

---

## 7. Step 5 — Scaling: AMIs, Multiple Instances, Target Groups, Load Balancer

### 7.1 Create an AMI from your working backend instance
1. EC2 → select `backend-1` (fully configured and tested) → **Actions → Image and templates → Create image**.
2. Name: `travelmemory-backend-ami`.
3. Wait for the AMI to become available.

📸 **Screenshot:** AMI creation confirmation and the AMI listed as "available".

### 7.2 Launch backend-2 from the AMI (if not already done manually)
Launch a new instance choosing "My AMIs" → `travelmemory-backend-ami`. This guarantees identical configuration. Update its `.env` if needed (same DB, so usually no changes required).

### 7.3 Create a Target Group
1. EC2 → **Target Groups → Create target group**.
2. Target type: Instances.
3. Protocol: HTTP, Port: 80 (since Nginx reverse-proxies to 3000).
4. Health check path: `/` (or a lightweight health endpoint if the API has one).
5. Register `backend-1` and `backend-2` as targets.

📸 **Screenshot:** Target group with both backend instances showing status **healthy**.

### 7.4 Create the Application Load Balancer (ALB)
1. EC2 → **Load Balancers → Create Load Balancer → Application Load Balancer**.
2. Name: `travelmemory-alb`.
3. Scheme: internet-facing.
4. Listeners: HTTP:80 → forward to the target group created above.
5. Select at least 2 Availability Zones/subnets.
6. Security group: allow inbound 80 (and 443 if you add HTTPS) from 0.0.0.0/0.
7. Create. Note the **ALB DNS name**, e.g. `travelmemory-alb-123456789.us-east-1.elb.amazonaws.com`.

📸 **Screenshot:** ALB details page showing state "active" and the DNS name.
📸 **Screenshot:** Browser hitting `http://<ALB_DNS_NAME>/` and getting a valid response, proving the load balancer is distributing to backend targets.

### 7.5 (Optional but recommended) Frontend scaling
Repeat the AMI → launch → target group → ALB pattern for the frontend instances if you want the front end load-balanced too. Otherwise a single frontend instance behind Cloudflare's proxy/CDN is acceptable for this assignment, since Cloudflare itself provides caching and edge distribution for static assets.

---

## 8. Step 6 — Domain Setup with Cloudflare

Assume your domain is `yourdomain.com`.

### 8.1 Add site to Cloudflare
1. Cloudflare dashboard → **Add a site** → enter `yourdomain.com`.
2. Choose the Free plan.
3. Update your domain's nameservers (at your registrar) to the two Cloudflare nameservers shown.
4. Wait for Cloudflare to confirm the domain is active.

📸 **Screenshot:** Cloudflare dashboard showing the domain status as "Active".

### 8.2 Create DNS records
Go to **DNS → Records → Add record**.

**A record** — points your root/app domain at the frontend EC2 instance:
| Type | Name | Content | Proxy status |
|---|---|---|---|
| A | `@` (or `www`) | `<FRONTEND_PUBLIC_IP>` | Proxied |

**CNAME record** — points an API subdomain at the load balancer:
| Type | Name | Content | Proxy status |
|---|---|---|---|
| CNAME | `api` | `<ALB_DNS_NAME>` | Proxied |

📸 **Screenshot:** Cloudflare DNS records page showing both the A record and CNAME record configured.

### 8.3 Update the frontend to use the new API domain
Back on the frontend instance:
```bash
cd TravelMemory/frontend/src
nano url.js
```
```javascript
export const baseUrl = "https://api.yourdomain.com";
```
Rebuild and redeploy:
```bash
npm run build
sudo cp -r build/* /var/www/html/
```

📸 **Screenshot:** Site loading successfully at `https://yourdomain.com` with the browser address bar visible (showing the custom domain and Cloudflare padlock/SSL).
📸 **Screenshot:** DevTools Network tab showing API calls now going to `https://api.yourdomain.com`.

> Cloudflare provides free "Flexible" or "Full" SSL out of the box once proxied (orange cloud). For production, set SSL/TLS mode to **Full (strict)** and install a certificate on your EC2 instances (e.g., via Let's Encrypt/Certbot) for end-to-end encryption.

---

## 9. Step 7 — Security Best Practices

- Restrict SSH (port 22) security group rule to your IP only, not `0.0.0.0/0`.
- Never commit `.env` or MongoDB credentials to GitHub — add `.env` to `.gitignore`.
- Use IAM roles/least-privilege for anything touching AWS APIs.
- Enable Cloudflare SSL/TLS (Full or Full Strict) rather than leaving traffic unencrypted.
- Keep Node.js, npm packages, and Ubuntu packages patched (`sudo apt update && sudo apt upgrade`).
- Consider a Web Application Firewall (Cloudflare WAF) for basic protection against common attacks.
- Use PM2 or systemd (not just `node index.js` in a terminal) so the backend survives reboots/crashes.

---

## 10. Step 8 — Architecture Diagram (draw.io)

A ready-to-import diagram file is provided alongside this document: **`architecture-diagram.drawio`**.

To use it:
1. Go to https://app.diagrams.net (the current draw.io app).
2. **File → Open From → Device** and select `architecture-diagram.drawio`.
3. Adjust IPs/domain names to match your actual deployment.
4. Export as PNG/SVG (**File → Export as**) and embed the exported image into this document.

📸 **Screenshot:** Your final exported architecture diagram (paste it here).

---

## 11. Troubleshooting

| Symptom | Likely Cause | Fix |
|---|---|---|
| `curl` to backend times out | Security group blocks port | Open port 80/3000 for the right source |
| Frontend loads but data doesn't appear | Wrong `url.js` value, or CORS blocked | Fix URL, rebuild; enable `cors()` in Express |
| 502 Bad Gateway from Nginx | Node app not running | `pm2 status`, `pm2 restart travelmemory-backend` |
| ALB targets "unhealthy" | Health check path wrong, or Nginx not proxying correctly on port 80 | Verify `curl localhost:80` on the instance itself |
| Cloudflare shows "521 Web server is down" | Origin server down or wrong IP in A record | Verify instance is running, IP matches, port 80 open |
| Mixed content / SSL warnings | Cloudflare SSL mode mismatch | Set SSL/TLS mode to Full/Full-Strict |

---

## 12. Submission Checklist

- [ ] Backend running on 2+ EC2 instances, behind Nginx reverse proxy, managed by PM2.
- [ ] Frontend built and served via Nginx on EC2.
- [ ] `.env` configured with MongoDB URI and PORT (not committed to Git).
- [ ] `url.js` updated to point to backend/ALB/API domain.
- [ ] Target Group + Application Load Balancer configured and healthy.
- [ ] Cloudflare domain added; A record → frontend IP; CNAME → ALB DNS.
- [ ] Application fully functional at `https://yourdomain.com`.
- [ ] All screenshots captured and inserted into this document.
- [ ] Architecture diagram exported and embedded.
- [ ] Code pushed to your own GitHub repository (fork of TravelMemory with your config).
- [ ] This documentation (as PDF/Word) + repo link submitted via Vlearn.
