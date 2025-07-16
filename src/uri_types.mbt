/// URI library based on RFC 3986 ABNF specification
/// Provides parsing, validation, and creation of URIs

///| Represents the different types of paths in a URI
pub(all) enum PathType {
  AbEmpty // begins with "/" or is empty
  Absolute // begins with "/" but not "//"
  NoScheme // begins with a non-colon segment
  Rootless // begins with a segment
  Empty // zero characters
} derive(Eq, Show)

///| Represents different types of hosts
pub(all) enum HostType {
  IPv4(String) // IPv4 address
  IPv6(String) // IPv6 address  
  IPvFuture(String) // Future IP version
  RegName(String) // Regular name (domain name)
} derive(Eq, Show)

///| Represents a parsed URI authority component
pub(all) struct Authority {
  userinfo : String? // optional userinfo
  host : HostType // host (required)
  port : Int? // optional port number
} derive(Eq, Show)

///| Represents a parsed URI
pub(all) struct URI {
  scheme : String // scheme (required)
  authority : Authority? // optional authority
  path : String // path
  path_type : PathType // type of path
  query : String? // optional query
  fragment : String? // optional fragment
} derive(Eq, Show)

///| Represents parsing errors
pub enum URIError {
  InvalidScheme(String)
  InvalidAuthority(String)
  InvalidHost(String)
  InvalidPort(String)
  InvalidPath(String)
  InvalidQuery(String)
  InvalidFragment(String)
  InvalidPercentEncoding(String)
  MalformedURI(String)
} derive(Eq, Show)

///| Result type for URI operations
pub typealias Result[T, URIError] as URIResult[T]

///| Constructor functions for HostType to enable blackbox testing
pub fn make_ipv4_host(addr : String) -> HostType {
  IPv4(addr)
}

///|
pub fn make_ipv6_host(addr : String) -> HostType {
  IPv6(addr)
}

///|
pub fn make_ipv_future_host(addr : String) -> HostType {
  IPvFuture(addr)
}

///|
pub fn make_reg_name_host(name : String) -> HostType {
  RegName(name)
}
