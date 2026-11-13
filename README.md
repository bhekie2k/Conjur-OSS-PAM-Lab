CyberArk Conjur Open Source PAM Lab

A self-hosted secrets management lab built on Docker and WSL2. Deploys CyberArk Conjur Open Source, designs an onboarding policy and a least privilege access model for three simulated applications, implements three different secret delivery patterns, and adds credential lifecycle operations and Kubernetes native authentication on top.

Every phase includes the problems encountered during the build and their root causes.

What this demonstrates
Deploying and operating a Conjur vault: policy design, RBAC permission scoping, audit logging.
Three patterns for getting a secret into an application, from the app holding the credential itself through to the application never seeing a credential at all.
Credential lifecycle operations: manual and automated rotation, revocation, break-glass access.
Kubernetes native workload identity: a pod authenticating to the vault using its own service account token.
Governance documentation mapped to ISO 27001, NIST SP 800-190, and CIS Docker Benchmark.
Architecture

Architecture diagram

Six containers form the vault stack (Conjur, Postgres, nginx, CLI client, pgAdmin, a test utility container), plus a standalone Secretless Broker container and a kind Kubernetes cluster bridged onto the same Docker network.

The three onboarding patterns
Pattern	Who authenticates	Does the app hold the secret?
Direct API	The application itself	Yes, in memory
Summon	A launcher process, at startup	Briefly, as an injected environment variable
Secretless Broker	A broker sitting in the connection path	No. The application connects to the broker believing it's the database

Each step removes the application further from the secret. The progression is the point.

Phases
Vault deployment — Conjur, Postgres, and nginx via Docker Compose, self-signed TLS, CLI authentication.
Policy design — three application branches, each scoped to a real function using a five-question framework:<br> i) What is this identity's real job?<br> ii) What systems does that job require it to reach, and how does it authenticate to each?<br> iii) For each secret, does the identity need to read the secret, use the secret, or change the secret?<br> iv) Who owns this identity, and who is responsible for its lifecycle?<br> v) If this identity is compromised, is the damage proportional to its job?
Application onboarding — direct API, Summon, and Secretless implementations.
Credential lifecycle — manual rotation (and the drift window it creates), automated rotation with a scoped rotation identity, revocation, and break-glass access with post-use key rotation.
Kubernetes JWT authentication — a pod authenticates to Conjur using its own service account token via the authn-jwt authenticator, built against CyberArk's own published reference architecture for this feature (see References below). No API key exists in the pod spec, environment, or a mounted secret at any point.
Governance documentation — security controls matrix, onboarding and rotation runbooks, key custody procedure, break-glass procedure, secret inventory, and access matrix.

Full write-up of each phase, including the specific errors hit and how they were diagnosed, is in /docs.

A few of the sharper findings
Conjur returns 404 Not Found, not 403 Forbidden, when an identity lacks permission on a secret. Deliberate: it prevents an attacker from confirming a path exists at all.
The Secretless Broker resolves credentials per connection. Rotating a credential requires no broker restart, but a revoked credential also takes effect on the very next connection attempt.
A JWT is not simply valid or invalid. It is validated against a specific set of claims (signature, issuer, audience), each of which can fail independently. An audience mismatch between the cluster's token and Conjur's expected value was the actual cause of an early 401 that looked, from the application side, identical to every other failure.
Self-signed certificate pinning is fragile by design. Every regeneration of the lab's certificate broke trust for the CLI and for the broker until it was explicitly re-pinned, which is the operational argument for CA-issued certificates with defined rotation in a real deployment.
References

The Kubernetes JWT authentication in Phase 5 follows CyberArk's own published documentation and reference implementation. It is not an independently derived approach.

JWT-based Kubernetes authentication — CyberArk's official Conjur OSS documentation. The policy structure used in this lab (service ID, the five authenticator variables, a consumer group, the !permit grant) follows their published example directly.
cyberark/conjur-authn-k8s-client — CyberArk's reference client implementation on GitHub.

CyberArk's own documentation explicitly flags the audience claim as a security consideration. The mismatch described above under sharper findings is the failure mode their documentation warns about.

Repository structure
Conjur-OSS-PAM-Lab/
├── docs/
│   ├── Conjur_Lab_Technical_Build_Record.pdf
│   ├── Conjur_Lab_Governance_Documentation.pdf
│   └── architecture.png
├── compose/          Docker Compose file for the vault stack
├── policies/         Conjur policy files (apps, rotation, break-glass, k8s authenticator)
│   └── lifecycle/    Revoke and restore policies from Phase 4
├── apps/             The three delivery patterns (direct API, Summon, Secretless) and secrets.yml for Summon
├── secretless/       Secretless Broker config
├── scripts/          Rotation script and the JWT demo
├── k8s/              Test pod spec for Phase 5
└── README.md
Stack

Docker, Docker Compose, WSL2, CyberArk Conjur OSS, Postgres, nginx, Summon, Secretless Broker, kind, Python (conjur-api SDK, psycopg2), Bash.

Scope and disclaimer

This is a local, single instance lab. Self-signed certificates, a manually generated data key, and fake credential values throughout. The governance documentation names the specific gaps between this build and a production-grade deployment (HA, real CA-issued certificates, external KMS/HSM, CyberArk CPM, SIEM integration).

Author

Bheki Nkomo — PAM and IAM professional, 20+ years in IT, currently focused on PAM/IAM engineering and identity governance.
