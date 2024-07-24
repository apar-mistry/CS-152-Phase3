# utilizing c++11 made sure to change from gcc
parse: miniL.lex miniL.y
	bison -v -d --file-prefix=y miniL.y
	flex miniL.lex
	g++ -std=c++11 -o parser lex.yy.c y.tab.c -lfl

clean:
	rm -f lex.yy.c y.tab.* y.output *.o parser