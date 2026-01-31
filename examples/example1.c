#include <clog/core.h>

int log_level = LOG_INFO;

int main(void) {
    log_init();
    printl(LOG_ERR, "This is an error!");
    printl(LOG_WARN, "This is a warn!");
    printl(LOG_INFO, "This is an info!");
    return 0;
}