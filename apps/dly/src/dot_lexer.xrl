Definitions.

KEYWORDS    = digraph|graph|subgraph|node|edge
WORD        = [a-zA-Z_][a-zA-Z0-9_\.]*
OP          =->
SYMBOLS     =[{}\[\]=;:,]
WHITESPACE  =[\s\t\r\n]+
NUM         =[0-9]+
STRING      ="[^\"]+"
COMMENT     =//.*

Rules.

{KEYWORDS}      : {token, {list_to_atom(TokenChars), TokenLine}}.
% {ATTR_NAME}     : {token, {list_to_atom(TokenChars), TokenLine}}.
{OP}            : {token, {op, TokenLine}}.
{WORD}          : {token, {word,  TokenLine, TokenChars}}.
{NUM}\.{NUM}    : {token, {float, TokenLine, list_to_float(TokenChars)}}.
{NUM}           : {token, {int,   TokenLine, list_to_integer(TokenChars)}}.
{STRING}        : {token, {string,  TokenLine, extract_string(TokenChars)}}.
{SYMBOLS}       : {token, {list_to_atom(TokenChars), TokenLine}}.
{WHITESPACE}    : skip_token.
{COMMENT}       : skip_token.

Erlang code.

extract_string(Chars) ->
    lists:sublist(Chars,2, length(Chars) -2).
