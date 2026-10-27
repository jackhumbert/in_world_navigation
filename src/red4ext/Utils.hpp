#pragma once
#include <filesystem>

namespace Utils
{
void CreateLogger();
std::filesystem::path GetRootDir();
#ifndef __APPLE__
std::wstring ToWString(const char* aText);
#endif
}
