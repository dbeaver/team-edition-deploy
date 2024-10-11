### Clouds volumes configuration

#### Prerequisites

- [gcloud](https://cloud.google.com/sdk/docs/install) installed and configured
- [Helm](https://helm.sh/docs/intro/install/) installed
- Access to an existing **GKE cluster**

#### Step 1: Enable the Cloud Filestore API and the Google Kubernetes Engine API

```
gcloud services enable file.googleapis.com container.googleapis.com
```

#### Step 2: Configure values.yaml file

Open the file `team-edition-deploy/k8s/cbte/values.yaml` and fill in the following parameters as shown in the example:

```
cloudProvider: gcp
storage:
  type: filestore
  storageClassName: "filestore-sc"
```

Once this is set up, you can deploy Team Edition by following [this guide](../../k8s/README.md#how-to-run-services).
