%{
  #include <stdio.h>
  #include <stdlib.h>
  #include <string.h>
  #include "defs.h"
  #include "symtab.h"
  #include "codegen.h"

  int yyparse(void);
  int yylex(void);
  int yyerror(char *s);
  void warning(char *s);

  extern int yylineno;
  int out_lin = 0;
  char char_buffer[CHAR_BUFFER_LENGTH];
  int error_count = 0;
  int warning_count = 0;
  int var_num = 0;
  int fun_idx = -1;
  int fcall_idx = -1;
  int lit_start = 0;
  int lab_num = -1;
  int free_this_reg = -1;
  
  int case_arr[64] = {0};
  int case_i = 0;
  int case_type[64] = {0};
  int case_ti = 0;
  int check_lab_num = -1;
  int case_lab_num = -1;
  int check_pom = 0;
  
  int for_num = 0;
  int for_lab_num = -1;
  int lower_limit = 0;
  int upper_limit = 0;
  int step = 0;
  FILE *output;
  
  void do_inc()
  {
  	int idx = get_last_element();
	while(get_kind(idx) != 1) //16 32 64
	{
		if(get_kind(idx) == 16 || get_kind(idx) == 32 || get_kind(idx) == 64)
			if(get_atr2(idx) != 0)
			{
				code("\n\t\t%s\t", ar_instructions[ADD + (get_type(idx) - 1) * AROP_NUMBER]);
				gen_sym_name(idx);
				code(",$%d,", get_atr2(idx));
				gen_sym_name(idx);
				free_if_reg(idx);
				//int pom = take_reg();
				//gen_sym_name(pom);
				//set_type(pom, get_type(idx));
				//gen_mov(pom, idx);
				set_atr2(idx, 0);
				//print_symtab();
				//printf("inkrementirao promenljivu\n");
			 }
		idx--;
	}
  }
%}

%union {
  int i;
  char *s;
}

%token <i> _TYPE
%token _IF
%token _ELSE
%token _RETURN
%token <s> _ID
%token <s> _INT_NUMBER
%token <s> _UINT_NUMBER
%token _LPAREN
%token _RPAREN
%token _LBRACKET
%token _RBRACKET
%token _ASSIGN
%token _SEMICOLON
%token <i> _AROP
%token <i> _RELOP
%token _COMMA
%token _POST_INC
%token <i> _AND
%token <i> _OR
%token _FOR
%token _IN
%token _STEP
%token _DOTDOT
%token _CASE
%token _CHECK
%token _OTHERWISE
%token _IMPL
%token _Q_MARK
%token _COLON

%type <i> num_exp exp literal function_call argument argument_list rel_exp variable_no_semicolon assignment_statement check_no_otherwise case if_statement if_part log_exp_and log_exp_or post_inc for_statement global_var_no_semicolon

%nonassoc ONLY_IF
%nonassoc _ELSE

%%

program
  : global_list function_list
      {  
        if(lookup_symbol("main", FUN) == NO_INDEX)
          err("undefined reference to 'main'");
       }
  ;
  
global_list
  : 
  | global_list global_var
  ;
  
global_var
  : global_var_no_semicolon _SEMICOLON
  ;
  
global_var_no_semicolon
  : _TYPE _ID
  {
  	int idx = lookup_symbol($2, GVAR);
  	if(idx != NO_INDEX)
  		err("redefinition of '%s'", $2);
  	else{
  		insert_symbol($2, GVAR, $1, NO_ATR, NO_ATR);
  		code("\n%s:\n\t\tWORD\t1", $2);
  	}
  }
  | global_var_no_semicolon _COMMA _ID 
  {
     if(lookup_symbol($3, GVAR) == NO_INDEX)
     {
        insert_symbol($3, GVAR, $1, ++var_num, NO_ATR);
        code("\n%s:\n\t\tWORD\t1", $3);
     }
     else 
        err("redefinition of '%s'", $3);
  }
  ;

function_list
  : function
  | function_list function
  ;

function
  : _TYPE _ID
      {
        fun_idx = lookup_symbol($2, FUN);
        if(fun_idx == NO_INDEX)
          fun_idx = insert_symbol($2, FUN, $1, NO_ATR, NO_ATR);
        else 
          err("redefinition of function '%s'", $2);
        
        code("\n%s:", $2);
        code("\n\t\tPUSH\t%%14");
        code("\n\t\tMOV \t%%15,%%14");
      }
    _LPAREN parameter _RPAREN body
      {
        clear_symbols(fun_idx + 1);
        var_num = 0;
        
        code("\n@%s_exit:", $2);
        code("\n\t\tMOV \t%%14,%%15");
        code("\n\t\tPOP \t%%14");
        code("\n\t\tRET");
      }
  ;
  
parameter
  : { set_atr1(fun_idx, 0); }
  | parameter parameter_list
  ;
  
parameter_list
  : _TYPE _ID
      {
      	if($1 == 3) err("Only functions can be void");
        insert_symbol($2, PAR, $1, 1, NO_ATR);
        set_atr1(fun_idx, 1);
        set_atr2(fun_idx, $1);
      }
  | parameter_list _COMMA _TYPE _ID
      {
        if($3 == 3) err("Only functions can be void");
        if(lookup_symbol($4, PAR) == NO_INDEX)
        {
          insert_symbol($4, PAR, $3, get_atr1(fun_idx)+1, NO_ATR);
          set_atr1(fun_idx, get_atr1(fun_idx)+1);
        }
        else err("redefinition of '%s'", $4);
      }
  ;

body
  : _LBRACKET variable_list
  	  {
        if(var_num)
          code("\n\t\tSUBS\t%%15,$%d,%%15", 4*var_num);
        code("\n@%s_body:", get_name(fun_idx));
      }
    statement_list return_statement _RBRACKET
  ;

variable_list
  :
  | variable_list variable
  ;

variable
  : variable_no_semicolon _SEMICOLON
  ;

variable_no_semicolon
  : _TYPE _ID
      {
      	$$ = $1;
      	if($1 == 3)
      	   err("variable cannot use type 'void'");
        if(lookup_symbol($2, VAR|PAR|GVAR) == NO_INDEX)
           insert_symbol($2, VAR, $1, ++var_num, NO_ATR);
        else 
           err("redefinition of '%s'", $2);
      }
  | variable_no_semicolon _COMMA _ID 
  	  {
        if(lookup_symbol($3, VAR|PAR|GVAR) == NO_INDEX)
           insert_symbol($3, VAR, $1, ++var_num, NO_ATR);
        else 
           err("redefinition of '%s'", $3);
      }
  ;

// Pojedinacni zadatak 3.
check
  : check_no_otherwise _RBRACKET { code("\n@checkexit%d:", check_lab_num); }
  | check_no_otherwise _OTHERWISE _IMPL 
  	{
  		code("\n@otherwise:");
  	}
  	statement _RBRACKET
  	{
  		code("\n@checkexit%d:", check_lab_num);
  	}
  ;

check_no_otherwise
  : _CHECK 
  	{
  		
  	}
  	_LPAREN _ID _RPAREN _LBRACKET
  	{
  		
  	}
  	case
  	{
  		if(lookup_symbol($4, VAR|PAR) == NO_INDEX)
  			err("'%s' is not defined", $4);
  		else if(get_type(lookup_symbol($4, VAR|PAR)) != get_type(check_pom))
  			err("case number must match check_expression type");
  		else
  		{
  			for(int i = 0; i < case_ti-1; i++)
  			{
  				//printf("case_type[i] = %d <==> case_type[i+1] = %d \n", case_type[i], case_type[i+1]);
  				if(case_type[i] != case_type[i+1])
  				{
  					err("case number must match check_expression type");
  					break;
  					printf("%d ", case_arr[i]);
  				}
  			}
  		}
  		case_lab_num = case_lab_num - case_i;
  		code("\n@check%d:", check_lab_num);
  		int check_id = lookup_symbol($4, VAR|PAR|GVAR);
  		for(int i = 0; i < case_i; i++) {
			if(get_type(check_id) == INT)
				code("\n\t\tCMPS \t");
			  else
				code("\n\t\tCMPU \t");
			gen_sym_name(check_id);
			code(",$%d", case_arr[i]);
			case_arr[i] = 0; //ponisti sadrzaj
			code("\n\t\tJEQ \t");
			code("@case%d", ++case_lab_num);
		}
  	}
  ;
  
case
  : _CASE literal
  {
  	check_pom = $2;
  	//printf("vrednost koju vraca get_type($2) = %d\n", get_type($2));
  	case_type[case_ti] = get_type($2);
  	case_ti++;
  	case_arr[case_i] = atoi(get_name($2));
  	case_i++;
	++check_lab_num;
	code("\n\t\tJMP \t@check%d", check_lab_num);
	++case_lab_num;
	code("\n@case%d:", case_lab_num);
  	
  }
  _IMPL statement
  {
  	code("\n\t\tJMP \t@checkexit%d", check_lab_num);
  }
  
  | case _CASE literal
  {
  	check_pom = $3;
  	//printf("vrednost koju vraca get_type($3) = %d\n", get_type($3));
  	case_type[case_ti] = get_type($3);
  	case_ti++;
  	for(int i = 0; i<case_i; i++)
  	{
  		if(case_arr[i] == atoi(get_name($3)))
  			err("case numbers must be distinct");
  	}
  	case_arr[case_i] = atoi(get_name($3));
  	case_i++;
	++case_lab_num;
	code("\n@case%d:", case_lab_num);
  }
  _IMPL statement
  {
  	code("\n\t\tJMP \t@checkexit%d", check_lab_num);
  }
  ;

// Pojedinacni zadatak 2.
for_statement
  : _FOR _TYPE _ID _IN _LPAREN literal _DOTDOT literal _STEP literal _RPAREN
  	{
  		$<i>$ = ++for_lab_num;
  		if($2 == 3) err("variable cannot use type 'void'");
  		if(lookup_symbol($3, VAR) == NO_INDEX)
           insert_symbol($3, VAR, $2, NO_ATR, NO_ATR); 
        for_num++;
        //printf("pozvan for iskaz, broj iskaza = %d\n", for_num);
        //else err("redefinition of '%s'", $3);
  		if($2 != get_type($6) || $2 != get_type($8) || $2 != get_type($10))
  			err("Variable types don't match");
  		//print_symtab();
  	//generisanje koda	
  		if(atoi(get_name($8)) >= atoi(get_name($6)))
  		{
  			lower_limit = take_reg();
  			set_type(lower_limit, get_type($6));
  			//gen_mov($6, lower_limit);
  			code("\n\t\tMOV \t$%d,", atoi(get_name($6)));
  			gen_sym_name(lower_limit);
  			
  			upper_limit = take_reg();
  			set_type(upper_limit, get_type($8));
  			//gen_mov($8, upper_limit);
  			code("\n\t\tMOV \t$%d,", atoi(get_name($8)));
  			gen_sym_name(upper_limit);
  			
  			step = take_reg();
  			set_type(step, get_type($10));
  			//gen_mov($10, step);
  			code("\n\t\tMOV \t$%d,", atoi(get_name($10)));
  			gen_sym_name(step);
  			
  			code("\n@for%d:", for_lab_num);
  			//gen_cmp(upper_limit, lower_limit);
  			if(get_type(upper_limit) == INT)
				code("\n\t\tCMPS \t");
			  else
				code("\n\t\tCMPU \t");
			gen_sym_name(upper_limit);
			code(",");
			gen_sym_name(lower_limit);
  			code("\n\t\t%s\t@forexit%d", opp_jumps[3 + ((get_type($6) - 1) * RELOP_NUMBER)], for_lab_num);
  				
  			int idx = lookup_symbol($3, VAR);
  			code("\n\t\tMOV \t%%%d,", lower_limit);
  			gen_sym_name(idx);
  			code("\n\t\t%s\t", ar_instructions[ADD + (get_type($6) - 1) * AROP_NUMBER]);
	  		gen_sym_name(lower_limit);
	  		code(",");
	  		gen_sym_name(step);
	  		code(",");
	  		gen_sym_name(lower_limit);
  		}
  		else
  		{
  			upper_limit = take_reg();
  			set_type(upper_limit, get_type($6));
  			//gen_mov($8, upper_limit);
  			code("\n\t\tMOV \t$%d,", atoi(get_name($6)));
  			gen_sym_name(upper_limit);
  			
  			lower_limit = take_reg();
  			set_type(lower_limit, get_type($8));
  			//gen_mov($6, lower_limit);
  			code("\n\t\tMOV \t$%d,", atoi(get_name($8)));
  			gen_sym_name(lower_limit);
  			
  			step = take_reg();
  			set_type(step, get_type($10));
  			//gen_mov($10, step);
  			code("\n\t\tMOV \t$%d,", atoi(get_name($10)));
  			gen_sym_name(step);
  			
  			code("\n@for%d:", for_lab_num);
  			//gen_cmp(lower_limit, upper_limit);
  			if(get_type(lower_limit) == INT)
				code("\n\t\tCMPS \t");
			  else
				code("\n\t\tCMPU \t");
			gen_sym_name(lower_limit);
			code(",");
			gen_sym_name(upper_limit);
  			code("\n\t\t%s\t@forexit%d", opp_jumps[2 + ((get_type($6) - 1) * RELOP_NUMBER)], for_lab_num);
  				
  			int idx = lookup_symbol($3, VAR);
  			code("\n\t\tMOV \t%%%d,", upper_limit);
  			gen_sym_name(idx);
  			code("\n\t\t%s\t", ar_instructions[SUB + (get_type($6) - 1) * AROP_NUMBER]);
	  		gen_sym_name(upper_limit);
	  		code(",");
	  		gen_sym_name(step);
	  		code(",");
	  		gen_sym_name(upper_limit);
  		}
  		
    }
    statement
    {
    	if(for_num == 0)
    		clear_symbols(lookup_symbol($3, PAR));
    	else
    		for_num--;
    	//printf("broj for iskaza nakon zavrsetka jednog = %d\n", for_num);
    	code("\n\t\tJMP \t@for%d", $<i>12);
    	code("\n@forexit%d:", $<i>12);
    	free_if_reg(upper_limit);
    	free_if_reg(lower_limit);
    	free_if_reg(step);
    }
  ;

statement_list
  :
  | statement_step
  ;

statement_step
  : statement
  | statement_step statement
  ;

statement
  : compound_statement
  | assignment_statement
  | if_statement { free_reg(); }
  | function_call _SEMICOLON
  | for_statement
  | check
  {
  	/*print_symtab();
  	for(int i = 0; i<64; i++)
  	{
  		printf("%d\n", case_arr[i]);
  	}*/
  	
  	//resetovanje za sledeci check
  	for(int i = 0; i<case_i; i++)
  	{
  		case_arr[i] = 0;
  		case_type[i] = 0;
  	}
  	case_i = 0;
  	case_ti = 0;
  	
  	/*printf("=======\n");
  	for(int i = 0; i<64; i++)
  	{
  		printf("%d\n", case_arr[i]);
  	}*/
  }
  ;

compound_statement
  : _LBRACKET statement_list _RBRACKET
  ;

assignment_statement
  : _ID _POST_INC _SEMICOLON
  	  {
  		int idx = lookup_symbol($1, VAR|PAR|GVAR);
        if(idx == NO_INDEX) err("'%s' undeclared", $1);
        code("\n\t\t%s\t", ar_instructions[ADD + (get_type(idx) - 1) * AROP_NUMBER]);
        gen_sym_name(idx);
        code(",$1,");
        free_if_reg(idx);
        $$ = take_reg();
        gen_sym_name($$);
        set_type($$, get_type(idx));
        gen_mov($$, idx);
  	  }
  | _ID _ASSIGN num_exp _SEMICOLON
      {
        int idx = lookup_symbol($1, VAR|PAR|GVAR);
        if(idx == NO_INDEX)
          err("invalid lvalue '%s' in assignment", $1);
        else if(get_type(idx) != get_type($3))
            err("incompatible types in assignment");
        gen_mov($3, idx);
        do_inc();
        free_if_reg(free_this_reg);
        free_this_reg = -1;
      }
  ;

num_exp
  : exp
  | num_exp _AROP exp
      {
        if(get_type($1) != get_type($3))
          err("invalid operands: arithmetic operation");
        else
        {
        	//print_symtab();
		    int t1 = get_type($1);    
		    code("\n\t\t%s\t", ar_instructions[$2 + (t1 - 1) * AROP_NUMBER]);
		    gen_sym_name($1);
		    code(",");
		    gen_sym_name($3);
		    code(",");
		    free_if_reg($3);
		    free_if_reg($1);
		    $$ = take_reg();
		    gen_sym_name($$);
		    set_type($$, t1);
		    //print_symtab();
		    //do_inc();
		    
		}
      }
  ;

exp
  : literal
  | _ID post_inc
      {
		    $$ = lookup_symbol($1, VAR|PAR|GVAR);
		    if($$ == NO_INDEX)
		      err("'%s' undeclared", $1);
		   	else if($2 == 1)
		   	{
		   		//printf("treba inkrementovati\n");
		   		int idx = lookup_symbol($1, VAR|PAR|GVAR);
		   		set_atr2(idx, get_atr2(idx)+1);
		   	}
      }
  | function_call
  | _LPAREN num_exp _RPAREN
      { $$ = $2; }
  | _LPAREN log_exp_or _RPAREN _Q_MARK exp _COLON exp
	  {
		if(get_type($5) != get_type($7)){
		  err("ekspresije nisu istog tipa");
		}
		lab_num++;
		$$ = take_reg();
		code("\n\t\tCMPS\t$0,");
		gen_sym_name($$-1);
		code("\n\t\t%s\t@false%d", opp_jumps[5], lab_num);
		code("\n@true%d:", lab_num);
		gen_mov($5, $$);
		code("\n\t\tJMP \t@exit%d", lab_num);
		code("\n@false%d:", lab_num);
		gen_mov($7, $$);
		code("\n@exit%d:", lab_num);
		free_this_reg = $$;
	  }
  ;
  
post_inc
  : { $$ = 0; }
  | _POST_INC { $$ = 1; }
  ;

literal
  : _INT_NUMBER
      { $$ = insert_literal($1, INT); if(lit_start == 0) lit_start = get_last_element(); } //pronalazim indeks u tabeli nakon kog krecu literali

  | _UINT_NUMBER
      { $$ = insert_literal($1, UINT); if(lit_start == 0) lit_start = get_last_element(); } //pronalazim indeks u tabeli nakon kog krecu literali
  ;

function_call
  : _ID 
      {
        fcall_idx = lookup_symbol($1, FUN);
        if(fcall_idx == NO_INDEX)
          err("'%s' is not a function", $1);
      }
    _LPAREN argument _RPAREN
      {
        if(get_atr1(fcall_idx) != $4)
          err("wrong number of arguments");
        code("\n\t\t\tCALL\t%s", get_name(fcall_idx));
        if($4 > 0)
          code("\n\t\t\tADDS\t%%15,$%d,%%15", $4 * 4);
        set_type(FUN_REG, get_type(fcall_idx));
        $$ = FUN_REG;
      }
  ;

argument
  : { $$ = 0; }
  | argument_list { $$ = $1; }
  ;

argument_list
  : num_exp
    {
      $$ = 1;
      if(get_atr2(fcall_idx) != get_type($1))
        err("incompatible type for argument in '%s'", get_name(fcall_idx));
      free_if_reg($1);
      code("\n\t\t\tPUSH\t");
      gen_sym_name($1);
    }
  | argument_list _COMMA num_exp
    {
      $$++;
      if(get_atr2(fcall_idx) != get_type($3))
        err("incompatible type for argument in '%s'", get_name(fcall_idx));
      free_if_reg($3);
      code("\n\t\t\tPUSH\t");
      gen_sym_name($3);
    }
  ;

if_statement
  : if_part %prec ONLY_IF
  		{ code("\n@exit%d:", $1); }
  | if_part _ELSE statement
  		{ code("\n@exit%d:", $1); }
  ;

if_part
  : _IF _LPAREN
      {
        $<i>$ = ++lab_num;
        code("\n\n\n@if%d:", lab_num);
      }
    log_exp_or
      {
        //code("\n\t\t%s\t@false%d", opp_jumps[$4], $<i>3);
        code("\n\t\tCMPS\t");
        gen_sym_name($4);
        code(",$1");
        code("\n\t\tJNE \t@false%d", $<i>3);
        code("\n@true%d:", $<i>3);
      }
    _RPAREN statement
      {
        code("\n\t\tJMP \t@exit%d", $<i>3);
        code("\n@false%d:", $<i>3);
        $$ = $<i>3;
      }
  ;

// Pojedinacni zadatak 1.
rel_exp
  : num_exp _RELOP num_exp
      {
      	++lab_num;
        if(get_type($1) != get_type($3))
          err("invalid operands: relational operator");
        //$$ = $2 + ((get_type($1) - 1) * RELOP_NUMBER); //bilo ovde pre nego sam poceo sa generisanjem koda
        $$ = take_reg();
        if(get_type($1) == INT)
			code("\n\t\tCMPS \t");
	    else
			code("\n\t\tCMPU \t");
        gen_sym_name($1);
        code(",");
        gen_sym_name($3);
        code("\n\t\t%s\t@false%d", opp_jumps[$2 + ((get_type($1) - 1) * RELOP_NUMBER)], lab_num); //biram kontra slucaj postavljenog relacionog izraza i ako je zadovoljen skacem na false
        code("\n\t\tMOV \t$1,");
        gen_sym_name($$);
        code("\n\t\tJMP \t@exit%d", lab_num);
        code("\n@false%d:", lab_num);
       	code("\n\t\tMOV \t$0,");
       	gen_sym_name($$);
        code("\n@exit%d:", lab_num);
      }
  ;
  
log_exp_and
  : rel_exp
  | log_exp_and _AND rel_exp
  	{
  		/*++lab_num;
  		code("\n\t\tCMPS\t");
        gen_sym_name($1);
        code(",$1");
  		code("\n\t\tJNE \t@false%d", lab_num);
  		code("\n\t\tCMPS\t");
        gen_sym_name($3);
        code(",$1");
  		code("\n\t\tJEQ \t@exit%d", lab_num);
  		code("\n@false%d:", lab_num);
  		code("\n\t\tMOV \t$0,");
  		gen_sym_name($1);
  		code("\n@exit%d:", lab_num);*/
  		code("\n\t\tMULS\t");
  		gen_sym_name($1);
  		code(",");
  		gen_sym_name($3);
  		code(",");
  		gen_sym_name($1);
  		free_if_reg($3);
  		$$ = $1;
  	}
  ;
  
log_exp_or
  : log_exp_and
  | log_exp_or _OR log_exp_and
  	{
  		++lab_num;
  		code("\n\t\tCMPS\t");
        gen_sym_name($1);
        code(",$1");
  		code("\n\t\tJEQ \t@true%d", lab_num);
  		code("\n\t\tCMPS\t");
        gen_sym_name($3);
        code(",$1");
  		code("\n\t\tJNE \t@exit%d", lab_num);
  		code("\n@true%d:", lab_num);
  		code("\n\t\tMOV \t$1,");
  		gen_sym_name($1);
  		code("\n@exit%d:", lab_num);
  		free_if_reg($3);
  		$$ = $1;
  	}
  ;

return_statement
  :
  	 {
      if(get_type(fun_idx) == 1 || get_type(fun_idx) == 2)
      	warning("missing return value in non void function");
      code("\n\t\tJMP \t@%s_exit", get_name(fun_idx));  
     }  
     
  | _RETURN _SEMICOLON
  	 {
      if(get_type(fun_idx) == 1 || get_type(fun_idx) == 2)
        warning("missing return value in non void function");
      code("\n\t\tJMP \t@%s_exit", get_name(fun_idx));  
  	 }
  	 
  | _RETURN num_exp _SEMICOLON
     {
      if(get_type(fun_idx) == 3)
      	err("void function cannot return a value");
      else if(get_type(fun_idx) != get_type($2))
      	err("incompatible types in return");
      gen_mov($2, FUN_REG);
      code("\n\t\tJMP \t@%s_exit", get_name(fun_idx));  
     }
  ;

%%

int yyerror(char *s) {
  fprintf(stderr, "\nline %d: ERROR: %s", yylineno, s);
  error_count++;
  return 0;
}

void warning(char *s) {
  fprintf(stderr, "\nline %d: WARNING: %s", yylineno, s);
  warning_count++;
}

int main() {
  int synerr;
  init_symtab();
  output = fopen("output.asm", "w+");

  synerr = yyparse();

  clear_symtab();
  fclose(output);
  
  if(warning_count)
    printf("\n%d warning(s).\n", warning_count);

  if(error_count) {
    remove("output.asm");
    printf("\n%d error(s).\n", error_count);
  }

  if(synerr)
    return -1;  //syntax error
  else if(error_count)
    return error_count & 127; //semantic errors
  else if(warning_count)
    return (warning_count & 127) + 127; //warnings
  else
    return 0; //OK
}

