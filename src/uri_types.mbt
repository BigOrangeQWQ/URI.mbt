///| URI library based on RFC 3986
pub(all) enum PathType {
  AbEmpty
  Absolute
  NoScheme
  Rootless
  Empty
} derive(Eq, Show)

///|
pub(all) enum HostType {
  IPv4(String)
  IPv6(String)
  IPvFuture(String)
  RegName(String)
} derive(Eq, Show)

///|
pub(all) struct Authority {
  userinfo : String?
  host : HostType
  port : Int?
} derive(Eq, Show)

///|
pub(all) struct URI {
  scheme : String
  authority : Authority?
  path : String
  path_type : PathType
  query : String?
  fragment : String?
} derive(Eq, Show)

///|
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

///|
pub typealias Result[T, URIError] as URIResult[T]

///|
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
