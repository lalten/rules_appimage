#include <filesystem>

int main(int argc, char *argv[]) {
  return (std::filesystem::exists("tests/generated_data.txt") ? 0 : 1);
}
