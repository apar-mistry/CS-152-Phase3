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
    std::set<std::string> reserved {"FUNCTION", "BEGIN_PARAMS", "END_PARAMS", "BEGIN_LOCALS", "END_LOCALS", 
    "BEGIN_BODY", "END_BODY", "INTEGER", "ARRAY", "OF", "IF", "THEN", "ENDIF", "ELSE", "WHILE", "DO", "FOR", "BEGINLOOP", 
    "ENDLOOP", "CONTINUE", "READ", "WRITE", "TRUE", "FALSE", "RETURN", "SEMICOLON", "COLON", "COMMA", };
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
                std::string::ident = parse.substr(left, right);
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
                lef
                t = right + 1;
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

%%