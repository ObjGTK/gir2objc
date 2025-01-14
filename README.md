gir2objc
==========

gir2objc is a utility that generates Objective-C language bindings for GNOME GLib/Gobject based libraries using GObject Introspection (GOI), which it does by parsing GIR files.

It belongs to the ObjGTK project, which is a fork of [CoreGTK](https://github.com/coregtk), originally by Tyler Burton, now for use with [ObjFW](https://objfw.nil.im/) by Jonathan Schleifer.

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

## Code base

The code base of ObjGTK should be compatible with the Objective C dialect of GCC ("Objective C 2.0") as introduced as of Mac OS X 10.5. So there should be no need to use clang.

Aim of the generator development is to generate library wrappers that map Objective-C memory management (MRC) to GObject memory management correctly. If this is achieved you should be able to use clang and ARC with any Objective-C app that builds upon these library wrappers.

Currently there are only untested, unstable preview releases of ObjGTK. Take care when using. API is going to change. See [milestones](https://codeberg.org/Letterus/objgtkgen/milestones) for the further release plan.

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
