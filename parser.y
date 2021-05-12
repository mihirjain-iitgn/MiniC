%{ 
#include "parser.h"

int yylex(void);
void yyerror(char*);

/*
Note : Active in the subsequent lines refers to the function that is
       currently being parsed.
*/

// value of the next address 
int Adr = 0;

// size of the activation record of the Active Function 
int size = 0;

// Number of parameters of a Function
int num_args = 0;

// Number of parameters of the Active Function
int cur_func_args = 0;

// Name of the Active Function
char cur_func[100];

// Used During the Label generation process
int countLabel = 0;

// Line number of the current line
int lines = 1;

// file pointer of the output file
FILE* fp;

// Active Symbol Table
struct symrec* sym_table = NULL;

// Active Function
struct FuncBlock* Func = NULL;

// Linked List of functions in the program
struct FuncBlock* Functions = NULL;
%}

%union{
    int val; // Number
    char id[1000]; // Name of a Variable or Function
    struct stmtBlock* stmtptr; 
    struct stmtsBlock* stmtsptr;
    char code[10000];
    char nData[1000]; // Used to load Varibles or constans.
    int num_params; // Number of parameters 
}

%token IF MAIN INT ELSE WHILE FOR RETURN INPUT PRINT VOID
%token<id> ID
%token<val> NUM
%token SEMICOLON COMMA LPAREN RPAREN LBRACK RBRACK LBRACE RBRACE
%token PLUS MINUS MUL DIV MOD
%token EQ NEQ LT LE GT GE
%token AND OR 
%token TRUE FALSE
%token ASSIGN
// Assigning types to non terminals
%type<stmtsptr> stmts
%type<stmtptr> stmt dec_stmt assignment_stmt while_stmt for_stmt if_stmt function_call dec_only dec_assign return_stmt input_int output_int
%type<code> bool_exp exp params_call function_call_assigned
%type<num_params> params
%type<nData> x bool_literal x1

%right ASSIGN
%left OR AND XOR
%right NOT
%left EQ NEQ LT LE GT GE
%left PLUS MINUS
%left MUL DIV
%left MOD
%right UNIMINUS

// for better error messages.
%define parse.error verbose
%%
 
prog : functions
;
// function grammar
functions : function functions | function | main_func
;
// main function 
main_func : VOID MAIN LPAREN RPAREN
                    {
                        // storing the function name in active functions variable.
                        strcpy(cur_func,"main");
                        // initialisation of function block 
                        Func = GetFuncBlock();
                        strcpy(Func->name,cur_func);
                        // initialisation of sumbol table for main function 
                        sym_table = NULL;
                        Adr = -8;
                        size = 8;
                    }
                    // stmnts inside the function  
            LBRACE stmts RBRACE 
                    {
                        // Func is current functions node  
                        Func->size = size;
                        Func->Stmts = $7;
                        Func->Next = Functions;
                        Func->SymbolTable = sym_table;
                        // Funnctions is linked list, we are inserting at head of it.
                        /*
                        Inserting at the head of the Linked List.
                        */
                        Functions = Func;
                    }
;

// parameter passing 
params : type ID COMMA
                    {
                        /*
                        The parameters are put in the symbol table of the function.
                        */
                        struct symrec* s;
                        s = putsym($2,1,0);
                    }
         params
                    {
                        /*
                        Counting the number of parameters.
                        */
                        $$ = 1 + $5;
                    }
       | type ID
                    {
                        /*
                        The parameters are put in the symbol table of the function.
                        */
                        struct symrec* s;
                        s = putsym($2,1,0);
                        $$ = 1;
                    }
       |  
                    {
                        $$ = 0;
                    }
;
// general function grammar 
function : type ID LPAREN
                    {
                        /*
                        A New Function Block and Symbol Table
                        is initialised.
                        */
                        strcpy(cur_func,$2);
                        Func = GetFuncBlock();
                        strcpy(Func->name,cur_func);
                        sym_table = Getsymrec();
                        /*
                        The first two memory blocks will be used to
                        store base address of parent and $ra. 
                        */
                        Adr = -8;
                    }
            params RPAREN
                    {
                        /*
                        size is initialised to 8 + size of parameters
                        */
                        size = 4*($5+2);
                        cur_func_args = $5;
                    }
            LBRACE stmts RBRACE
                    {
                        /*
                        Setting function struct values.
                        */
                        Func->Stmts = $9;
                        Func->Next = Functions;
                        Func->SymbolTable = sym_table;
                        Func->num_args = $5;
                        /*
                        Inserting at the head of the Linked List.
                        */
                        Func->size = size;
                        Functions = Func;
                    }
;


stmts :  stmt stmts 
                    {
                        $$ = GetstmtsBlock(); 
                        $$->left = $1; 
                        $$->right = $2; 
                        $$->RightNull = 0;
                    }
       | stmt  
                    {
                        $$ = GetstmtsBlock();
                        $$->left = $1;
                        $$->right = NULL;
                        $$->RightNull = 1;
                    }
;

stmt :  dec_stmt 
                    {
                        $$ = $1;
                    } 
      | assignment_stmt
                    {
                        $$ = $1;
                    } 
      | while_stmt
                    {
                        $$ = $1;
                    }
      | for_stmt
                    {
                        $$ = $1;
                    }
      | if_stmt
                    {
                        $$ = $1;
                    }
      | function_call
                    {
                        $$ = $1;
                    }
      | return_stmt
                    {
                        $$ = $1;
                    }
      | input_int
                    {
                        $$ = $1;
                    }
      | output_int
                    {
                        $$ = $1;
                    }
;
// declaration stmnt grammar
dec_stmt :  dec_only SEMICOLON
                    {
                        $$ = $1;
                    }
         |  dec_assign SEMICOLON
                    {
                        $$ = $1;
                    }
;


dec_only :  type ID
                    {
                        /*
                        Variable is put in the symbol table with initial value 0.
                        */
                        struct symrec* s;
                        s = putsym($2,1,0);
                        $$ = GetstmtBlock();
                        $$->isTYPE = 0;
                        sprintf($$->Body,"li $t0,0\nsw $t0,%s($t8)\n", s->addr);
                        $$->Next = NULL;
                        /*
                        Int stores 4 bytes.
                        */
                        size = size + 4;
                    }
          | type ID LBRACK NUM RBRACK
                    {
                        // array declaration
                        struct symrec* s;
                        /* putsym(name,size,isarray) */
                        s = putsym($2,$4,1);
                        $$ = NULL;
                        /*
                        Each element of array is 4 bytes.
                        */
                        size = size + 4*$4;
                    }
;

// Assignment declaration stmnt grammar
dec_assign : type ID ASSIGN exp
                    {
                        /*
                        Variable is put in the symbol table with initial value generated by exp.
                        */
                        struct symrec* s;
                        s = putsym($2,1,0);
                        $$ = GetstmtBlock();
                        $$->isTYPE = 0;
                        sprintf($$->Body,"%ssw $t0,%s($t8)\n", $4, s->addr);
                        $$->Next = NULL;
                        /*
                        Int stores 4 bytes.
                        */
                        size = size + 4;
                    }
;
// assignment_stmt grammar
assignment_stmt : ID ASSIGN exp SEMICOLON
                    {
                        /*
                        Assignment to int
                        */
                        struct symrec* s;
                        s = getsym($1);
                        if (s == NULL){
                            /*
                            Variable not found in symbol table
                            */
                            printf("Undefined Reference to %s\n",$1);
                            exit(0);
                        }
                        $$ = GetstmtBlock();
                        $$->isTYPE = 0;
                        sprintf($$->Body,"%s\nsw $t0,%s($t8)\n", $3, s->addr);
                        $$->Next = NULL;  
                    }
                | ID LBRACK x1 RBRACK ASSIGN exp SEMICOLON
                    {
                        /*
                        Assignment to array element
                        */
                        struct symrec* s;
                        // getsym gives the pointer to the variable
                        s = getsym($1);
                        if (s == NULL){
                            printf("Undefined Reference to %s\n",$1);
                            exit(0);
                        }
                        $$ = GetstmtBlock();
                        $$->isTYPE = 0;
                        sprintf($$->Body,"%s\n%s\nmul $t2,$t2,4\nli $t3,%s\nadd $t3,$t3,$t8\nadd $t2,$t2,$t3\nsw $t0,0($t2)\n",$6,$3,s->addr);
                        $$->Next = NULL;
                    }
;

// while stmnt grammar
while_stmt : WHILE LPAREN bool_exp RPAREN LBRACE stmts RBRACE
                    {
                        $$ = GetstmtBlock();
                        $$->isTYPE = 1;
                        $$->Next = $6;
                        sprintf($$->Condition,"%s\n",$3);
                        sprintf($$->Jump,"beq $t0, $0,");
                    }
;

params_call : ID COMMA params_call
                    {
                        /*
                        caller is puting the parameters on the activation record
                        of the calee.
                        */
                        struct symrec* s;
                        s = getsym($1);
                        if (s == NULL){
                            /*
                            Variable not found in symbol table
                            */
                            printf("Undefined Reference to %s\n",$1);
                            exit(0);
                        }
                        if (s->isarray == 1){
                            /*
                            Arrays not allowed in parameter passing.
                            */
                            printf("%s is not an int\n",$1);
                            exit(0);  
                        }
                        int pos = -4*num_args;
                        num_args = num_args - 1;
                        sprintf($$, "lw $t0,%s($t8)\nsw $t0, %d($sp)\n%s",s->addr,pos,$3);
                    }
       | ID
                    {
                        /*
                        caller is puting the parameters on the activation record
                        of the calee.
                        */
                        struct symrec* s;
                        s = getsym($1);
                        if (s == NULL){
                            /*
                            Variable not found in symbol table
                            */
                            printf("Undefined Reference to %s\n",$1);
                            exit(0);
                        }
                        if (s->isarray == 1){
                            /*
                            Arrays not allowed in parameter passing.
                            */
                            printf("%s is not an int\n",$1);
                            exit(0);  
                        }
                        int pos = -4*num_args;
                        num_args = num_args - 1;
                        sprintf($$,"lw $t0,%s($t8)\nsw $t0, %d($sp)\n",s->addr,pos);
                    }
       |            {
                        sprintf($$,"\0");
                    }
;

// function call grammar
function_call : ID LPAREN 
                    {
                        if (strcmp(cur_func,$1)==0){
                            num_args = cur_func_args + 2;
                        }
                        else{
                            num_args = getNumArgs($1) + 2;
                        }
                    }
                params_call RPAREN SEMICOLON
                    {   
                        $$ = GetstmtBlock();
                        $$->isTYPE = 0;
                        sprintf($$->Body,"%sjal %s\n", $4,$1);
                        $$->Next = NULL;
                    }
;

function_call_assigned : ID LPAREN 
                    {
                        if (strcmp(cur_func,$1)==0){
                            /*
                            Call to same function
                            */
                            num_args = cur_func_args + 2;
                        }
                        else{
                            /*
                            Call to other Function
                            */
                            num_args = getNumArgs($1) + 2;
                        }
                    }
                params_call RPAREN
                    {
                        /*
                        Result of function call will be returned in $v0.
                        */
                        sprintf($$,"%sjal %s\nmove $t0,$v0", $4,$1);
                    }

// for statement grammar
for_stmt : FOR LPAREN dec_assign SEMICOLON bool_exp SEMICOLON assignment_stmt RPAREN LBRACE stmts RBRACE
            {
                $$ = GetstmtBlock();
                $$->isTYPE = 2;
                $$->Next = $10;
                sprintf($$->Condition,"%s\n",$5);
                sprintf($$->Jump,"beq $t0, $0,");
                sprintf($$->dec_assign_1,"%s",$3->Body);
                sprintf($$->assignment_stmt_1,"%s",$7->Body);
            }
;


if_stmt : IF LPAREN bool_exp RPAREN LBRACE stmts RBRACE 
                    {
                        $$ = GetstmtBlock(); 
                        $$->isTYPE = 3;
                        $$->Next =$6;
                        sprintf($$->Condition,"%s", $3);
                        sprintf($$->Jump,"beq $t0, $0,");   
                        $$->elseJump=NULL;
                    }

            | IF LPAREN bool_exp RPAREN LBRACE stmts RBRACE ELSE LBRACE stmts RBRACE
                    {
                        $$ = GetstmtBlock(); 
                        $$->isTYPE = 3;
                        sprintf($$->Condition,"%s", $3);
                        sprintf($$->Jump,"beq $t0, $0,");   
                        $$->Next = $6;
                        $$->elseJump = $10;
                    }
;


return_stmt : RETURN exp SEMICOLON
                    {
                        /*
                        Return stmt of a function.
                        Callee restores the stack pointer
                        and base address of the caller.
                        */
                        $$ = GetstmtBlock();
                        $$->isTYPE = 0;
                        sprintf($$->Body,"%smove $v0,$t0\naddi $sp, $sp, %d\nlw $t8,-4($sp)\nlw $ra,-8($sp)\njr $ra\n",$2,size);
                        $$->Next = NULL;
                    }
            | RETURN SEMICOLON
                    {
                        $$ = GetstmtBlock();
                        $$->isTYPE = 0;
                        sprintf($$->Body,"addi $sp, $sp, %d\nlw $t8,-4($sp)\nlw $ra,-8($sp)\njr $ra\n",size);
                        $$->Next = NULL;  
                    }
;

input_int : INPUT LPAREN ID RPAREN SEMICOLON
                    {
                        struct symrec* s;
                        s = getsym($3);
                        if (s == NULL){
                            printf("Undefined Reference to %s\n",$3);
                            exit(0);
                        }
                        if (s->isarray == 1){
                            printf("%s is not an int\n",$3);
                            exit(0);                            
                        }
                        $$ = GetstmtBlock();
                        $$->isTYPE = 0;
                        sprintf($$->Body,"addi $v0, $zero, 5\nsyscall\nmove $t0,$v0\nsw $t0,%s($t8)\n",s->addr);
                        $$->Next = NULL;  
                    }
          | INPUT LPAREN ID LBRACK x1 RBRACK RPAREN SEMICOLON
                    {
                        struct symrec* s;
                        s = getsym($3);
                        if (s == NULL){
                            printf("Undefined Reference to %s\n",$3);
                            exit(0);
                        }
                        if (s->isarray == 0){
                            printf("%s is not an array\n",$3);
                            exit(0);                            
                        }
                        $$ = GetstmtBlock();
                        $$->isTYPE = 0;
                        sprintf($$->Body,"addi $v0, $zero, 5\nsyscall\nmove $t0,$v0\n%s\nmul $t2,$t2,4\nli $t3,%s\nadd $t3,$t3,$t8\nadd $t2,$t2,$t3\nsw $t0,0($t2)\n",$5,s->addr);
                        $$->Next = NULL;
                    }
;

output_int : PRINT LPAREN ID RPAREN SEMICOLON
                    {
                        struct symrec* s;
                        s = getsym($3);
                        if (s == NULL){
                            printf("Undefined Reference to %s\n",$3);
                            exit(0);
                        }
                        if (s->isarray == 1){
                            printf("%s is not an int\n",$3);
                            exit(0);                            
                        }
                        $$ = GetstmtBlock();
                        $$->isTYPE = 0;
                        sprintf($$->Body,"lw $t0,%s($t8)\nmove $a0,$t0\naddi $v0,$zero,1\nsyscall\nli $v0, 4\nla $a0, newline\nsyscall\n",s->addr);
                        $$->Next = NULL;
                    }
            | PRINT LPAREN ID LBRACK x1 RBRACK RPAREN SEMICOLON
                    {
                        struct symrec* s;
                        s = getsym($3);
                        if (s == NULL){
                            printf("Undefined Reference to %s\n",$3);
                            exit(0);
                        }
                        if (s->isarray == 0){
                            printf("%s is not an array\n",$3);
                            exit(0);                            
                        }
                        $$ = GetstmtBlock();
                        $$->isTYPE = 0;
                        sprintf($$->Body,"%s\nmul $t2,$t2,4\nli $t3,%s\nadd $t3,$t3,$t8\nadd $t2,$t2,$t3\nlw $t0,0($t2)\nmove $a0,$t0\naddi $v0,$zero,1\nsyscall\nli $v0, 4\nla $a0, newline\nsyscall\n",$5,s->addr);
                        $$->Next = NULL;
                    }
;

bool_exp : exp EQ exp 
                    {
                        sprintf($$,"%ssw $t0,-4($sp)\naddi $sp,$sp,-4\n%s\nsw $t0,-4($sp)\naddi $sp,$sp,-4\nlw $t1,0($sp)\naddi $sp,$sp,4\nlw $t0,0($sp)\naddi $sp,$sp,4\nseq $t0,$t0,$t1\n",$1,$3);
                    }
         | exp NEQ exp
                    {
                        sprintf($$,"%ssw $t0,-4($sp)\naddi $sp,$sp,-4\n%s\nsw $t0 -4($sp)\naddi $sp,$sp,-4\nlw $t1,0($sp)\naddi $sp,$sp,4\nlw $t0,0($sp)\naddi $sp,$sp,4\nsne $t0,$t0,$t1\n",$1,$3);
                    }
         | exp LT exp
                    {
                        sprintf($$,"%ssw $t0,-4($sp)\naddi $sp,$sp,-4\n%s\nsw $t0 -4($sp)\naddi $sp,$sp,-4\nlw $t1,0($sp)\naddi $sp,$sp,4\nlw $t0,0($sp)\naddi $sp,$sp,4\nslt $t0,$t0,$t1\n",$1,$3);
                    } 
         | exp LE exp
                    {
                        sprintf($$,"%ssw $t0,-4($sp)\naddi $sp,$sp,-4\n%s\nsw $t0 -4($sp)\naddi $sp,$sp,-4\nlw $t1,0($sp)\naddi $sp,$sp,4\nlw $t0,0($sp)\naddi $sp,$sp,4\nsle $t0,$t0,$t1\n",$1,$3);
                    } 
         | exp GT exp
                    {
                        sprintf($$,"%ssw $t0,-4($sp)\naddi $sp,$sp,-4\n%s\nsw $t0 -4($sp)\naddi $sp,$sp,-4\nlw $t1,0($sp)\naddi $sp,$sp,4\nlw $t0,0($sp)\naddi $sp,$sp,4\nsgt $t0,$t0,$t1\n",$1,$3);
                    } 
         | exp GE exp
                    {
                        sprintf($$,"%ssw $t0,-4($sp)\naddi $sp,$sp,-4\n%s\nsw $t0 -4($sp)\naddi $sp,$sp,-4\nlw $t1,0($sp)\naddi $sp,$sp,4\nlw $t0,0($sp)\naddi $sp,$sp,4\nsge $t0,$t0,$t1\n",$1,$3);
                    } 
         | bool_exp OR bool_exp
                    {
                        sprintf($$,"%ssw $t0,-4($sp)\naddi $sp,$sp,-4\n%s\nsw $t0 -4($sp)\naddi $sp,$sp,-4\nlw $t1,0($sp)\naddi $sp,$sp,4\nlw $t0,0($sp)\naddi $sp,$sp,4\nor $t0,$t0,$t1\n",$1,$3);
                    } 
         | bool_exp AND bool_exp
                    {
                        sprintf($$,"%ssw $t0,-4($sp)\naddi $sp,$sp,-4\n%s\nsw $t0 -4($sp)\naddi $sp,$sp,-4\nlw $t1,0($sp)\naddi $sp,$sp,4\nlw $t0,0($sp)\naddi $sp,$sp,4\nand $t0,$t0,$t1\n",$1,$3);
                    }
         | bool_literal
                    {
                        printf($$,"%s",$1);
                    }    
         | LPAREN bool_exp RPAREN
                    {
                        sprintf($$,"%s",$2);
                    } 
;

bool_literal : TRUE
                    {
                        sprintf($$,"li $t0,1\n");
                    }
             | FALSE
                    {
                        sprintf($$,"li $t0,0\n");
                    }
;

type : INT

exp : x
                    {
                        sprintf($$,"%s\n",$1);
                    }
    | exp PLUS exp
                    {
                        sprintf($$,"%ssw $t0 -4($sp)\naddi $sp,$sp,-4\n%s\nsw,$t0 -4($sp)\naddi $sp,$sp,-4\nlw $t1,0($sp)\naddi $sp,$sp,4\nlw $t0,0($sp)\naddi $sp,$sp,4\nadd $t0,$t0,$t1\n",$1,$3);
                    }
    | exp MINUS exp
                    {
                        sprintf($$,"%ssw $t0 -4($sp)\naddi $sp,$sp,-4\n%s\nsw,$t0 -4($sp)\naddi $sp,$sp,-4\nlw $t1,0($sp)\naddi $sp,$sp,4\nlw $t0,0($sp)\naddi $sp,$sp,4\nsub $t0,$t0,$t1\n",$1,$3);
                    }
    | exp MUL exp
                    {
                        sprintf($$,"%ssw $t0 -4($sp)\naddi $sp,$sp,-4\n%s\nsw,$t0 -4($sp)\naddi $sp,$sp,-4\nlw $t1,0($sp)\naddi $sp,$sp,4\nlw $t0,0($sp)\naddi $sp,$sp,4\nmul $t0,$t0,$t1\n",$1,$3);
                    }
    | exp DIV exp
                    {
                        sprintf($$,"%ssw $t0 -4($sp)\naddi $sp,$sp,-4\n%s\nsw,$t0 -4($sp)\naddi $sp,$sp,-4\nlw $t1,0($sp)\naddi $sp,$sp,4\nlw $t0,0($sp)\naddi $sp,$sp,4\ndiv $t0,$t0,$t1\n",$1,$3);
                    }
    | exp MOD exp
                    {
                        sprintf($$,"%ssw $t0 -4($sp)\naddi $sp,$sp,-4\n%s\nsw,$t0 -4($sp)\naddi $sp,$sp,-4\nlw $t1,0($sp)\naddi $sp,$sp,4\nlw $t0,0($sp)\naddi $sp,$sp,4\nrem $t0,$t0,$t1\n",$1,$3);
                    }
    | MINUS exp %prec UNIMINUS
                    {
                        sprintf($$,"%sneg $t0,$t0\n",$2);
                    }       
    | LPAREN exp RPAREN
                    {
                        sprintf($$,"%s",$2);
                    }
    | function_call_assigned
                    {
                        sprintf($$,"%s\n",$1);
                    }
;

x : NUM
                    {
                        sprintf($$,"li $t0,%d",$1);
                    }
  | ID
                    {
                        struct symrec* s;
                        s = getsym($1);
                        if (s == NULL){
                            printf("Undefined Reference to %s\n",$1);
                            exit(0);
                        }
                        if (s->isarray == 1){
                            printf("%s is not an int\n",$1);
                            exit(0);                            
                        }
                        sprintf($$, "lw $t0,%s($t8)",s->addr);
                    }

  | ID LBRACK x1 RBRACK
                    {
                        struct symrec* s;
                        s = getsym($1);
                        if (s == NULL){
                            printf("Undefined Reference to %s\n",$1);
                            exit(0);
                        }
                        if (s->isarray == 0){
                            printf("%s is not an array\n",$1);
                            exit(0);                            
                        }
                        sprintf($$,"%s\nmul $t2,$t2,4\nli $t3,%s\nadd $t3,$t3,$t8\nadd $t2,$t2,$t3\nlw $t0,0($t2)",$3,s->addr);
                    }
;
// indices of array, register used to store : t2 
x1 : NUM
                    {
                        sprintf($$,"li $t2,%d",$1);
                    }
   | ID
                    {
                        struct symrec* s;
                        s = getsym($1);
                        if (s == NULL){
                            printf("Undefined Reference to %s\n",$1);
                            exit(0);
                        }
                        if (s->isarray == 1){
                            printf("Using Array %s as Index.\n",$1);
                            exit(0);                            
                        }
                        sprintf($$, "lw $t2,%s($t8)",s->addr);
                    }
;
%%

struct symrec* putsym(char* sym_name,int size,int isarray){
    /*
    Parameters :
        > sym_name : Name of the Variable.
        > size : Will be 1 incase of ints and length of the array otherwise.
        > int : Indicator variable to identify arrays.
    Returns :
        > Pointer to the symbol table entry of the variable after insertion.
    */
    struct symrec* ptr = (struct symrec*)malloc(sizeof(struct symrec));
    ptr->name = (char*)malloc(strlen(sym_name)+1);
    Adr = Adr - 4*size;
    strcpy(ptr->name,sym_name);
    sprintf(ptr->addr,"%d",Adr);
    ptr->isarray = isarray;
    // Inserting New Node at the head of the list
    ptr->next = (struct symrec*)sym_table;
    sym_table = ptr;
    return ptr;
}

struct symrec* getsym(char* sym_name){
    /*
    Parameters :
        > sym_name : Name of the Variable.
    Returns :
        > Pointer to the symbol table entry of the variable.
    */
    struct symrec* ptr;
    for(ptr = sym_table; ptr!=NULL; ptr = (struct symrec *)ptr->next){
        if (strcmp(ptr->name,sym_name) == 0){
            // Variable Present.
            return ptr;
        }
    }
    // Variable Absent.
    return NULL;
}

void StmtHandle(struct stmtBlock* Node){
    /*
    Parameters :
        > Node : Struct of the statement currently being executed.
    Generates the code for the given statement in the output file.
    */
    if (Node!=NULL){
        if (Node->isTYPE == 1){ 
            // while statement
            int startLabel = countLabel;
            int endLabel = countLabel;
            countLabel++;
            fprintf(fp, "WhileLoopStart%d:\n%s%sNext%d\n", startLabel,Node->Condition,Node->Jump,endLabel);
            TreeTraversal(Node->Next);
            fprintf(fp,"j WhileLoopStart%d \nNext%d:",startLabel,endLabel);
        }
        else if (Node->isTYPE==2){
            // for statement
            int startLabel = countLabel;
            int endLabel = countLabel;
            countLabel++;
            fprintf(fp, "%s\n", Node->dec_assign_1);                  
            fprintf(fp, "ForLoopStart%d:\n",startLabel);                  
            fprintf(fp,"%s\n", Node->Condition);                 
            fprintf(fp, "%s ForLoopEnd%d\n",Node->Jump,endLabel);  
            TreeTraversal(Node->Next);                                
            fprintf(fp, "%s\n",Node->assignment_stmt_1);                 
            fprintf(fp,"j ForLoopStart%d\nForLoopEnd%d:",startLabel,endLabel); 
        }
        else if (Node->isTYPE==3){
            // if-else statement
            int endLabel = countLabel;
            fprintf(fp,"%s\n", Node->Condition);
            if (Node->elseJump != NULL) {
                // if without else
                int elseLabel = countLabel;
                countLabel++; 
                fprintf(fp, "%s else%d\n",Node->Jump,elseLabel);    
                TreeTraversal(Node->Next);                                     
                fprintf(fp,"j ifEnded%d\nelse%d:\n",endLabel, elseLabel);  
                TreeTraversal(Node->elseJump);                                    
                fprintf(fp,"ifEnded%d:\n",endLabel);                        
            }
            else{
                // if with else 
                countLabel++;
                fprintf(fp, "%s ifEnded%d\n",Node->Jump,endLabel);    
                TreeTraversal(Node->Next);                                   
                fprintf(fp,"j ifEnded%d\nifEnded%d:\n",endLabel, endLabel);         
            }
        
        }
        else{
            fprintf(fp,"%s",Node->Body);
        }
    }
}

void TreeTraversal(struct stmtsBlock* Node){
    /*
    Parameters :
        > Node : A tree data structure. Refer parser.h.
    
    Traverses the tree of statements.
    */
    if (Node!=NULL){
        if (Node->RightNull == 1){
            // Right Node NULL
            StmtHandle(Node->left);
        }
        else{
            StmtHandle(Node->left);
            TreeTraversal(Node->right);
        }
    }
}

void FuncHandle(struct FuncBlock* Node){
    /*
    Parameters :
        > Node : A Linked List data structure. Refer parser.h.
    
    Generates the code for function stored in Node
    and recurses to the next entry in the Linked List.
    */
    if (Node!=NULL){
        // Function Label
        fprintf(fp,"%s:\n",Node->name);
        // Storing $t8 register of the caller.
        fprintf(fp,"sw $t8,-4($sp)\n");
        fprintf(fp,"sw $ra,-8($sp)\n");
        // Start of the activation record is put in $t8
        fprintf(fp,"move $t8, $sp\n");
        // Stack is moved to make space for activation record of the function.
        fprintf(fp,"addi $sp, $sp,-%d\n",Node->size);
        TreeTraversal(Node->Stmts);
        if (strcmp("main",Node->name)==0){
            // Program exit code after main.
            fprintf(fp,"li $v0, 10\nsyscall\n");
        }
        FuncHandle(Node->Next);
    }
}

int getNumArgs(char* func_name){
    /*
    Parameters :
        > func_name : Name of the function
    
    Returns :
        > Number of parameters of the function.
    */
    struct FuncBlock* Func = Functions;
    while(Func!=NULL){
        if (strcmp(Func->name,func_name)==0){
            // Function Present.
            return Func->num_args;
        }
        Func = Func->Next;
    }
    // Function Absent.
    return -1;
}

int getSize(char* func_name){
    /*
    Parameters :
        > func_name : Name of the function
    Returns :
        > Size of the activation record of the function.
    */
    struct FuncBlock* Func = Functions;
    while(Func!=NULL){
        if (strcmp(Func->name,func_name)==0){
            // Function Present.
            return Func->size;
        }
        Func = Func->Next;
    }
    // Function Absent.
    return -1;
}

int main(){
    fp = fopen("mips.asm","w");
    fprintf(fp,".data\n     newline: .asciiz \" \" \n.text\n");
    yyparse();
    FuncHandle(Functions);
    fclose(fp);
}

void yyerror(char* s){
    /*
    Parameters :
        s : Error Message for syntax error.
    This function is called on syntax errors.
    It prints the line number along with the expected input and actual input.
    */
    printf("%s\nline number : %d\n", s,lines);
}
