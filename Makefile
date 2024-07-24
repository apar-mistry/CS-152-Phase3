CFLAGS = -g -Wall -ansi -pedantic

parser: 
	bison -d -v --file-prefix=y miniL.y
	flex miniL.lex
	g++ $(CFLAGS) -std=c++11 lex.yy.c y.tab.c -lfl -o parser
	rm -f lex.yy.c *.output *.tab.c *.tab.h

test: parser
	cat ./tests/min/primes.min | ./parser > ./tests/mil/primes.mil
	cat ./tests/min/mytest.min | ./parser > ./tests/mil/mytest.mil
	cat ./tests/min/fibonacci.min | ./parser > ./tests/mil/fibonacci.mil
	cat ./tests/min/errors.min | ./parser > ./tests/mil/errors.mil
	cat ./tests/min/for.min | ./parser > ./tests/mil/for.mil

clean:
	rm -f lex.yy.c *.tab.* *.output *.o parser

