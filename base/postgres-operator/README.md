References
================================
-   <https://access.crunchydata.com/documentation/postgres-operator/4.5.0/>

-   <https://github.com/CrunchyData/postgres-operator>

following are the steps to install the operator

Inspect the Operator information
================================

we want to get information about the current operator csv and its provided API. First thing is to ensure that the operator exists in the channel catalog.
```bash
    $ oc get packagemanifests -n openshift-marketplace | grep crunchy-postgres-operator
```
Now we want to get the CSV information that we will use later.

```bash
    $ oc describe packagemanifests/crunchy-postgres-operator -n openshift-marketplace | grep -A1 Channels

    Channels:
      Current CSV:  postgresoperator.v4.4.1
```
```bash
    $ oc describe packagemanifests/crunchy-postgres-operator -n openshift-marketplace | grep -A35 Customresourcedefinitions

    Customresourcedefinitions:
      Owned:
        Description:   Represents a Postgres primary cluster member
        Display Name:  Postgres Primary Cluster Member
        Kind:          Pgcluster
        Name:          pgclusters.crunchydata.com
        Version:       v1
        Description:   Represents a Postgres replica cluster member
        Display Name:  Postgres Replica Cluster Member
        Kind:          Pgreplica
        Name:          pgreplicas.crunchydata.com
        Version:       v1
        Description:   Represents a Postgres sql policy
        Display Name:  Postgres SQL Policy
        Kind:          Pgpolicy
        Name:          pgpolicies.crunchydata.com
        Version:       v1
        Description:   Represents a Postgres workflow task
        Display Name:  Postgres workflow task
        Kind:          Pgtask
        Name:          pgtasks.crunchydata.com
        Version:       v1
    Description:       Crunchy PostgreSQL for OpenShift lets you run your own production-grade PostgreSQL-as-a-Service on OpenShift!

Powered by the Crunchy [PostgreSQL Operator](https://github.com/CrunchyData/postgres-operator), Crunchy PostgreSQL
for OpenShift automates and simplifies deploying and managing open source PostgreSQL clusters on OpenShift by providing the
essential features you need to keep your PostgreSQL clusters up and running, including:

- **PostgreSQL Cluster Provisioning**: [Create, Scale, & Delete PostgreSQL clusters with ease][provisioning],
while fully customizing your Pods and PostgreSQL configuration!
- **High-Availability**: Safe, automated failover backed by a [distributed consensus based high-availability solution][high-availability].
Uses [Pod Anti-Affinity][anti-affinity] to help resiliency; you can configure how aggressive this can be!
Failed primaries automatically heal, allowing for faster recovery time. You can even create regularly scheduled
backups as well and set your backup retention policy
- **Disaster Recovery**: Backups and restores leverage the open source [pgBackRest][] utility
and [includes support for full, incremental, and differential backups as well as efficient delta restores][disaster-recovery].
```

-   current CSV of the package.

-   note the Kind, Version, and the group (argoproj.io) field of list of CRDs, as this will be used to define the providedAPIs in OperatorGroup

Create a Subscription
=====================

As per the documentation ["`A user wanting a specific operator creates a Subscription which identifies a catalog, operator and channel within that operator. The Catalog Operator then receives that information and queries the catalog for the latest version of the channel requested. Then it looks up the appropriate ClusterServiceVersion identified by the channel and turns that into an InstallPlan.`"](https://github.com/operator-framework/operator-lifecycle-manager/blob/master/doc/design/architecture.md#catalog-operator)

So we will create a subscription

**[postgres-subscription.yaml](postgres-subscription.yaml).**

```yaml
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: crunchy-postgres-operator
spec:
  channel: stable
  installPlanApproval: Automatic
  name: crunchy-postgres-operator
  source: "certified-operators"
  sourceNamespace: "openshift-marketplace"
  startingCSV: postgresoperator.v4.4.1
```
-   the starting CSV version we want, it should match the current CSV

It is possible to configure how OLM deploys an Operator via the config field in the Subscription object, There is another subscription file if we want to run ArgoCD on infra nodes only, [quay-subscription-infra.yaml](quay-subscription-infra.yaml)

Create an Operator Group
========================

An OperatorGroup is an OLM resource that provides multitenant configuration to OLM-installed Operators. An OperatorGroup selects target namespaces in which to generate required RBAC access for its member Operators.

**[postgres-operatorgroup.yaml](postgres-operatorgroup.yaml).**

```yaml
apiVersion: operators.coreos.com/v1
kind: OperatorGroup
metadata:
  annotations:
    olm.providedAPIs: Pgcluster.v1.crunchydata.com,Pgreplica.v1.crunchydata.com,Pgpolicy.v1.crunchydata.com,Pgtask.v1.crunchydata.com
  generateName: crunchy-postgres-
  name: crunchy-postgres-operator
spec:
  targetNamespaces:
  - quay-enterprise
```

-   The annotation’s value is a string consisting of GroupVersionKinds (GVKs) in the format of &lt;kind&gt;.&lt;version&gt;.&lt;group&gt; delimited with commas. The GVKs of CRDs and APIServices provided by all active member CSVs of an OperatorGroup are included.

-   Target namespace selection, explicitly name the target namespace for an OperatorGroup. We define "quay-enterprise" as the target namespace that will be watched.

Deploy the Operator
===================

```bash
oc apply -k postgres-operator
```
Or

```bash
kustomize build postgres-operator |oc apply -f -
```
