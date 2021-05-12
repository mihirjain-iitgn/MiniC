%{
#include <string.h>
#include <stdlib.h>
#include "parser.tab.h"

int charPos = 1;

int token_pos = 0;

int commentNesting = 0;

extern int lines;
%}

identifier [a-z]+
digits [0-9]+
%x COMMENT
%%


[\r\t] { continue;}
if   { return IF;}
main { return MAIN;}
int  { return INT;}
else { return ELSE;}
while { return WHILE;}
for  	 { return FOR;}
return    { return RETURN;}
true      { return TRUE;}
false     { return FALSE;}
input     { return INPUT;}
print     { return PRINT;}
void     { return VOID;}
";" { return SEMICOLON;}
"(" { return LPAREN;}
")" { return RPAREN;}
"[" { return LBRACK;}
"]" { return RBRACK;}
"{" { return LBRACE;}
"}" { return RBRACE;}
"+" { return PLUS;}
"-" { return MINUS;}
"*" { return MUL;}
"/" { return DIV;}
"==" { return EQ;}
"!=" { return NEQ;}
"<" { return LT;}
"<=" { return LE;}
">" { return GT;}
">=" { return GE;}
"&&" { return AND;}
"||" { return OR;}
"=" { return ASSIGN;}
"%" { return MOD;}
","	 { return COMMA;}

"/*" { commentNesting++; BEGIN(COMMENT);}
"*/" { printf("close comment before open it line %d postion %d\n",lines,token_pos); exit(0);}
" "	 { continue;}
\n	 { lines++; charPos = 0; continue;}

{digits}	 { sscanf(yytext,"%d",&yylval.val); return NUM;}
{identifier} { strcpy(yylval.id, yytext); return ID;}

.	 { printf("illegal token at line %d postion %d\n", lines, token_pos); exit(0);}


<COMMENT>{
    "/*" {
        
        commentNesting++;
        continue;
    }
    "*/" {
        
        commentNesting--;
        if(commentNesting == 0){
            BEGIN(INITIAL);
        }
    }
    . {}       
}
%%
