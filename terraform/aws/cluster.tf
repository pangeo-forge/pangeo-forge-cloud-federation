
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 18"

  cluster_name = var.cluster_name

  vpc_id     = data.aws_vpc.default.id
  subnet_ids = data.aws_subnets.default.ids

  node_security_group_additional_rules = {
    # This seems to be required for the cluster to really work at all - without this,
    # pods can't really communicate with each other?!
    ingress_self_all = {
      description = "Node to node all ports/protocols"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    }
    egress_all = {
      description      = "Node all egress"
      protocol         = "-1"
      from_port        = 0
      to_port          = 0
      type             = "egress"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }

    # Every time we create a Flink CRD object, it needs to be validated.
    # The k8s master needs to POST it to the flink operator to validate it.
    # This sets up the appropriate network rule for that to work
    ingress_flink_operator_webhook_tcp = {
      description = "Control plane invokes flink-operator webhook"
      protocol    = "tcp"
      # 9443 is the *pod* port (not the service port) that the flink-operator webhook runs on
      from_port                     = 9443
      to_port                       = 9443
      type                          = "ingress"
      source_cluster_security_group = true
    }


  }

  # We need to use this if we want node groups that scale to 0.
  # Many years into EKS being available, but managed nodegroups still can't scale to 0!
  # https://github.com/aws/containers-roadmap/issues/724
  # self managed node groups seem a bit flaky, I can't really get them to work
  self_managed_node_groups = {}

  eks_managed_node_groups = {
    node = {
      # min size can't be 0  https://github.com/aws/containers-roadmap/issues/724
      # BOO
      min_size     = 1
      max_size     = var.max_instances
      desired_size = 1

      instance_types = [var.instance_type]
    }
  }

  # OIDC Identity provider
  cluster_identity_providers = {
    sts = {
      client_id = "sts.amazonaws.com"
    }
  }
}

module "cluster_autoscaler_irsa" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  role_name = "cluster_autoscaler"

  attach_cluster_autoscaler_policy = true
  cluster_autoscaler_cluster_ids = [
    module.eks.cluster_id
  ]

  oidc_providers = {
    main = {
      provider_arn = module.eks.oidc_provider_arn
      # FIXME: We can't depend on release name + ns of cluster-autoscaler helm_release, because it
      # creates a circular dependency (lol).
      namespace_service_accounts = ["cluster-autoscaler:cluster-autoscaler-aws-cluster-autoscaler"]
    }
  }
}
