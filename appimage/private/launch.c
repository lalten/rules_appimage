#include <errno.h>
#include <fcntl.h>
#include <linux/limits.h>
#include <stdio.h>
#include <string.h>
#include <sys/mman.h>
#include <unistd.h>

extern const char dash[];
extern const int dash_len;

int main(int argc, char *const argv[], char *envp[]) {
  int fd = memfd_create("dash", MFD_CLOEXEC);
  if (fd == -1) {
    perror("memfd_create");
    return errno;
  }
  if (write(fd, dash, dash_len) == -1) {
    perror("write");
    return errno;
  }
  char path[PATH_MAX];
  strcpy(path, argv[0]);
  strcat(path, ".sh");

  char *argv_new[argc + 2];
  argv_new[0] = argv[0];
  argv_new[1] = path;
  for (int i = 2; i <= argc; i++) {
    argv_new[i] = argv[i];
  }
  argv_new[argc + 1] = NULL;

  return execveat(fd, "", argv_new, envp, AT_EMPTY_PATH);
}