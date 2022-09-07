# AWS Bakery Infrastructure

This directory contains terraform code to set up a fully functional
Bakery that can be used by [pangeo-forge.org](http://pangeo-forge.org/).
In addition, under the `bakeries/` subdir, we also contain the configuration
for all the bakeries currently used by pangeo-forge.org running on AWS.

## Infrastructure pieces

pangeo-forge is based on [Apache Beam](https://beam.apache.org/) and on AWS it
uses the portable [FlinkRunner](https://beam.apache.org/documentation/runners/flink/) to execute
tasks on an [Apache Flink](https://flink.apache.org/) cluster deployed on
[AWS EKS](https://aws.amazon.com/eks/). The [Apache Flink Operator](https://nightlies.apache.org/flink/flink-kubernetes-operator-docs-stable/)
is used to deploy an Apache Flink cluster per pangeo-forge run on a single
EKS cluster.

So this repository sets up the following pieces of infrastructure:

1. An EKS cluster with an appropriate managed nodegroup.
2. [Cluster
   Autoscaler](https://github.com/kubernetes/autoscaler/tree/master/cluster-autoscaler)
   so the EKS cluster can scale up & down automatically as required.
3. [cert-manager](https://cert-manager.io/) as it is required by the Flink Operator
4. The Apache [Flink Operator](https://nightlies.apache.org/flink/flink-kubernetes-operator-docs-stable/)
   itself. While there are a few different operators, this has been the most actively developed
   operator with clearest community governance - so we choose this.
5. A series of support charts for useful functionality - [prometheus](https://prometheus.io/)
   for metrics and [ingress-nginx](https://kubernetes.github.io/ingress-nginx/) for
   getting traffic into the controller. Eventually we will add a Grafana as well.
6. (Optionally) S3 storage buckets to use as either caches or to put data into.