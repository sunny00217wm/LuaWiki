local re = require('lpeg.re')

local defs = {
  cr = lpeg.P('\r'),
  t = lpeg.P('\t'),
  merge_text = function(a, b) return a .. b end,
  gen_header = function(v)
    local htag = 'h' .. #v.htag
    return '<' .. htag .. '>' .. v[1]:gsub('^[ ]*', ''):gsub('[ ]*$', '') ..
      '</' .. htag .. '>'
  end,
  gen_link = function(a, b)
    local s = '<a href="/wiki/' .. a .. '">'
    if b then return s .. b .. '</a>'
    else return s .. a .. '</a>' end
  end
}

local wiki_grammar = re.compile([==[
  article        <- (block (newline block)*) ~> merge_text
  block          <- header / paragraph
  header         <- {| header_tag {[^=]+} =htag [ %t]* |} -> gen_header
  header_tag     <- {:htag: '=' '='^-6 :}
  paragraph      <- (newline / lines_of_text) -> '<p>%1</p>'
  lines_of_text  <- (formatted newline -> ' ')+ ~> merge_text
  formatted      <- (bold_text / italic_text / {"'"}? plain_text)+ ~> merge_text
  bold_text      <- ("'''" (italic_text / {"'"}? plain_text)+ ~> merge_text "'''") -> '<b>%1</b>'
  italic_text    <- ("''" (bold_text / {"'"}? plain_text)+ ~> merge_text "''") -> '<i>%1</i>'
  plain_text     <- (inline_element / {[^%cr%nl'] [^%cr%nl[{']*})+ ~> merge_text
  inline_element <- link
  link           <- ('[[' {link_part} ('|' {link_part})? ']]') -> gen_link
  link_part      <- (!'|' !']' .)+
  newline        <- %cr? %nl
]==], defs)

local wiki_html = wiki_grammar:match[==[
1=0，让世界回归平静

==我推荐的维基工具==
* [[WP:WIZ|创建条目向导]]
* [[WP:上传|文件上传向导]]
]==]

ngx.say('<!DOCTYPE html><html><head><title>维基百科，自由的百科全书</title><head><body>' ..
  (wiki_html or '') .. '</body></html>')
