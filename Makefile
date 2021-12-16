# export OVERLAY_PATH ?= $(APP_ROOT)/k8s/overlays/$(STAGE)/

# define kustomize-image-edit
#     cd $(OVERLAY_PATH) && kustomize edit set image api=$(1) && \
#     cd $(APP_ROOT)
# endef

k-apply:
    kustomize build $(OVERLAY_PATH)
    kustomize build $(OVERLAY_PATH) | kubectl apply -f -

# kustomize-edit:
#     $(call kustomize-image-edit,$(TARGET_IMAGE_LATEST))

