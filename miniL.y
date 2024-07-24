%{
    #include <stdio.h>
    #include <stdlib.h>
    #include <map>
    #include <string.h>
    #include <set>

    int tempCount = 0;
    int labelCount = 0;
    extern char* yytext;
    extern int num_lines;
    extern int num_column;
    extern FILE *yyin;
    std::map<std::string, std::string> varTemp;
    std::map<std::string, int> arrSize;
    bool mainFunc = false;
    std::set<std::string> funcs;
    std::set<std::string> reserved {"FUNCTION", "BEGIN_PARAMS", "END_PARAMS", "BEGIN_LOCALS", "END_LOCALS", "BEGIN_BODY", "END_BODY", "INTEGER",
    "ARRAY", "OF", "IF", "THEN", "ENDIF", "ELSE", "WHILE", "DO", "FOREACH", "IN", "BEGINLOOP", "ENDLOOP", "CONTINUE", "READ", "WRITE", "AND", "OR", 
    "NOT", "TRUE", "FALSE", "RETURN", "SUB", "ADD", "MULT", "DIV", "MOD", "EQ", "NEQ", "LT", "GT", "LTE", "GTE", "L_PAREN", "R_PAREN", "L_SQUARE_BRACKET",
    "R_SQUARE_BRACKET", "COLON", "SEMICOLON", "COMMA", "ASSIGN", "function", "Ident", "beginparams", "endparams", "beginlocals", "endlocals", "integer", 
    "beginbody", "endbody", "beginloop", "endloop", "if", "endif", "foreach", "continue", "while", "else", "read", "do", "write"};
    void yyerror(const char* s);
    int yylex();
    int yyparse();
    std::string new_temp();
    std::string new_label();
%}
%union{
    int num;
    char* ident;
    struct S {
        char* code;
    } statement;
    struct E {
        char* code;
        char* place;
        bool arr;
    } expression;
}
%start Program
%token <num> NUMBER
%token <ident> IDENT
%type <expression>  Function FuncIdent Declarations Declaration Vars Var Expressions Expression Idents Ident
%type <expression> Bool-Expr Relation-And-Expr Relation-Expr-Inv Relation-Expr Comp Multiplicative-Expr Term
%type <statement> Statements Statement

%token  RETURN FUNCTION SEMICOLON BEGIN_PARAMS END_PARAMS BEGIN_LOCALS END_LOCALS BEGIN_BODY END_BODY BEGINLOOP ENDLOOP  COLON COMMA
%token  INTEGER  ARRAY L_SQUARE_BRACKET R_SQUARE_BRACKET L_PAREN R_PAREN
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

Program: %empty
    {
        if(!mainFunc){
            printf("Error: No main function declared\n");
        }
    }
        | Function Program {}
        ;
Function: FUNCTION FuncIdent SEMICOLON BEGIN_PARAMS Declarations END_PARAMS BEGIN_LOCALS Declarations END_LOCALS BEGIN_BODY Statements END_BODY
    {
        std::string temp = "func ";
        temp.append($2.place);
        temp.append("\n");
        std::string s = $2.place;
        if (s == "main"){
            mainFunc = true;
        }
        temp.append($5.code);
        std::string decs = $5.code;
        int decNum = 0;

        while(decs.find(".") != std::string::npos){
            int pos = decs.find(".");
            decs.replace(pos, 1, "=");
            std::string part = ", $" + std::to_string(decNum) + "\n";
            decNum++;
            decs.replace(decs.find("\n", pos), 1, part);
        }
        temp.append(decs);
        temp.append($8.code);
        std::string statements = $11.code;
        if(statements.find("continue") != std::string::npos){
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
        $$.code = strdup("");
        $$.place = strdup("");
    }

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
                if(reserved.find(ident) != reserved.end()){
                    printf("Error: Reserved word used as identifier\n", ident.c_str());
                }
                if(funcs.find(ident) != funcs.end() || varTemp.find(ident) != varTemp.end()){
                    printf("ERROR: Identifier %s is previously declared\n", ident.c_str());
                } else{
                    varTemp[ident] = ident;
                    arrSize[ident] = 1;
                }
                temp.append(ident);
                ex = true;
            }else{
                std::string ident = parse.substr(left, right-left);
                if(reserved.find(ident) != reserved.end()){
                    printf("Identifier %s is a reserved word.\n", ident.c_str());
                }
                if(funcs.find(ident) != funcs.end() || varTemp.find(ident) != varTemp.end()){
                    printf("ERROR: Identifier %s is previously declared\n", ident.c_str());
                } else{
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
        std::string temp;
        bool ex = false;
        while(!ex){
            right = parse.find("|", left);
            temp.append(".[] ");
            if(right == std::string::npos){
                std::string ident = parse.substr(left, right);
                if(reserved.find(ident) != reserved.end()){
                    printf("Identifier %s's name is a reserved word\n", ident.c_str());
                }
                if(funcs.find(ident) != funcs.end() || varTemp.find(ident) != varTemp.end()){
                    printf("ERROR: Identifier %s is previously declared\n", ident.c_str());
                } else{
                    if($5 <= 0){
                        printf("ERROR: Array size must be greater than 0\n", ident.c_str());
                    }
                    varTemp[ident] = ident;
                    arrSize[ident] = $5;
                }
                temp.append(ident);
                ex = true;
            }else{
                std::string ident = parse.substr(left, right-left);
                if(reserved.find(ident) != reserved.end()){
                    printf("Identifier %s's name is a reserved word\n", ident.c_str());
                }
                if(funcs.find(ident) != funcs.end() || varTemp.find(ident) != varTemp.end()){
                    printf("ERROR: Identifier %s is previously declared\n", ident.c_str());
                } else{
                    if($5 <= 0){
                        printf("ERROR: Array size must be greater than 0\n", ident.c_str());
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
        if(funcs.find($1) != funcs.end()){
            printf("function name %s is already declared\n", $1);
        }else{
            funcs.insert($1);
        }
        $$.place = strdup($1);
        $$.place = strdup("");
    }
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
Ident : IDENT
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
        if($1.arr && $3.arr){
            temp += "[]= ";
        }
        else if($1.arr){
            temp += "[]= ";
        }
        else if($3.arr){
            temp += "= ";
        }
        else{
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
        std::string ifS = new_label();
        std::string after = new_label();
        std::string temp;
        temp.append($2.code);
        temp = temp + "?:= " + ifS + ", " + $2.place + "\n";
        temp = temp + ":= " + after + "\n";
        temp = temp + ": " + ifS + "\n";
        temp.append($4.code);
        temp = temp + ": " + after + "\n";
        $$.code = strdup(temp.c_str());
    }
    | IF Bool-Expr THEN Statements ELSE Statements ENDIF
    {
        std::string ifS = new_label();
        std::string after = new_label();
        std::string temp;
        temp.append($2.code);
        temp = temp + "?:= " + ifS + ", " + $2.place + "\n";
        temp.append($6.code);
        temp = temp + ":= " + after + "\n";
        temp = temp + ": " + ifS + "\n";
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
        while(pos != std::string::npos){
            code.replace(pos, 8, ":= "+begin);
            pos = code.find("continue");
        }
        temp.append(": ");
        temp += begin + "\n";
        temp.append($2.code);
       temp += "?:= " + inner + ", " ;
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
        while(pos != std::string::npos){
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
        while(pos != std::string::npos){
            code.replace(pos, 8, ":= "+increment);
            pos = code.find("continue");
        }
        temp.append($2.code);
        std::string middle = std::to_string($4);
        if($2.arr){
            temp += "[]= ";
        }else{
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
        if($8.arr){
            temp += "[]= ";
        }else{
            temp += "= ";
        }
        temp.append($8.place);
        temp.append(", ");
        temp.append($10.place);
        temp += "\n";
        temp += ": " + condition + "\n";
        temp += ": " + after + "\n";
        $$.code = strdup(temp.c_str());
    }
    | READ Vars
    {
        std::string temp;
        temp.append($2.code);
        size_t pos = temp.find("|", 0);
        while(pos != std::string::npos){
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
        while(pos != std::string::npos){
            temp.replace(pos, 1, ">");
            pos = temp.find("|", pos);
        }
        $$.code = strdup(temp.c_str());
    }
    |CONTINUE
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
Bool-Expr: Relation-And-Expr OR Bool-Expr
        {
            std::string dest = new_temp();
            std::string temp;

            temp.append($1.code);
            temp.append($3.code);
            temp.append(". ");
            temp.append(dest);
            temp.append("\n");

            temp.append("|| ");
            temp.append(dest);
            temp.append(", ");
            temp.append($1.place);
            temp.append(", ");
            temp.append($3.place);
            temp.append("\n");
            $$.code = strdup(temp.c_str());
            $$.place = strdup(dest.c_str());
        }
        | Relation-And-Expr
        {
            $$.code = strdup($1.code);
            $$.place = strdup($1.place);
        }
        ;
Relation-And-Expr: Relation-Expr-Inv
    {
        $$.code = strdup($1.code);
        $$.place = strdup($1.place);
    }
    | Relation-Expr-Inv AND Relation-And-Expr
    {
        std::string dest = new_temp();
        std::string temp;

        temp.append($1.code);
        temp.append($3.code);
        temp.append(". ");
        temp.append(dest);
        temp.append("\n");
        temp.append("&& ");
        temp.append(dest);
        temp.append(", ");
        temp.append($1.place);
        temp.append(", ");
        temp.append($3.place);
        temp.append("\n");
        $$.code = strdup(temp.c_str());
        $$.place = strdup(dest.c_str());
    }

Relation-Expr-Inv: NOT Relation-Expr-Inv
    {
        std::string temp;
        std::string dest = new_temp();
        temp.append($2.code);
        temp += ". " + dest + "\n";
        temp += "! " + dest + ", ";
        temp.append($2.place);
        temp.append("\n");
        $$.code = strdup(temp.c_str());
        $$.place = strdup(dest.c_str());
    }
    | Relation-Expr
    {
        $$.code = strdup($1.code);
        $$.place = strdup($1.place);
    
    }
    ;

Relation-Expr: Expression Comp Expression
    {
        std::string dest = new_temp();
        std::string temp;  

        temp.append($1.code);
        temp.append($3.code);
        temp.append(". ");
        temp.append(dest);
        temp.append("\n");
        temp.append($2.place);
        temp.append(dest);
        temp.append(", ");
        temp.append($1.place);
        temp.append(", ");
        temp.append($3.place);
        temp.append("\n");
        
        $$.code = strdup(temp.c_str());
        $$.place = strdup(dest.c_str());
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
    };

Comp: EQ
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
    | GT
    {
        std::string temp = "> ";
        $$.place = strdup(temp.c_str());
        $$.code = strdup("");
    }
    | LTE
    {
        std::string temp = "<= ";
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

Expressions: Expressions
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

        $$.code = strdup(temp.c_str());
        $$.place = strdup("");
    }
    ;

Expression: Multiplicative-Expr ADD Expression
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
    | Multiplicative-Expr
    {
        $$.place = strdup($1.place);
        $$.code = strdup($1.code);
    }
    ;

Multiplicative-Expr: Term MULT Multiplicative-Expr
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
    | Term
    {
        $$.code = strdup($1.code);
        $$.place = strdup($1.place);
    }
    ;

Term: Var
    {
        std::string dst = new_temp();
        std::string temp;
        if($1.arr){
            temp.append($1.code);
            temp.append(". ");
            temp.append(dst);
            temp.append("\n");
            temp += "=[] " + dst + ", ";
            temp.append($1.place);
            temp.append("\n");
        }else{
            temp.append(". ");
            temp.append(dst);
            temp.append("\n");
            temp += "= " + dst + ", ";
            temp.append($1.place);
            temp.append("\n");
        }
        if(varTemp.find($1.place) != varTemp.end()){
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
    | NUMBER
    {
        $$.code = strdup("");
        $$.place = strdup(std::to_string($1).c_str());
    }
    | L_PAREN Expression R_PAREN
    {
        $$.code = strdup($2.code);
        $$.place = strdup($2.place);
    }
    | Ident L_PAREN Expressions R_PAREN
    {
        if (functions.find(std::string($1.place)) == functions.end()) {
            char temp[128];
            snprintf(temp, 128, "Use of undeclared function %s", $1.place);
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

Vars:            Var
    {
        std::string temp;
        temp.append($1.code);
        if ($1.arr)
            temp.append(".[]| ");
        else
            temp.append(".| ");
        
        temp.append($1.place);
        temp.append("\n");

        $$.code = strdup(temp.c_str());
        $$.place = strdup("");
    }
    | Var COMMA Vars
    {
        std::string temp;
        temp.append($1.code);
        if ($1.arr)
            temp.append(".[]| ");
        else
            temp.append(".| ");
        
        temp.append($1.place);
        temp.append("\n");
        temp.append($3.code);
        
        $$.code = strdup(temp.c_str());
        $$.place = strdup("");
    };


Var: Ident
    {
        std::string temp;
        std::string ident = $1.place;
        if(funcs.find(ident) == funcs.end() && varTemp.find(ident) == varTemp.end()){
            printf("Identifier %s is not declared\n", ident.c_str());
        }else if(arrSize[ident] > 1){
            printf("Did not provide index for array Identifier %s \n", ident.c_str());
        }
        $$.code = strdup("");
        $$.place = strdup(ident.c_str());
        $$.arr = false;
    }
    | Ident L_SQUARE_BRACKET Expression R_SQUARE_BRACKET
    {
        std::string temp;
        std::string ident = $1.place;
        if(funcs.find(ident) == funcs.end() && varTemp.find(ident) == varTemp.end()){
            printf("Identifier %s is not declared\n", ident.c_str());
        }else if(arrSize[ident] > 1){
            printf("Provided index for non-array Identifier %s \n", ident.c_str());
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


std::string new_temp() {
  static int num = 0;
  std::string temp = "_t" + std::to_string(num++);
  return temp;
}

std::string new_label() {
  static int num = 0;
  std::string temp = 'L' + std::to_string(num++);
  return temp;
}

int main(int argc, char **argv) {
   if (argc > 1) {
      yyin = fopen(argv[1], "r");
      if (yyin == NULL){
         printf("syntax: %s filename\n", argv[0]);
      }//end if
   }//end if
   yyparse(); // Calls yylex() for tokens.
   return 0;
}


void yyerror(const char *msg) {
      printf("ERROR: %s at symbol on line %d, col %d\n", msg, num_lines, num_column);

}
		