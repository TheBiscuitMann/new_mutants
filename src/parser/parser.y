%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

extern int yylex();
extern int yylineno;
void yyerror(const char *s);
%}

/* Semantic Value Union */
%union {
    int ival;
    float fval;
    char *sval;
    /* AST node pointer will be added here in a later phase */
}

/* Tokens (Terminals) */
%token INT FLOAT BOOL IF ELSE WHILE PRINT TRUE FALSE
%token <sval> IDENTIFIER
%token <ival> INT_LIT
%token <fval> FLOAT_LIT
%token PLUS MINUS TIMES DIVIDE MOD
%token LT GT LE GE EQ NE
%token AND OR NOT
%token ASSIGN
%token LBRACE RBRACE LPAREN RPAREN SEMICOLON

/* Operator Precedence and Associativity (lowest to highest) */
%left OR
%left AND
%left EQ NE
%left LT GT LE GE
%left PLUS MINUS
%left TIMES DIVIDE MOD
%right NOT UMINUS

/* Starting Non-Terminal */
%start program

%%

/* 3.1 Program structure */
program:
      statement_list
    ;

statement_list:
      statement_list statement
    | /* empty (ε) */
    ;

/* 3.2 Statements */
statement:
      declaration
    | assignment
    | if_statement
    | while_statement
    | print_statement
    | block
    ;

/* 3.3 Declarations */
declaration:
      type IDENTIFIER SEMICOLON
    ;

type:
      INT
    | FLOAT
    | BOOL
    ;

/* 3.4 Assignment */
assignment:
      IDENTIFIER ASSIGN expression SEMICOLON
    ;

/* 3.5 Control flow */
if_statement:
      IF LPAREN expression RPAREN statement
    | IF LPAREN expression RPAREN statement ELSE statement
    ;

while_statement:
      WHILE LPAREN expression RPAREN statement
    ;

/* 3.6 Blocks (nested scopes) */
block:
      LBRACE statement_list RBRACE
    ;

/* 3.7 Print */
print_statement:
      PRINT expression SEMICOLON
    ;

/* 3.8 Expressions */
expression:
      expression PLUS expression
    | expression MINUS expression
    | expression TIMES expression
    | expression DIVIDE expression
    | expression MOD expression
    | expression LT expression
    | expression GT expression
    | expression LE expression
    | expression GE expression
    | expression EQ expression
    | expression NE expression
    | expression AND expression
    | expression OR expression
    | NOT expression
    | MINUS expression %prec UMINUS
    | LPAREN expression RPAREN
    | IDENTIFIER
    | INT_LIT
    | FLOAT_LIT
    | TRUE
    | FALSE
    ;

%%

/* Error reporting function */
void yyerror(const char *s) {
    fprintf(stderr, "Syntax Error on line %d: %s\n", yylineno, s);
}

/* Main function for the parser side */
int main(void) {
    if (yyparse() == 0) {
        printf("Parsing completed successfully!\n");
    }
    return 0;
}