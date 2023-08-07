---
title: "Practical Policy Enforcement with CUE"
aliases:
  - ../2023/06/06/practical-policy-enforcement-with-cue
date: 2023-06-06T00:00:00Z
draft: false
---

I have been using [CUE](https://cuelang.org/) for over 2 years and I’ve found it to be incredibly good at defining policies. CUE is an elegant configuration language because of the guarantees that it can express. It has many additional uses such as applying policies on existing configurations, whether they are written in CUE or in another format like JSON or YAML. Let’s take a look at some easy and practical policy enforcement applications for CUE for Kubernetes, OpenAPI and Terraform.

# Kubernetes

I have been writing Kubernetes configurations in CUE, so applying policies here feels most natural. Let’s go through an example of applying a policy to a Kubernetes configuration written in CUE. Note that this does not result in a completely valid Kubernetes deployment specification, but it is sufficient to demonstrate policy application.

```cue
deployment: [ID=_]: {
    apiVersion: "apps/v1"
    kind:       "Deployment"
}
 
deployment: load_balancer: {
  metadata: name: "load_balancer"
  spec: template: spec: containers: [
    {
      name: "main"
      image: "nginx:latest"
    }
  ]
}
 
deployment: backend: {
  metadata: name: "backend"
  spec: template: spec: containers: [
    {
      name: "main"
      image: "python:latest"
    }
  ]
}
```

You can see it in action here: https://cuelang.org/play/?id=HScoWLip5-9#cue@export@yaml

If we render this configuration, the resulting YAML is as follows:

```yaml
deployment:
  load_balancer:
    metadata:
      name: load_balancer
    apiVersion: apps/v1
    spec:
      template:
        spec:
          containers:
            - name: main
              image: nginx:latest
    kind: Deployment
  backend:
    metadata:
      name: backend
    apiVersion: apps/v1
    spec:
      template:
        spec:
          containers:
            - name: main
              image: python:latest
    kind: Deployment
```

To deploy this, you need to transform this structure into YAML documents and apply them using kubectl apply. This process is pretty straightforward, so we won’t cover it.

Now, let’s say we want to apply some policies to this configuration. One simple policy is to ensure that all pods have a read-only filesystem. We can modify our deployment definition as follows:

```cue
deployment: [ID=_]: {
    apiVersion: "apps/v1"
    kind:       "Deployment"
    spec: template: spec: containers: [...{
        securityContext: readOnlyRootFilesystem: true
    }]
}
```

Amazingly, this not only requires the containers to have a read-only filesystem, but it actually generates the config needed to make it happen. You can see it in action here: https://cuelang.org/play/?id=HbEvTNMOU5j#cue@export@yaml

The output is:

```yaml
deployment:
  load_balancer:
    metadata:
      name: load_balancer
    apiVersion: apps/v1
    kind: Deployment
    spec:
      template:
        spec:
          containers:
            - name: main
              securityContext:
                readOnlyRootFilesystem: true
              image: nginx:latest
  backend:
    metadata:
      name: backend
    apiVersion: apps/v1
    kind: Deployment
    spec:
      template:
        spec:
          containers:
            - name: main
              securityContext:
                readOnlyRootFilesystem: true
              image: python:latest
```

The next policy is more complex. We want to ensure that if pods have only one replica, they use the Recreate deployment strategy. If they have more than one replica, they should use the RollingUpdate strategy. We can express this policy as follows:

```cue
deployment: [ID=_]: {
    apiVersion: "apps/v1"
    kind:       "Deployment"
    spec: {
        replicas: *1 | uint
        if replicas == 1 {
            strategy: type: "Recreate"
        }
        if replicas > 1 {
            strategy: {
                type: "RollingUpdate"
                rollingUpdate: {
                    maxUnavailable: 1
                    maxSurge:       replicas
                }
            }
        }
        template: spec: containers: [...{
            securityContext: readOnlyRootFilesystem: true
        }]
    }
}
```

If we render this, all deployments will have one replica. To see how it works, we should update one of them to have two replicas:

```cue
deployment: backend: {
    metadata: name: "backend"
    spec: {
        replicas: 2
        template: spec: containers: [
            {
                name:  "main"
                image: "python:latest"
            },
        ]
    }
}
```

You can see the full example here: https://cuelang.org/play/?id=HnFAnXiw5Yc#cue@export@yaml

The output is:

```yaml
deployment:
  load_balancer:
    metadata:
      name: load_balancer
    apiVersion: apps/v1
    kind: Deployment
    spec:
      replicas: 1
      strategy:
        type: Recreate
      template:
        spec:
          containers:
            - name: main
              securityContext:
                readOnlyRootFilesystem: true
              image: nginx:latest
  backend:
    metadata:
      name: backend
    apiVersion: apps/v1
    kind: Deployment
    spec:
      replicas: 2
      strategy:
        type: RollingUpdate
        rollingUpdate:
          maxUnavailable: 1
          maxSurge: 2
      template:
        spec:
          containers:
            - name: main
              securityContext:
                readOnlyRootFilesystem: true
              image: python:latest
```

The policy has automatically set the correct update strategy for the deployments, without the deployment author having to worry about it.

CUE enables a lot of automation like this. Rather than simply adding policies on top of existing configurations, writing both the configuration and the policy in CUE results in the configurations being modified to adhere to the policies.

# Swagger / OpenAPI

Even if we are not currently writing our configs in CUE, we can still apply policies using the power of CUE. Below is a subset of an OpenAPI spec that we want to apply a policy to (the entire spec is not relevant and is too large to display inline):

```yaml
components:
  schemas:
    APIKey:
      title: APIKeyDetails
      type: object
      example:
        id: 181210f8f9c779c26da1d9b2075bde0127302ee0e3fca38c9a83f5b1dd8e5d3b
        permissions:
          - permission: WRITE
            repoIds:
              - "123"
              - "321"
          - permission: READ
      properties:
        id:
          description: The ID of the API key.
          type: string
        permissions:
          description: The permissions for an API key.
          type: array
          items:
            type: object
            required:
              - permission
            properties:
              permission:
                type: string
                enum:
                  - READ
                  - WRITE
                  - DELETE
              repoIds:
                description: An optional list of repositories allowed to act on.
                type: array
                items:
                  type: string
                uniqueItems: true
```

The following policy enforces camel case in all type definitions, including their items fields, which can recursively contain other type definitions.

```cue
// Enforce camel case:
// Starts with lower case
// No special characters
// No consecutive capital letters (camel case with acronyms treated as words)
let fieldNameRegex = =~"^[a-z]([a-z0-9]|[A-Z][a-z0-9])*$"
 
components: schemas: [ID=_]: _typeDef
 
_typeDef: {
    properties: [PROP_NAME=_]: {
        _test : PROP_NAME & fieldNameRegex
    }
    items: [..._typeDef]
}
```

To apply this rule to the specified part of an OpenAPI spec, use the cue vet command.

```text
cue vet yaml: spec.yaml cue: policy.cue
```

> ⚠️ Note that we need to specify how the file types should be interpreted; otherwise, the OpenAPI config will be treated as a schema rather than data.

In this CUE playground link, the YAML spec is converted to CUE and made part of the same file so that you can see it working without running it locally: https://cuelang.org/play/?id=x2GHc5gUE-o#cue@export@yaml

You can cause it to fail by, for example, changing id to ID. You may see an error like this when you run the following command:

```text
$ cue vet yaml: spec.yaml cue: policy.cue
components.schemas.APIKeyDetails.properties.ID._test: invalid value "ID" (out of bound =~"^[a-z]([a-z0-9]|[A-Z][a-z0-9])*$"):
    -:53:22
    -:59:11
```

In this example, we create a hidden field called _test that triggers an error whenever a key in the properties map does not match the regex in the policy. Though this is a non-trivial CUE config, it’s a very useful pattern. To improve the error message, you can rename _test to something like _property_names_must_be_camel_case.

Including a rule like this in your continuous integration pipeline is an excellent way to ensure that standards are followed. Even if you don’t convert your configuration to CUE, you can still use your understanding of CUE to apply policies with varying levels of complexity.

# Terraform

Terraform configuration is defined in HCL format, which is not natively supported by CUE. While I haven’t had experience with these methods in a production environment, I see a few ways to define policies for Terraform:

* **A**: Write your configs in CUE, YAML, JSON, etc. and output terraform readable JSON in .tf.json files https://developer.hashicorp.com/terraform/language/syntax/json
* **B**: Write policies against the output of terraform plan
* **C**: Convert HCL files to JSON or YAML and then use CUE vet on them
* **D**: Write policies against the terraform state file after the config is applied

If I were to try this, I would choose Option **B**.

* Option A requires a big migration before your policies can apply to your entire config. Only the migrated parts would have the policy applied to them.
I don’t know how to do Option C. None of the tools I could find support the latest terraform syntax and/or don’t do any variable evaluation.
* Option D would apply the policy only after it’s too late
* Option B, which involves applying policies to the output of terraform plan, would work as follows:

To begin, generate the Terraform plan and then convert it to JSON.

```text
terraform plan -output tfplan
terraform show -json tfplan > tmp.json
```

The output will be significant, and here is a condensed version of one change, with some of the data redacted:

```json
{
  "format_version": "1.1",
  "resource_changes": [
    {
      "address": "google_storage_bucket.static",
      "module_address": "module.anchorage_root",
      "mode": "managed",
      "type": "google_storage_bucket",
      "name": "static",
      "provider_name": "registry.terraform.io/hashicorp/google",
      "change": {
        "actions": ["delete", "create"],
        "before": {
          "autoclass": [],
          "cors": [],
          "custom_placement_config": [],
          "default_event_based_hold": false,
          "encryption": [],
          "force_destroy": false,
          "id": "redacted-static",
          "labels": {},
          "lifecycle_rule": [],
          "location": "US",
          "logging": [],
          "name": "redacted-static",
          "project": "redacted",
          "public_access_prevention": "inherited",
          "requester_pays": false,
          "retention_policy": [],
          "self_link": "<https://www.googleapis.com/storage/v1/b/redacted-static>",
          "storage_class": "MULTI_REGIONAL",
          "timeouts": null,
          "uniform_bucket_level_access": true,
          "url": "gs://redacted-static",
          "versioning": [],
          "website": []
        },
        "after": {
          "autoclass": [],
          "cors": [],
          "custom_placement_config": [],
          "default_event_based_hold": null,
          "encryption": [],
          "force_destroy": false,
          "lifecycle_rule": [],
          "location": "EU",
          "logging": [],
          "name": "redacted-static",
          "requester_pays": null,
          "retention_policy": [],
          "storage_class": "MULTI_REGIONAL",
          "timeouts": null,
          "uniform_bucket_level_access": true
        },
        "after_unknown": {
          "autoclass": [],
          "cors": [],
          "custom_placement_config": [],
          "encryption": [],
          "id": true,
          "labels": true,
          "lifecycle_rule": [],
          "logging": [],
          "project": true,
          "public_access_prevention": true,
          "retention_policy": [],
          "self_link": true,
          "url": true,
          "versioning": true,
          "website": true
        },
        "before_sensitive": {
          "autoclass": [],
          "cors": [],
          "custom_placement_config": [],
          "encryption": [],
          "labels": {},
          "lifecycle_rule": [],
          "logging": [],
          "retention_policy": [],
          "versioning": [],
          "website": []
        },
        "after_sensitive": {
          "autoclass": [],
          "cors": [],
          "custom_placement_config": [],
          "encryption": [],
          "labels": {},
          "lifecycle_rule": [],
          "logging": [],
          "retention_policy": [],
          "versioning": [],
          "website": []
        },
        "replace_paths": [["location"]]
      },
      "action_reason": "replace_because_cannot_update"
    }
  ]
}
```

This is an example CUE policy that enforces the location of GCP buckets to be “US”.

```cue
format_version: "1.1" // sanity check
resource_changes: [...{
    type: string
    change: {
        if type == "google_storage_bucket" {
            after: location: "US"
        }
    }
}]
```

To see the error, you can execute it as you did before.

```text
$ cue vet diff.json policy.cue
resource_changes.0.change.after.location: conflicting values "US" and "EU":
    ./diff.json:46:23
    ./policy.cue:13:20
    ./policy.cue:16:3
    ./policy.cue:17:21
```

Fortunately, Terraform plans provide a wealth of information about the Terraform state. This policy enforcement method applies policies not only to the changes themselves, but to the entire future state of the configuration. You can modify which policies to apply and how to apply them by matching different parts of the Terraform plan file. For instance, you can write policies for what’s okay to delete or not, policies that apply only in specific cases or on new resources. Anything you can imagine can probably be expressed in a CUE policy applied to a Terraform plan.

# Key takeaway
CUE is a powerful tool for applying policies to structured configs. Whenever you encounter an unstructured config, consider whether it can be constrained with types and policies. As tooling around CUE evolves, using CUE definitions has the potential to make every config safer to modify. Anyone who takes the time to learn how to use CUE can wield this power.