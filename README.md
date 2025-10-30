gir2objc
==========

gir2objc is a utility that generates Objective-C language bindings for GNOME GLib/Gobject based libraries using GObject Introspection (GOI), which it does by parsing GIR files.

It is the heart of the ObjGTK project, which is a fork of [CoreGTK](https://github.com/coregtk), originally created by Tyler Burton, now in use with [ObjFW](https://objfw.nil.im/) by Jonathan Schleifer.

ObjGTK and [gir2objc](https://codeberg.org/ObjGTK/gir2objc) are based on [Codeberg](https://codeberg.org/ObjGTK/). You will need a Codeberg account to submit and respond to issues.

## Maturity

gir2objc is abandoned. It was a "tech preview" or a "proof of concept" whether GObject bindings could be done in Objective-C using ObjFW. It turns out: It can be done and it could be very delightful to use, but I'm missing time to accomplish it.

## Contributing

You're welcome to pick this project up, I am happy to transfer it to you. Or create a Codeberg account and submit a pull request. [Contact me](https://devbeejohn.de/contact.gmi) before submitting a bigger one. Agree to publishing under the terms of GPL 3.0.

Join Matrix room `#objfw:nil.im` at any time to discuss issues and questions.

## Features

- Objective-C API generation on a class level for any GObject based library that provides a proper GIR file
- generated API wraps GObject in-parameters and return types of methods using Objective-C wrapper classes and `gchar` types using `OFString`
- recursive generation for library dependencies
- writing out documentation for classes and methods
- error handling using ObjFW exceptions
- memory management for GObject based classes providing manual reference counting (MRC) on library level using toggle references on GObject side
- ARC (automatic reference counting) on application level is possible using clang
- generic way of signal binding thanks to contributors
- compatibility with gcc should be given currently (but providing only limited ObjC features of gcc, often called "Objective-C 2.0")
- unwanted library dependencies may be excluded via configuration
- unwanted (f.e. internal) classes may be excluded via configuration
- configuration for renaming libraries
- manual implementations of classes (or categories…) are added to the generated ones when placed in the `LibrarySourceAdditions` directory
- generation of build files for each generated library that makes use of the very portable autoconf and ObjFW buildsys

## Not-yet features, most wanted first (workaround in brackets)

- configuration for renaming methods
- configuration for renaming classes
- generic way of callback binding (you may use regular C functions)
- automatic subclassing (you may register types in C or use Vala for subclassing)
- API generation for GLib types that are not GObject-based/non-GObject records
- wrapping or conversion of out-parameters of methods
- conversion of C types that are not `gchar` or GObject-based (you may just use them "as is")
- ObjC implementation of [GObject type interfaces](https://docs.gtk.org/gobject/struct.TypeInterface.html), protocol translation layer
- ObjC implementation for container types like `GList`, `GSList`, `GHashTable` and `GArray`, `GPtrArray`, `GByteArray` using `OFArray` or `OFDictionary` f.e.

## Usage

You may run `gir2objc` as installed binary (f.e. within a flatpak app) or locally. it expects `Config`, `Resources` and `LibrarySourceAdditions` directories with the corresponding files to work with. It will look for these either in the configured data path (f.e. `/usr/share/gir2objc/`) or `.` if the configured path is empty. You may tweak the app configuration and behaviour using the `global_conf.json` and `library_conf.json` files.

Run it like so:

```
gir2objc </path/to/file.gir>
```

f.e.
```
gir2objc /usr/share/gir-1.0/Gtk-4.0.gir
```

This will generate the library definition for GTK4 into the output dir specified by the config file. The output will include all the library dependencies specified by `Gtk-4.0.gir`.

The generator is going to lookup these dependencies recursively at the path of the gir file specified as argument. You may exclude library and class dependencies of each library by modifying `global_conf.json` and `library_conf.json`.

## Dependencies and building

### Build Dependencies

- gcc or clang, make, autoconf
- [ObjFW](https://objfw.nil.im/)
- pkg-config

### Runtime dependencies

- [ObjFW](https://objfw.nil.im/)
- The [GIR files](https://gi.readthedocs.io/en/latest/) for the library to generate a wrapper for - and all of its depending GIR files. This will be enough for generation of the wrapper source files. You are going to need all library files (shared library, headers, pkg-config description) and the files of the dependending libraries required for your library at build time (only).
    - For GLib-2.0 using Debian/Ubuntu this is at least libgirepository1.0-dev including the GIR file for GIO. 

### Build generated library wrappers

- For building a generated library you need [OGObject](https://codeberg.org/ObjGTK/OGObject).

Build a generated library calling from its root dir:

```
./autogen.sh
./configure
make
```

Use `make install` for installing. For further options to configure build and installation see `./configure --help`

### GIR files

You may use the GIR files and libraries provided by your Linux distribution. F.e. for Debian Unstable and GTK 4 use `apt install libgtk-4-dev`.

If you don't use a rolling Linux distribution, the GIR packages and its library sets may be out of date and lack features required by this generator. It then may be more appropriate to use some more recent library releases. If you want to get the current libraries (read: daily builds of the GNOME SDK) you may use flatpak (see below).

As noted [by the GTK bindings for Rust project](https://github.com/gtk-rs/gir-files) it may be helpful to consult the [GIR format reference](https://gi.readthedocs.io/en/latest/annotations/giannotations.html) or the [XML schema](https://gitlab.gnome.org/GNOME/gobject-introspection/-/blob/main/docs/gir-1.2.rnc).

### Building

- `chmod +x autogen.sh && ./autogen.sh && ./configure && make`

#### Flatpak

```bash
# Add the GNOME Nightly repo
flatpak remote-add --if-not-exists gnome-nightly https://nightly.gnome.org/gnome-nightly.flatpakrepo

# Install SDK and LLVM extension
flatpak install org.gnome.Sdk//master -y --noninteractive
flatpak install org.freedesktop.Sdk.Extension.llvm17 -y --noninteractive

# Build binary and install it in its sandbox
flatpak-builder build-dir --force-clean org.codeberg.objgtk.gir2objc.yml --user --install

# Run the app: This will use the most current GIR files from the SDK and output ObjGTK4 to your local working directory:
flatpak run org.codeberg.ObjGTK.gir2objc /usr/share/gir-1.0/Gtk-4.0.gir
```

## Licensing

gir2objc is free software. Its source files Tyler Burton originally released under
GNU LGPL 2.1 or later. This licensing was kept for the files existing and for the directory LibrarySourceAdditions, which is meant to be part of the generated libraries and is NOT part of the generator.

In consent with Tyler Burton the generator itself is released under GNU GPL 3.0 or later.

Regarding GTK3 (and 4 or any other library wrapper) the generator is meant to generate wrapper source files which may be distributed under LGPL 2.1 or later.

## How it works

The generator does the following currently:

1. Using `XMLReader` it parses a [GIR file (.gir)](https://gi.readthedocs.io/en/latest/) into object instances of the GIR classes (see directory `src/GIR`) (source models)
2. `Gir2Objc` then maps the information of the GIR models into the models prefixed with `OGTK` (see directory `src/Generator`) (target models, "information objects"). Please note that these models still hold API/class informationen using C names and types as used by the Glib/GObject libraries. These models provide methods to transform their Glib ("c") data/names/types into Objective-C classes/names/types.
3. It does the same for further libraries iterating recursively through all the libraries specified as dependencies by the GIR file given.
4. When all library and class definitions are held in memory necessary to resolve class dependencies correctly using `OGTKMapper`, then `OGTKLibraryWriter` is called to first invoke `OGTKClassWriter`.
5. `OGTKClassWriter` is going to write out the Objective-C class definitions (header and source files). It does so by resolving GObject types to Objective-C/OGTK types (swapping them) using the class mappings and definitions hold in multiple `OFDictionary`s by `OGTKMapper`. It wraps GObject C functions calls with Objective-C method calls/message sends.
6. When all class files are written, additional source files, written manually, that may be provided through a directory within the directory named `LibrarySourceAdditions` are added to the `Output` directory (the generated library). Please note the classes located in the directory named `LibrarySourceAdditions` are **not** part of the generator itself. You may add your own code by creating new directories which naming convention needs to meet that of the corresponding gir file.

You will find the main business logic preparing data structures in `Gir2Objc.m` and `Generator/OGTKMapper.m` as `Gir2Objc` calls `OGTKMapper` for multiple loops through all the parsed (Gobj) class/API information to complete dependency information (naming of parent classes) and the dependency graph (parent classes, depending classes). This is necessary to correctly insert `#import` and `@class` statements when generating the ObjC class definitions without getting stuck in a circular dependency loop.

For the actual generation and composition of the source files see `Generator/OGTKLibraryWriter.m` and `Generator/OGTKClassWriter.m`.
