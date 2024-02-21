# ####################################################################################################### #
# Copyright (c) 2024 Oracle and/or its affiliates,  All rights reserved.                                  #
# Licensed under the Universal Permissive License v 1.0 as shown at https: //oss.oracle.com/licenses/upl. #
# Author: Cosmin Tudor                                                                                    #
# Author email: cosmin.tudor@oracle.com                                                                   #
# Last Modified: Thu Feb 21, 2023                                                                         #
# Modified by: andre.correa@oracle.com                                                                    #
# ####################################################################################################### #


data "http" "dependency_files_urls" {
  count = var.dependency_files_urls != null ? length(var.dependency_files_urls) : 0
  url = var.dependency_files_urls[count.index]
  # Optional request headers
  request_headers = {
    Accept = "application/json"
  }
}

# locals {
#   github_repo_from_url   = [for url in var.dependency_files_urls : regex("^https://raw.githubusercontent.com/andrecorreaneto/(.*)/.*$",url)[0]]
#   github_branch_from_url = [for url in var.dependency_files_urls : regex("^https://raw.githubusercontent.com/andrecorreaneto/.*/(.*)/.*$",url)[0]]
#   github_file_from_url   = [for url in var.dependency_files_urls : regex("^https://raw.githubusercontent.com/andrecorreaneto/.*/.*/(.*)$",url)[0]]
# }

# data "github_repository_file" "readtest" {
#   repository          = "oci-landing-zone-configuration"
#   branch              = "test"
#   file                = "rms-iam/output/compartments_output.json"
# }

locals {
  all_json_dependency_files = data.http.dependency_files_urls != null ? length(data.http.dependency_files_urls) > 0 ? [
    for element in flatten(data.http.dependency_files_urls[*].body) : jsondecode(element) if try(jsondecode(element), null) != null
  ] : null : null

  all_json_dependency_l1_keys = local.all_json_dependency_files != null ? length(local.all_json_dependency_files) > 0 ? flatten([
    for value in local.all_json_dependency_files : keys(value) if value != null
  ]) : null : null

  merged_dependency_files = local.all_json_dependency_l1_keys != null ? length(local.all_json_dependency_l1_keys) > 0 ? {
    for key in local.all_json_dependency_l1_keys : key => [
      for config in local.all_json_dependency_files : config[key] if contains(keys(config), key) && config != null
    ][0]
  } : null : null

  compartments_dependency = local.merged_dependency_files != null ? contains(keys(local.merged_dependency_files), "compartments") ? local.merged_dependency_files.compartments : null : null
  tags_dependency         = local.merged_dependency_files != null ? contains(keys(local.merged_dependency_files), "tags") ? local.merged_dependency_files.tags : null : null
  networks_dependency     = local.merged_dependency_files != null ? contains(keys(local.merged_dependency_files), "provisioned_networking_resources") ? local.merged_dependency_files.provisioned_networking_resources : null : null
  kms_dependency          = local.merged_dependency_files != null ? contains(keys(local.merged_dependency_files), "keys") ? local.merged_dependency_files.keys : null : null
  streams_dependency      = local.merged_dependency_files != null ? contains(keys(local.merged_dependency_files), "streams") ? local.merged_dependency_files.streams : null : null
  topics_dependency       = local.merged_dependency_files != null ? contains(keys(local.merged_dependency_files), "topics") ? local.merged_dependency_files.topics : null : null
  logging_dependency      = local.merged_dependency_files != null ? merge(contains(keys(local.merged_dependency_files), "service_logs") ? local.merged_dependency_files.service_logs : {}, contains(keys(local.merged_dependency_files), "custom_logs") ? local.merged_dependency_files.custom_logs : {}) : null
  functions_dependency    = local.merged_dependency_files != null ? contains(keys(local.merged_dependency_files), "functions") ? local.merged_dependency_files.functions : null : null
}