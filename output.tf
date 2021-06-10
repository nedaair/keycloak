output "keycloak_admin_address" {
    value = aws_instance.keycloak_instance.public_ip
}