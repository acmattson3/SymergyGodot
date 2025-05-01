# SymergyGodot - Microgrid Visualization Platform

SymergyGodot is a comprehensive executable for visualizing and monitoring microgrid systems. It provides real-time data visualization of electrical components including power sources, loads, and distribution infrastructure.

## Features

- **Real-time monitoring** of microgrid components via MQTT
- **Customizable widgets** with historical data charts and value gauges
- **Status indicators** for component health and operational state
- **Map visualization** showing the geographical layout of the microgrid

## About

SymergyGodot is built using **Godot 4.3**. It functions as a standalone executable file. It follows [**this MQTT standard**](https://github.com/acmattson3/SymergySim/blob/main/mqtt_standard.md).

## Development

### Launch Flags

When launching the executable via a terminal, it accepts the following flags:
* `--mqtt-host`: The MQTT broker hostname
* `--mqtt-user`: The MQTT broker username
* `--mqtt-pass`: The MQTT broker password
* `--run-tests`: Run unit tests on startup

The hostname, username, and password can all also be specified directly via the application's settings menu

### Future Changes

Many things in this interface work but are not ideally implemented:
* The value gauge should have different colors
* The settings menu does not scale to smaller resolutions well

Some things could be added:
* Rubber-sheetable drag-and-drop background (user can upload a custom image, define the image coordinate bounds, and have the image automatically fit the map diagram)
* Set up properly, this interface can function **without internet connectivity**, across local networks. Godot can be exported to **Android and iOS**; future developers may wish to extend the interface to work on these platforms
* A 3D view, with topology, is possible with Godot
* New widgets can be added by developing custom Godot UI elements to be held by a Widget container

## License

This project is licensed under the MIT License - see the LICENSE file for details.


For questions or support, please open an issue on the GitHub repository.
