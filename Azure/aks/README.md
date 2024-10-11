### Clouds volumes configuration

#### Prerequisites

- [Helm](https://helm.sh/docs/intro/install/) installed
- Access to an existing **AKS cluster**

#### Step 1: Configure values.yaml file

Open the file `team-edition-deploy/k8s/cbte/values.yaml` and fill in the following parameters as shown in the example:

```
cloudProvider: azure
storage:
  type: azurefile
  storageClassName: "azurefile"
```

Once this is set up, you can deploy Team Edition by following [this guide](../../k8s/README.md#how-to-run-services).