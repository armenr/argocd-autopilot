- Docker Desktop
- Brew
- `kubernetes.docker.internal` in /etc/ hosts --> pointing to 127.0.0.1
- export your GitHub username
- export a GitHub token
        ```sh
        export GIT_TOKEN=TOKEN
        export GITHUB_USER=USER
        ```

NOTES:

This REPO is the backbone of our new GitOps approach/flow, AND is the starting point for a significant "shift left" in the way 5K TechOps runs.

1. This repo was initially generated with argocd-autopilot (please check that out)
2. This repo is incomplete -- mostly a POC turning into an MVP
3. Have a look at the makefile to get an idea of what's happening here...

### Shit for Brew (lots of goodies in here, explore at will!)

Some of these are required for THIS repo.

Others are included because, in my not-so-humble-opinion, it would behoove any architect, engineer, or platform developer/operator to know about and leverage the wonderful tools in this list!

Please keep in mind, I hadn't had much hands-on time with k8s prior to this, so if my choices in tooling make me look like a newb, so be it. I like to be efficient, not write a 15-line bash command with "\" at the end of every bloody line, directly in my terminal.

🤓🤓🤓🤓🤓🤓🤓🤓🤓

```sh
brew install k3d argocd argo
brew install lazygit
brew tap vmware-tanzu/carvel
brew install vendir
brew install remake
brew install kuztomize
brew install --cask cakebrew
brew install kubeseal
brew install helm
brew install dive
brew install robscott/tap/kube-capacity
brew install kubectx
brew search octant
brew install boz/repo/kail
brew install --cask lens
brew install yq jq ytt
```

### Get started

```sh
make cluster            # K3d cluster serving up k3s goodness
make v-sync             # vendir sync (look up vendir, awesome!)
make v-manifests        # render custom templates from ytt overrides + vendir
make argo-bootstrap     # bootstrap argo completely
```

THIS will bootstrap a best-practices/opinionated argoCD-oriented GitOps repo for you

Access Argo right away with: https://kubernetes.docker.internal/argocd/

Go here --> https://argocd-autopilot.readthedocs.io/en/stable/

To observe what does a "new project/new environment/new application workflow" look like:

`argocd-autopilot project create testing`

`argocd-autopilot app create hello-world --app github.com/argoproj-labs/`

`argocd-autopilot/examples/demo-app/ -p testing --wait-timeout 2m`

### TEARDOWN/RESET

`make destroy` --> ALL resources will be dispatched to their doom, easily and quickly.