# kubectl completion
source <(kubectl completion bash)

alias k=kubectl
# kubectl completion for 'k' alias
complete -o default -F __start_kubectl k
# show current kubectl namespace or switch to another
alias kn='f() { [ "$1" ] && kubectl config set-context --current --namespace $1 || kubectl config view --minify | grep namespace | cut -d" " -f6 ; } ; f'
# show current kubectl context or switch to another
alias kx='f() { [ "$1" ] && kubectl config use-context $1 || kubectl config current-context ; } ; f'
# get events sorted by creation time
alias kevents="kubectl get events --sort-by='.metadata.creationTimestamp'"

# build image for arm64 and amd64 and push to repository
alias dockerpush="docker buildx build --push --platform linux/arm64/v8,linux/amd64"