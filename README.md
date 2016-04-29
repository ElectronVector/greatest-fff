# greatest-fff
An embedded test framework based on greatest and the fake function framework.

## Changes to greatest.h
Made the TEST function definitions **not** static. This is so that they can be externed in a runner file where the SUITE is created. Creating the SUITE is easily automated, so that's why we want to do it in automatically generated runner file.
Change this line:
```c
#define GREATEST_TEST static greatest_test_res
```
To this:
```c
#define GREATEST_TEST greatest_test_res
```