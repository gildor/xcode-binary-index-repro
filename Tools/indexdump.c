// Minimal libIndexStore client: for each symbol name given on the command line, prints every
// unit/record in the store that DEFINES or DECLARES it (what Open Quickly surfaces), plus whether
// the owning unit is marked as a system unit.
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef void *indexstore_error_t, *indexstore_store_t, *indexstore_unit_reader_t,
    *indexstore_unit_dependency_t, *indexstore_record_reader_t, *indexstore_symbol_t;
typedef struct { const char *data; size_t length; } indexstore_string_ref_t;

extern indexstore_store_t indexstore_store_create(const char *, indexstore_error_t *);
extern const char *indexstore_error_get_description(indexstore_error_t);
extern bool indexstore_store_units_apply_f(indexstore_store_t, unsigned, void *, bool (*)(void *, indexstore_string_ref_t));
extern indexstore_unit_reader_t indexstore_unit_reader_create(indexstore_store_t, const char *, indexstore_error_t *);
extern void indexstore_unit_reader_dispose(indexstore_unit_reader_t);
extern indexstore_string_ref_t indexstore_unit_reader_get_module_name(indexstore_unit_reader_t);
extern indexstore_string_ref_t indexstore_unit_reader_get_main_file(indexstore_unit_reader_t);
extern bool indexstore_unit_reader_is_system_unit(indexstore_unit_reader_t);
extern bool indexstore_unit_reader_dependencies_apply_f(indexstore_unit_reader_t, void *, bool (*)(void *, indexstore_unit_dependency_t));
extern int indexstore_unit_dependency_get_kind(indexstore_unit_dependency_t);
extern bool indexstore_unit_dependency_is_system(indexstore_unit_dependency_t);
extern indexstore_string_ref_t indexstore_unit_dependency_get_name(indexstore_unit_dependency_t);
extern indexstore_string_ref_t indexstore_unit_dependency_get_filepath(indexstore_unit_dependency_t);
extern indexstore_record_reader_t indexstore_record_reader_create(indexstore_store_t, const char *, indexstore_error_t *);
extern void indexstore_record_reader_dispose(indexstore_record_reader_t);
extern bool indexstore_record_reader_symbols_apply_f(indexstore_record_reader_t, bool, void *, bool (*)(void *, indexstore_symbol_t));
extern indexstore_string_ref_t indexstore_symbol_get_name(indexstore_symbol_t);
extern uint64_t indexstore_symbol_get_roles(indexstore_symbol_t);
extern indexstore_string_ref_t indexstore_symbol_get_usr(indexstore_symbol_t);

#define ROLE_DECL 1
#define ROLE_DEF 2

static indexstore_store_t store;
static int nwanted;
static char **wanted;
static int *found;

static char *dup_ref(indexstore_string_ref_t s) {
    char *r = malloc(s.length + 1); memcpy(r, s.data, s.length); r[s.length] = 0; return r;
}

struct unit_ctx { char *unit, *module, *main_file; bool sys; };
struct rec_ctx { struct unit_ctx *u; char *file; bool dep_sys; };

static bool on_symbol(void *ctx, indexstore_symbol_t sym) {
    struct rec_ctx *rc = ctx;
    indexstore_string_ref_t n = indexstore_symbol_get_name(sym);
    uint64_t roles = indexstore_symbol_get_roles(sym);
    if (getenv("INDEXDUMP_REFS")) {  // also print references, with USR
        for (int i = 0; i < nwanted; i++)
            if (strlen(wanted[i]) == n.length && !memcmp(wanted[i], n.data, n.length)) {
                indexstore_string_ref_t u = indexstore_symbol_get_usr(sym);
                printf("  %s roles=0x%llx usr=%.*s module=%s\n", wanted[i], (unsigned long long)roles,
                       (int)u.length, u.data, rc->u->module);
            }
    }
    if (!(roles & (ROLE_DECL | ROLE_DEF))) return true;
    for (int i = 0; i < nwanted; i++) {
        if (strlen(wanted[i]) == n.length && !memcmp(wanted[i], n.data, n.length)) {
            found[i]++;
            printf("  %-28s module=%-12s unitSystem=%d depSystem=%d file=%s\n", wanted[i],
                   rc->u->module, rc->u->sys, rc->dep_sys, rc->file);
        }
    }
    return true;
}

static bool on_dep(void *ctx, indexstore_unit_dependency_t dep) {
    if (indexstore_unit_dependency_get_kind(dep) != 2 /* record */) return true;
    char *name = dup_ref(indexstore_unit_dependency_get_name(dep));
    struct rec_ctx rc = { ctx, dup_ref(indexstore_unit_dependency_get_filepath(dep)),
                          indexstore_unit_dependency_is_system(dep) };
    indexstore_error_t err = NULL;
    indexstore_record_reader_t rr = indexstore_record_reader_create(store, name, &err);
    if (rr) { indexstore_record_reader_symbols_apply_f(rr, true, &rc, on_symbol); indexstore_record_reader_dispose(rr); }
    free(name); free(rc.file);
    return true;
}

static bool verbose;
static bool on_unit(void *ctx, indexstore_string_ref_t unit_name) {
    char *un = dup_ref(unit_name);
    indexstore_error_t err = NULL;
    indexstore_unit_reader_t ur = indexstore_unit_reader_create(store, un, &err);
    if (!ur) { free(un); return true; }
    struct unit_ctx u = { un, dup_ref(indexstore_unit_reader_get_module_name(ur)),
                          dup_ref(indexstore_unit_reader_get_main_file(ur)),
                          indexstore_unit_reader_is_system_unit(ur) };
    if (verbose) printf("unit module=%s system=%d main=%s\n", u.module, u.sys, u.main_file);
    indexstore_unit_reader_dependencies_apply_f(ur, &u, on_dep);
    indexstore_unit_reader_dispose(ur);
    free(u.unit); free(u.module); free(u.main_file);
    return true;
}

int main(int argc, char **argv) {
    if (argc < 3) { fprintf(stderr, "usage: indexdump [-v] <DataStore path> <symbol>...\n"); return 2; }
    int a = 1;
    if (!strcmp(argv[a], "-v")) { verbose = true; a++; }
    indexstore_error_t err = NULL;
    store = indexstore_store_create(argv[a++], &err);
    if (!store) { fprintf(stderr, "open failed: %s\n", indexstore_error_get_description(err)); return 1; }
    wanted = argv + a; nwanted = argc - a; found = calloc(nwanted, sizeof(int));
    indexstore_store_units_apply_f(store, 0, NULL, on_unit);
    printf("-- summary\n");
    for (int i = 0; i < nwanted; i++) printf("  %-28s %s\n", wanted[i], found[i] ? "DEFINED in index" : "MISSING");
    return 0;
}
