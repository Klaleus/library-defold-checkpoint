# Checkpoint

Checkpoint is a simple library for writing and reading data to and from files in a Defold game engine project.

Please click the ☆ button on GitHub if this repository is useful. Thank you!

![Checkpoint Thumbnail](https://github.com/user-attachments/assets/956ec2b1-bb0b-4adf-a7de-f44ac75f1606)

## Introduction

There are many libraries available that more or less perform these ubiquitous file-related operations. Checkpoint differentiates itself by focusing on an extremely simple API, and perhaps more importantly, its ability to work with directory hierarchies rather than just stuffing one standard save location with multiple unrelated files.

In order to work with the user's file system, Checkpoint depends on the [Lua File System](https://github.com/britzl/defold-lfs) library.

Each operating system has its own preferences for where applications should store data. Checkpoint prepends the following root save directories to any paths specified by the user:

| OS      | Path                                                     |
| ------- | -------------------------------------------------------- |
| Windows | C:\\Users\\\<user>\\AppData\\Roaming\\\<project_title>\\ |
| Linux   | /home/\<user>/.local/share/\<project_title>/             |

Checkpoint was only tested on the above platforms. Testing and contributions for other platforms are welcome and appreciated.

## Installation

Add Checkpoint as a dependency in your `game.project` file:  
https://github.com/klaleus/library-defold-checkpoint/archive/main.zip

Add Lua File System as a dependency in your `game.project` file:  
https://github.com/britzl/defold-lfs/archive/master.zip

Require `checkpoint.lua` in any script or module:  
`local m_checkpoint = require("checkpoint.checkpoint")`

## API

### checkpoint.exists(path)

Checks if a file exists.

This function is useful when deciding whether to read data from a file, or use default data if there's no file to read from.

**Parameters**

* `path`: Relative path from the root save directory.

**Returns**

* `true` or `false`.

**Example**

```lua
if m_checkpoint.exists("settings.json") then
    local data, err = m_checkpoint.read("settings.json")
    -- configure settings via `data`
else
    local success, err = m_checkpoint.write("settings.json", default_data)
    -- configure settings via `default_data`
end
```

---

### checkpoint.write(path, data)

Writes data to a file.

If the file doesn't exist, then it will be created, along with its entire directory hierarchy.

Note that Defold structures like `vmath.vector3()` are only compatible with binary file types.
If you'd like to write one of these structures to a file, then consider breaking it down into primitives.

**Parameters**

* `path`: Relative path from the root save directory.
* `data`: Data table.

**Returns**

* `true` on success.
* `false` and an error string on failure.

**Example**

```lua
local data =
{
    age = 27,
    favorite_season = "winter",

    -- The binary file format `.myformat` allows proper serialization and deserialization of `vmath.vector3()`.
    coordinates = vmath.vector3(4, 7, 4)
}

local success, err = m_checkpoint.write("profiles/klaleus/bio.myformat", data)
```

```lua
local data =
{
    age = 27,
    favorite_season = "winter",

    -- The `.json` format doesn't allow proper serialization and deserialization, so `vmath.vector3()` is broken down into primitives.
    coordinates_x = 4,
    coordinates_y = 7,
    coordinates_z = 4
}

local success, err = m_checkpoint.write("profiles/klaleus/bio.json", data)
```

---

### checkpoint.read(path)

Reads data from a file.

**Parameters**

* `path`: Relative path from the root save directory.

**Returns**

* Table on success.
* `false` and an error string on failure.

**Example**

```lua
local data, err = m_checkpoint.read("settings.json")
```
