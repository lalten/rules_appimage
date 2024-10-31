#include <cstdlib>
#include <iostream>
#include <string>

#include <filesystem>

namespace fs = std::filesystem;

int main(int argc, char **argv, char **envp) {
  (void)argc;
  (void)argv;

  int ret{EXIT_SUCCESS};

  // Go through the environment variables and find the one we set in the BUILD.
  // When running inside the appimage, we want the env to not be lost.
  bool have_binary_env = false;
  bool have_appimage_env = false;
  std::string bazel_version{"unknown"};
  for (char **env = envp; *env != 0; env++) {
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
    ret |= EXIT_FAILURE;
  }
  if (!have_appimage_env) {
    std::cerr << "MY_APPIMAGE_ENV not found or has wrong value" << std::endl;
    ret |= EXIT_FAILURE;
  }

  // Check for broken symlinks
  std::cout << "\n";
  bool libfoo_found{false}; // Make sure the test "libfoo.*.so" exists
  for (const auto &entry :
       fs::recursive_directory_iterator(fs::current_path())) {
    if (entry.path().filename() == "libfoo.so") {
      std::cout << "libfoo.so found" << std::endl;
      libfoo_found = true;
    }
    if (fs::is_symlink(entry.path())) {
      fs::path symlink_target = fs::read_symlink(entry.path());
      std::cerr << entry.path() << " -> " << symlink_target;
      if (!fs::exists(entry.path().parent_path() / symlink_target)) {
        std::cerr << " is broken" << std::endl;
        ret |= EXIT_FAILURE;
      }
      std::cerr << std::endl;
    }
  }
  if (!libfoo_found) {
    std::cerr << "libfoo.so not found" << std::endl;
    ret |= EXIT_FAILURE;
  }

  return ret;
}
