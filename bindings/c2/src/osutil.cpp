#include <sys/resource.h>
#include <stdio.h>

extern "C" {

int os_rlimit() {
    rlimit r;
    int res = getrlimit(RLIMIT_NOFILE, &r);
    if (res == 0) {
        printf("cur %llu max %llu\n", r.rlim_cur, r.rlim_max);
        res = setrlimit(RLIMIT_NOFILE, &r);
    }
    return res;
}

}
