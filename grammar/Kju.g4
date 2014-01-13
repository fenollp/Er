grammar Kju;

root : block+ EOF ;

block : export
      | funDef ;

/// Blanks

Comment : '#' ~[\r\n]* '\r'? '\n' -> channel(HIDDEN) ;

WS : [ \t\r\n]+ -> channel(HIDDEN) ;

/// Ops

compOp : '<' | '=<' | '==' | '=>' | '>' | '/=' | '=/=' | '=:=' ;

listOp : '++' | '--' ;

addOp : '+' | '-' | 'bsl' | 'bsr'
      | 'or' | 'xor' | 'bor' | 'bxor' ;

mulOp : '*' | '/' | 'div' | 'rem' | 'and' | 'band' ;

prefixOp : '+' | '-' | 'not' | 'bnot' ;

end : 'end' | '.' ;

when : 'when' | '|' ;

/// Tokens

atom : Atom ;
Atom : [a-z] ~[ \t\r\n()\[\]{}:;,./]* //[_a-zA-Z0-9]*
     | '\'' ( '\\' (~'\\'|'\\') | ~[\\''] )* '\'' ;
    // Add A-Z to the negative match to forbid camelCase

// When using negative match, be sure to also negative match
//   previously-defined rules.

var : Var ;
Var : [A-Z_][0-9a-zA-Z_]* ;

float_ : Float ;
Float : [0-9]+ '.' [0-9]+  ([Ee] [+-]? [0-9]+)? ;

integer : Integer ;
Integer : [0-9]+ ('#' [0-9a-zA-Z]+)? ;

char_ : Char ;
Char : '$' ('\\'? ~[\r\n] | '\\' [0-9] [0-9] [0-9]) ;

string : String ;
String : '"' ( '\\' (~'\\'|'\\') | ~[\\""] )* '"' ;

atomic : char_
       | integer
       | float_
       | atom
       | string+
       ;

/// export

export : 'export' fa* end ;

fa : atom '/' integer ;

/// funDef

funDef : atom args guard? '=' seqExprs ;

args : '(' exprMs? ')' ;

guard : when exprA ;

/// expr | seqExprs | exprA

expr    : (expr150|lastOnly) ('='|'!') (expr150|lastOnly)
        |  expr150 ;

expr150 : (expr160|lastOnly) 'orelse'  (expr150|lastOnly)
        |  expr160 ;

expr160 : (expr200|lastOnly) 'andalso' (expr160|lastOnly)
        |  expr200 ;

expr200 : (expr300|lastOnly) compOp    (expr200|lastOnly)
        |  expr300 ;

expr300 : (expr400|lastOnly) listOp    (expr300|lastOnly)
        |  expr400 ;

expr400 : (expr500|lastOnly) addOp     (expr400|lastOnly)
        |  expr500 ;

expr500 : (expr600|lastOnly) mulOp     (expr500|lastOnly)
        |  expr600 ;

expr600 :                    prefixOp  (exprMax|lastOnly)
        |                               exprMax ;

exprMax : atomic
        //| recordExpr
        | list
        //| binary
        | tuple
        | lr | br | tr // range
        | lc | bc | tc // comprehension
        | begin
        | if_
        | case_
        | receive
        | fun
        | try_
        ;

lastOnly : var
         | '(' exprA ')' ;

seqExprs : expr+ lastOnly?
         |       lastOnly ;

exprAs : exprA (',' exprA)* ;
exprA : lastOnly | expr    ;

exprMs : exprM (',' exprM)* ;
exprM : lastOnly | exprMax ;

/// Detailed expressions

functionCall : mf  args
             | ':' args ;

//recordExpr : '‹'

list : '['       ']'
     | '[' exprA tail ;
tail :           ']'
     | '|' exprA ']'
     | ',' exprA tail ;

// binary : '<<'

tuple : '{' exprAs? '}' ;

lc :  '[' seqExprs '|' gen+ ']'  ;
bc : '<<' seqExprs '|' gen+ '>>' ;
tc :  '{' seqExprs '|' gen+ '}'  ;

lr :  '[' exprA '..' exprA ']'  ;
br : '<<' exprA '..' exprA '>>' ;
tr :  '{' exprA '..' exprA '}'  ;

begin : 'begin' seqExprs 'end' ;

if_ : 'if' exprA 'then' seqExprs 'else' seqExprs end ;

case_ : 'case' exprA of end ;

receive : 'receive' clauses                end
        | 'receive'         'after' clause end
        | 'receive' clauses 'after' clause end ;

fun : 'fun' mf      '/' exprM
    | 'fun' mf args '/' exprM
    | 'fun' args guard? '->' seqExprs end ; //clauses+?

try_ : 'try' seqExprs of? 'catch' catchClauses                  end
     | 'try' seqExprs of? 'catch' catchClauses 'after' seqExprs end
     | 'try' seqExprs of?                      'after' seqExprs end ;

/// Utils

clauses : (clause | clauseGuard)+ ;
clause :      exprM       '->' seqExprs ;
clauseGuard : exprM guard '->' seqExprs ;

mf :           exprM
   |       ':' exprM
   | exprM ':' exprM ; //funccall should be possible

gen :                        exprA
    | exprM ('<-'|'<='|'<~') exprA ;

catchClauses : catchClause+ ;
catchClause : exprM? ':'? (clause|clauseGuard) ;

of : 'of' clauses ;
