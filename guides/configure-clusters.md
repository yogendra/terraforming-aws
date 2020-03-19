# Configure Clusters

# Prerequisites

- Working PKS environment
- Configured workspace where you are able to:
  - Access PKS API via `pks` cli
  - Access Ops Manager API via `om` cli
  - Access BOSH via `bosh` cli

# Create Application Cluster

``bash
export PATH=PATH_TO_MANAGE_PKS/aws:\$PATH

manage-cluster provision 

```

