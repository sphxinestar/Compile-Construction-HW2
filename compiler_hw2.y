/*	Definition section */
%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

extern int yylineno;
extern int yylex();
extern char* yytext;   // Get current token from lex
extern char buf[256];  // Get current code line from lex

/* Symbol table function - you can add new function if needed. */
int lookup_symbol();
void create_symbol();
void insert_symbol(int conditional, char name[], char entry_type[], int scope_level, int func_f);
void dump_symbol();
void yyerror();

struct symbol_table{
	int func_f;
	char name[100];
	char entry_type[100];
	char data_type[100];
	int scope_level;
	char attribute[100];
}st[100];
/*struct symbol_table st[100];*/

char parameter_buf[100];
int st_index = 0;
%}

/* Use variable or self-defined structure to represent
 * nonterminal and token type
 */
%union {
    int i_val;
    double f_val;
    char* string;
}

/* Token without return */
%token ADD SUB MUL DIV MOD INC DEC MT LT MTE LTE EQ NE
%token ASGN ADDASGN SUBASGN MULASGN DIVASGN MODASGN
%token AND OR NOT LB RB LCB RCB LSB RSB COMMA
%token PRINT 
%token IF ELSE FOR WHILE TRUE FALSE RET
%token SEMICOLON 

/* Token with return, which need to sepcify type */
%token <i_val> I_CONST
%token <f_val> F_CONST
%token <string> S_CONST
%token <string> ID BOOL INT STRING FLOAT VOID 

/* Nonterminal with return, which need to sepcify type */
%type <string> type
/*%type <f_val> stat*/

/* Yacc will start at this nonterminal */
%start program

/* Grammar section */
%%

program
	: stat
	| program stat
	;
stat
	: function_definition
	| declaration
	| print_func_statement
	;
function_definition
	: type ID LB declaration_list RB compound_statement {
		insert_symbol(0, $2, $1, 0, 0);
	}
	| type ID LB RB compound_statement {
		insert_symbol(0, $2, $1, 0, 1);
	}
	;
type
	: INT	{$$ = $1; }
	| FLOAT	{$$ = $1; }
	| BOOL	{$$ = $1; }
	| STRING	{$$ = $1; }
	| VOID	{$$ = $1; }
	;
declaration_list
	: declaration_list COMMA d_l_t
	| d_l_t
	;
d_l_t
	:type ID{
                if(strcmp(parameter_buf,"") == 0){
                        strcat(parameter_buf, $1);
                }else{
                        strcat(parameter_buf, ",");
                        strcat(parameter_buf, $1);
                }
                if(strcmp(parameter_buf,"") == 0){
                        strcat(parameter_buf, $2);
                }else{
                        strcat(parameter_buf, ",");
                        strcat(parameter_buf, $2);
                }
		insert_symbol(1, $2, $1, 1, 0);
	}
	;
compound_statement
	: LCB RCB
	| LCB block_item_list RCB
	;
block_item_list
	: block_item
	| block_item_list block_item
	;
block_item
	: internal_declaration
	| statement
	;
internal_declaration
        : type ID ASGN expression SEMICOLON{
                insert_symbol(2, $2, $1, 1, 0);
        }
        | type ID SEMICOLON{
                insert_symbol(2, $2, $1, 1, 0);
        }
        ;
declaration
	: type ID ASGN expression SEMICOLON{
		insert_symbol(2, $2, $1, 0, 0);
	}
	| type ID SEMICOLON{
		insert_symbol(2, $2, $1, 0, 0);
	}
	;
statement
	 /*labeled_statement*/
	: compound_statement
	| expression_statement
	| selection_statement
	| iteration_statement
	| jump_statement
	| print_func_statement
	;
print_func_statement
	: PRINT LB S_CONST RB
	| PRINT LB ID RB
	;
expression_statement
	: expression SEMICOLON
	| SEMICOLON
	;
expression
	: assignment_expression
	| expression COMMA assignment_expression
	;
assignment_expression
	: conditional_expression
	| unary_expression assignment_operator assignment_expression
	;
assignment_operator
	: ASGN
	| MULASGN
	| DIVASGN
	| MODASGN
	| ADDASGN
	| SUBASGN
	;
unary_expression
	: postfix_expression
	| INC unary_expression
	| DEC unary_expression
	;
postfix_expression
	: primary_expression
	| postfix_expression LSB expression RSB
	| postfix_expression LB RB
	| postfix_expression LB argument_expression_list RB
	| postfix_expression INC
	| postfix_expression DEC
	;
primary_expression
	: ID
	| constant
	;
constant
	: I_CONST
	| SUB I_CONST
	| F_CONST
	| SUB F_CONST
	| S_CONST
	| TRUE
	| FALSE
	;	
argument_expression_list
	: assignment_expression
	| argument_expression_list COMMA assignment_expression
	;
conditional_expression
	: logical_or_expression
	| logical_or_expression '?' expression ':' conditional_expression
	;
logical_or_expression
	: logical_and_expression
	| logical_or_expression OR logical_and_expression
	;
logical_and_expression
	: inclusive_or_expression
	| logical_and_expression AND inclusive_or_expression
	;
inclusive_or_expression
	: exclusive_or_expression
	| inclusive_or_expression '|' exclusive_or_expression
	;
exclusive_or_expression
	: and_expression
	| exclusive_or_expression '^' and_expression
	;
and_expression
	: equality_expression
	| and_expression '&' equality_expression
	;
equality_expression
	: relational_expression
	| equality_expression EQ relational_expression
	| equality_expression NE relational_expression
	;
relational_expression
	: additive_expression 
	| relational_expression LT additive_expression
	| relational_expression MT additive_expression
	| relational_expression LTE additive_expression 
	| relational_expression MTE additive_expression
	| relational_expression EQ additive_expression
	| relational_expression NE additive_expression
	;
additive_expression
	: multiplicative_expression
	| additive_expression ADD multiplicative_expression
	| additive_expression SUB multiplicative_expression
	;
multiplicative_expression
	: unary_expression
	| multiplicative_expression MUL unary_expression
	| multiplicative_expression DIV unary_expression
	| multiplicative_expression MOD unary_expression
	;
selection_statement
	: IF LB expression RB statement ELSE statement
	| IF LB expression RB statement
	;
iteration_statement
	: WHILE LB expression RB statement
	;
jump_statement
	: RET SEMICOLON
	| RET expression SEMICOLON 
	;



%%

/* C code section */
int main(int argc, char** argv)
{
    yylineno = 0;
	
    yyparse();
    dump_symbol();
    printf("\nTotal lines: %d \n",yylineno);

    return 0;
}

void yyerror(char *s)
{
    printf("\n|-----------------------------------------------|\n");
    printf("| Error found in line %d: %s\n", yylineno, buf);
    printf("| %s", s);
    printf("\n|-----------------------------------------------|\n\n");
}

void create_symbol() {
	int i = 0;
	for(i = 0; i< 100; i++){
		st[i].func_f = 0;
		memset(st[i].name, 0, strlen(st[i].name));
		memset(st[i].entry_type, 0, strlen(st[i].entry_type));
		memset(st[i].data_type, 0, strlen(st[i].data_type));
		st[i].scope_level = 0;
		memset(st[i].attribute, 0, strlen(st[i].attribute));
	}
}
void insert_symbol(int conditional, char name[], char data_type[], int scope_level, int func_f){
	switch(conditional){
		case 0:
			sprintf(st[st_index].name, "%s", name);
			sprintf(st[st_index].entry_type , "%s", "function");
			sprintf(st[st_index].data_type ,"%s", data_type);
			st[st_index].scope_level = scope_level;
			sprintf(st[st_index].attribute, "%s", parameter_buf);	
			memset(parameter_buf,0,strlen(parameter_buf));		
			st[st_index].func_f = func_f;
			st_index ++;
		break;
		case 1:
                        sprintf(st[st_index].name, "%s", name);
                        sprintf(st[st_index].entry_type , "%s", "parameter");
                        sprintf(st[st_index].data_type ,"%s", data_type);
                        st[st_index].scope_level = scope_level;
                        st[st_index].func_f = func_f;
                        st_index ++;			
		break;	
		case 2:
                        sprintf(st[st_index].name, "%s", name);
                        sprintf(st[st_index].entry_type , "%s", "variable");
                        sprintf(st[st_index].data_type ,"%s", data_type);
                        st[st_index].scope_level = scope_level;
                        st[st_index].func_f = func_f;
                        st_index ++;
		break;
	}
}
int lookup_symbol() {}
void dump_symbol() {
	int i = 0;
	int index = 0;
	for(i = 0;i < st_index; i++){
		if(st[i].scope_level == 0){
			printf("\n%-10s%-10s%-12s%-10s%-10s%-10s\n\n","Index", "Name", "Kind", "Type", "Scope", "Attribute");
			break;
		}
	}
	for(i = 0;i < st_index; i++){
		printf("%-10d%-10s%-12s%-10s%-10d%s\n",index, st[i].name, st[i].entry_type, st[i].data_type, st[i].scope_level, st[i].attribute);
		index ++;
	}
}








