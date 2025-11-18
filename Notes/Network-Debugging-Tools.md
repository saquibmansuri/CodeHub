# Network Debugging Tools --- Quick Reference

This README explains common network debugging tools with: - What they
do
- When to use them
- Whether they support IP / DNS / both
- Examples
- Sample outputs
- Key differences

------------------------------------------------------------------------

## 🔹 1. `ping` --- Reachability Test (ICMP)

**Purpose:** Check if a host responds to ICMP Echo.
**Supports:** **Only IP** (DNS resolves to IP)
**When to use:** Basic connectivity test.
**Does NOT work:** If ICMP is blocked (very common in cloud load
balancers).

### Example

``` bash
ping 10.10.0.5
ping google.com
```

### Sample Output (Success)

    PING google.com (142.250.193.110) 56(84) bytes of data.
    64 bytes from bom12s04-in-f14.1e100.net: icmp_seq=1 ttl=113 time=24.3 ms

### Sample Output (Blocked)

    PING 10.32.0.23 (10.32.0.23) 56(84) bytes of data.
    (no replies)

------------------------------------------------------------------------

## 🔹 2. `curl` --- Application-Level HTTP/HTTPS Test

**Purpose:** Make HTTP/HTTPS requests.
**Supports:** **IP + DNS**
**When to use:** API testing, website debugging, response codes.

### Example

``` bash
curl -v http://10.10.0.5:8080/api/health
curl https://example.com
```

### Sample Output

    > GET /api/health HTTP/1.1
    < HTTP/1.1 200 OK
    < Content-Type: application/json
    {"status":"UP"}

------------------------------------------------------------------------

## 🔹 3. `nc` (netcat) --- TCP/UDP Port Connectivity Test

**Purpose:** Check if a port is reachable.
**Supports:** **IP + DNS**
**When to use:** Database ports, microservices, firewalls.

### Example

``` bash
nc -vz 10.10.0.5 3306
```

### Sample Output

    Connection to 10.10.0.5 3306 port [tcp/mysql] succeeded!

------------------------------------------------------------------------

## 🔹 4. `telnet` --- Basic TCP Port Test

**Purpose:** Check if a TCP port is open.
**Supports:** **IP + DNS**
**When to use:** Quick TCP testing.

### Example

``` bash
telnet 10.10.0.5 80
```

### Sample Output

    Trying 10.10.0.5...
    Connected to 10.10.0.5.
    Escape character is '^]'.

------------------------------------------------------------------------

## 🔹 5. `traceroute` --- Routing Path Debugging

**Purpose:** See every hop packets travel.
**Supports:** **IP + DNS**
**When to use:** VPC peering, routing loops, blocked paths.

### Example

``` bash
traceroute 10.10.0.5
```

### Sample Output

    1  10.0.0.1  1.23 ms
    2  172.16.0.1  5.22 ms
    3  * * *

------------------------------------------------------------------------

## 🔹 6. `dig` --- DNS Lookup Tool

**Purpose:** Detailed DNS record lookup.
**Supports:** **DNS only**
**When to use:** Deep DNS debugging.

### Example

``` bash
dig example.com
```

### Sample Output

    ;; ANSWER SECTION:
    example.com.   300   IN   A   93.184.216.34

------------------------------------------------------------------------

## 🔹 7. `nslookup` --- Simple DNS Lookup

**Purpose:** Quick DNS resolution.
**Supports:** **DNS only**
**When to use:** Simple DNS checks.

### Example

``` bash
nslookup example.com
```

### Sample Output

    Name: example.com
    Address: 93.184.216.34

------------------------------------------------------------------------

## 🔹 8. `tcpdump` --- Packet Capture

**Purpose:** Deep packet-level debugging.
**Supports:** Works on **interfaces**, not DNS or IP directly.
**When to use:** When packets aren't arriving.

### Example

``` bash
sudo tcpdump -i eth0 port 443
```

### Sample Output

    IP 10.0.0.5.443 > 10.0.0.10.52044: Flags [P.], length 1448

------------------------------------------------------------------------

## Interview Tip

If asked: *"How do you debug network connectivity?"*

Answer this sequence:

1.  `ping` → is the host reachable?
2.  `nc` / `telnet` → is the port open?
3.  `curl` → is the app responding?
4.  `traceroute` → is routing correct?
5.  `nslookup` / `dig` → is DNS correct?
6.  `tcpdump` → deep packet troubleshooting

------------------------------------------------------------------------
