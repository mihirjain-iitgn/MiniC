do:
	bison -d parser.y
	flex lexer.l
	gcc -w parser.tab.c lex.yy.c -lfl

run:
	./a.out<strln.prog

clean:
	rm parser.tab.c parser.tab.h lex.yy.c a.out

all:
	rm -f parser.tab.c parser.tab.h lex.yy.c a.out
	bison -d parser.y
	flex lexer.l
	gcc -w parser.tab.c lex.yy.c -lfl
	./a.out<strln.prog