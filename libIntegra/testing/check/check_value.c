#include <check.h>
#include "config.h"

#include "value.h"
#include "Integra/integra.h"

#define VALUES_DECLARE \
    ntg_value *value_i;\
    ntg_value *value_f;\
    ntg_value *value_s;\
    ntg_value *value_b;\
    ntg_value *value_n;\
    ntg_value *value_l;

#define VALUES_FREE \
    ntg_value_free(value_i);\
    ntg_value_free(value_f);\
    ntg_value_free(value_s);\
    ntg_value_free(value_b);\
    ntg_value_free(value_n);\
    ntg_value_free(value_l);

static const int    i_    = 1;
static const float  f_    = 1.f;
static const char   s_[]  = "1";
static const char   b_[1] = "1";
static const void  *n_    = NULL;
static const void  *l_    = NULL;

static const size_t len_s_ = sizeof(s_) - 1; /* work around strlen bug */
static const size_t len_b_ = sizeof(b_);
static const size_t len_l_ = 0;

#define VALUES_DEFINE \
    value_i = ntg_value_new(NTG_INTEGER, &i_);\
    value_f = ntg_value_new(NTG_FLOAT,   &f_);\
    value_s = ntg_value_new(NTG_STRING,  s_);\
    value_b = ntg_value_new(NTG_BLOB,    b_, len_b_);\
    value_n = ntg_value_new(NTG_NIL,     n_);\
    value_l = ntg_value_new(NTG_LIST,    l_);

START_TEST (test_ntg_value_new)
{

    VALUES_DECLARE;
    VALUES_DEFINE;

    /* check types */
    fail_unless(ntg_value_get_type(value_i) == NTG_INTEGER,
            "Type of %d should be %d", i_, NTG_INTEGER);
    fail_unless(ntg_value_get_type(value_f) == NTG_FLOAT,
            "Type of %f should be %d", f_, NTG_FLOAT);
    fail_unless(ntg_value_get_type(value_s) == NTG_STRING,
            "Type of %s should be %d", s_, NTG_STRING);
    fail_unless(ntg_value_get_type(value_b) == NTG_BLOB,
            "Type should be %d", NTG_BLOB);
    fail_unless(ntg_value_get_type(value_n) == NTG_NIL,
            "Type should be %d", NTG_NIL);
    fail_unless(ntg_value_get_type(value_l) == NTG_LIST,
            "Type should be %d", NTG_LIST);

    /* check lengths */
    fail_unless(ntg_value_get_length(value_i) == -1,
            "Length of numeric value should be -1");
    fail_unless(ntg_value_get_length(value_f) == -1,
            "Length of numeric value should be -1");
    fail_unless(ntg_value_get_length(value_s) == len_s_,
            "Length of %s should be %d", s_, len_s_);
    fail_unless(ntg_value_get_length(value_b) == len_b_,
            "Length should be %d, but instead it was: %d", len_b_,
            ntg_value_get_length(value_b));
    fail_unless(ntg_value_get_length(value_n) == -1,
            "Length of nil should be -1");
    fail_unless(ntg_value_get_length(value_l) == len_l_,
            "Length should be %d", len_l_);

    /* check values */
    fail_unless(ntg_value_get_int(value_i) == i_,
            "New integer value should be %d", i_);
    fail_unless(ntg_value_get_float(value_f) == f_,
            "New floating point value should be %f", f_);
    fail_unless(!strncmp(ntg_value_get_string(value_s), s_, len_s_),
            "New string value should be %s", s_);
    fail_unless(!memcmp(ntg_value_get_blob(value_b), b_, len_b_),
            "New blob value should be %s", b_);
    fail_unless(ntg_value_pop(value_l) == NULL,
            "New list should have zero elements");

    VALUES_FREE;

}
END_TEST

START_TEST(test_ntg_value_from_string)
{
    VALUES_DECLARE;
    char str_l_[6];
    char str_n_[6];

    value_i = ntg_value_from_string(NTG_INTEGER, s_);
    value_f = ntg_value_from_string(NTG_FLOAT,   s_);
    value_s = ntg_value_from_string(NTG_STRING,  s_);
    value_b = ntg_value_from_string(NTG_BLOB,    s_);
    value_n = ntg_value_from_string(NTG_NIL,     s_);
    value_l = ntg_value_from_string(NTG_LIST,    s_);

    ntg_value_sprintf(str_l_, value_l);
    ntg_value_sprintf(str_n_, value_n);

    fail_unless(ntg_value_get_float(value_f) == f_,
            "%s as string should return %f as float", s_, f_);
    fail_unless(ntg_value_get_int(value_i) == i_,
            "%s as string should return %d as int", s_, i_);
    fail_unless(!strncmp(ntg_value_get_string(value_s), s_, strlen(s_)),
            "%s as string should return %s as string", s_, s_);
    fail_unless(!memcmp(ntg_value_get_blob(value_b), b_, strlen(s_)),
            "%s as string should return %s as blob", s_, b_);
    fail_unless(!strncmp(str_l_, NTG_NIL_REPR, strlen(NTG_NIL_REPR)),
            "%s as string should return  %s", s_, NTG_NIL_REPR);
    fail_unless(!strncmp(str_n_, NTG_NIL_REPR, strlen(NTG_NIL_REPR)),
            "%s as string should return  %s", s_, NTG_NIL_REPR);

    VALUES_FREE;

}
END_TEST

START_TEST(test_list_ops)
{
    VALUES_DECLARE;
    VALUES_DEFINE;

    ntg_value *value_i_;
    ntg_value *value_f_;
    ntg_value *value_s_;
    ntg_value *value_b_;
    ntg_value *value_n_;
    ntg_value *value_l_;

    /* mixed list, no nesting */
    ntg_value_push(value_l, value_i);
    ntg_value_push(value_l, value_f);
    ntg_value_push(value_l, value_s);
    ntg_value_push(value_l, value_b);
    ntg_value_push(value_l, value_n);

    value_l_ = ntg_value_duplicate(value_l);

    value_n_ = ntg_value_pop(value_l);
    value_b_ = ntg_value_pop(value_l);
    value_s_ = ntg_value_pop(value_l);
    value_f_ = ntg_value_pop(value_l);
    value_i_ = ntg_value_pop(value_l);

    fail_unless(ntg_value_compare(value_n_, value_n) == NTG_NO_ERROR,
            "Values are not equal");
    fail_unless(ntg_value_compare(value_b_, value_b) == NTG_NO_ERROR,
            "Values are not equal");
    fail_unless(ntg_value_compare(value_s_, value_s) == NTG_NO_ERROR,
            "Values are not equal");
    fail_unless(ntg_value_compare(value_f_, value_f) == NTG_NO_ERROR,
            "Values are not equal");
    fail_unless(ntg_value_compare(value_i_, value_i) == NTG_NO_ERROR,
            "Values are not equal");

    /* nested list */
    fail_unless(ntg_value_push(value_l, value_l_) == NTG_ERROR,
            "Nested listing should not be possible");

    fail_unless(ntg_value_get_length(value_l) == 0,
            "List length should be zero");

    ntg_value_free(value_i_);
    ntg_value_free(value_f_);
    ntg_value_free(value_s_);
    ntg_value_free(value_b_);
    ntg_value_free(value_n_);
    ntg_value_free(value_l_);

    VALUES_FREE;

}
END_TEST


Suite *make_value_suite(void)
{
    Suite *s  = suite_create("Values");

    TCase *tc = tcase_create("Core");

    suite_add_tcase(s, tc);
    tcase_add_test(tc, test_ntg_value_new);
    tcase_add_test(tc, test_ntg_value_from_string);
    tcase_add_test(tc, test_list_ops);

    return s;

}
