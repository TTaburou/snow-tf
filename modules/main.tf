terraform {
  required_providers {
    snowflake = {
      source  = "Snowflake-Labs/snowflake"
      version = "0.42.1"
    }
  }
}

provider "snowflake" {
  role  = "SYSADMIN"
}

resource "snowflake_database" "db" {
  name     = "TF_DEMO_DB"
}

resource "snowflake_warehouse" "warehouse" {
  name           = "TF_DEMO_WH"
  warehouse_size = "large"
  auto_suspend = 60
}