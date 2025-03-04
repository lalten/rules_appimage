
#include "rules_cc/cc/runfiles/runfiles.h"

#include <cassert>
#include <filesystem>
#include <iostream>

using rules_cc::cc::runfiles::Runfiles;

int main(int argc, const char **argv) {
  assert(argc > 0 && "Failed to get argc");
  assert(argv[0] != nullptr && "Failed to get argv");
  std::cout << "argv0: " << argv[0] << std::endl;

  const auto runfiles{Runfiles::Create(argv[0])};
  assert(runfiles != nullptr && "Failed to load runfiles");

  const auto path =
      runfiles->Rlocation("appimage_runtime_aarch64/file/downloaded");
  assert(!path.empty() && "Failed to find external binary");
  std::cout << "path: " << path << std::endl;

  const auto exists = std::filesystem::exists(path);
  assert(exists && "external path does not exist");

  return exists ? 0 : 1;
}
