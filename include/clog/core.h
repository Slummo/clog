#ifndef CLOG_LOG_H
#define CLOG_LOG_H

#include <stdio.h>
#include <errno.h>
#include <stdlib.h>
#include <string.h>

#define LOG_ERR 0
#define LOG_WARN 1
#define LOG_INFO 2
#define LOG_DEBUG 3

extern int log_level;

/**
 * @brief Print a message to stdout
 *
 */
#define OUT(fmt, ...) fprintf(stdout, fmt "\n", ##__VA_ARGS__)

/**
 * @brief Print a message and eventually errno to stderr
 *
 */
#define ERR(fmt, ...)                        \
    {                                        \
        fprintf(stderr, fmt, ##__VA_ARGS__); \
        if (errno) {                         \
            perror(". ERR");                 \
            errno = 0;                       \
        } else {                             \
            fprintf(stderr, "\n");           \
        }                                    \
    }

#define printl(type, fmt, ...)                                                 \
    {                                                                          \
        if (log_level >= type) {                                               \
            switch (type) {                                                    \
                case LOG_ERR:                                                  \
                    ERR("{-}[%s:%d] " fmt, __FILE__, __LINE__, ##__VA_ARGS__); \
                    break;                                                     \
                case LOG_WARN:                                                 \
                    OUT("{~}[%s:%d] " fmt, __FILE__, __LINE__, ##__VA_ARGS__); \
                    break;                                                     \
                case LOG_INFO:                                                 \
                    OUT("{+}[%s:%d] " fmt, __FILE__, __LINE__, ##__VA_ARGS__); \
                    break;                                                     \
                case LOG_DEBUG:                                                \
                    OUT("{*}[%s:%d] " fmt, __FILE__, __LINE__, ##__VA_ARGS__); \
                    break;                                                     \
                default:                                                       \
                    break;                                                     \
            }                                                                  \
        }                                                                      \
    }

static inline void log_init(void) {
    char* env = getenv("LOG_LEVEL");
    if (env) {
        log_level = atoi(env);
    }
}

#endif