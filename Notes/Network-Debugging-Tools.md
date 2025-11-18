# Network Debugging Tools --- Quick Reference (Interview Friendly)

This README explains common network debugging tools with: - What they
do - When to use them - Whether they support IP / DNS / both -
Examples - Key differences

------------------------------------------------------------------------

## 🔹 1. `ping` --- Reachability Test (ICMP)

**Purpose:** Check if a host responds to ICMP Echo.\
**Supports:** **Only IP** (DNS works but is converted to IP first)\
**When to use:** Basic connectivity test.\
**Does NOT work:** If ICMP is blocked (common in cloud LBs, firewalls).

### Example

``` bash
ping 10.10.0.5
ping google.com
```

------------------------------------------------------------------------

## 🔹 2. `curl` --- Application-Level HTTP/HTTPS Test

**Purpose:** Make HTTP/HTTPS requests.\
**Supports:** **Both IP and DNS names**\
**When to use:** Check APIs, websites, response codes, redirects.\
**Difference:** Layer 7 test --- shows app behavior.

### Example

``` bash
curl -v http://10.10.0.5:8080/api/health
curl https://example.com
```

------------------------------------------------------------------------

## 🔹 3. `nc` (netcat) --- TCP/UDP Port Connectivity Test

**Purpose:** Verify if a port is reachable.\
**Supports:** **Both IP and DNS names**\
**When to use:** Database ports, service ports, firewall testing.\
**Difference:** Pure TCP test --- does not check HTTP/application
response.

### Example

``` bash
nc -vz 10.10.0.5 3306
nc -vz mydb.internal 5432
```

------------------------------------------------------------------------

## 🔹 4. `telnet` --- Basic TCP Connectivity

**Purpose:** Tests TCP port and allows manual input.\
**Supports:** **Both IP and DNS names**\
**When to use:** Quick port testing on old systems.\
**Difference:** Obsolete but simple; only supports TCP.

### Example

``` bash
telnet 10.10.0.5 80
```

------------------------------------------------------------------------

## 🔹 5. `traceroute` --- Route Path Debugging

**Purpose:** Shows each hop packets take.\
**Supports:** **Both IP and DNS names**\
**When to use:** Diagnose routing issues, VPC peering issues.\
**Difference:** Layer 3 routing visibility.

### Example

``` bash
traceroute 10.10.0.5
traceroute example.com
```

------------------------------------------------------------------------

## 🔹 6. `dig` --- DNS Lookup Tool

**Purpose:** Detailed lookup of DNS records.\
**Supports:** **Only DNS names**\
**When to use:** DNS debugging, CNAME, A, AAAA, MX records.\
**Difference:** Most detailed DNS tool.

### Example

``` bash
dig example.com
dig A example.com
```

------------------------------------------------------------------------

## 🔹 7. `nslookup` --- Simple DNS Lookup

**Purpose:** Quick DNS resolution.\
**Supports:** **Only DNS names**\
**When to use:** Faster, simpler DNS troubleshooting.\
**Difference:** Less detailed than `dig`.

### Example

``` bash
nslookup example.com
```

------------------------------------------------------------------------

## 🔹 8. `tcpdump` --- Packet Sniffing

**Purpose:** Capture real packets to debug deep network issues.\
**Supports:** Works on **interfaces**, not directly on IP or DNS.\
**When to use:** Traffic is not reaching VM/Pod, or leaving but never
returning.\
**Difference:** Deep Layer 2--4 debugging.

### Example

``` bash
sudo tcpdump -i eth0 port 443
```

------------------------------------------------------------------------

## Comparison Table

  Tool             Supports IP?   Supports DNS?          Layer   Primary Use
  ---------------- -------------- ---------------------- ------- --------------------
  **ping**         Yes            Yes (resolved to IP)   L3      Basic reachability
  **curl**         Yes            Yes                    L7      HTTP/API debugging
  **nc**           Yes            Yes                    L4      Port checking
  **telnet**       Yes            Yes                    L4      Quick TCP test
  **traceroute**   Yes            Yes                    L3      Routing path
  **dig**          No             Yes                    L7      DNS queries
  **nslookup**     No             Yes                    L7      DNS check
  **tcpdump**      N/A            N/A                    L2-L4   Packet capture

------------------------------------------------------------------------

## Interview Tip

If asked "How do you debug connectivity?" answer with:

1.  `ping` → basic reachability\
2.  `nc/telnet` → port open?\
3.  `curl` → service responding?\
4.  `traceroute` → routing issue?\
5.  `dig/nslookup` → DNS issue?\
6.  `tcpdump` → packet-level debugging

------------------------------------------------------------------------

Happy debugging 🚀
