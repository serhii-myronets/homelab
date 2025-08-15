ui = true
disable_mlock = true

listener "tcp" {
  address     = "0.0.0.0:8200"
  tls_disable = 1
}

storage "file" {
  path = "/vault/file"
}

seal "awskms" {
  region     = "us-east-1"
  kms_key_id = "arn:aws:kms:us-east-1:058264369873:key/9049f302-ecb8-4f04-ba8e-ca441b8b062d"
}

api_addr     = "http://vault:8200"
cluster_addr = "http://vault:8201"