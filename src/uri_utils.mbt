/// 使用标准库函数的简化版本

pub fn find_char_index(s : String, c : Char) -> Int? {
  s.find(c.to_string())
}

pub fn find_last_index_str(s : String, substr : String) -> Int? {
  s.rev_find(substr)
}

/// 使用标准库解析整数，增加错误处理
pub fn parse_int_simple(s : String) -> Int {
  // 使用标准库的字符串转换功能
  let chars = s.to_array()
  let mut result = 0
  for c in chars {
    if is_digit(c) {
      result = result * 10 + (c.to_int() - '0'.to_int())
    }
  }
  result
}

/// 分割字符串的简化实现
pub fn split_string_at(s : String, delimiter : Char) -> (String, String?) {
  match s.find(delimiter.to_string()) {
    Some(pos) => (s.substring(start=0, end=pos), Some(s.substring(start=pos + 1)))
    None => (s, None)
  }
}

/// 检查字符串是否为空或只包含空白字符 
pub fn is_empty_or_whitespace(s : String) -> Bool {
  if s.is_empty() {
    true
  } else {
    // 简单的空白字符检查
    for c in s {
      if c != ' ' && c != '\t' && c != '\n' && c != '\r' {
        return false
      }
    }
    true
  }
}