Here is the documentation in proper Markdown format:

# CSAN-Harbor Integration with EGI Check-in

This document outlines the steps performed to integrate a **CSAN-Harbor** deployment with the **EGI Check-in** AAI platform, hosted on a server provisioned via Scaleway. The goal is to enable federated authentication using EGI AAI for managing CSAN container artifacts in a secure and production-ready environment.

---

## 1. Server Provisioning on Scaleway

A virtual machine was deployed on **Scaleway** using the following automation script:

📜 [k8s-school/k8s-server](https://github.com/k8s-school/k8s-server)

This script automates the deployment of a Kubernetes-ready server environment, including basic OS hardening, Docker installation, and Kubernetes tooling.

---

## 2. DNS Configuration

The public IP address of the Scaleway server was registered in DNS under:

🌐 [https://csan-demo.fedcloud.fr/](https://csan-demo.fedcloud.fr/)

This hostname will serve the Harbor web interface and act as the endpoint for the OpenID Connect flow.

---

## 3. Service Registration on EGI AAI Federation

The service was registered in the **EGI AAI Federation** to allow OpenID Connect-based authentication. This was done via the EGI Check-in administration platform:

🔗 [EGI Check-in Services Registry](https://aai.egi.eu/federation/egi/services)

Relevant metadata and endpoints of the Harbor instance were submitted, including:

- EntityID
- Redirect URIs
- Client Name (e.g., `CSAN-Harbor`)
- Logo and Description

---

## 4. CSAN-Harbor Tooling Deployment

With the server and DNS in place, the CSAN-Harbor stack was deployed using the official tooling:

📜 [CSAN-hub/csan-harbor](https://github.com/CSAN-hub/csan-harbor)

Execution steps:

```bash
git clone https://github.com/CSAN-hub/csan-harbor
cd csan-harbor
./run-all.sh
````

This script deploys Harbor along with accompanying services such as Minio/S3 for image storage, nginx-controller for external access and, cert-manager to enable `Let's encrypt` support.

---

## 5. Harbor Initial Configuration

Once deployed, the Harbor instance was accessible at:

🌐 [https://csan-demo.fedcloud.fr/](https://csan-demo.fedcloud.fr/)

The **admin password** was immediately changed from the default via the Harbor web UI (https://csan-demo.fedcloud.fr/account/sign-in), as a security best practice.

---

## 6. OpenID Connect Integration with EGI Check-in

Federated authentication was configured in the Harbor UI:

* Go to **Administration > Configuration > Authentication**
* Select **OIDC** as the authentication mode
* Fill in the following fields:

| Parameter         | Value                                                          |
| ----------------- | -------------------------------------------------------------- |
| **Name**          | EGI Check-in                                                   |
| **OIDC Endpoint** | `https://aai-demo.egi.eu/auth/realms/egi`                      |
| **Scope**         | `openid,voperson_id,email,profile,entitlements,offline_access` |

### 🔐 Example Configuration Screenshot

![EGI OpenID Config Screenshot](https://raw.githubusercontent.com/CSAN-hub/csan-harbor/refs/heads/main/img/openid-config.png)

> ☑️ **Note:** The `offline_access` scope is required to allow Harbor to request long-lived refresh tokens.

---

## 7. TODO Configuration Backup

Once the OIDC setup was completed, the Harbor configuration was exported via:

```bash
docker exec -it harbor-core /bin/bash
cd /etc/harbor
cat harbor.yml > /data/backup/harbor-config-$(date +%F).yml
```

This ensures that the authentication configuration is recoverable.

---

## 🔒 TODO Security Considerations

* Use HTTPS with a valid TLS certificate (e.g., via Let's Encrypt)
* Regularly rotate client secrets associated with the EGI service
* Audit user access logs via Harbor's built-in logging features
* Use OIDC Group Claim Mapping to limit access based on entitlements or roles

---

## 📎 Related Links

* [CSAN-Harbor GitHub](https://github.com/CSAN-hub/csan-harbor)
* [Harbor Official Docs](https://goharbor.io/docs/)
* [EGI Check-in Documentation](https://docs.egi.eu/users/aai/check-in/)
* [OIDC Setup in Harbor](https://goharbor.io/docs/2.8.0/administration/configure-authentication/oidc/)

