terraform {
  required_version = ">= 1.6.0"

  required_providers {
    hcs = {
      source  = "registry.terraform.io/huaweicloud/hcs"
      version = "2.4.26"
    }
    random = {
      source  = "registry.terraform.io/hashicorp/random"
      version = "3.9.0"
    }
  }
}
