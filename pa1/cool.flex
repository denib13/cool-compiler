/* 
 *  The scanner definition for COOL.
 */

/*
 *  Stuff enclosed in %{ %} in the first section is copied verbatim to the
 *  output, so headers and global definitions are placed here to be visible
 * to the code in the file.  Don't remove anything that was here initially
 */
%{
#include <cool-parse.h>
#include <stringtab.h>
#include <utilities.h>

/* The compiler assumes these identifiers. */
#define yylval cool_yylval
#define yylex  cool_yylex

/* Max size of string constants */
#define MAX_STR_CONST 1025
#define YY_NO_UNPUT   /* keep g++ happy */

extern FILE *fin; /* we read from this file */

/* define YY_INPUT so we read from the FILE fin:
 * This change makes it possible to use this scanner in
 * the Cool compiler.
 */
#undef YY_INPUT
#define YY_INPUT(buf,result,max_size) \
	if ( (result = fread( (char*)buf, sizeof(char), max_size, fin)) < 0) \
		YY_FATAL_ERROR( "read() in flex scanner failed");

char string_buf[MAX_STR_CONST]; /* to assemble string constants */
char *string_buf_ptr;
int string_buf_len;
bool string_buf_overflow;

extern int curr_lineno;
extern int verbose_flag;

extern YYSTYPE cool_yylval;
int comment_nesting;

 
/*
 *  Add Your own definitions here
 */

%}

%x STRING
%x STRING_SLASH
%x COMMENT
%x ONELINECOMMENT
%x ERROR_STRING
%x EOF_STRING
%x EOF_COMMENT

/*
 * Define names for regular expressions here.
 */





WS              [ \t\f\v]+
CLASS           [Cc][Ll][Aa][Ss][Ss]             
FI              [Ff][Ii]
IF              [Ii][Ff]
IN              [Ii][Nn]
INHERITS        [Ii][Nn][Hh][Ee][Rr][Ii][Tt][Ss]
ISVOID          [Ii][Ss][Vv][Oo][Ii][Dd]
LET             [Ll][Ee][Tt]
LOOP            [Ll][Oo][Oo][Pp]    
POOL            [Pp][Oo][Oo][Ll]        
THEN            [Tt][Hh][Ee][Nn]                            
WHILE           [Ww][Hh][Ii][Ll][Ee]
CASE            [Cc][Aa][Ss][Ee]  
ESAC            [Ee][Ss][Aa][Cc]
NEW             [Nn][Ee][Ww]         
OF              [Oo][Ff]   
NOT             [Nn][Oo][Tt]          
ELSE            [Ee][Ll][Ss][Ee]
TRUE            t[Rr][Uu][Ee]
FALSE           f[Aa][Ll][Ss][Ee]
TYPEID          [A-Z][a-zA-Z0-9_]*
DIGIT           [0-9]  
INTEGER         {DIGIT}+
OBJECTID        [a-z][a-zA-Z0-9_]*
OPERATORS       [-+*/@,~:=<]
DOT             \.
SEMICOLON       \;
LBRACKET        \(
RBRACKET        \)
LCBRACKET       \{
RCBRACKET       \}
LSBRACKET       \[
RSBRACKET       \]
LE              <=
DARROW          =>
ASSIGN          <-
UNDERSCORE      _
SYMBOLS         [!#%$\^&>?`\\]
UNMATCHED       "*)"
VERTICALTAB     \v
TAB             \t
CARRIAGERETURN  \r
FORMFEED        \f
STRING          [^\"\0\n\\]+
NULL            \0
QUOTE           \"
NEW_LINE        \n
SLASH           \\
OTHER           .

%%
        comment_nesting = 0;

"(*"   {
          BEGIN(COMMENT);
          comment_nesting++;
}
<COMMENT>"(*"           { comment_nesting++;  }
<COMMENT>"*"+")"        { comment_nesting--; if(comment_nesting == 0) { BEGIN(INITIAL); } }
<COMMENT>"*"+           ;
<COMMENT>[^\(*\n]+      ;
<COMMENT>[\(]           ;
<COMMENT>\n             { curr_lineno++;  }
<COMMENT><<EOF>>        {
                            cool_yylval.error_msg  = "EOF in comment";
                            BEGIN(EOF_COMMENT);
                            return (ERROR);
}
<EOF_COMMENT>\n|.       {   yyterminate();  }


"--"   {
          BEGIN(ONELINECOMMENT);
}
<ONELINECOMMENT>[^\n]*
<ONELINECOMMENT>"\n"    { curr_lineno++; BEGIN(INITIAL);  }




{QUOTE} {
          string_buf_ptr = string_buf;
          string_buf_ptr[0] = '\0';
          string_buf_len = 0;
          string_buf_overflow = false;
          BEGIN(STRING);
        }
<STRING>{QUOTE} { 
        {
          BEGIN(INITIAL);
          if(string_buf_overflow || string_buf_len > MAX_STR_CONST - 1)
          {
             cool_yylval.error_msg = "String constant too long";
             return (ERROR);
          }
          else 
          {
            cool_yylval.symbol = inttable.add_string(string_buf_ptr);
            return (STR_CONST);
          }
        }}
<STRING><<EOF>> { 
        {
          yyrestart(yyin);
          cool_yylval.error_msg = "EOF in string constant";
          BEGIN(EOF_STRING);
          return (ERROR);
        }}
<STRING>\n { 
        {
          cool_yylval.error_msg = "Unterminated string constant";
          BEGIN(INITIAL);
          return (ERROR);
        }}        
<STRING>{SLASH} { 
        {
          BEGIN(STRING_SLASH);
        }}  
<STRING>{STRING} { 
        {
          if(string_buf_overflow || string_buf_len + yyleng > MAX_STR_CONST - 1)
          {
            string_buf_overflow = true;
          }
          else 
          {
            for(int i = 0; i < yyleng; i++) 
            {
              string_buf_ptr[string_buf_len++] = yytext[i];
            }
            string_buf_ptr[string_buf_len] = '\0';
          }
        }}
<STRING_SLASH>\0 {{
        cool_yylval.error_msg = "String contains escaped null character.";
        BEGIN(ERROR_STRING);
        return (ERROR);
}}
<STRING_SLASH>\n {{
        curr_lineno++;
        if(string_buf_overflow || string_buf_len + 1 > MAX_STR_CONST - 1)    
        {
          string_buf_overflow = true;
        }      
        else 
        {
          string_buf_ptr[string_buf_len++] = '\n';
          string_buf_ptr[string_buf_len] = '\0';
        }
        BEGIN(STRING);
}}
<STRING_SLASH><<EOF>> {{
          yyrestart(yyin);
          cool_yylval.error_msg = "EOF in string constant";
          BEGIN(EOF_STRING);
          return (ERROR);
}}        
<STRING_SLASH>. {{
        if(string_buf_overflow || string_buf_len + 1 > MAX_STR_CONST - 1)    
        {
          string_buf_overflow = true;
        }      
        else 
        {
          char c = yytext[0];
          if (c == 't') {
              c = '\t';
          } else if (c == 'b') {
              c = '\b';
          } else if (c == 'n') {
              c = '\n';
          } else if (c == 'f') {
              c = '\f';
          }
          string_buf_ptr[string_buf_len++] = c;
          string_buf_ptr[string_buf_len] = '\0';
        }
        BEGIN(STRING);
}}
<ERROR_STRING>{QUOTE} { 
        { 
          BEGIN(INITIAL);
        }}
<ERROR_STRING>\n { 
        { 
          BEGIN(INITIAL);
        }}
<ERROR_STRING><<EOF>> { 
        {
          yyterminate();
        }}
<EOF_STRING>\n|. { 
        {
          yyterminate();
        }}

{WS}                        ;
{NEW_LINE}|{CARRIAGERETURN}   { curr_lineno++;  }     
{CLASS}      { return (CLASS); }
{FI}      { return (FI); }
{IF}      { return (IF); }
{IN}      { return (IN); }
{INHERITS}      { return (INHERITS); }
{ISVOID}      { return (ISVOID); }
{LET}      { return (LET); }
{LOOP}      { return (LOOP); }
{POOL}      { return (POOL); }
{THEN}      { return (THEN); }
{WHILE}      { return (WHILE); }
{CASE}      { return (CASE); }
{ESAC}      { return (ESAC); }
{NEW}      { return (NEW); }
{OF}      { return (OF); }
{NOT}      { return (NOT); }
{ELSE}      { return (ELSE); }
{TRUE}      { cool_yylval.boolean = true;
              return (BOOL_CONST); 
}
{FALSE}      { cool_yylval.boolean = false;
               return (BOOL_CONST); 
}
{TYPEID}     { cool_yylval.symbol = inttable.add_string(yytext);
                return (TYPEID); 
}
{INTEGER}   { 
              cool_yylval.symbol = inttable.add_string(yytext);
              return (INT_CONST); 
}
{OBJECTID}  { 
              cool_yylval.symbol = inttable.add_string(yytext);
              return (OBJECTID); 
}
{OPERATORS} { return yytext[0]; }
{DOT}       { return yytext[0]; }
{SEMICOLON} { return yytext[0]; }
{LBRACKET}  { return yytext[0]; }
{RBRACKET}  { return yytext[0]; }
{LCBRACKET} { return yytext[0]; }
{RCBRACKET} { return yytext[0]; }
{LSBRACKET} {
              cool_yylval.error_msg = yytext;
              return (ERROR);
}

{RSBRACKET} {
              cool_yylval.error_msg = yytext;
              return (ERROR);
}
{LE}        { return (LE);}
{DARROW}		{ return (DARROW); }
{ASSIGN}    { return (ASSIGN);}
{UNDERSCORE} {
              cool_yylval.error_msg = yytext;
              return (ERROR);
}

{SYMBOLS}   {
              cool_yylval.error_msg = yytext;
              return (ERROR);
}
{UNMATCHED}  {
              cool_yylval.error_msg = "Unmatched *)";
              return (ERROR);
}
{OTHER}      {
              cool_yylval.error_msg = yytext;
              return (ERROR);
}

 /*
  * Keywords are case-insensitive except for the values true and false,
  * which must begin with a lower-case letter.
  */


 /*
  *  String constants (C syntax)
  *  Escape sequence \c is accepted for all characters c. Except for 
  *  \n \t \b \f, the result is c.
  *
  */


%%
