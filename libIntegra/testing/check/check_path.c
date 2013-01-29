#include "config.h"
#include <check.h>

#include "path.h"
#include "memory.h"
#include "Integra/integra.h"

START_TEST(test_ntg_path_new)
{
    ntg_path *path = ntg_path_new();

    fail_if(path == NULL, "path shouln't be NULL");
    ntg_path_free(path);
}
END_TEST


Suite *make_path_suite(void)
{
    Suite *s  = suite_create("Paths");

    TCase *tc = tcase_create("Core");

    suite_add_tcase(s, tc);
    tcase_add_test(tc, test_ntg_path_new);

    return s;

}
