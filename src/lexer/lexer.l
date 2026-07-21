%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "parser.tab.h"

/* in order to report error, line counting has been included as per the instruction manual */
/* int line_count = 1; */
%}

%option noyywrap yylineno

/*making the regex definitions */

DIGIT		[0-9]
LETTER		[a-zA-Z]
ID		({LETTER}|_)({LETTER}|{DIGIT}|_)*
INT_LIT		{DIGIT}+
FLOAT_LIT	{DIGIT}+"."{DIGIT}+
%%
  /*	flex uses the longest match rule, and on ties the first rule wins	*/
  /*	whitespace will be discarded but newlines will bumb the line counter variable	 */
[ \t\r]+	{ /* ignore spaces and tabbs */}
\n		{ /* no need to count manually, yylineno will handle */ }

  /*	Comments: discarded, not tokenized as per the instruction manul		*/
"//"[^\n]*	{ /* single line comment will be ignored to end of line */}
"/*"([^*]|\*+[^*/])*\*+"/"	{ /* yylineno will do the counting, so removed the loop */ }

  /* keywords!! they must come before the identifier rule */
"int"		{ return INT; }
"float"		{ return FLOAT; }
"bool"		{ return BOOL; }
"if"		{ return IF; }
"else"		{ return ELSE; }
"while"		{ return WHILE; }
"print"		{ return PRINT; }
"true"		{ return TRUE; }
"false"		{ return FALSE; }

{FLOAT_LIT}	{ yylval.fval = atof(yytext); return FLOAT_LIT; }
{INT_LIT}	{ yylval.ival = atoi(yytext); return INT_LIT; }

  /* Identifier */

{ID}		{ yylval.sval = strdup(yytext); return IDENTIFIER; }

  /*	operators that has more than one char must be listed before their single char prefixes	*/

"<="		{ return LE; }
">="		{ return GE; }
"=="		{ return EQ; }
"!="		{ return NE; }
"&&"		{ return AND; }
"||"		{ return OR; }

"+"		{ return PLUS; }
"-"		{ return MINUS; }
"*"		{ return TIMES; }
"/"		{ return DIVIDE; }
"%"		{ return MOD; }
"<"		{ return LT; }
">"		{ return GT; }
"!"		{ return NOT; }
"="		{ return ASSIGN; }


"{"		{ return LBRACE; }
"}"		{ return RBRACE; }
"("		{ return LPAREN; }
")"		{ return RPAREN; }
";"		{ return SEMICOLON; }

  /* Anything else is a lexical error */

.		{ printf("Lexical Error: unexpected character '%s' on line %d\n", yytext, yylineno); }

%%
