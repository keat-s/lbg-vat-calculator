package accurics

tcp_port_22_open[api.id] {
    api := input.google_compute_firewall[_]
    rule := api.config.allow[_]
    port := rule.ports[_]
    contains(lower(port), "22")
    api.config.direction == "INGRESS"
    api.config.source_ranges[_] == "0.0.0.0/0"
}