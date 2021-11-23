// https://github.com/peggyjs/peggy/blob/main/examples/json.pegjs
// https://github.com/pegjs/pegjs/blob/master/examples/javascript.pegjs
// https://dev.to/meseta/peg-parsers-sometimes-more-appropriate-than-regex-4jkk

// JSON Grammar
// ============
//
// Based on the grammar from RFC 7159 [1].
//
// Note that JSON is also specified in ECMA-262 [2], ECMA-404 [3], and on the
// JSON website [4] (somewhat informally). The RFC seems the most authoritative
// source, which is confirmed e.g. by [5].
//
// [1] http://tools.ietf.org/html/rfc7159
// [2] http://www.ecma-international.org/publications/standards/Ecma-262.htm
// [3] http://www.ecma-international.org/publications/standards/Ecma-404.htm
// [4] http://json.org/
// [5] https://www.tbray.org/ongoing/When/201x/2014/03/05/RFC7159-JSON

{
  var current_parent = options.parent;
  var current_env = null;
  var vz = options.vz;
  var parents_stack = [];
}

// ----- 2. JSON Grammar -----

JSON_text
  = ws @env_list ws

begin_array     = ws "[" ws
begin_object    = ws "{" ws
end_array       = ws "]" ws
end_object      = ws "}" ws
name_separator  = ws ":" ws
value_separator = ws "," ws

ws "whitespace" = [ \t\n\r]*

// ----- A1. env items
env_modifier
  = attr_assignment
  / link_assignment
  / feature_addition
 
// ----- A2. attr_assignment
attr_assignment
  = name:attr_name ws "=" ws value:value {
    //console.log("AAAAAAAAAAAAAAAA",value);
    if (current_env.parsed_alive === undefined) current_env.parsed_alive = true;
    current_env.setParam( name, value );
  }
  
link_assignment
  = name:attr_name ws "=" ws linkvalue:link {
    console.log("LINK",linkvalue);
    if (current_env.parsed_alive === undefined) current_env.parsed_alive = true;
    current_env.linkParam( name, linkvalue.value );
  }
  / linkvalue:link {
    var re = linkvalue.value.replaceAll("->.","->output");
    console.log("POSITIONAL LINK",linkvalue,re);
    current_env.linkParam( "input", re );
  }
  
feature_addition
  = name:attr_name {
    if (current_env.parsed_alive === undefined) current_env.parsed_alive = true;
    current_env.feature( name );
  }
  
// ------ A3. attr_name
Word
  = [a-zA-Z0-9_-]+ { return text(); }

attr_name
  = Word

obj_id
  = [a-zA-Z0-9_]+ { return text(); }

// ------- A. envs
one_env
  =
  (__ envid:(attr_name ws ":")? {
    current_env = vz.createObj( {parent:current_parent, name: (envid || [])[0]} );
    parents_stack.push(current_parent);
    current_parent = current_env;
    current_env.finalize_parse = () => { 
       current_parent = parents_stack.pop() 
       if (!current_env.parsed_alive) current_env.remove();
    };
    // + еще событие надо будет
  })
  __
  env_modifiers:(head:env_modifier tail:(__ @env_modifier)*)*
  child_envs:(__ "{" ws env_list ws "}" __)*
  {
    current_env.finalize_parse();
    if (!current_env.removed)
         return current_env;
  }

env
  = env_pipe
//  = one_env  
//  / one_env
  
env_pipe
 = head:one_env tail:(__ "|" @one_env)*
 {
   console.log("found env pipe:",head,tail)
   for (var i=0; i<tail.length; i++);
 }
  
env_list
  = head:env tail:(__ ";" @env)*

link
  = "@" obj_id "->" attr_name
  {
    return { link: true, value: text() }
  }
  / "@" obj_id
  {
    return { link: true, value: text() + "->." }
  }

// ----- 3. Values -----

value
  = false
  / null
  / true
  / object
  / array
  / number
  / string

false = "false" { return false; }
null  = "null"  { return null;  }
true  = "true"  { return true;  }

// ----- 4. Objects -----

object
  = begin_object
    members:(
      head:member
      tail:(value_separator @member)*
      {
        var result = {};
        [head].concat(tail).forEach(function(element) {
          result[element.name] = element.value;
        });
        return result;
      }
    )?
    end_object
    { return members !== null ? members: {}; }

member
  = name:string name_separator value:value {
      return { name: name, value: value };
    }

// ----- 5. Arrays -----

array
  = begin_array
    values:(
      head:value
      tail:(value_separator @value)*
      { return [head].concat(tail); }
    )?
    end_array
    { return values !== null ? values : []; }

// ----- 6. Numbers -----

number "number"
  = minus? int frac? exp? { return parseFloat(text()); }

decimal_point
  = "."

digit1_9
  = [1-9]

e
  = [eE]

exp
  = e (minus / plus)? DIGIT+

frac
  = decimal_point DIGIT+

int
  = zero / (digit1_9 DIGIT*)

minus
  = "-"

plus
  = "+"

zero
  = "0"

// ----- 7. Strings -----

string "string"
  = quotation_mark chars:char* quotation_mark { return chars.join(""); }

char
  = unescaped
  / escape
    sequence:(
        '"'
      / "\\"
      / "/"
      / "b" { return "\b"; }
      / "f" { return "\f"; }
      / "n" { return "\n"; }
      / "r" { return "\r"; }
      / "t" { return "\t"; }
      / "u" digits:$(HEXDIG HEXDIG HEXDIG HEXDIG) {
          return String.fromCharCode(parseInt(digits, 16));
        }
    )
    { return sequence; }

escape
  = "\\"

quotation_mark
  = '"'

unescaped
  = [^\0-\x1F\x22\x5C]

// ----- Core ABNF Rules -----

// See RFC 4234, Appendix B (http://tools.ietf.org/html/rfc4234).
DIGIT  = [0-9]
HEXDIG = [0-9a-f]i

///////////////////// comments

// ----- A.1 Lexical Grammar -----

SourceCharacter
  = .

WhiteSpace "whitespace"
  = "\t"
  / "\v"
  / "\f"
  / " "
  / "\u00A0"
  / "\uFEFF"
  / Zs

// Separator, Space
Zs = [\u0020\u00A0\u1680\u2000-\u200A\u202F\u205F\u3000]

LineTerminator
  = [\n\r\u2028\u2029]

LineTerminatorSequence "end of line"
  = "\n"
  / "\r\n"
  / "\r"
  / "\u2028"
  / "\u2029"

Comment "comment"
  = MultiLineComment
  / SingleLineComment

MultiLineComment
  = "/*" (!"*/" SourceCharacter)* "*/"

MultiLineCommentNoLineTerminator
  = "/*" (!("*/" / LineTerminator) SourceCharacter)* "*/"

SingleLineComment
  = "//" (!LineTerminator SourceCharacter)*

__
  = (WhiteSpace / LineTerminatorSequence / Comment)*  