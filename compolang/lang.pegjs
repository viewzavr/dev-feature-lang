// https://github.com/peggyjs/peggy/blob/main/examples/json.pegjs
// https://github.com/peggyjs/peggy/blob/main/examples/javascript.pegjs
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
  function new_env( name ) {
    var new_env = { features: {}, params: {}, children: {}, links: {} };
    new_env.$base_url = base_url;
    if (!name) name="item";
    new_env.$name = name;
    return new_env;
  }

  function append_children_envs( env, envs ) {
    var counter=0;
    for (let e of envs) {
      if ( Object.keys(e.features).length > 0
        || Object.keys(e.params).length > 0
        || Object.keys(e.children).length > 0
        || Object.keys(e.links).length > 0)
        {
           var cname = e.$name;
           while (env.children[ cname ])
             cname = `${cname}_${counter++}`;

           env.children[ cname ] = e;
        }
    }
  }

  var envs_stack = [];
  var base_url = options.base_url || "";
  var current_env;
  new_env();

  if (!options.base_url) console.error("COMPOLANG PARSER: base_url option is not defined")
}

// ----- 2. JSON Grammar -----

JSON_text
  = ws envs:env_list ws {
     var env = new_env();
     append_children_envs( env, envs );
     return env;
  }

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
    return { param: true, name: name, value: value }
  }
  
link_assignment
  = name:attr_name ws "=" ws linkvalue:link {
    //var linkrecordname = `link_${Object.keys(current_env.links).length}`;
    //while (current_env.links[ linkrecordname ]) linkrecordname = linkrecordname + "x";
    //current_env.links[linkrecordname] = { to: `.->${name}`, from: linkvalue.value };
    return { link: true, to: `.->${name}`, from: linkvalue.value }
    //console.log("LINK",linkvalue);
  }
  
feature_addition
  = name:attr_name {
    return { feature: true, name: name, params: {} }
    //current_env.features[name] = true;
  }
  
// ------ A3. attr_name
Word
  = [a-zA-Z0-9_-]+ { return text(); }

attr_name
  = Word

obj_id
  = [a-zA-Z0-9_]+ { return text(); }

obj_path
  = [\.\/]+ { return text(); }  

// ------- A. envs
one_env
  =
  envid: (__ @(@attr_name ws ":")?)
  env_modifiers:(__ @env_modifier)*
  child_envs:(__ "{" ws @env_list ws "}" __)*
  {
    var env = new_env( envid );
    var linkcounter = 0;
    for (let m of env_modifiers) {
      if (m.feature)
        env.features[ m.name ] = m.params;
      else
      if (m.param)
        env.params[ m.name ] = m.value;
      else
      if (m.link)
        env.links[ `link_${linkcounter++}` ] = { from: m.from, to: m.to }
    }

    append_children_envs( env, child_envs[0] || [] );

    //console.log("final, env.$name=",env.$name)
    if (env.$name == "item" && Object.keys( env.features ).length > 0) {
        env.$name = Object.keys( env.features ).join("_");
    }

    return env;
  }

env
  = __ @env_pipe
//  = one_env  
//  / one_env
  
env_pipe
 = pipeid:(attr_name __ ":")? __ input_link:link tail:(__ "|" @one_env)+
 {
   console.log("found env pipe with input link:",input_link,tail)
   var pipe = new_env( (pipeid || [])[0] );
   pipe.features["pipe"] = true;

   append_children_envs( pipe, tail );

   var input_link_v = input_link.value.replaceAll("->.","->output");
   pipe.links["input"] = { to: ".->input", from: input_link_v}
   //return finish_env();
   return pipe;
 }
 / head:one_env tail:(__ "|" @one_env)*
 {
   if (head && tail.length > 0) {
     console.log("found env pipe of objects:",head,tail)
     // прямо пайпа
     // переименуем голову, т.к. имя заберет пайпа
     var orig_env_id = head.$name;
     head.$name = "head";
     var pipe = new_env( orig_env_id );
     pipe.features["pipe"] = true;
     append_children_envs( pipe, [head,...tail] );
     
     return pipe;
   }
   else {
     return head;
   }
 }
  
env_list
  = head:env tail:(__ ";" @env)* { 
    return [head,...tail]; 
    }

link
  = "@" obj_id "->" attr_name
  {
    return { link: true, value: text() }
  }
  / "@" obj_id
  {
    return { link: true, value: text() + "->." }
  }
  / "@" path:(obj_path "->" attr_name)
  {
    return { link: true, value: path.join("") }
  }
  / "@" path:obj_path 
  {
    return { link: true, value: path + "->." }
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
  = "`" chars:(!"`" SourceCharacter)* "`" { 
    return chars.map(c=>c[1]).join(""); 
  }
  / "'" chars:(!"'" SourceCharacter)* "'" { 
    return chars.map(c=>c[1]).join(""); 
  }
  / "\"" chars:(!"\"" SourceCharacter)* "\"" { 
    return chars.map(c=>c[1]).join(""); 
  }  
  / quotation_mark chars:char* quotation_mark { return chars.join(""); }

//  / quotation_mark2 chars:char* quotation_mark2 { return chars.join(""); }
//  / quotation_mark3 chars:char* quotation_mark3 { return chars.join(""); }

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
quotation_mark2
  = "'"
quotation_mark3
  = "`"

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