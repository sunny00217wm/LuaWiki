local re = require('lpeg.re')

local defs = {
  cr = lpeg.P('\r'),
  t = lpeg.P('\t'),
  merge_text = function(a, b) return a .. b end,
  gen_heading = function(v)
    local htag = 'h' .. #v.htag
    return '<' .. htag .. '>' .. v[1]:gsub('^[ ]*', ''):gsub('[ ]*$', '') ..
      '</' .. htag .. '>'
  end,
  gen_list = function(t)
    local str = ''
    for i, v in ipairs(t) do
      str = str .. '<li>' .. v[2] .. '</li>'
    end
    return '<ul>' .. str .. '</ul>'
  end,
  gen_par_plus = function(t)
    local p_content = table.concat(t)
    if p_content == '' then p_content = '<br>' end
    local str = '<p>' .. p_content .. '</p>'
    if t.special then str = str .. t.special end
    return str
  end,
  gen_link = function(a, b)
    local s = '<a href="/wiki/' .. a .. '">'
    if b then return s .. b .. '</a>'
    else return s .. a .. '</a>' end
  end
}

local wiki_grammar = re.compile([==[
  article        <- ((special_block / paragraph_plus / block) block*) ~> merge_text
  block          <- sol? (special_block / paragraph_plus)

  paragraph_plus <- {| (newline / pline) latter_plines? |} -> gen_par_plus
  latter_plines  <- {:special: special_block :} / pline latter_plines?
  pline          <- (formatted newline -> ' ') ~> merge_text
  special_block  <- &[-={*#:;] (horizontal_rule / heading / list_block / table) newline?
  
  horizontal_rule <- ('-'^+4 -> '<hr>' (formatted -> '<p>%1</p>')?) ~> merge_text
  heading        <- {| heading_tag {[^=]+} =htag [ %t]* |} -> gen_heading
  heading_tag    <- {:htag: '=' '='^-6 :}
  list_block     <- {| list_item (newline list_item)* |} -> gen_list
  list_item      <- {| {list_char+} list_body |}
  list_char      <- [*#:;]
  list_body      <- __ formatted
  table          <- { '{|' (!'|}' .)* '|}' }
  
  formatted      <- (bold_text / italic_text / {"'"}? plain_text)+ ~> merge_text
  bold_text      <- ("'''" (italic_text / {"'"}? plain_text)+ ~> merge_text "'''") -> '<b>%1</b>'
  italic_text    <- ("''" (bold_text / {"'"}? plain_text)+ ~> merge_text "''") -> '<i>%1</i>'
  plain_text     <- (inline_element / {[^%cr%nl'] [^%cr%nl[{']*})+ ~> merge_text
  inline_element <- link
  link           <- ('[[' {link_part} ('|' {link_part})? ']]') -> gen_link
  link_part      <- (!'|' !']' .)+
  sol            <- __ newline
  __             <- [ \t]*
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
