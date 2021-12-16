.PHONY : ygen vsync argo-bootstrap install-cert-manager argo-deprovision cluster

CHDIR_SHELL := $(SHELL)

define chdir
   $(eval _D=$(firstword $(1) $(@D)))
   $(info $(MAKE): cd $(_D)) $(eval SHELL = cd $(_D); $(CHDIR_SHELL))
endef

# spin up k3s cluser via k3d
cluster:
	 k3d cluster create --config k3d_local.yaml

# destroy all the things
destroy:
	k3d cluster delete local-argo-autopilot

# auto-gen dependent manifests via vendir + YTT
v-manifests:
	$(call chdir,dependencies)
	../scripts/ytt-generate-manifests.sh

# sync external manifests & charts
v-sync:
	$(call chdir,dependencies)
	vendir sync

# bootstrap argo locally
argo-bootstrap:
	@[ "$(GITHUB_USER)" ] || $(call log_error, "GITHUB_USER not set!")
	@[ "$(GIT_TOKEN)" ] || $(call log_error, "GIT_TOKEN not set!")
	$(call chdir,dependencies)
	kubectl create namespace argocd
	kustomize build bootstrap/argo-cd | kubectl apply -f -
	kubectl apply -f bootstrap/argo-cd.yaml && kubectl apply -f bootstrap/root.yaml
	kubectl -n argocd create secret generic autopilot-secret \
		--from-literal git_username=$GITHUB_USER \
		--from-literal git-token=$GIT_TOKEN

argo-deprovision:
	@[ "$(GITHUB_USER)" ] || $(call log_error, "GITHUB_USER not set!")
	@[ "$(GIT_TOKEN)" ] || $(call log_error, "GIT_TOKEN not set!")
	$(call chdir,dependencies)
	kubectl create namespace argocd
	kustomize build bootstrap/argo-cd | kubectl apply -f -
	kubectl -n argocd create secret generic autopilot-secret \
		--from-literal git_username=$GITHUB_USER \
		--from-literal git-token=$GIT_TOKEN
	kubectl apply -f bootstrap/argo-cd.yaml && kubectl apply -f bootstrap/root.yaml

install-cert-manager:
	helm upgrade --install \
    cert-manager \
    jetstack/cert-manager \
    --namespace cert-manager \
    --create-namespace \
    --set installCRDs=true\
    --wait

# export OVERLAY_PATH ?= $(APP_ROOT)/k8s/overlays/$(STAGE)/
# define kustomize-image-edit
#     cd $(OVERLAY_PATH) && kustomize edit set image api=$(1) && \
#     cd $(APP_ROOT)
# endef

# k-apply:
#     kustomize build $(OVERLAY_PATH)
#     kustomize build $(OVERLAY_PATH) | kubectl apply -f -


# 	#!/bin/bash
# set -ex

# vendir sync --locked

# # clean previously rendered files
# rm -rf ./deploy/rendered

# while IFS= read -r -d '' app_directory ; do
#   app_name="$(basename "$app_directory")"

#   mkdir "./deploy/rendered/$app_name" \
#     --parents

#   # render Helm templates if Chart.yaml file is found
#   SYNCED_DIR="./deploy/synced/$app_name"
#   if [ -f "./deploy/synced/$app_name/Chart.yaml" ]; then
#     tmp_helm_rendered="$(mktemp --suffix .yaml)"
#     helm template "$app_name" "./deploy/synced/$app_name" > "$tmp_helm_rendered"

#     SYNCED_DIR="$tmp_helm_rendered"
#   fi

#   ytt \
#     --file "$SYNCED_DIR" \
#     --file "./deploy/overlays/$app_name" \
#   > "./deploy/rendered/$app_name/deploy.yaml"

# done < <(find ./deploy/synced/* -maxdepth 0 -type d -print0)

# kapp app-group deploy \
#   --directory ./deploy/rendered \
#   --group dev \
#   --yes
