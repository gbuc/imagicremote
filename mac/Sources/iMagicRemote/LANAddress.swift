import Darwin
import Foundation

enum LANAddress {
  static func ipv4() -> String? {
    var addrList: UnsafeMutablePointer<ifaddrs>?
    guard getifaddrs(&addrList) == 0, let first = addrList else { return nil }
    defer { freeifaddrs(addrList) }
    var cursor: UnsafeMutablePointer<ifaddrs>? = first
    while let ptr = cursor {
      let flags = Int32(ptr.pointee.ifa_flags)
      let up = (flags & IFF_UP) != 0 && (flags & IFF_LOOPBACK) == 0
      if up, let addr = ptr.pointee.ifa_addr, addr.pointee.sa_family == UInt8(AF_INET) {
        var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
        let result = getnameinfo(
          addr,
          socklen_t(addr.pointee.sa_len),
          &hostname,
          socklen_t(hostname.count),
          nil,
          0,
          NI_NUMERICHOST
        )
        if result == 0 {
          let ip = String(cString: hostname)
          if !ip.hasPrefix("127.") && !ip.hasPrefix("169.254.") {
            return ip
          }
        }
      }
      cursor = ptr.pointee.ifa_next
    }
    return nil
  }
}
