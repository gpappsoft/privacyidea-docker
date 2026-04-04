# Tekton pipeline resources

This directory contains the project-local Tekton resources for building and
pushing the `privacyidea-docker` image.

## Apply the base resources

```bash
kubectl apply -k .tekton/
```

This installs:

- namespace `privacyidea-ci`
- service account `image-builder`
- task `git-clone-simple`
- task `kaniko-build-push`
- pipeline `build-image`

## Create the required secrets

Copy and adapt these example files before applying them:

- `github-auth-secret.example.yaml`
- `ghcr-auth-secret.example.yaml`

Create local copies without the `.example` suffix and then apply them:

```bash
cp .tekton/github-auth-secret.example.yaml .tekton/github-auth-secret.yaml
cp .tekton/ghcr-auth-secret.example.yaml .tekton/ghcr-auth-secret.yaml
kubectl apply -f .tekton/github-auth-secret.yaml
kubectl apply -f .tekton/ghcr-auth-secret.yaml
```

The service account already references both secrets. The generated `*-secret.yaml`
files should stay local and are ignored by git.

## Start a build manually

```bash
kubectl create -f .tekton/run-build-image.example.yaml
```

Useful follow-up commands:

```bash
tkn pipelinerun list -n privacyidea-ci
tkn pipelinerun logs -f -n privacyidea-ci
kubectl get pods -n privacyidea-ci
```
