References
================================
-   <https://access.redhat.com/documentation/en-us/red_hat_quay/3.3/html/deploy_red_hat_quay_on_openshift_with_quay_operator/index>

-   <https://github.com/quay/quay-operator>


TODO
================================
1. Custom route ssl certficate
2. Repo mirroring
3. Trust another Registry certificates https://access.redhat.com/documentation/en-us/red_hat_quay/3.3/html-single/deploy_red_hat_quay_on_openshift_with_quay_operator/index#injecting_configuration_files
4. clair database verify-ca


Deploy the Quay Instance
===================

```bash
oc apply -k quay-instance/overlays/non-prod
```
Or

```bash
kustomize build quay-instance/overlays/non-prod |oc apply -f -
```
