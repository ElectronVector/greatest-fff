#include "greatest.h"

#include "sample.h"

TEST default_sample_value_should_be_1() {
    int actual = sample_get_value();
    ASSERT_EQ_FMT(1, actual, "%d");
    PASS();
}

GREATEST_MAIN_DEFS();

int main(int argc, char **argv) {
    GREATEST_MAIN_BEGIN();      /* command-line arguments, initialization. */
    /* If tests are run outside of a suite, a default suite is used. */
    RUN_TEST(default_sample_value_should_be_1);
    
    GREATEST_MAIN_END();        /* display results */
}