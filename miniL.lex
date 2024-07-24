%{
#include <unistd.h>
#include "y.tab.h"
%}
	//DEFINITIONS

	int line = 1, column = 0;

DIGIT [0-9]
LETTER [a-zA-Z]
UNDERSCORE _
COMMENT ##.*\n

%%
	//RULES

	/*Reserved Words*/
function		column = column + yyleng; return FUNCTION;
beginparams		column = column + yyleng; return BEGIN_PARAMS;
endparams		column = column + yyleng; return END_PARAMS;
beginlocals		column = column + yyleng; return BEGIN_LOCALS;
endlocals		column = column + yyleng; return END_LOCALS;
beginbody		column = column + yyleng; return BEGIN_BODY;
endbody			column = column + yyleng; return END_BODY;
integer			column = column + yyleng; return INTEGER;
array			column = column + yyleng; return ARRAY;
of				column = column + yyleng; return OF;
if				column = column + yyleng; return IF;
then			column = column + yyleng; return THEN;
endif			column = column + yyleng; return ENDIF;
else			column = column + yyleng; return ELSE;
while			column = column + yyleng; return WHILE;
do				column = column + yyleng; return DO;
for				column = column + yyleng; return FOR;
beginloop		column = column + yyleng; return BEGINLOOP;
endloop			column = column + yyleng; return ENDLOOP;
continue		column = column + yyleng; return CONTINUE;
read			column = column + yyleng; return READ;
write			column = column + yyleng; return WRITE;
and				column = column + yyleng; return AND;
or				column = column + yyleng; return OR;
not				column = column + yyleng; return NOT;
true			column = column + yyleng; return TRUE;
false			column = column + yyleng; return FALSE;
return			column = column + yyleng; return RETURN;

	/*Arithmetic Operators*/
"-"				column = column + yyleng; return SUB;
"+"				column = column + yyleng; return ADD;
"*"				column = column + yyleng; return MULT;
"/"				column = column + yyleng; return DIV;
"%"				column = column + yyleng; return MOD;

	/*Comparison Operators*/
"=="			column = column + yyleng; return EQ;
"<>"			column = column + yyleng; return NEQ;
"<"				column = column + yyleng; return LT;
">"				column = column + yyleng; return GT;
"<="			column = column + yyleng; return LTE;
">="			column = column + yyleng; return GTE;


	/*Other Special Symbols*/
";"				column = column + yyleng; return SEMICOLON;
":"				column = column + yyleng; return COLON;
","				column = column + yyleng; return COMMA;
"("				column = column + yyleng; return L_PAREN;
")"				column = column + yyleng; return R_PAREN;
"["				column = column + yyleng; return L_SQUARE_BRACKET;
"]"				column = column + yyleng; return R_SQUARE_BRACKET;
":="			column = column + yyleng; return ASSIGN;

{COMMENT}		++line; //no retun...?


\n				++line; column = 0; //no retun...?
" "|\t			 column = column + yyleng; //no retun...?





	/*Numbers only*/
{DIGIT}+		{/*printf("NUMBER %.*s\n", yyleng, yytext);*/ column = column + yyleng; yylval.num = atof(yytext); return NUMBER;}


	/* Errors */
({DIGIT}|{UNDERSCORE})({LETTER}|{DIGIT}|{UNDERSCORE})*		/*printf("Error at line %d, column %d: identifier \"%.*s\" must begin with letter\n", line, column, yyleng, yytext);*/ column = column + yyleng; //exit(1);

({LETTER}|{DIGIT}|{UNDERSCORE})+{UNDERSCORE}		/*printf("Error at line %d, column %d: identifier \"%.*s\" cannot end with underscore\n",line, column, yyleng, yytext);*/ column = column + yyleng; //exit(1);



	/*Identifiers only*/
{LETTER}({LETTER}|{DIGIT}|{UNDERSCORE})*			{/*printf("IDENT %.*s\n", yyleng, yytext);*/ column = column + yyleng; yylval.id = strdup(yytext); return IDENT;}


	/* More Errors */
.					/*printf("Error at line %d, column %d: unrecognized symbol \"%.*s\"\n",line, column, yyleng, yytext);*/ //column = column + yyleng; //exit(1);


%%