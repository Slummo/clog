#include <log.h>

#include <stdio.h>
#include <stdlib.h>

int log_level = LOG_INFO;

int main(void) {
    log_init();
    printl(LOG_WARN, "This is a warn");
    printl(LOG_ERR, "This is an error");
    printl(LOG_INFO, "This is an info");
    return EXIT_SUCCESS;
}