output "load_balancer_name" {
  value = "${aws_lb.harbor.*.name}"
}

output "target_groups" {
  value = [
    "${aws_lb_target_group.harbor_443.*.name}",
    "${aws_lb_target_group.harbor_4443.*.name}",
  ]
}

output "hostname" {
  value = "harbor.${var.env_name}.${var.dns_suffix}"
}

output "lb_security_group_id" {
  value = "${aws_security_group.harbor_lb_security_group.*.id}"
}

output "lb_security_group_name" {
  value = "${aws_security_group.harbor_lb_security_group.*.name}"
}

output "admin_password" {
  value = "${random_password.admin_password.result}"
}
