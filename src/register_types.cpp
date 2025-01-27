#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/godot.hpp>

using namespace godot;

// Function to register types (empty for now)
void register_extension_types() {
    // Placeholder: Add class registrations here in the future
}

// Function to unregister types (empty for now)
void unregister_extension_types() {
    // Placeholder: Add cleanup code here in the future
}

// Initialization entry point
extern "C" void GDExtensionInit(GDExtensionInterfaceGetProcAddress get_proc_address, GDExtensionClassLibraryPtr library, GDExtensionInitialization *initialization) {
    GDExtensionBinding::InitObject init_obj(get_proc_address, library, initialization);

    init_obj.register_initializer(register_extension_types);
    init_obj.register_terminator(unregister_extension_types);
    init_obj.set_minimum_library_initialization_level(MODULE_INITIALIZATION_LEVEL_SCENE);

    init_obj.init();
}
