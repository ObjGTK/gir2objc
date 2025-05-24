/*
 * SPDX-FileCopyrightText: 2015-2017 Tyler Burton <software@tylerburton.ca>
 * SPDX-FileCopyrightText: 2021-2022 Johannes Brakensiek <objfw@codingpastor.de>
 * SPDX-FileCopyrightText: 2015-2022 The ObjGTK authors, see AUTHORS file
 * SPDX-License-Identifier: GPL-3.0+
 */

#import "../GIR/GIRReturnValue.h"
#import <ObjFW/ObjFW.h>

@class OGTKClass;
@class OGTKLibrary;

/**
 * @brief Essential class that does the main work of mapping GObject/C data
 * types (called "Gobj") to ObjGTK/Objective-C classes (called "ObjC").
 * @details It aims to be implemented library agnostic to allow the generic
 * generation of wrappers for any GLib/GObject library that provides a GIR
 * introspection description file.
 */
@interface OGTKMapper: OFObject
{
	OFMutableDictionary OF_GENERIC(OFString *, OGTKLibrary *) * _girNameToLibraryMapping;

	OFMutableDictionary OF_GENERIC(OFString *, OGTKClass *) * _gobjTypeToClassMapping;
	OFMutableDictionary OF_GENERIC(OFString *, OGTKClass *) * _girNameToClassMapping;
	OFMutableDictionary OF_GENERIC(OFString *, OGTKClass *) * _objcTypeToClassMapping;
}

/**
 * @property girNameToLibraryMapping
 * @brief Dictionary that maps general API names that are specified in the .gir
 * file to library information objects of type OGTKLibrary.
 */
@property (readonly, nonatomic) OFMutableDictionary OF_GENERIC(OFString *, OGTKLibrary *) *
    girNameToLibraryMapping;

/**
 * @property gobjTypeToClassMapping
 * @brief Dictionary that maps Gobj type names to class information objects of
 * type OGTKClass.
 */
@property (readonly, nonatomic) OFMutableDictionary OF_GENERIC(OFString *, OGTKClass *) *
    gobjTypeToClassMapping;

/**
 * @property girNameToClassMapping
 * @brief Dictionary that maps general type names that are specified in the .gir
 * file to class information objects of type OGTKClass.
 */
@property (readonly, nonatomic) OFMutableDictionary OF_GENERIC(OFString *, OGTKClass *) *
    girNameToClassMapping;

/**
 * @property objcTypeToClassMapping
 * @brief Dictionary that maps ObjC type names to class information objects of
 * type OGTKClass.
 */
@property (readonly, nonatomic) OFMutableDictionary OF_GENERIC(OFString *, OGTKClass *) *
    objcTypeToClassMapping;

/**
 * @brief Singleton
 * @return instancetype One unique instance of OGTKMapper
 */
+ (instancetype)sharedMapper;

/**
 * @brief Adds a library to the mapping dictionary
 * @param libraryInfo The object describing the library
 */
- (void)addLibrary:(OGTKLibrary *)libraryInfo;

/**
 * @brief Removes a library from the mapping dictionary
 * @param libraryInfo The object describing the library
 */
- (void)removeLibrary:(OGTKLibrary *)libraryInfo;

/**
 * @brief Adds a class to the mapping dictionaries
 * @param classInfo The object describing the class
 */
- (void)addClass:(OGTKClass *)classInfo;

/**
 * @brief Removes a class from the mapping dictionaries
 * @param classInfo The object describing the class
 */
- (void)removeClass:(OGTKClass *)classInfo;

/**
 * @brief Iterates through all the class information objects retained
 * and tries to look up C types of parent classes from the other objects
 *
 * For this method to work all the class information objects need to be filled
 * with correct data.
 */
- (void)determineParentClassNames;

/**
 * @brief Iterates through all the class information objects retained in the
 * dict and looks for class dependencies
 * @details Dependencies are stored as Gobj types as well and should be
 * mapped/swapped using this class when actually written out to ObjC files.
 *
 * For this method to work all the class information objects need to be filled
 * with correct data.
 */
- (void)determineClassDependencies;

/**
 * @brief Iterates through all the dependencies of all the class information
 * objects retained in the dict
 * @details This will only work if ```determineDependencies``` is called before
 * @see -determineDependencies
 */
- (void)detectAndMarkCircularClassDependencies;

/**
 * @brief Returns if a given type string is listed as GObj type name
 * @return True if the given string is a listed GObj type name
 */
- (bool)hasGIRType:(OFString *)type;

/**
 * @brief Returns if a given type string is listed as Gobj C class name
 * @return True if the given string is a listed Gobj C class name
 */
- (bool)isGobjType:(OFString *)type;

/**
 * @brief Returns if a given type string is listed as ObjC class type
 * @return True if the given string is a listed ObjC class type
 */
- (bool)isObjcType:(OFString *)type;

/**
 * @brief Tries to swap Gobj data types with ObjC data types and vice versa.
 * Returns the input if it can't.
 * @details In addition to the class information provided via
 * ```addClass:```before this method will also swap basic data types like gchar*
 * and gboolean.
 *
 * Class types of basic (runtime) libraries which Gtk depends on, f.e. Glib, are
 * always mapped to OGObject because we do not want to wrap and use those but
 * use ObjFW classes instead.
 *
 * Pointers to pointer (**) currently are not swapped because conversion of
 * these types is not yet implemented by ```convertType:withName:toType```.
 * @see -convertType:withName:toType
 *
 */
- (OFString *)swapTypes:(OFString *)type;

/**
 * @brief Tests if the given type is swappable by ```swapTypes:```
 * @param type The Gobj or ObjC type name
 * @return True if the given type is swappable by ```swapTypes:```
 */
- (bool)isTypeSwappable:(OFString *)type;

/**
 * @brief      Alias for convertType:withName:toType:ownership: adding ownership =
 * 			   GIRReturnValueOwnershipUnknown as default paramter.
 *
 * @param      fromType  The from type
 * @param      name      The name
 * @param      toType    To type
 *
 * @return     Return value of the called method.
 */
- (OFString *)convertType:(OFString *)fromType withName:(OFString *)name toType:(OFString *)toType;

/**
 * @brief Provides the string holding the source code snipped to convert
 * ```fromType``` to ```toType``` holding ```name``` as variable name
 * @details This method is the corresponding part to ```swapTypes:```. While
 * that swaps type names this is meant to provide the code snipped string needed
 * to transfor one type to the other.
 * @param fromType The Gobj or ObjC type name to provide conversion code for.
 * @param name The name of the variable in the source code, defined by fromType.
 * @param toType The ObjC or Gobj type name which the returned code should
 * convert to.
 * @param ownership GLib Ownership type of the C value, considered for strings
 * @return The source code needed to convert ```fromType``` to
 * ```toType``` holding ```name``` as variable name
 *
 */
- (OFString *)convertType:(OFString *)fromType
                 withName:(OFString *)name
                   toType:(OFString *)toType
                ownership:(GIROwnershipTransferType)ownership;

/**
 * @brief Returns the cType (Gobj type) for a name following the gir file naming
 * convention
 * @details In some cases the gir format files do not provide cTypes (Gobj/Glib
 * type names). Then this method may be used to retrieve the correct cType for
 * gir class (name) definition.
 *
 * This only works if the necessary class information has been provided using
 * ```addClass:``` before.
 * @see -addClass:
 */
- (OFString *)getCTypeFromName:(OFString *)name;

/**
 * @brief Returns the class info object if found in the dictionary by the Gobj C
 * type name given
 * @param gobjTypeUnfiltered The Gobj type name to look for. It may contain pointer asterisks (*), which will be stripped
 */
- (OGTKClass *)classInfoByGobjType:(OFString *)gobjTypeUnfiltered;

/**
 * @brief Returns the class info object if found in the dictionary by the Gobj
 * type name (GIR name) given
 * @param girName The Gobj type name specified by the GObj type system and the Gir files to look for.
 */
- (OGTKClass *)classInfoByGIRName:(OFString *)girName;

/**
 * @brief Returns the library info object if found in the dictionary by the name
 * of the library/namespace given
 * @param libNamespace The name of the namespace/library to look for
 */
- (OGTKLibrary *)libraryInfoByNamespace:(OFString *)libNamespace;

/**
 * @brief      Returns the number of asterisk chars in given identifier
 *
 * @param      identifier  The identifier string
 *
 * @return     Number of asterisk chars
 */
- (size_t)numberOfAsterisksIn:(OFString *)identifier;

/**
 * @brief Return is ```type``` is known by the Gobj type dict
 *
 */
+ (bool)isGobjType:(OFString *)type;

/**
 * @brief Return is ```type``` is known by the ObjC type dict
 *
 */
+ (bool)isObjcType:(OFString *)type;

/**
 * @brief Tries to swap Gobj data types with ObjC data types and vice versa.
 * Returns the input if it can't. Singleton access shortcut.
 * @see -swapTypes:
 */
+ (OFString *)swapTypes:(OFString *)type;

/**
 * @brief Tests if the given type is swappable by ```swapTypes:``` Singleton
 * access shortcut.
 * @see -isTypeSwappable:
 */
+ (bool)isTypeSwappable:(OFString *)type;

/**
 * @brief Provides the string holding the source code snipped to convert
 * ```fromType``` to ```toType``` holding ```name``` as variable name. Singleton
 * access shortcut.
 * @see -convertType:withName:toType:
 */
+ (OFString *)convertType:(OFString *)fromType withName:(OFString *)name toType:(OFString *)toType;

/**
 * @brief Provides the string holding the source code snipped to convert
 * ```fromType``` to ```toType``` holding ```name``` as variable name. Singleton
 * access shortcut.
 * @see -convertType:withName:toType:ownership
 */
+ (OFString *)convertType:(OFString *)fromType
                 withName:(OFString *)name
                   toType:(OFString *)toType
                ownership:(GIROwnershipTransferType)ownership;

/**
 * @brief Returns the cType (Gobj type) for a name following the gir file naming
 * convention. Singleton access shortcut.
 * @details In some cases the gir format files do not provide cTypes (Gobj/Glib
 * type names). Then this method may be used to retrieve the correct cType for
 * gir class (name) definition.
 *
 * This only works if the necessary class information has been provided using
 * ```addClass:``` before.
 * @see -getCTypeFromName:
 */
+ (OFString *)getCTypeFromName:(OFString *)name;

/**
 * @brief Returns the class info object if found in the dictionary by the Gobj
 * type name given. Singleton access shortcut.
 * @param gobjType The Gobj type name to look for
 */
+ (OGTKClass *)classInfoByGobjType:(OFString *)gobjType;

/**
 * @brief Returns the library info object if found in the dictionary by the name
 * of the library/namespace given. Singleton access shortcut.
 * @param libNamespace The name of the namespace/library to look for
 */
+ (OGTKLibrary *)libraryInfoByNamespace:(OFString *)libNamespace;

@end
