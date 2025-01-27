import os

env = Environment()

# Adjust these paths as necessary
godot_cpp_path = './godot-cpp'
src_path = './src'
build_path = './build'

env.Append(CPPPATH=[godot_cpp_path + '/include', godot_cpp_path + '/include/core', godot_cpp_path + '/include/gen'])
env.Append(LIBPATH=[godot_cpp_path + '/bin'])
env.Append(LIBS=['godot-cpp'])

env.Append(CPPFLAGS=['-std=c++17', '-fPIC'])
env.Append(LINKFLAGS=['-shared'])

sources = Glob(src_path + '/*.cpp')
#target = build_path + '/your_extension_name'  # Replace 'your_extension_name' with your desired output name

#env.SharedLibrary(target=target, source=sources)
