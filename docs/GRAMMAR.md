# Formal Grammar Specification

**Mini Language Compiler — Compiler Construction Lab, Metropolitan University**

This document defines the complete Context-Free Grammar (CFG) for the mini language
specified in Section 5 of the project manual. It is the authoritative reference for
the Bison parser (`src/parser/parser.y`) and for Chapter 7 of the project report.

The grammar is written in a BNF-style notation:

- Uppercase words in the productions that map to `%token` names (e.g. `INT`, `IF`,
  `IDENTIFIER`) are **terminals** produced by the lexer.
- Lowercase italic-style names (e.g. `program`, `statement`, `expression`) are
  **non-terminals**.
- `ε` denotes the empty production.
- `|` separates alternatives.

---

## 1. Tokens (terminals)

These are the terminal symbols the lexer must emit. They correspond directly to
Sections 5.1–5.4 of the manual.

### Keywords
```
INT      -> "int"
FLOAT    -> "float"
BOOL     -> "bool"
IF       -> "if"
ELSE     -> "else"
WHILE    -> "while"
PRINT    -> "print"
TRUE     -> "true"
FALSE    -> "false"
```

### Identifiers and literals
```
IDENTIFIER   -> letter or '_' , followed by letters, digits, or '_'
INT_LIT      -> one or more digits          (e.g. 42)
FLOAT_LIT    -> digits '.' digits           (e.g. 3.14)
```
(Boolean literals are the keywords `TRUE` / `FALSE` above, not a separate token class.)

### Operators
```
PLUS  '+'     MINUS '-'     TIMES '*'     DIVIDE '/'    MOD '%'
LT '<'   GT '>'   LE '<='   GE '>='   EQ '=='   NE '!='
AND '&&'   OR '||'   NOT '!'
ASSIGN '='
```

### Delimiters
```
LBRACE '{'   RBRACE '}'   LPAREN '('   RPAREN ')'   SEMICOLON ';'
```

---

## 2. Operator precedence and associativity

The manual requires that arithmetic expressions respect operator precedence
(Section 4.6). Rather than encoding precedence by stratifying the grammar into many
levels, we write a single `expression` non-terminal and resolve ambiguity with Bison
`%left` / `%right` / `%nonassoc` declarations. This keeps the grammar readable and is
the standard, viva-defensible approach.

Precedence, from **lowest** (binds loosest) to **highest** (binds tightest):

| Level | Operators        | Associativity | Bison declaration        |
|-------|------------------|---------------|--------------------------|
| 1     | `\|\|`           | left          | `%left OR`               |
| 2     | `&&`             | left          | `%left AND`              |
| 3     | `== !=`          | left          | `%left EQ NE`            |
| 4     | `< > <= >=`      | left          | `%left LT GT LE GE`      |
| 5     | `+ -`            | left          | `%left PLUS MINUS`       |
| 6     | `* / %`          | left          | `%left TIMES DIVIDE MOD` |
| 7     | `!`, unary `-`   | right         | `%right NOT UMINUS`      |

Notes:
- `UMINUS` is a **precedence pseudo-token** for unary minus (e.g. `-x`). The rule
  `expression: MINUS expression` is tagged `%prec UMINUS` so that unary minus binds
  tighter than any binary operator, independent of the binary `MINUS`.
- Logical `!` and unary `-` are right-associative (prefix operators).

---

## 3. Grammar productions

### 3.1 Program structure

```
program        -> statement_list

statement_list -> statement_list statement
                | ε
```

A program is a (possibly empty) sequence of statements. Left recursion is used
deliberately — Bison (an LALR parser) handles left recursion efficiently and without
stack growth, unlike a recursive-descent parser.

### 3.2 Statements

```
statement -> declaration
           | assignment
           | if_statement
           | while_statement
           | print_statement
           | block
```

### 3.3 Declarations

```
declaration -> type IDENTIFIER SEMICOLON

type        -> INT
             | FLOAT
             | BOOL
```

The manual's grammar (Section 5.2) lists declaration as `int x;` — a type followed by
a single identifier. We do **not** support multiple declarations per line
(`int x, y;`) or declaration-with-initialization (`int x = 5;`) because Section 5 does
not require them. Assignment is a separate statement.

### 3.4 Assignment

```
assignment -> IDENTIFIER ASSIGN expression SEMICOLON
```

### 3.5 Control flow

```
if_statement -> IF LPAREN expression RPAREN statement
              | IF LPAREN expression RPAREN statement ELSE statement

while_statement -> WHILE LPAREN expression RPAREN statement
```

**Dangling else.** The two `if` alternatives above are ambiguous: in
`if (a) if (b) s1 else s2`, the `else` could attach to either `if`. This is the
classic dangling-else conflict and Bison will report a shift/reduce conflict on it.
The standard resolution — which we adopt — is to let Bison's **default shift** bind
the `else` to the nearest (innermost) `if`, which is the conventional and correct
behavior for C-like languages. This is documented here so the shift/reduce conflict in
the parser output is understood and expected, not a bug. (It can optionally be silenced
with `%expect 1` or a `%nonassoc` precedence trick on `ELSE`.)

Note that the body of `if`/`while` is a single `statement`. Because `block` is one of
the statements (3.6), `if (a) { ... }` works: the block *is* a statement.

### 3.6 Blocks (nested scopes)

```
block -> LBRACE statement_list RBRACE
```

A block introduces a new scope. The manual (Sections 4.4, 5.2) requires nested blocks
with proper scoping — a variable declared inside a block must not be visible outside
it. The grammar only defines the *structure* of a block; scope entry/exit is handled
by the symbol table when the semantic analyzer walks the AST for `{` and `}`.

### 3.7 Print

```
print_statement -> PRINT expression SEMICOLON
```

The manual writes `print a` (Section 4.6). We accept any `expression`, not just a bare
identifier, so `print x + 1;` is valid — this is a superset of the requirement and
strictly safer.

### 3.8 Expressions

A single `expression` non-terminal, disambiguated by the precedence table in Section 2:

```
expression -> expression PLUS   expression
            | expression MINUS  expression
            | expression TIMES  expression
            | expression DIVIDE expression
            | expression MOD    expression
            | expression LT     expression
            | expression GT     expression
            | expression LE     expression
            | expression GE     expression
            | expression EQ     expression
            | expression NE     expression
            | expression AND    expression
            | expression OR     expression
            | NOT expression
            | MINUS expression            %prec UMINUS
            | LPAREN expression RPAREN
            | IDENTIFIER
            | INT_LIT
            | FLOAT_LIT
            | TRUE
            | FALSE
```

Parentheses are handled by `LPAREN expression RPAREN` and are stripped when building
the AST (they only affect parse structure, not the tree).

---

## 4. Complete grammar (quick reference)

```
program         -> statement_list

statement_list  -> statement_list statement
                 | ε

statement       -> declaration
                 | assignment
                 | if_statement
                 | while_statement
                 | print_statement
                 | block

declaration     -> type IDENTIFIER SEMICOLON
type            -> INT | FLOAT | BOOL

assignment      -> IDENTIFIER ASSIGN expression SEMICOLON

if_statement    -> IF LPAREN expression RPAREN statement
                 | IF LPAREN expression RPAREN statement ELSE statement

while_statement -> WHILE LPAREN expression RPAREN statement

print_statement -> PRINT expression SEMICOLON

block           -> LBRACE statement_list RBRACE

expression      -> expression PLUS   expression
                 | expression MINUS  expression
                 | expression TIMES  expression
                 | expression DIVIDE expression
                 | expression MOD    expression
                 | expression LT     expression
                 | expression GT     expression
                 | expression LE     expression
                 | expression GE     expression
                 | expression EQ     expression
                 | expression NE     expression
                 | expression AND    expression
                 | expression OR     expression
                 | NOT expression
                 | MINUS expression   %prec UMINUS
                 | LPAREN expression RPAREN
                 | IDENTIFIER
                 | INT_LIT
                 | FLOAT_LIT
                 | TRUE
                 | FALSE
```

---

## 5. Worked example

The sample program from Section 5.5 of the manual, and how it derives:

```
int x;
int y;
bool flag;
x = 10;
y = 0;
flag = true;
while (x > 0) {
    y = y + x;
    x = x - 1;
}
if (flag == true) {
    print y;
} else {
    print x;
}
```

- `int x;` → `declaration` → `type(INT) IDENTIFIER(x) SEMICOLON`
- `x = 10;` → `assignment` → `IDENTIFIER(x) ASSIGN expression(INT_LIT 10) SEMICOLON`
- `while (x > 0) { ... }` → `while_statement`, condition `x > 0` is
  `expression LT/GT expression`, body is a `block` opening a new scope
- `if (flag == true) { ... } else { ... }` → the two-armed `if_statement`, each arm a
  `block`

Every construct in the sample program is covered by the grammar above, confirming the
grammar accepts the required language.

---

## 6. What is intentionally excluded

Per Section 6 of the manual ("What Is Not Required"), the grammar does **not** include:
functions, arrays, `for` / `do-while` loops, `switch`, multiple declaration per line,
declaration-with-initialization, increment/decrement, or string types. These are
Section 14 bonus features and would be added as separate productions only after the
core language is complete.
