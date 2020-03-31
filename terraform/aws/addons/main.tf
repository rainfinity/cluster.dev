provider "helm" {
}

# Check for kubeconfig and update resources when cluster gets re-created.
resource "null_resource" "kubeconfig_update" {
  triggers = {
    policy_sha1 = "${sha1(file("~/.kube/config"))}"
  }
}

# Create Namespace for External DNS
resource "kubernetes_namespace" "external-dns" {
  metadata {
    name = "external-dns"
  }
}

data "helm_repository" "bitnami" {
  name = "bitnami"
  url  = "https://charts.bitnami.com/bitnami"
}

resource "helm_release" "external-dns" {
  name       = "external-dns"
  repository = data.helm_repository.bitnami.metadata[0].name
  chart      = "external-dns"
  version    = "2.20.10"
  namespace  = "external-dns"

  values = [
    file("external-dns-values.yaml")
  ]
  depends_on = [
    null_resource.kubeconfig_update,
  ]
  set {
    name  = "aws.region"
    value = var.aws_region
  }
}

# Create Namespace for Cert Manager
resource "kubernetes_namespace" "cert-manager" {
  metadata {
    name = "cert-manager"
  }
}

data "helm_repository" "jetstack" {
  name = "jetstack"
  url  = "https://charts.jetstack.io"
}

resource "helm_release" "cert-manager" {
  name       = "cert-manager"
  repository = data.helm_repository.jetstack.metadata[0].name
  chart      = "cert-manager"
  version    = "v0.1.0"
  namespace  = "cert-manager"

  values = [
    file("cert-manager-values.yaml")
  ]
  depends_on = [
    null_resource.kubeconfig_update,
  ]
}
