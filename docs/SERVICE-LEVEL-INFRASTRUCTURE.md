
# Service-level infrastructure (networking)

This document describes the **service-level networking diagram** for the Pilot-HDC platform: which services exist, how they communicate, and which **external systems** the platform depends on.

![`docs/Networking diagram at service level.png`](service-level-diagram.png)

## Legend / connection types

The diagram uses different line styles/colors to distinguish common connection types. At a high level:

- **Service HTTP connections**: asynchronous REST/HTTP calls between microservices.
- **BFF proxy connections**: Portal/CLI traffic proxied through dedicated Backend-For-Frontend services.
- **PostgreSQL connections**: services persisting operational data.
- **Kafka connections**: event streaming / pub-sub patterns.
- **RabbitMQ connections**: messaging / job queues.
- **Redis connections**: caching, short-lived state, and/or queue coordination.
- **Elasticsearch connections**: search indexing and querying.
- **MinIO connections**: S3-compatible object storage (uploads/downloads, artifacts).

## Main traffic entrypoints

The diagram shows two primary clients and their dedicated entry services:

### Portal → BFF Web Service

- The **Portal** (browser UI) talks to the platform through the **Backend-For-Frontend (BFF) Web Service**.
- The BFF aggregates calls and provides a UI-friendly API surface, then dispatches requests to internal domain services.

### CLI → BFF CLI Service

- The **CLI** connects through a separate **BFF CLI Service**.
- This separation allows different authentication and routing needs (e.g., long-running operations, file workflows) while keeping internal services protected from direct external access.

## Core internal services (high-level roles)

The diagram groups a set of microservices that implement the Pilot-HDC platform. Names below match the diagram labels.

### Identity & access

- **Auth Service**: internal authentication/authorization logic used by backend services.
- **Keycloak (internal)**: platform IAM in-cluster, used by Portal/CLI and services.

Keycloak also connects to an external federated identity provider (see “External connections”).

### Project / metadata domain services

- **Project Service**: project lifecycle, membership, and project-scoped operations.
- **Metadata Service**: metadata CRUD, integration with downstream indexing and events.
- **Dataset Service**: dataset lifecycle management.
- **Approval Service**: approvals / governance workflows.

### Data movement services

- **Upload Service**: ingest data (often into MinIO) and coordinate metadata updates.
- **Download Service**: serve data back to users/services and enforce access checks.
- **Pipelines Filecopy**: file copy/transfer tasks used by pipeline workflows.

### Pipelines / operations

- **PipelineWatch Service**: monitors pipeline execution/state.
- **Pipelines Bids Validator**: validates BIDS compliance (domain-specific validation step).
- **Dataops Service**: operational workflows that can span multiple domain services.

### Search and lineage

- **Search Service**: queries Elasticsearch and/or triggers indexing.
- **Lineage Service**: captures lineage/provenance across operations.
- **Audit Trail Service**: records security/audit events.

### Integration services

- **KG Integration Service**: integrates platform metadata with the EBRAINS Knowledge Graph.
- **Metadata Event Handler**: reacts to domain events and triggers downstream actions.

### Queue services

The queue services shown in the diagram represent a common pattern:

- **Queue Service Producer**: publishes messages/events.
- **Queue Service Consumer**: consumes and processes messages.
- **Queue Service SocketIO**: pushes asynchronous status updates to the UI (e.g., progress notifications).

## Shared platform dependencies (data plane)

The following shared components are used across many services:

- **PostgreSQL DB**: primary relational datastore for operational data.
- **MinIO**: object storage (S3-compatible), used for uploads/downloads and artifacts.
- **Kafka**: event streaming for service-to-service event propagation.
- **RabbitMQ**: message queue for asynchronous workloads.
- **Redis**: cache and/or coordination for background processing.
- **Elasticsearch**: indexing/search backend.
- **Atlas**: metadata catalog component (shown as a shared dependency in the diagram).
- **Email Server**: outbound notifications (used by Notification Service and/or system alerts).

## Typical end-to-end flows (examples)

### 1) Portal login and API access

1. Portal authenticates against **Keycloak** (internal).
2. Keycloak may federate the login to **EBRAINS Keycloak** (external) depending on configured identity providers.
3. Portal calls the **BFF Web Service** with an access token.
4. BFF calls internal services (Project/Metadata/Dataset/etc.) over HTTP.

### 2) Upload data

1. Portal/CLI → BFF → **Upload Service**.
2. Upload Service stores blobs into **MinIO** and writes records to **PostgreSQL**.
3. Upload triggers events (Kafka/RabbitMQ), handled by **Metadata Event Handler**.
4. Handler updates **Elasticsearch** (via Search/Metadata services) and optionally updates **Lineage/Audit Trail**.

### 3) Search

1. Portal → BFF → **Search Service**.
2. Search Service queries **Elasticsearch** and returns results.

### 4) Knowledge Graph synchronization

1. Domain changes emit events.
2. **KG Integration Service** consumes events and communicates with **EBRAINS Knowledge Graph** (external).

## External connections (existing)

The platform relies on the following **external EBRAINS services**. They are not represented in the diagram.

### EBRAINS Keycloak

- **What it is**: EBRAINS Identity and Access Management system.
- **Why we connect**: provides account management for the Pilot-HDC **Portal** via identity federation.
- **How it is used**: internal Keycloak is configured with EBRAINS Keycloak as an external identity provider.

### EBRAINS Collaboratory

- **What it is**: management system for *Collabs*.
- **Why we connect**: Collabs are used to access and manage **Knowledge Graph spaces**.
- **How it is used**: platform services that manage projects/spaces may call Collaboratory APIs to resolve memberships/permissions and to relate Pilot-HDC projects to EBRAINS Collabs.

### EBRAINS Knowledge Graph

- **What it is**: the EBRAINS Knowledge Graph services.
- **Why we connect**: used for Knowledge Graph Integration.
- **How it is used**: the **KG Integration Service** (and supporting services) communicates with the Knowledge Graph APIs to publish and query KG entities.

### EBRAINS Harbour Docker Registry

- **What it is**: Docker registry for storing and managing container images.
- **Why we connect**: used to store and manage Docker images for building and deployment of Pilot-HDC services to the cluster.
- **How it is used**:
  - CI pipelines push images to Harbour.
  - Kubernetes pulls images from Harbour during deployment/rollouts.

