Pre-requisites:
1. Internal Gateway API uses Google-managed Envoy proxies in a proxy-only subnet (so your vpc should have atleast 1 proxy only type subnet)
2. VPC firewall rule must allow traffic from that proxy type subnet to gateway as destination, otherwise requests time out issue will occur. Simply create a firewall rule with cidr of proxy subnet as source and gateway ip as destination

You can access the apps without https and with hostnames like this
curl -H "Host: app1.internal" http://<gateway-ip>
curl -H "Host: app2.internal" http://<gateway-ip>

Note: For https setup you need to do dns config
https://app1.internal
https://app2.internal
