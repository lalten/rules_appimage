#include <cstdlib>
#include <iostream>
#include <string>

int main(int argc, char** argv, char** envp) {
  // Go through the environment variables and find the one we set in the BUILD.
  // When running inside the appimage, we want the env to not be lost.
  bool have_binary_env = false;
  bool have_appimage_env = false;
  for (char** env = envp; *env != 0; env++) {
    char* thisEnv = *env;
    std::cout << thisEnv << std::endl;
    if (std::string(thisEnv) == "MY_BINARY_ENV=not lost") {
      have_binary_env = true;
    } else if (std::string(thisEnv) == "MY_APPIMAGE_ENV=overwritten") {
      have_appimage_env = true;
    }
  }
  if (!have_binary_env) {
    std::cerr << "MY_BINARY_ENV not found or has wrong value" << std::endl;
    return EXIT_FAILURE;  // remove if Bazel version < 6
  }
  if (!have_appimage_env) {
    std::cerr << "MY_APPIMAGE_ENV not found or has wrong value" << std::endl;
    return EXIT_FAILURE;
  }
  return EXIT_SUCCESS;
}
