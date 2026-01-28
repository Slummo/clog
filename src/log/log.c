#include <log.h>

#include <stdlib.h>

void log_init(void) {
    char* env = getenv("LOG_LEVEL");
    if (env) {
        log_level = atoi(env);
    }
}