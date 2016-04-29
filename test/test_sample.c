#include "greatest.h"

#include "sample.h"
#include <stdio.h>

void setup(void *data) {
    printf("setup callback for each test case\n");
}

void teardown(void *data) {
    printf("teardown callback for each test case\n");
}

TEST default_sample_value_should_be_1() {
    int actual = sample_get_value();
    ASSERT_EQ_FMT(1, actual, "%d");
    PASS();
}
