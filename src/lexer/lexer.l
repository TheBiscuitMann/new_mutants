%{
#include <stdio.h>
#include <stdlib.h>

/* in order to report error, line counting has been included as per the instruction manual */
int line_count = 1;
%}

%option noyywrap

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
\n		{ line_count++; }

  /*	Comments: discarded, not tokenized as per the instruction manul		*/
"//"[^\n]*	{ /* single line comment will be ignored to end of line */}
"/*"([^*]|\*+[^*/])*\*+"/"	{
			for (char *p = yytext; *p; p++)
				if(*p == '\n') line_count++;
		}

  /* keywords!! they must come before the identifier rule */
"int"		{ printf("Keyword(int)\n"); }
"float"		{ printf("Keywod(float)\n"); }
"bool"		{ printf("Keyword(boolean)\n"); }
"if"		{ printf("Keyword(if)\n"); }
"else"		{ printf("Keyword(else)\n"); }
"while"		{ printf("Keyword(while)\n"); }
"print"		{ printf("Keyword(print)\n"); }
"true"		{ printf("Boolean Literal(true)\n"); }
"false"		{ printf("Boolean Literal(false)\n"); }

{FLOAT_LIT}	{ printf("FLOAT Literal(%s)\n", yytext); }
{INT_LIT}	{ printf("INT Literal(%s)\n", yytext); }

  /* Identifier */

{ID}		{ printf("Identifier(%s)\n", yytext); }

  /*	operators that has more than one char must be listed before their single char prefixes	*/

"<="		{ printf("Relational Operator(<=)\n"); }
">="		{ printf("Relational Operator(>=)\n"); }
"=="		{ printf("Relational Operator(==)\n"); }
"!="		{ printf("Operator(!=)\n"); }
"&&"		{ printf("Operator(&&)\n"); }
"||"		{ printf("Operator(||)\n"); }

"+"		{ printf("Operator(+)\n"); }
"-"		{ printf("Operator(-)\n"); }
"*"		{ printf("Operator(*)\n"); }
"/"		{ printf("Operator(/)\n"); }
"%"		{ printf("Operator(%%)\n"); }
"<"		{ printf("Relational Operator(<)\n"); }
">"		{ printf("Relational Operator(>)\n"); }
"!"		{ printf("Operator(!)\n"); }
"="		{ printf("Assignment Operator(=)\n"); }


"{"		{ printf("LBrace\n"); }
"}"		{ printf("RBrace\n"); }
"("		{ printf("LParenthesis\n"); }
")"		{ printf("RParenthesis\n"); }
";"		{ printf("Punctuator(;)\n"); }

  /* Anything else is a lexical error */

.		{ printf("Lexical Error: unexpected character '%s' on line %d\n", yytext, line_count); }

%%

int main(int argc, char **argv)
{
	if(argc > 1) {
		FILE *f = fopen(argv[1], "r");
		if(!f) {
			fprintf(stderr, "Error: cant open file '%s'\n", argv[1]);
			return 1;
		}
		yyin = f;
	}
	yylex();
	return 0;
}
