#include <cstdlib>
#include <iostream>
#include <string>

int main(int argc, char** argv, char** envp) {
  (void)argc;
  (void)argv;
  // Go through the environment variables and find the one we set in the BUILD.
  // When running inside the appimage, we want the env to not be lost.
  bool have_binary_env = false;
  bool have_appimage_env = false;
  std::string bazel_version{"unknown"};
  for (char** env = envp; *env != 0; env++) {
    std::string thisEnv{*env};
    std::cout << thisEnv << std::endl;
    if (thisEnv == "MY_BINARY_ENV=not lost") {
      have_binary_env = true;
    } else if (thisEnv == "MY_APPIMAGE_ENV=overwritten") {
      have_appimage_env = true;
    } else if (thisEnv.starts_with("USE_BAZEL_VERSION=")) {
      bazel_version = thisEnv.substr(18);
    }
  }
  if (!have_binary_env) {
    std::cerr << "MY_BINARY_ENV not found or has wrong value" << std::endl;
    if (bazel_version.starts_with("5")) {
      // This is only expected to work in Bazel 6+
    } else {
      return EXIT_FAILURE;
    }
  }
  if (!have_appimage_env) {
    std::cerr << "MY_APPIMAGE_ENV not found or has wrong value" << std::endl;
    return EXIT_FAILURE;
  }
  return EXIT_SUCCESS;
}
