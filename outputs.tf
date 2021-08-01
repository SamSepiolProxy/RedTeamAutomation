output "C2CovPublicIP" {
  value = module.C2_Cov.C2_Public_IP
}
output "C2CovPrivateIP" {
  value = module.C2_Cov.C2_Private_IP
}
output "C2RDRPublicIP" {
  value = module.C2_RDR.C2_RDR_Public_IP
}
output "C2RDRPrivateIP" {
  value = module.C2_RDR.C2_RDR_Private_IP
}
output "DNSNameservers" {
  value = azurerm_dns_zone.C2DNS.name_servers
}
