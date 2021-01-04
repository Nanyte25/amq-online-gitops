References
================================
-   <https://access.redhat.com/documentation/en-us/red_hat_amq/7.7/html/installing_and_managing_amq_online_on_openshift/index>

-   <https://github.com/EnMasseProject/enmasse>

following are the steps to install the operator

Inspect the Operator information
================================

we want to get information about the current operator csv and its provided API. First thing is to ensure that the operator exists in the channel catalog.
```bash
    $ oc get packagemanifests -n openshift-marketplace | grep amq-online
```
Now we want to get the CSV information that we will use later.

```bash
    $ oc describe packagemanifests/amq-online -n openshift-marketplace | grep -A1 Channels
  Channels:
    Current CSV:  amq-online.1.6.1

```
```bash
    $ oc describe packagemanifests/amq-online -n openshift-marketplace | grep -A59 Customresourcedefinitions
      Customresourcedefinitions:
        Owned:
          Description:   A messaging user that can connect to an Address Space
          Display Name:  Messaging User
          Kind:          MessagingUser
          Name:          messagingusers.user.enmasse.io
          Version:       v1beta1
          Description:   A resource representing the available schema of plans and authentication services
          Display Name:  AddressSpaceSchema
          Kind:          AddressSpaceSchema
          Name:          addressspaceschemas.enmasse.io
          Version:       v1beta1
          Description:   A group of messaging addresses that can be accessed via the same endpoint
          Display Name:  Address Space
          Kind:          AddressSpace
          Name:          addressspaces.enmasse.io
          Version:       v1beta1
          Description:   A messaging address that can be used to send/receive messages to/from
          Display Name:  Address
          Kind:          Address
          Name:          addresses.enmasse.io
          Version:       v1beta1
          Description:   Infrastructure configuration template for the standard address space type
          Display Name:  Standard Infra Config
          Kind:          StandardInfraConfig
          Name:          standardinfraconfigs.admin.enmasse.io
          Version:       v1beta1
          Description:   Infrastructure configuration template for the brokered address space type
          Display Name:  Brokered Infra Config
          Kind:          BrokeredInfraConfig
          Name:          brokeredinfraconfigs.admin.enmasse.io
          Version:       v1beta1
          Description:   Plan describing the resource usage of a given address type
          Display Name:  Address Plan
          Kind:          AddressPlan
          Name:          addressplans.admin.enmasse.io
          Version:       v1beta2
          Description:   Plan describing the capabilities and resource limits of a given address space type
          Display Name:  Address Space Plan
          Kind:          AddressSpacePlan
          Name:          addressspaceplans.admin.enmasse.io
          Version:       v1beta2
          Description:   Authentication service configuration available to address spaces.
          Display Name:  Authentication Service
          Kind:          AuthenticationService
          Name:          authenticationservices.admin.enmasse.io
          Version:       v1beta1
          Description:   Console Service Singleton for deploying global console.
          Display Name:  Console Service
          Kind:          ConsoleService
          Name:          consoleservices.admin.enmasse.io
          Version:       v1beta1
      Description:       **Red Hat Integration - AMQ Online** provides messaging as a managed service on OpenShift.
With Red Hat Integration - AMQ Online, administrators can configure a cloud-native,
multi-tenant messaging service either in the cloud or on premise.
Developers can provision messaging using the Red Hat Integration - AMQ Online Console.
Multiple development teams can provision the brokers and queues from the
console, without requiring each team to install, configure, deploy,
maintain, or patch any software. 
```

-   current CSV of the package.

-   note the Kind, Version, and the group (argoproj.io) field of list of CRDs, as this will be used to define the providedAPIs in OperatorGroup

Create a Subscription
=====================

As per the documentation ["`A user wanting a specific operator creates a Subscription which identifies a catalog, operator and channel within that operator. The Catalog Operator then receives that information and queries the catalog for the latest version of the channel requested. Then it looks up the appropriate ClusterServiceVersion identified by the channel and turns that into an InstallPlan.`"](https://github.com/operator-framework/operator-lifecycle-manager/blob/master/doc/design/architecture.md#catalog-operator)

So we will create a subscription

**[quay-subscription.yaml](quay-subscription.yaml).**

```yaml
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: amq-online-operator
spec:
  channel:amq-online.1.6.1
  installPlanApproval: Automatic
  name: amq-online-operator
  source: "stable"
  sourceNamespace: "openshift-marketplace"
  startingCSV: red-hat-quay.v3.3.2-20200903
```
-   the starting CSV version we want, it should match the current CSV

It is possible to configure how OLM deploys an Operator via the config field in the Subscription object, There is another subscription file if we want to run ArgoCD on infra nodes only, [quay-subscription-infra.yaml](quay-subscription-infra.yaml)

Create an Operator Group
========================

An OperatorGroup is an OLM resource that provides multitenant configuration to OLM-installed Operators. An OperatorGroup selects target namespaces in which to generate required RBAC access for its member Operators.

**[amq-online-operatorgroup.yaml](amq-online-operatorgroup.yaml).**

```yaml
apiVersion: operators.coreos.com/v1
kind: OperatorGroup
metadata:
  annotations:
    olm.providedAPIs: Address.v1beta1.enmasse.io,AddressPlan.v1beta2.admin.enmasse.io,AddressSpace.v1beta1.enmasse.io,AddressSpacePlan.v1beta2.admin.enmasse.io,AddressSpaceSchema.v1beta1.enmasse.io,AuthenticationService.v1beta1.admin.enmasse.io,BrokeredInfraConfig.v1beta1.admin.enmasse.io,ConsoleService.v1beta1.admin.enmasse.io,MessagingUser.v1beta1.user.enmasse.io,StandardInfraConfig.v1beta1.admin.enmasse.io
  generateName: amq-online-infra-
  name: amq-online-infra-operator
spec:
  targetNamespaces:
  - amq-online-infra
```

-   The annotation’s value is a string consisting of GroupVersionKinds (GVKs) in the format of &lt;kind&gt;.&lt;version&gt;.&lt;group&gt; delimited with commas. The GVKs of CRDs and APIServices provided by all active member CSVs of an OperatorGroup are included.

-   Target namespace selection, explicitly name the target namespace for an OperatorGroup. We define "quay-enterprise" as the target namespace that will be watched.

Deploy the Operator
===================

```bash
oc apply -k amq-online-operator
```
Or

```bash
kustomize build amq-online-operator |oc apply -f -
```
