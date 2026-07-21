CC	= gcc
LEXER	= src/lexer/lexer.l
PARSER	= src/parser/parser.y
TARGET	= compiler

all: $(TARGET)

parser.tab.c parser.tab.h: $(PARSER)
	bison -d $(PARSER)

lex.yy.c: $(LEXER) parser.tab.h
	flex $(LEXER)

$(TARGET): parser.tab.c lex.yy.c
	$(CC) parser.tab.c lex.yy.c -o $(TARGET)

clean:
	rm -f parser.tab.c parser.tab.h lex.yy.c $(TARGET)

.PHONY: all clean
