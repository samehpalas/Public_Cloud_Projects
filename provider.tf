provider "aws" {
  #region: select the required region to match the customer needs, dont' forget the key_pair is per region
  region     = var.Select_region-ex_us-east-1 
  access_key = "${file("Access_key.txt")}"  #your own_credentaial
  secret_key = "${file ("secret Key.txt")}" #your own_credentaial
}
