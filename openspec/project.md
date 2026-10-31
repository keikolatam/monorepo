# Proyecto: Keiko Latam — dapp-monorepo

**Plataforma de colaboración educativa descentralizada (DApp).** Transforma el aprendizaje en capital humano verificable: cada **LearningInteraction atómica** (estándar xAPI/Tin Can) se registra en la **Keikochain** (appchain L3 sobre Starknet/Madara) y construye el **LifeLearningPassport** del aprendiz — inmutable, públicamente verificable, infalsificable.

## Stack

- **Frontend:** Flutter/Dart (`apps/mobile`), UI compartida en `packages/keiko_ui` (Atomic Design + Material 3).
- **Backend:** Rust modular (`apps/backend`), GraphQL (`apps/api-gateway`), gRPC (`apps/grpc-gateway`), Redis Streams.
- **Appchain:** Cairo/Starknet vía Madara (`apps/appchain`). Ver [[keiko-appchain-starknet]] (memoria). Decisión: Starknet, no Polkadot.
- **Agentes IA:** `agentic-core` (librería Python) consumida como **adapter** en `apps/coach-sidecar` (NO fork). Precedente: `altrupets/apps/agent-sidecar`.

## Arquitectura

**Explicit Architecture** (DDD + Hexagonal + Onion + Clean + CQRS — Herberto Graça) en backend y mobile. Código compartido en `libs/{domain,application,adapters,proto}` (precedente: aduanext). El dominio es puro; los transportes (WebSocket/GraphQL/Starknet RPC) son adapters de infraestructura.

## Convención de monorepo

`apps/{mobile,backend,api-gateway,grpc-gateway,appchain,coach-sidecar,widgetbook}` + `packages/<x>_ui` + `libs/{domain,application,adapters,proto}`. Root `Makefile`. Consistente con vertivo/altrupets/aduanext/habitanexus.

## Proceso

Diseño vía brainstorming → OpenSpec change (proposal/design-ADRs/tasks/specs) → issues en GitHub vía `/make-no-mistakes:spike-recommend` (épica) + `/make-no-mistakes:spec-recommend` (sub-issues). **PRs de migración pasan por `/make-no-mistakes:domain-driven-advisor` antes de merge.**
