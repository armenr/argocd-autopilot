# Recitals
.ONESHELL:
.PHONY : \
    argo-bootstrap \
    argo-deprovision \
    cluster \
    destroy \
    install-cert-manager \
    install-sealed-secrets \
    sealed-secrets-generator-aws \
    v-manifests \
	v-sync

# Vars
CHDIR_SHELL := $(SHELL)
AWS_ACCESS_KEY_ID := $(aws configure get default.aws_access_key_id)
AWS_SECRET_ACCESS_KEY := $(aws configure get default.aws_secret_access_key)
CLUSTER_ID := $(whoami)

define chdir
	$(eval _D=$(firstword $(1) $(@D)))
	$(info $(MAKE): cd $(_D)) $(eval SHELL = cd $(_D); $(CHDIR_SHELL))
endef

install-argocd:
	kubectl create namespace argocd && \
	kustomize build bootstrap/argo-cd | kubectl apply -f - &&\
	kubectl apply -f bootstrap/argo-cd.yaml && kubectl apply -f bootstrap/root.yaml && \
	kubectl -n argocd create secret generic autopilot-secret \
		--from-literal git_username=$GITHUB_USER \
		--from-literal git-token=$GIT_TOKEN

kustomize-argo-workflows:
	kubectl create namespace argo && \
	kustomize build bootstrap/argo-workflows | kubectl apply -f -

install-argo-workflows:
	kubectl create namespace argo && \
	helm upgrade --install \
		argo-workflows argo/argo-workflows \
		--namespace argo \
		--create-namespace \
		--set server.base.href="/workflows/" \
		--set server.extraArgs="{--auth-mode=server}" \
		--wait

bootstrap-argo-stack:
	$(MAKE) install-cert-manager
	$(MAKE) v-sync
	$(MAKE) v-manifests
	$(MAKE) argo-workflows-install
	$(MAKE) argocd-install
	# @[ "$(GITHUB_USER)" ] || $(call log_error, "GITHUB_USER not set!")
	# @[ "$(GIT_TOKEN)" ] || $(call log_error, "GIT_TOKEN not set!")

# bootstrap argo locally
argo-bootstrap-old:
	$(MAKE) install-cert-manager
	$(MAKE) install-sealed-secrets
	$(MAKE) v-sync
	$(MAKE) v-manifests
	# @[ "$(GITHUB_USER)" ] || $(call log_error, "GITHUB_USER not set!")
	# @[ "$(GIT_TOKEN)" ] || $(call log_error, "GIT_TOKEN not set!")

# remove argo and all traces
argo-deprovision:			# TODO
	echo "nope!"

# spin up k3s cluser via k3d
cluster:
	k3d cluster create local-$(USER) --config ./assets/k3d_local.yaml
	$(MAKE) install-cert-manager

# destroy all the things
destroy:
	k3d cluster delete local-$(USER)

install-cert-manager:
	helm upgrade --install \
    cert-manager \
    jetstack/cert-manager \
    --namespace cert-manager \
    --create-namespace \
    --set installCRDs=true\
    --wait

install-sealed-secrets:
	helm upgrade --install \
    cert-manager \
    jetstack/cert-manager \
    --namespace cert-manager \
    --create-namespace \
    --set installCRDs=true\
    --wait

sealed-secrets-generate-aws:
	kubectl --namespace argocd \
    create secret generic aws-creds \
    --from-file creds=./aws-creds.conf \
    --output json \
    --dry-run=client \
    | kubeseal \
    --controller-namespace argocd \
    --controller-name sealed-secrets \
    --format yaml \
    | tee crossplane/configs/config-aws-creds.yaml

# auto-gen dependent manifests via vendir + YTT
v-manifests:
	$(call chdir,dependencies)
	../assets/scripts/kustomize-generate-manifests.sh

# sync external manifests & charts
v-sync:
	$(call chdir,dependencies)
	vendir sync

kapp-deploy-argo-workflows-server:
	kapp deploy \
		-a argo-workflows \
		-n kube-system \
		-f <'('helm template  --values my-vals.yml')'

# kapp deploy -n argo -a argo-workflows -f <(kustomize build bootstrap/argo-workflows) --diff-changes
# kapp deploy -n argo -a argo-workflows -f <(helm template argo-workflows --repo https://argoproj.github.io/argo-helm argo-workflows)
# $kapp deploy -a my-chart -f <(helm template my-chart --values my-vals.yml)


# kapp -y deploy -a argo-workflows -f <(helm template argo-workflows --repo https://argoproj.github.io/argo-helm argo-workflows \
#     --set server.ingress.hosts="{kubernetes.docker.internal}" \
#     --set server.ingress.paths="{/workflows}" \
#     --set server.ingress.enabled=true
#     --set server.extraArgs="{--auth-mode=server}" \
# )

# kapp deploy -a argo-workflows -f https://raw.githubusercontent.com/argoproj/argo-workflows/master/manifests/quick-start-postgres.yaml
