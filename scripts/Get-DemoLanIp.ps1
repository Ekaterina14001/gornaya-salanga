# Shared LAN IP detection for demo APK (prefers Wi-Fi over VirtualBox/Hyper-V).
function Get-DemoLanIp {
    $virtualPrefix = @(
        '192.168.56.', '192.168.57.', '192.168.58.',
        '172.17.', '172.18.', '172.19.'
    )

    $adapters = Get-NetAdapter -ErrorAction SilentlyContinue |
        Where-Object {
            $_.Status -eq 'Up' -and
            $_.Name -notmatch 'vEthernet|WSL|Loopback|VirtualBox|VMware|Hyper-V'
        }

    $candidates = @()
    foreach ($adapter in $adapters) {
        $addrs = Get-NetIPAddress -AddressFamily IPv4 -InterfaceIndex $adapter.ifIndex -ErrorAction SilentlyContinue
        foreach ($addr in $addrs) {
            if ($addr.IPAddress -like '127.*' -or $addr.IPAddress -like '169.254.*') { continue }
            $isVirtual = $false
            foreach ($prefix in $virtualPrefix) {
                if ($addr.IPAddress.StartsWith($prefix)) { $isVirtual = $true; break }
            }
            if ($isVirtual) { continue }

            $isWiFi = ($adapter.MediaType -eq 'Native 802.11' -or $adapter.Name -match 'Wi-?Fi|WLAN|Wireless')

            $candidates += [PSCustomObject]@{
                IP              = $addr.IPAddress
                InterfaceMetric = $addr.InterfaceMetric
                Adapter         = $adapter.Name
                MediaType       = $adapter.MediaType
                IsWiFi          = $isWiFi
            }
        }
    }

    if (-not $candidates.Count) { return $null }

    $wifi = $candidates | Where-Object { $_.IsWiFi } | Sort-Object InterfaceMetric | Select-Object -First 1
    if ($wifi) { return $wifi }

    $ethernet = $candidates | Where-Object { $_.MediaType -eq '802.3' } | Sort-Object InterfaceMetric | Select-Object -First 1
    if ($ethernet) { return $ethernet }

    return $candidates | Sort-Object InterfaceMetric | Select-Object -First 1
}

function Get-DemoLanIpCandidates {
    $virtualPrefix = @(
        '192.168.56.', '192.168.57.', '192.168.58.',
        '172.17.', '172.18.', '172.19.'
    )

    $adapters = Get-NetAdapter -ErrorAction SilentlyContinue | Where-Object { $_.Status -eq 'Up' }
    $all = @()
    foreach ($adapter in $adapters) {
        $addrs = Get-NetIPAddress -AddressFamily IPv4 -InterfaceIndex $adapter.ifIndex -ErrorAction SilentlyContinue
        foreach ($addr in $addrs) {
            if ($addr.IPAddress -like '127.*' -or $addr.IPAddress -like '169.254.*') { continue }
            $tag = ''
            foreach ($prefix in $virtualPrefix) {
                if ($addr.IPAddress.StartsWith($prefix)) { $tag = 'virtual'; break }
            }
            $all += [PSCustomObject]@{
                IP      = $addr.IPAddress
                Adapter = $adapter.Name
                Tag     = $tag
            }
        }
    }
    return $all
}
