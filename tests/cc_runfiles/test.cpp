
#include "rules_cc/cc/runfiles/runfiles.h"

#include <cassert>
#include <filesystem>
#include <iostream>

using rules_cc::cc::runfiles::Runfiles;

int main(int argc, const char **argv) {
  // Under Bzlmod, this can be "_main" - but not in WORKSPACE
  const std::string workspace_name{"rules_appimage"};

  const auto runfiles{Runfiles::Create("")};
  assert(runfiles != nullptr && "Failed to load runfiles");

  for (const auto &runfile : {
           std::string{"appimage_runtime_aarch64/file/downloaded"},
           workspace_name + "/tests/cc_runfiles/file.txt",
       }) {
    const auto path = runfiles->Rlocation(runfile);

    if (path.empty()) {
      std::cerr << "Failed to find runfile " << runfile << std::endl;
      return 1;
    }
    std::cout << "path for " << runfile << " is " << path << std::endl;

    if (!std::filesystem::exists(path)) {
      std::cerr << "runfile path does not exist: " << path << std::endl;
      return 1;
    }
  }

  return 0;
}
