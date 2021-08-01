output "C2_Public_IP" {
  value = "${azurerm_public_ip.C2.ip_address}"
}
output "C2_Private_IP" {
  value = "${azurerm_network_interface.C2.private_ip_address}"
}
