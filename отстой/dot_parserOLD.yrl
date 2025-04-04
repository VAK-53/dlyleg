Terminals '[' ']' '{' '}' ',' '=' ';' op digraph graph node edge word int float string. % subgraph
Nonterminals branch stmt_list attr_stmt stmt attr_list node_stmt edge_stmt edgeRHS a_para node_list gr_attr_list.
Rootsymbol branch.

branch       -> digraph word '{' stmt_list '}'   : [ [extract_token('$1'), extract_word('$2') ] | '$4'].
branch       -> graph word '{' stmt_list '}'     : [ [extract_token('$1'), extract_word('$2') ] | '$4'].

stmt_list   -> stmt stmt_list     : [ '$1' | '$2' ].
stmt_list   -> stmt               : [ '$1'].

stmt        -> edge_stmt ';'      :  '$1'.
stmt        -> node_stmt ';'      :  '$1'.
stmt        -> attr_stmt ';'      :  '$1'.
stmt        -> a_para ';'         :  '$1'. % атрибуты графа

edge_stmt   -> word edgeRHS                     : [extract_head('$2'), extract_word('$1')| extract_tail('$2')].
edge_stmt   -> word edgeRHS '[' attr_list ']'   : [extract_head('$2'), extract_word('$1')| extract_tail('$2')] ++ ['$4'].
node_stmt   -> word                             : [ node, extract_word('$1') ].
node_stmt   -> word '[' attr_list ']'           : [ node, extract_word('$1') , '$3' ].

attr_stmt   -> node '[' attr_list  ']'    : [ node_attrs, '$3' ].
attr_stmt   -> edge '[' attr_list  ']'    : [ edge_attrs, '$3' ].


edgeRHS     -> op word                   : [ op , [extract_word('$2')]].
edgeRHS     -> op '{' node_list '}'      : [ extract_token('$1'), '$3' ].
edgeRHS     -> op word edgeRHS           : [ extract_token('$1'), extract_word('$2') | extract_tail('$3')].

node_list   -> word ';' node_list          : [ extract_word('$1') | '$3' ].
node_list   -> word                        : [ extract_word('$1')].
attr_list   -> a_para ',' attr_list        : [ '$1' | '$3' ].
attr_list   -> a_para                      : [ '$1' ].

a_para      -> word '=' word        : [list_to_atom(extract_word('$1')), extract_word('$3')].
a_para      -> word '=' int         : [list_to_atom(extract_word('$1')), extract_int('$3')].
a_para      -> word '=' float       : [list_to_atom(extract_word('$1')), extract_float('$3')].
a_para      -> word '=' string      : [list_to_atom(extract_word('$1')), extract_string('$3')].

Erlang code.

extract_word({word, _, Word})       ->  Word.
extract_int({int, _, Int})          ->  Int.
extract_float({float, _, Float})    ->  Float.
extract_string({string, _, String}) ->  String.
extract_token({Token, _})           ->  Token.
extract_tail([_ | Tail])            ->  Tail.
extract_head([Head | _])            ->  Head.
