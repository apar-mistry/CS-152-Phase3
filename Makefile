CFLAGS = -g -Wall -ansi -pedantic

parser: 
	bison -d -v --file-prefix=y miniL.y
	flex miniL.lex
	g++ $(CFLAGS) -std=c++11 lex.yy.c y.tab.c -lfl -o miniL
	rm -f lex.yy.c *.output *.tab.c *.tab.h 


clean:
	rm -f lex.yy.c *.tab.* *.output *.o miniL *.mil