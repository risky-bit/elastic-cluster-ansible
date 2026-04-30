# Semaphore UI — Compose stack

Source: adapted from a colleague's Kubespray/K8s deployment stack.
See `ORIGINAL-README.md` for the original.

## Status: NOT READY TO RUN

Two things must happen before this stack is usable for this project:

1. **Rename K8s references.** The Compose file uses paths and env vars
   from a Kubespray context (`/workspace/moi-k8s-cluster`,
   `KUBESPRAY_SSH_PASSWORD`, etc.). Rename to match this project before
   running, otherwise the mounts and naming will be confusing.

2. **Obtain the custom Semaphore image build script.** The Compose file
   references `moi-semaphore:v2.17.37-ansible2.17` — a custom build,
   not the stock image. The original README mentions
   `scripts/build-semaphore-image.sh` but it was not supplied. Get it
   from the original author before running this stack; do not run an
   opaque image in this environment.

## When ready

Used in Phase C, Step 9 of the project plan. Not before. CLI playbook
execution must work end-to-end first; a UI on top of broken automation
is worse than no UI.