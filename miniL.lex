%{   
  #include "y.tab.h"
  #include <string>

   int num_lines = 1, num_column = 1;
%}

DIGIT    [0-9]
LETTER   [a-zA-Z]
ID	 [a-zA-Z][a-zA-Z_0-9]*

%%
##[^\n]*              	{/* ignore comments */ num_column += num_lines;}

"function"              { num_column += yyleng; return FUNCTION; }
"beginparams"           { num_column += yyleng; return BEGIN_PARAMS; }
"endparams"             { num_column += yyleng; return END_PARAMS; }
"beginlocals"           { num_column += yyleng; return BEGIN_LOCALS; }
"endlocals"             { num_column += yyleng; return END_LOCALS; }
"beginbody"             { num_column += yyleng; return BEGIN_BODY; }
"endbody"               { num_column += yyleng; return END_BODY; }
"integer"               { num_column += yyleng; return INTEGER; }
"array"                 { num_column += yyleng; return ARRAY; }
"of"                    { num_column += yyleng; return OF; }
"if"                    { num_column += yyleng; return IF; }
"then"                  { num_column += yyleng; return THEN; }
"endif"                 { num_column += yyleng; return ENDIF; }
"else"                  { num_column += yyleng; return ELSE; }
"for"                   { num_column += yyleng; return FOR; }
"while"                 { num_column += yyleng; return WHILE; }
"do"                    { num_column += yyleng; return DO; }
"beginloop"             { num_column += yyleng; return BEGINLOOP; }
"endloop"               { num_column += yyleng; return ENDLOOP; }
"continue"              { num_column += yyleng; return CONTINUE; }
"read"                  { num_column += yyleng; return READ; }
"write"                 { num_column += yyleng; return WRITE; }
"and"                   { num_column += yyleng; return AND; }
"or"                    { num_column += yyleng; return OR; }
"not"                   { num_column += yyleng; return NOT; }
"true"                  { num_column += yyleng; return TRUE; }
"false"                 { num_column += yyleng; return FALSE; }
"return"                { num_column += yyleng; return RETURN; }
"enum"                  { num_column += yyleng; return ENUM; }

"-"                     { num_column += yyleng; return SUB; }
"+"                     { num_column += yyleng; return ADD; }
"*"                     { num_column += yyleng; return MULT; }
"/"                     { num_column += yyleng; return DIV; }
"%"                     { num_column += yyleng; return MOD; }

"=="                    { num_column += yyleng; return EQ; }
"!="                    { num_column += yyleng; return NEQ; }
"<"                     { num_column += yyleng; return LT; }
"<="                    { num_column += yyleng; return LTE; }
">"                     { num_column += yyleng; return GT; }
">="                    { num_column += yyleng; return GTE; }

{LETTER}({LETTER}|{DIGIT}|_)*_ { printf("Error at line %d, column %d: identifier \"%s\" cannot end with an underscore\n", num_lines, num_column, yytext); exit(1); }
{ID}+                     { yylval.ident = strdup(yytext); return IDENT; }
{DIGIT}+                 { yylval.int_val = atoi(yytext); return NUMBER; }

";"                     { num_column += yyleng; return SEMICOLON; }
":"                     { num_column += yyleng; return COLON; }
","                     { num_column += yyleng; return COMMA; }
"("                     { num_column += yyleng; return L_PAREN; }
")"                     { num_column += yyleng; return R_PAREN; }
"["                     { num_column += yyleng; return L_SQUARE_BRACKET; }
"]"                     { num_column += yyleng; return R_SQUARE_BRACKET; }
":="                    { num_column += yyleng; return ASSIGN; }

[\t ]+                  {  }

"\n"                    { num_lines++; num_column = 1; }

{DIGIT}{LETTER}({LETTER}|{DIGIT}|_)* {printf("Error at line %d, column %d: identifier \"%s\" must begin with a letter\n", num_lines, num_column, yytext); exit(1);}
.              		{printf("Error at line %d, column %d: unrecognized symbol \"%s\"\n", num_lines, num_column, yytext); exit(1);}

%%

		