%{
#include <stdio.h>
#include <stdlib.h>
#include <map>
#include <string.h>
#include <set>

int tempCount = 0;
int labelCount = 0;
extern char* yytext;
extern int currPos;
extern FILE *yyin;
std::map<std::string, std::string> varTemp;
std::map<std::string, int> arrSize;
bool mainFunc = false;
std::set<std::string> funcs;

std::set<std::string> reserved {"NUMBER", "IDENT", "RETURN", "FUNCTION", "SEMICOLON", "BEGIN_PARAMS", "END_PARAMS", "BEGIN_LOCALS", "END_LOCALS", "BEGIN_BODY",
    "END_BODY", "BEGINLOOP", "ENDLOOP", "COLON", "INTEGER", "COMMA", "ARRAY", "L_SQAURE_BRACKET", "R_SQUARE_BRACKET", "L_PAREN", "R_PAREN", "IF", "ELSE", "THEN",
    "CONTINUE", "ENDIF", "OF", "READ", "WRITE", "DO", "WHILE", "FOR", "TRUE", "FALSE", "ASSIGN", "EQ", "NEQ", "LT", "LTE", "GT", "GTE", "ADD", "SUB", "MULT", "DIV",
    "MOD", "AND", "OR", "NOT", "Function", "Declarations", "Declaration", "Vars", "Var", "Expressions", "Expression", "Idents", "Ident", "Bool-Expr",
    "Relation-And-Expr", "Relation-Expr-Inv", "Relation-Expr", "Comp", "Multiplicative-Expr", "Term", "Statements", "Statement", "enum"};

void yyerror(const char *msg);
extern int yylex();
std::string new_temp();
std::string new_label();

%}

%union {
  int int_val;
  char* ident;
  struct S {
    char* code;
  } statement;
  struct E {
    char* place;
    char* code;
    bool arr;
  } expression;
}

%error-verbose

%start Program
%token <int_val> NUMBER
%token <ident> IDENT
%type <expression> Function FuncIdent Declarations Declaration Vars Var Expressions Expression Idents Ident
%type <expression> Bool-Expr Relation-And-Expr Relation-Expr-Inv Relation-Expr Comp Multiplicative-Expr Term
%type <statement> Statements Statement


%token RETURN FUNCTION SEMICOLON BEGIN_PARAMS END_PARAMS BEGIN_LOCALS END_LOCALS BEGIN_BODY END_BODY BEGINLOOP ENDLOOP
%token COLON INTEGER COMMA ARRAY ENUM L_SQUARE_BRACKET R_SQUARE_BRACKET L_PAREN R_PAREN
%token IF ELSE THEN CONTINUE ENDIF OF READ WRITE DO WHILE FOR
%token TRUE FALSE
%right ASSIGN
%left OR
%left AND
%right NOT
%left EQ NEQ LT LTE GT GTE
%left ADD SUB
%left MULT DIV MOD

%%

  /* write your rules here */
Program:    %empty
    {
      if (!mainFunc) {
        printf("Error: No main Function Declared!\n");
        
      }
    }
    | Function Program
    {
    }
    ;

Function:  FUNCTION FuncIdent SEMICOLON BEGIN_PARAMS Declarations END_PARAMS BEGIN_LOCALS Declarations END_LOCALS BEGIN_BODY Statements END_BODY
    {
      std::string temp = "func ";
      temp.append($2.place);
      temp.append("\n");
      std::string s = $2.place;
      if (s == "main") {
        mainFunc = true;
      }
      temp.append($5.code);

      std::string decs = $5.code;
      int decNum = 0;

      while (decs.find(".") != std::string::npos) {
        int pos = decs.find(".");
        decs.replace(pos, 1, "=");
        std::string part = ", $" + std::to_string(decNum) + "\n";
        decNum++;
        decs.replace(decs.find("\n", pos), 1, part);
      }
      temp.append(decs);

      temp.append($8.code);
      std::string statements = $11.code;
      if (statements.find("continue") != std::string::npos) {
        printf("ERROR: Continue outside loop in function %s\n", $2.place);
        
      }

      temp.append(statements);
      temp.append("endfunc\n\n");
      printf(temp.c_str());
    }
    ;

Declarations: Declaration SEMICOLON Declarations
  {
    std::string temp;
    temp.append($1.code);
    temp.append($3.code);
    $$.code = strdup(temp.c_str());
    $$.place = strdup("");
  }
  | %empty
  {
    $$.place = strdup("");
    $$.code = strdup("");
  }
  ;

Declaration: Idents COLON INTEGER
{
  int left = 0;
  int right = 0;

  std::string parse($1.place);
  std::string temp;

  bool ex = false;

  while(!ex){
    right = parse.find("|", left);
    temp.append(". ");

    if (right == std::string::npos){
      std::string ident = parse.substr(left, right);
      if (reserved.find(ident) != reserved.end()) {
        printf("Identifier %s 's name is a reserves word.\n", ident.c_str());
        
      }
      if (funcs.find(ident) != funcs.end() || varTemp.find(ident) != varTemp.end()){
        printf("Identifier %s is previously declared.\n", ident.c_str());
        
      }
      else{
        varTemp[ident] = ident;
        arrSize[ident] = 1;
      }
      temp.append(ident);
      ex = true;
    }
    else{
      std::string ident = parse.substr(left, right - left);
      if(reserved.find(ident) != reserved.end()) {
        printf("Identifier %s's name is a reserved word.\n", ident.c_str());
        
      }
      if(funcs.find(ident) != funcs.end() || varTemp.find(ident) != varTemp.end()){
        printf("Identifier %s is previously declared\n", ident.c_str());
        
      }
      else{
        varTemp[ident] = ident;
        arrSize[ident] = 1;
      }
      temp.append(ident);
      left = right + 1;
    }
    temp.append("\n");
  }
  $$.code = strdup(temp.c_str());
  $$.place = strdup("");
}
| Idents COLON ARRAY L_SQUARE_BRACKET NUMBER R_SQUARE_BRACKET OF INTEGER
{
  size_t left = 0;
  size_t right = 0;
  std::string parse($1.place);
  std:: string temp;
  bool ex = false;
  while(!ex) {
    right = parse.find("|", left);
    temp.append(".[] ");
    if(right == std::string::npos){
      std::string ident = parse.substr(left, right);
      if (reserved.find(ident) != reserved.end()){
        printf("Identifier %s's name is a reserved word.\n", ident.c_str());
        
      }
      if(funcs.find(ident) != funcs.end() || varTemp.find(ident) != varTemp.end()){
        printf("Identifier %s is previously declared.\n", ident.c_str());
        
      }
      else{
        if($5 <= 0){
          printf("Declaring array ident %s of size <= 0,\n", ident.c_str());
          
        }
        varTemp[ident] = ident;
        arrSize[ident] = $5;
      }
      temp.append(ident);
      ex = true;
    }
    else{
      std::string ident = parse.substr(left, right - left);
      if (reserved.find(ident) != reserved.end()){
        printf("Identifier %s's name is a reserved word.\n", ident.c_str());
        
      }
      if(funcs.find(ident) != funcs.end() || varTemp.find(ident) != varTemp.end()){
        printf("Identifier %s is previously declared.\n", ident.c_str());
        
      }
      else{
        if($5 <= 0){
          printf("Declaring array ident %s of size <= 0,\n", ident.c_str());
          
        }
        varTemp[ident] = ident;
        arrSize[ident] = $5;
      }
      temp.append(ident);
      left = right + 1;
    }
    temp.append(", ");
    temp.append(std::to_string($5));
    temp.append("\n");
  }
  $$.code = strdup(temp.c_str());
  $$.place = strdup("");
}
;

FuncIdent: IDENT
  {
    if (funcs.find($1) != funcs.end()) {
      printf("function name %s already declared.\n", $1);
      
    } else {
      funcs.insert($1);
    }
  $$.place = strdup($1);
  $$.code = strdup("");
  }
  ;

Idents: Ident
  {
    $$.place = strdup($1.place);
    $$.code = strdup("");
  }
  | Ident COMMA Idents
  {
    std::string temp;
    temp.append($1.place);
    temp.append("|");
    temp.append($3.place);
    $$.place = strdup(temp.c_str());
    $$.code = strdup("");
  }
  ;

Ident:  IDENT
  {
    $$.place = strdup($1);
    $$.code = strdup("");
  }
  ;

Statements: Statement SEMICOLON Statements
  {
    std::string temp;
    temp.append($1.code);
    temp.append($3.code);
    $$.code = strdup(temp.c_str());
  }
  | Statement SEMICOLON
  {
    $$.code = strdup($1.code);
  }
  ;

Statement: Var ASSIGN Expression
  {
    std::string temp;
    temp.append($1.code);
    temp.append($3.code);
    std::string middle = $3.place;
   
    if ($1.arr && $3.arr) {
      temp += " []= ";
    } else if ($1.arr) {
      temp += " []= ";
    } else if ($3.arr) {
      temp += "= ";
    } else {
      temp += "= ";
    }

    temp.append($1.place);
    temp.append(", ");
    temp.append(middle);
    temp += "\n";
    $$.code = strdup(temp.c_str());
  }
  | IF Bool-Expr THEN Statements ENDIF
  {
    std::string ifs = new_label();
    std::string after = new_label();
    std::string temp;
    temp.append($2.code);
    temp = temp + "?:= " + ifs + ", " + $2.place + "\n";
    temp = temp + ":= " + after + "\n";
    temp = temp + ": " + ifs + "\n";
    temp.append($4.code);
    temp = temp + ": " + after + "\n";
    $$.code = strdup(temp.c_str());
  }
  | IF Bool-Expr THEN Statements ELSE Statements ENDIF
  {
    std::string ifs = new_label();
    std::string after = new_label();
    std::string temp;
    temp.append($2.code);
    temp = temp + "?:= " + ifs + ", " + $2.place + "\n";
    temp.append($6.code);
    temp = temp + ":= " + after + "\n";
    temp = temp + ": " + ifs + "\n";
    temp.append($4.code);
    temp = temp + ": " + after + "\n";
    $$.code = strdup(temp.c_str());
  }
  | WHILE Bool-Expr BEGINLOOP Statements ENDLOOP
  {
    std::string temp;
    std::string begin = new_label();
    std::string inner = new_label();
    std::string after = new_label();
    std::string code = $4.code;
    size_t pos = code.find("continue");
    while (pos != std::string::npos) {
      code.replace(pos, 8, ":= "+begin);
      pos = code.find("continue");
    }
    temp.append(": ");
    temp += begin + "\n";
    temp.append($2.code);
    temp += "?:= " + inner + ", ";
    temp.append($2.place);
    temp.append("\n");
    temp += ":= " + after + "\n";
    temp += ": " + inner + "\n";
    temp.append(code);
    temp += ":= " + begin + "\n";
    temp += ": " + after + "\n";
    $$.code = strdup(temp.c_str());
  }
  | DO BEGINLOOP Statements ENDLOOP WHILE Bool-Expr
  {
    std::string temp;
    std::string begin = new_label();
    std::string condition = new_label();
    std::string code = $3.code;
    size_t pos = code.find("continue");
    while (pos != std::string::npos) {
      code.replace(pos, 8, ":= "+condition);
      pos = code.find("continue");
    }
    temp.append(": ");
    temp += begin + "\n";
    temp.append(code);
    temp += ": " + condition + "\n";
    temp.append($6.code);
    temp += "?:= " + begin + ", ";
    temp.append($6.place);
    temp.append("\n");
    $$.code = strdup(temp.c_str());
  }
  | FOR Var ASSIGN NUMBER SEMICOLON Bool-Expr SEMICOLON Var ASSIGN Expression BEGINLOOP Statements ENDLOOP
  {
    std::string temp;
    std::string dst = new_temp();
    std::string condition = new_label();
    std::string inner = new_label();
    std::string increment = new_label();
    std::string after = new_label();
    std::string code = $12.code;
    size_t pos = code.find("continue");
    while (pos != std::string::npos) {
      code.replace(pos, 8, ":= "+increment);
      pos = code.find("continue");
    }
    temp.append($2.code);
    std::string middle = std::to_string($4);
    if ($2.arr) {
      temp += "[]= ";
    } else {
      temp += "= ";
    }
    temp.append($2.place);
    temp.append(", ");
    temp.append(middle);
    temp += "\n";
    temp += ": " + condition + "\n";
    temp.append($6.code);
    temp += "?:= " + inner + ", ";
    temp.append($6.place);
    temp.append("\n");
    temp += ":= " + after + "\n";
    temp += ": " + inner + "\n";
    temp.append(code);
    temp += ": " + increment + "\n";
    temp.append($8.code);
    temp.append($10.code);
    if ($8.arr) {
      temp += "[]= ";
    } else {
      temp += "= ";
    }
    temp.append($8.place);
    temp.append(", ");
    temp.append($10.place);
    temp += "\n";
    temp += ":= " + condition + "\n";
    temp += ": " + after + "\n";
    $$.code = strdup(temp.c_str());
  }
  | READ Vars
  {
    std::string temp;
    temp.append($2.code);
    size_t pos = temp.find("|", 0);
    while (pos != std::string::npos) {
      temp.replace(pos, 1, "<");
      pos = temp.find("|", pos);
    }
    $$.code = strdup(temp.c_str());
  }
  | WRITE Vars
  {
    std::string temp;
    temp.append($2.code);
    size_t pos = temp.find("|", 0);
    while (pos != std::string::npos) {
      temp.replace(pos, 1, ">");
      pos = temp.find("|", pos);
    }
    $$.code = strdup(temp.c_str());
  }
  | CONTINUE
  {
    $$.code = strdup("continue\n");
  }
  | RETURN Expression
  {
    std::string temp;
    temp.append($2.code);
    temp.append("ret ");
    temp.append($2.place);
    temp.append("\n");
    $$.code = strdup(temp.c_str());
  }
  ;

/*This starts at about 1:41:00*/
Bool-Expr: Relation-And-Expr OR Bool-Expr
  {
      std::string dst = new_temp();
      std::string temp;

      temp.append($1.code);
      temp.append($3.code);
      temp += ", " + dst + "\n";

      temp += "|| " + dst + ", ";
      temp.append($1.place);
      temp.append(", ");
      temp.append($3.place);
      temp.append("\n");
 
      $$.code = strdup(temp.c_str());
      $$.place = strdup(dst.c_str());
  }
  | Relation-And-Expr
  {
      $$.place = strdup($1.place);
      $$.code = strdup($1.code);
  }
  ;

Relation-And-Expr: Relation-Expr-Inv AND Relation-And-Expr
  {
      std::string dst = new_temp();
      std::string temp;

      temp.append($1.code);
      temp.append($3.code);
      temp += ". " + dst + "\n";
 
      temp += "&& " + dst + ", ";
      temp.append($1.place);
      temp.append(", ");
      temp.append($3.place);
      temp.append("\n");
 
  $$.code = strdup(temp.c_str());
  $$.place = strdup(dst.c_str());
  }
  | Relation-Expr-Inv
  {
      $$.place = strdup($1.place);
      $$.code = strdup($1.code);
  }
  ;

Relation-Expr-Inv: NOT Relation-Expr-Inv
  {
    std::string temp;
    std::string dst = new_temp();
    temp.append($2.code);
    temp += ". " + dst + "\n";
    temp += "! " + dst + ", ";
    temp.append($2.place);
    temp.append("\n");
    $$.code = strdup(temp.c_str());
    $$.place = strdup(dst.c_str());
  }
  | Relation-Expr
  {
    $$.code = strdup($1.code);
    $$.place = strdup($1.place);
  }
  ;

Relation-Expr:  Expression Comp Expression
{
    std::string dst = new_temp();
    std::string temp;  

    temp.append($1.code);
    temp.append($3.code);
    temp += ". " + dst + "\n";
    temp.append($2.place);
    temp += dst + ", ";
    temp.append($1.place);
    temp.append(", ");
    temp.append($3.place);
    temp.append("\n");

    $$.code = strdup(temp.c_str());
    $$.place = strdup(dst.c_str());
}
| TRUE
{
    char temp[2] = "1";
    $$.place = strdup(temp);
    $$.code = strdup("");
}
| FALSE
{  
    char temp[2] = "0";
    $$.place = strdup(temp);
    $$.code = strdup("");
}
| L_PAREN Bool-Expr R_PAREN
{
    $$.place = strdup($2.place);
    $$.code = strdup($2.code);
}
;

Comp:   EQ
{
    std::string temp = "== ";
    $$.place = strdup(temp.c_str());
    $$.code = strdup("");
}
| NEQ
{
    std::string temp = "!= ";
    $$.place = strdup(temp.c_str());
    $$.code = strdup("");
}
| LT
{
    std::string temp = "< ";
    $$.place = strdup(temp.c_str());
    $$.code = strdup("");
}
| LTE
{
    std::string temp = "<= ";
    $$.place = strdup(temp.c_str());
    $$.code = strdup("");
}
| GT
{
    std::string temp = "> ";
    $$.place = strdup(temp.c_str());
    $$.code = strdup("");
}
| GTE
{
    std::string temp = ">= ";
    $$.place = strdup(temp.c_str());
    $$.code = strdup("");
}
;

Expressions:Expression
{
    std::string temp;
    temp.append($1.code);
    temp.append("param ");
    temp.append($1.place);
    temp.append("\n");

    $$.code = strdup(temp.c_str());
    $$.place = strdup("");
}
| Expression COMMA Expressions
{
    std::string temp;
    temp.append($1.code);
    temp.append("param ");
    temp.append($1.place);
    temp.append("\n");
    temp.append($3.code);
}
;

Expression: Multiplicative-Expr
{
    $$.code = strdup($1.code);
    $$.place = strdup($1.place);
}
| Multiplicative-Expr ADD Expression
{
    $$.place = strdup(new_temp().c_str());
 
    std::string temp;
    temp.append($1.code);
    temp.append($3.code);
    temp.append(". ");
    temp.append($$.place);
    temp.append("\n");
    temp.append("+ ");
    temp.append($$.place);
    temp.append(", ");
    temp.append($1.place);
    temp.append(", ");
    temp.append($3.place);
    temp.append("\n");

    $$.code = strdup(temp.c_str());
}
| Multiplicative-Expr SUB Expression
{
    $$.place = strdup(new_temp().c_str());
 
    std::string temp;
    temp.append($1.code);
    temp.append($3.code);
    temp.append(". ");
    temp.append($$.place);
    temp.append("\n");
    temp.append("- ");
    temp.append($$.place);
    temp.append(", ");
    temp.append($1.place);
    temp.append(", ");
    temp.append($3.place);
    temp.append("\n");

  $$.code = strdup(temp.c_str());
}
;

Multiplicative-Expr: Term
{
    $$.code = strdup($1.code);
    $$.place = strdup($1.place);
}
| Term MULT Multiplicative-Expr
{
    $$.place = strdup(new_temp().c_str());
 
    std::string temp;
    temp.append(". ");
    temp.append($$.place);
    temp.append("\n");
    temp.append($1.code);
    temp.append($3.code);
    temp.append("* ");
    temp.append($$.place);
    temp.append(", ");
    temp.append($1.place);
    temp.append(", ");
    temp.append($3.place);
    temp.append("\n");

  $$.code = strdup(temp.c_str());
}
| Term DIV Multiplicative-Expr
{
    $$.place = strdup(new_temp().c_str());
 
    std::string temp;
    temp.append(". ");
    temp.append($$.place);
    temp.append("\n");
    temp.append($1.code);
    temp.append($3.code);
    temp.append("/ ");
    temp.append($$.place);
    temp.append(", ");
    temp.append($1.place);
    temp.append(", ");
    temp.append($3.place);
    temp.append("\n");

    $$.code = strdup(temp.c_str());
}
| Term MOD Multiplicative-Expr
{
    $$.place = strdup(new_temp().c_str());
 
    std::string temp;
    temp.append(". ");
    temp.append($$.place);
    temp.append("\n");
    temp.append($1.code);
    temp.append($3.code);
    temp.append("% ");
    temp.append($$.place);
    temp.append(", ");
    temp.append($1.place);
    temp.append(", ");
    temp.append($3.place);
    temp.append("\n");

    $$.code = strdup(temp.c_str());
}
;

Term:   Var
{
      std::string dst = new_temp();
      std::string temp;
      if ($1.arr) {
        temp.append($1.code);
        temp += ". " + dst + "\n";
        temp += "=[] " + dst + ", ";
        temp.append($1.place);
        temp.append("\n");
      }
      else{
        temp += ". " + dst + "\n";
        temp += "= " + dst + ", ";
        temp.append($1.place);
        temp.append("\n");
        temp.append($1.code);
      }
      if (varTemp.find($1.place) != varTemp.end()){
        varTemp[$1.place] = dst;
      }
      $$.code = strdup(temp.c_str());
      $$.place = strdup(dst.c_str());
}
| SUB Var
{
    $$.place = strdup(new_temp().c_str());
    std::string temp;
    temp.append($2.code);
    temp.append(". ");
    temp.append($$.place);
    temp.append("\n");
    if ($2.arr) {
      temp.append("=[] ");
      temp.append($$.place);
      temp.append(", ");
      temp.append($2.place);
      temp.append("\n");
    }
    else {
      temp.append("= ");
      temp.append($$.place);
      temp.append(", ");
      temp.append($2.place);
      temp.append("\n");
    }
    temp.append("* ");
    temp.append($$.place);
    temp.append(", ");
    temp.append($$.place);
    temp.append(", -1\n");
 
    $$.code = strdup(temp.c_str());
    $$.arr = false;
}
| SUB NUMBER
{
    std::string temp;
    temp.append("-");
    temp.append(std::to_string($2));
    $$.code = strdup("");
    $$.place = strdup(temp.c_str());
}
| NUMBER
{
    $$.code = strdup("");
    $$.place = strdup(std::to_string($1).c_str());
}
| SUB L_PAREN Expression R_PAREN
{
    $$.place = strdup($3.place);
    std::string temp;
    temp.append($3.code);
    temp.append("* ");
    temp.append($3.place);
    temp.append(", ");
    temp.append($3.place);
    temp.append(", -1\n");
    $$.code = strdup(temp.c_str());
}
| L_PAREN Expression R_PAREN
{
    $$.code = strdup($2.code);
    $$.place = strdup($2.place);
}
| Ident L_PAREN Expressions R_PAREN
{
    if (funcs.find(std::string($1.place)) == funcs.end()) {
      char temp[128];
      printf(temp, 128, "Use of undeclared function %s", $1.place);
      yyerror(temp);
    }
    $$.place = strdup(new_temp().c_str());
    std::string temp;
    temp.append($3.code);
    temp.append(". ");
    temp.append($$.place);
    temp.append("\n");
    temp.append("call ");
    temp.append($1.place);
    temp.append(", ");
    temp.append($$.place);
    temp.append("\n");
    $$.code = strdup(temp.c_str());
}
;

Vars:   Var COMMA Vars
{
    std::string temp;
    temp.append($1.code);
    if ($1.arr){
      temp.append(".[]| ");
    }
    else{
      temp.append(".| ");
    }
    temp.append($1.place);
    temp.append("\n");
    temp.append($3.code);
    $$.code = strdup(temp.c_str());
    $$.place = strdup("");
}
| Var
{
    std::string temp;
    temp.append($1.code);
    if ($1.arr) {
      temp.append(".[]| ");
    }
    else{
      temp.append(".| ");
    }
    temp.append($1.place);
    temp.append("\n");
    $$.code = strdup(temp.c_str());
    $$.place = strdup("");
}
;

Var:    Ident
{
    std:: string temp;
    std::string ident = $1.place;
    if (funcs.find(ident) == funcs.end() && varTemp.find(ident) == varTemp.end()) {
      printf("Identifier %s is not declared.\n", ident.c_str());
    }
    else if (arrSize[ident] > 1) {
      printf("Did not provide index for the array Identifier %s.\n", ident.c_str());
    }

    $$.code = strdup("");
    $$.place = strdup(ident.c_str());
    $$.arr = false;
}
| Ident L_SQUARE_BRACKET Expression R_SQUARE_BRACKET
{
    std::string temp;
    std::string ident = $1.place;
    if (funcs.find(ident) == funcs.end() && varTemp.find(temp) == varTemp.end()) {
      printf("Identifier %s is not declared.\n", ident.c_str());
    }
    else if (arrSize[ident] == 1) {
      printf("Provided index for non-array Identifier %s.\n", ident.c_str());
    }

    temp.append($1.place);
    temp.append(", ");
    temp.append($3.place);
    $$.code = strdup($3.code);
    $$.place = strdup(temp.c_str());
    $$.arr = true;
}
;
%%

int main(int argc, char **argv) {

  if (argc > 1) {
    yyin = fopen(argv[1], "r");
    if (yyin == NULL) {
      printf("syntax: %s filename", argv[0]);
    }
  }

   yyparse();
   return 0;
}

void yyerror(const char *msg) {
    /* implement your error handling */
  extern int yylineno;
  extern char *yytext;

  printf("%s on line %d at char %d at symbol \"%s\n", yylineno, msg,  yytext);
  exit(1);
}

std::string new_temp() {
   std::string t = "t" + std::to_string(tempCount);
   tempCount++;
   return t;
}

std::string new_label() {
   std::string l = "L" + std::to_string(labelCount);
   labelCount++;
   return l;
}
