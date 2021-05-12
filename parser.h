#include <stdio.h>
#include <string.h>
#include <stdlib.h>

// structure defined for symbol table
struct symrec{
  char* name;
  char addr[100];
  int isarray;
  struct symrec *next;
};

// structure for tree traversal for statements
struct stmtsBlock{
  int RightNull;
  struct stmtBlock* left;
  struct stmtsBlock* right;
};

// structure for a single statement
struct stmtBlock{
  int isTYPE; //isTYPE = 1 -> while , 2 -> for, 3 -> if
  char Body[1000]; //int x = y (assignment stmnt)
  char Condition[1000]; // code of conditional statements
  char dec_assign_1[1000]; // used in for loop for variable assignment
  char assignment_stmt_1[1000];
  char Jump[100];
  struct stmtsBlock* elseJump; //stmnts inside if-else 
  struct stmtsBlock* Next; // stmnt inside while loop 
};

//structure for function
struct FuncBlock{
  char name[100];
  int size;
  int num_args;
  struct symrec* SymbolTable;
  struct stmtsBlock* Stmts;
  struct FuncBlock* Next;
};


struct FuncBlock* GetFuncBlock(){
  struct FuncBlock* New = (struct FuncBlock*)malloc(sizeof(struct FuncBlock));
  return New;
}

struct stmtsBlock* GetstmtsBlock(){
  struct stmtsBlock* New = (struct stmtsBlock*)malloc(sizeof(struct stmtsBlock));
  return New;
}

struct stmtBlock* GetstmtBlock(){
  struct stmtBlock* New = (struct stmtBlock*)malloc(sizeof(struct stmtBlock));
  return New;
}

struct symrec* Getsymrec(){
  struct symrec* New = (struct symrec*)malloc(sizeof(struct symrec));
  return New;
}

struct symrec* putsym();
struct symrec* getsym();
void TreeTraversal(struct stmtsBlock* Node);
void StmtHandle(struct stmtBlock* Node);
void FuncHandle(struct FuncBlock* Node);
int getNumArgs(char* func_name);
int getSize(char* func_name);
