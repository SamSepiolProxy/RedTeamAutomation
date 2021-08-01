output "C2_RDR_Public_IP" {
  value = "${azurerm_public_ip.C2RDR.ip_address}"
}
output "C2_RDR_Private_IP" {
  value = "${azurerm_network_interface.C2RDRNic.private_ip_address}"
}

output "C2RDR_Name" {
value = "${azurerm_public_ip.C2RDR.name}"
}