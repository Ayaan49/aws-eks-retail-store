# Manual Deployment Guide

Every command below is meant to be typed and run one at a time, so you can see exactly what each step does. Nothing here is wrapped in a script.

---

# PART 1 — Prerequisites

Install locally: `aws` CLI, `terraform` (>= 1.10), `kubectl`, `helm`, `git`.

Run once to confirm AWS CLI is configured:
```bash
aws sts get-caller-identity
```
This should print your Account ID, User ID, and ARN. Write your Account ID down — you'll need it repeatedly below.

---

# PART 2 — One-Time Manual Setup

These must all be done before you run any command in Part 3. Skipping any of these will make a later step fail.

### 2.1 Replace the hardcoded AWS Account ID

The project files have the course instructor's AWS Account ID (`180789647333`) hardcoded in IAM policies, the CI workflow, and ingress cert ARNs. Find every file that has it:
```bash
grep -rl "180789647333" . --include="*.tf" --include="*.json" --include="*.yaml" --include="*.yml"
```
Open each file this lists and replace `180789647333` with your own Account ID.

### 2.2 Create your own Terraform state bucket

```bash
aws s3api create-bucket --bucket YOUR-BUCKET-NAME --region us-east-1
aws s3api put-bucket-versioning --bucket YOUR-BUCKET-NAME --versioning-configuration Status=Enabled
```
Then replace the placeholder bucket name in every Terraform backend/remote-state block:
```bash
grep -rl "tfstate-dev-us-east-1-jpjtof" terraform/
```
Open each file this lists and replace `tfstate-dev-us-east-1-jpjtof` with `YOUR-BUCKET-NAME`.

### 2.3 Create the AWS Secrets Manager secret

Terraform reads this secret — it does not create it. This must exist before you touch `terraform/data-plane/`.
```bash
aws secretsmanager create-secret \
  --name retailstore-db-secret-1 \
  --secret-string '{"username":"retailadmin","password":"ChangeMe123!"}' \
  --region us-east-1
```
Note: `catalog` and `orders` both reference this same secret name as shipped. That's fine to run as-is.

### 2.4 Create the ECR repository for `ui`

Only `ui` gets built by this project's CI pipeline — the other 4 services pull pre-built public images, so they need no ECR setup.
```bash
aws ecr create-repository --repository-name retail-store/ui --region us-east-1
```

### 2.5 Set up GitHub OIDC (so GitHub Actions can push to your ECR without stored AWS keys)

Create the OIDC identity provider (skip this specific command if your AWS account already has one):
```bash
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea
```

Open `iam/github-actions-oidc-trust-policy.json` and replace `stacksimplify/aws-devops-github-actions-ecr-argocd3` with `your-github-username/your-repo-name`.

Create the role:
```bash
aws iam create-role \
  --role-name github-actions-oidc-role-ui3 \
  --assume-role-policy-document file://iam/github-actions-oidc-trust-policy.json
```

Attach ECR push permissions:
```bash
aws iam attach-role-policy \
  --role-name github-actions-oidc-role-ui3 \
  --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser
```

### 2.6 Point the CI workflow at your own role

Open `.github/workflows/build-push-ui.yaml`. Confirm the `role-to-assume:` line reads your Account ID and role name (Step 2.1's find-replace should have already updated the Account ID part — double check the role name matches `github-actions-oidc-role-ui3`).

### 2.7 Point ArgoCD at your own fork

Push this whole project to your own GitHub repo first if you haven't already. Then open `argocd/application-ui.yaml` and change:
```yaml
repoURL: https://github.com/your-github-username/your-repo-name.git
```

---

# PART 3 — Commands to Run, In Order

### 3.1 Provision the VPC

```bash
cd terraform/vpc
terraform init
terraform apply
```
Type `yes` when prompted. Wait for it to finish.

### 3.2 Provision the EKS cluster + core add-ons

This one step creates the EKS cluster itself, plus the AWS Load Balancer Controller, EBS CSI Driver, Secrets Store CSI Driver, ExternalDNS, and Metrics Server — all as EKS add-ons.
```bash
cd ../eks-cluster
terraform init
terraform apply
```

### 3.3 Point kubectl at your new cluster

```bash
aws eks update-kubeconfig --region us-east-1 --name eksdemo1
kubectl get nodes
```
You should see your node(s) listed.

### 3.4 Provision Karpenter, OpenTelemetry, and the data plane

These three are independent of each other — run them in any order.
```bash
cd ../karpenter
terraform init
terraform apply
```
```bash
cd ../opentelemetry
terraform init
terraform apply
```
```bash
cd ../data-plane
terraform init
terraform apply
```
This last one creates your RDS MySQL, RDS Postgres, DynamoDB table, ElastiCache Redis, and SQS queue.

```bash
cd ../..
```
(back to your project root)

### 3.5 Apply the Karpenter node configuration

```bash
kubectl apply -f kubernetes/karpenter/01_ec2nodeclass.yaml
kubectl apply -f kubernetes/karpenter/02_nodepool_ondemand.yaml
kubectl apply -f kubernetes/karpenter/03_nodepool_spot.yaml
```

### 3.6 Apply the OpenTelemetry pipeline configuration

```bash
kubectl apply -f kubernetes/opentelemetry/01_adot_collector_traces.yaml
kubectl apply -f kubernetes/opentelemetry/01_adot_collector_logs.yaml
kubectl apply -f kubernetes/opentelemetry/01_adot_collector_prometheus_full_k8s_cluster.yaml
kubectl apply -f kubernetes/opentelemetry/02_adot_instrumentation_traces.yaml
```

### 3.7 Deploy `catalog`, `cart`, `checkout`, `orders` via Helm

First, add the chart repository (one-time, adds a local nickname pointing at Kalyan's published chart repo):
```bash
helm repo add stacksimplify https://stacksimplify.github.io/helm-charts
helm repo update
```

Then run each install one at a time, from inside `helm/values/low-cost/`:
```bash
cd helm/values/low-cost
```

```bash
helm upgrade --install catalog stacksimplify/retail-store-sample-catalog-chart \
  --version 2.0.0 \
  -f values-catalog-v2.0.0.yaml \
  --wait --timeout 5m
```
```bash
helm upgrade --install carts stacksimplify/retail-store-sample-cart-chart \
  --version 1.0.0 \
  -f values-cart.yaml \
  --wait --timeout 5m
```
```bash
helm upgrade --install checkout stacksimplify/retail-store-sample-checkout-chart \
  --version 1.0.0 \
  -f values-checkout.yaml \
  --wait --timeout 5m
```
```bash
helm upgrade --install orders stacksimplify/retail-store-sample-orders-chart \
  --version 2.0.0 \
  -f values-orders-v2.0.0.yaml \
  --wait --timeout 5m
```

Check what got deployed:
```bash
helm list
kubectl get pods
```

```bash
cd ../../..
```
(back to your project root)

### 3.8 Install ArgoCD

```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl rollout status deployment argocd-server -n argocd --timeout=120s
```

Get the admin password:
```bash
kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 --decode
```
Copy that password.

Open the UI:
```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```
Go to `https://localhost:8080` in your browser. Username `admin`, password from above.

### 3.9 Deploy `ui` via ArgoCD — this is where the automation kicks in

```bash
kubectl apply -f argocd/application-ui.yaml
```
This alone creates the ArgoCD `Application` object. From this point on, ArgoCD takes over `ui` completely — it pulls the chart from your fork's `app/ui/chart` path, deploys it, and re-checks your repo every ~2 minutes for changes, auto-syncing anything it finds. You did nothing else manually for `ui` from here on.

You can watch it happen in the UI you opened above, or via:
```bash
kubectl get application ui -n argocd
kubectl get pods -l app.kubernetes.io/name=ui
```

### 3.10 Trigger your first CI build (optional, to see the whole pipeline fire)

Make any small change under `app/ui/src/`, then:
```bash
git add .
git commit -m "test CI pipeline"
git push
```
Go watch the Actions tab on your GitHub repo — it builds the image, pushes to your ECR, and commits the new image tag back into `app/ui/chart/values-ui.yaml`. Within about 2 minutes, ArgoCD picks up that commit and redeploys `ui` — with zero further commands from you.

### 3.11 Verify everything is live

```bash
kubectl get ingress
```
Open the address shown in a browser — that's your running app.

---

# PART 4 — The One-Command Shortcut (separate, optional)

Everything in **Section 3.7** above (the 4 `helm upgrade --install` commands) is exactly what's already written, in the same order, inside:
```
helm/values/low-cost/05-v2.0.0-install-remote-helm-charts.sh
```
If you ever want the convenience version instead of typing those 4 commands by hand, you can just run:
```bash
cd helm/values/low-cost
chmod +x 05-v2.0.0-install-remote-helm-charts.sh
./05-v2.0.0-install-remote-helm-charts.sh
```
It does the identical 4 installs, plus prints a summary (`helm list`, `kubectl get pods/svc/ingress`) at the end. Nothing different happens on your cluster either way — it's the same commands, just typed for you.

---

# Tearing it down (reverse order)

```bash
helm uninstall catalog carts checkout orders
kubectl delete -f argocd/application-ui.yaml

cd terraform/data-plane    && terraform destroy && cd ../..
cd terraform/opentelemetry && terraform destroy && cd ../..
cd terraform/karpenter     && terraform destroy && cd ../..
cd terraform/eks-cluster   && terraform destroy && cd ../..
cd terraform/vpc           && terraform destroy && cd ../..
```
Also manually delete the Secrets Manager secret, the ECR repo, and the S3 state bucket if you want a fully clean AWS account afterward.
