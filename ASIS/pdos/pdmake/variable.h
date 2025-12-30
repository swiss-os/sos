/* Released to the public domain.
 *
 * Anyone and anything may copy, edit, publish,
 * use, compile, sell and distribute this work
 * and all its parts in any form for any purpose,
 * commercial and non-commercial, without any restrictions,
 * without complying with any conditions
 * and by any means.
 */

#ifdef SHORT_NAMES
#define variables_init _Pvinit
#define variables_destroy _Pvdest
#define variable_add _Pvadd
#define variable_find _Pvfind
#define variable_change _Pvxchg
#define variable_expand_line _Pvxplin
#define parse_var_line _Ppvrlin
#endif /* SHORT_NAMES */ 

enum variable_flavor {
    VAR_FLAVOR_RECURSIVELY_EXPANDED,
    VAR_FLAVOR_SIMPLY_EXPANDED,
    VAR_FLAVOR_IMMEDIATELY_EXPANDED
};

enum variable_origin {
    VAR_ORIGIN_AUTOMATIC,
    VAR_ORIGIN_COMMAND_LINE,
    VAR_ORIGIN_FILE
};    

typedef struct variable {
    char *name;
    char *value;
    enum variable_flavor flavor;
    enum variable_origin origin;
} variable;

void variables_init (void);
void variables_destroy (void);

variable *variable_add (char *name, char *value, enum variable_origin origin);
variable *variable_find (const char *name);
variable *variable_change (char *name, char *value, enum variable_origin origin);

char *variable_expand_line (char *line);

void parse_var_line (char *line, enum variable_origin origin);
