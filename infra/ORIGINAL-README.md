# Infra Controller Stack

This directory contains the Podman Compose stack for the infra server controller plane.

## Services

- Semaphore UI
- PostgreSQL for Semaphore metadata

Semaphore's container image already includes the Ansible runtime used by the UI.
Kubespray also runs from that container runtime, using the writable `/tmp/semaphore/kubespray` workspace.

## Files

- `podman-compose.yml`: service definitions
- `.env.example`: local overrides for image tags, passwords, and mount paths

## Start

```bash
cp infra/.env.example infra/.env
podman-compose --env-file infra/.env -f infra/podman-compose.yml up -d
```

## Notes

- The repo is mounted into the Semaphore container at `/workspace/moi-k8s-cluster`.
- Semaphore reads playbooks from `/workspace/moi-k8s-cluster/playbooks`.
- Offline artifacts are mounted at `/srv/moi/artifacts`.
- Set `KUBESPRAY_SSH_PASSWORD` in `infra/.env` so Kubespray can log in to the control-plane nodes noninteractively.
- Kubespray runtime state is written under `/tmp/semaphore/kubespray`.
- Semaphore state and Postgres data are bound to `${SEMAPHORE_STORAGE_DIR:-/data/semaphore}` on the infra host.
- Build or load the custom Semaphore image `moi-semaphore:v2.17.37-ansible2.17` before starting the stack.
- Use `scripts/build-semaphore-image.sh` to build the image and save the tarball for offline staging.
- The Postgres image must already be available locally on the infra server.
- Generate `SEMAPHORE_ACCESS_KEY_ENCRYPTION` once and keep it stable for the life of the Semaphore database.