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

```lua
-- Checks if a file exists.
local exists = checkpoint.exists(path)

-- Writes data to a file.
local success, err = checkpoint.write(path, data)

-- Reads data from a file.
local data, err = checkpoint.read(path)
```

### checkpoint.exists(path)

Checks if a file exists.

This function is useful when deciding whether to read data from a file, or use default data if there's no file to read from.

**Parameters**

* `path` Relative path from the root save directory.

**Returns**

* `boolean`

**Example**

```lua
local path = "settings.json"
local default_data = { fullscreen = true }

if m_checkpoint.exists(path) then
    local data, err = m_checkpoint.read(path)
else
    local success, err = m_checkpoint.write(path, default_data)
end
```

---

### checkpoint.write(path, data)

Writes data to a file.

If the file doesn't exist, then it will be created, along with its entire directory hierarchy.

By default, data is serialized and deserialized in binary mode. This allows the user to write and read Defold structures like `vmath.vector3()`. However, if the specified `path` has a file extension of `.json`, then only data types supported by JSON are valid.

**Parameters**

* `path` Relative path from the root save directory.
* `data` Data table.

**Returns**

* `true` on success.
* `false` and an error `string` on failure.

**Example**

```lua
-- Since the `.myformat` file type is interpretted as a binary file,
-- serializing and deserializing `vmath.vector3()` is valid.
local path = "profiles/klaleus/data.myformat"
local data = { coordinates = vmath.vector3(7, 4, 7) }

local success, err = m_checkpoint.write(path, data)
```

```lua
-- Since the `.json` file type is interpretted as a text file,
-- serializing and deserializing `vmath.vector3()` is invalid.
-- Therefore, `coordinates` is broken down into primitives.
local path = "profiles/klaleus/data.json"
local data = { x = 7, y = 4, z = 7 }

local success, err = m_checkpoint.write(path, data)
```

---

### checkpoint.read(path)

Reads data from a file.

**Parameters**

* `path` Relative path from the root save directory.

**Returns**

* `table` on success.
* `false` and an error `string` on failure.

**Example**

```lua
local path = "settings.json"
local data, err = m_checkpoint.read(path)
```
