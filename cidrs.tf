locals {
  base_cidr     = var.vpc_cidr_block
  prefix_length = var.subnet_prefix_size

  // How many CIDR groups are defined? Count the keys of the cidrgroup definition
  num_cidrgroups = length(keys(local.cidr_groups))

  // List only the sizes of the CIDR groups (without the keys); e.g. [ 3, 2, 2, 1 ]
  cidr_sizes = tolist(values(local.cidr_groups))

  total_num_cidrs = sum(local.cidr_sizes)

  // A list of the CIDR/subnet prefix for each CIDR (e.g. [ 4, 4, 4, 4, 4, 4, 4, 4 ] for 8 subnets
  cidr_prefix_lengths = [for i in range(local.total_num_cidrs) : local.prefix_length]

  // The actual CIDRs based on the total number and the prefix lengths calculated above
  cidrs = cidrsubnets(local.base_cidr, local.cidr_prefix_lengths...)

  // Need to pick the CIDRs from cidrs based on their index, so here we calculate at which index which group starts;
  // e.g. [ 0, 3, 5, 7 ]
  cidr_indices = concat([0], [for grp_idx in range(1, local.num_cidrgroups) : sum(slice(local.cidr_sizes, 0, grp_idx))])

  // Combine the name of each CIDR group with the start index in the cidr variable; used later for lookup
  group_start_index = zipmap(keys(local.cidr_groups), local.cidr_indices)

  // The final product, a map that maps the name of each CIDR group to a list of CIDRs to use for that group
  grouped_cidrs = { for group_name, start_index in local.group_start_index : group_name =>
    slice(local.cidrs, start_index, start_index + local.cidr_groups[group_name])
  }
}
