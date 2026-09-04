include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "component" {
  path = "${dirname(find_in_parent_folders("root.hcl"))}/_env/alb-security-group.hcl"
}
