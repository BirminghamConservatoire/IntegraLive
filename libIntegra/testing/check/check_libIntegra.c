#include <stdlib.h>
#include <check.h>
#include "check_libIntegra.h"

#include "config.h"

int main(void)
{
    unsigned int n_failed;
    SRunner *sr;

    sr = srunner_create(make_value_suite());
    srunner_add_suite(sr, make_path_suite());

    srunner_run_all (sr, CK_NORMAL);
    n_failed = srunner_ntests_failed(sr);
    srunner_free(sr);

    return (n_failed == 0) ? EXIT_SUCCESS : EXIT_FAILURE;

}

