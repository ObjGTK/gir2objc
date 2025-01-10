/*
 * SPDX-FileCopyrightText: 2015-2017 Tyler Burton <software@tylerburton.ca>
 * SPDX-FileCopyrightText: 2021-2022 Johannes Brakensiek <objfw@codingpastor.de>
 * SPDX-FileCopyrightText: 2015-2022 The ObjGTK authors, see AUTHORS file
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

#import <ObjFW/ObjFW.h>

/**
 * @brief Provides utility functions for ObjGTKGen.
 */
@interface OGTKUtil: OFObject

/**
 * @brief Returns the underscore_separated_string in camelCase.
 * @param input The underscore_separated_string
 * @return The underscore_separated_input_string in camelCase
 */
+ (OFString *)convertUSSToCamelCase:(OFString *)input;

/**
 * @brief Returns the underscore_separated_string in CapitalCase.
 * @param input The underscore_separated_string
 * @return The underscore_separated_input_string in CapitalCase
 */
+ (OFString *)convertUSSToCapCase:(OFString *)input;

/**
 * @brief Tests if a character is uppercase.
 * @param character The character
 * @return true if uppercase, false if not.
 */
+ (bool)isUppercase:(OFString *)character;

/**
 * @brief Converts GTK style type_new_with_param style functions into ObjGTK
 * initWithParam inits.
 * @param func The GTK style type_new_with_param style function definition
 * @param methodName Name of the first part of the selector. For convenience constructors it's
 * usually the name of the class/type.
 * @return The Objective-C initWithParam method definition.
 */
+ (OFString *)convertFunctionToInit:(OFString *)func
                    UsingMethodName:(OFString *)methodName;

/**
 * @brief Returns a super constructor call for the given type.
 * @param type Takes the ObjC type to construct from.
 * @param cCtor The constructor call as string.
 * @return The super constructor call in the format of ```[super
 * initWithGObject:gtk_class_new(params)]```
 */
+ (OFString *)getFunctionCallForConstructorOfType:(OFString *)type
                                  withConstructor:(OFString *)cCtor;

/**
 * @brief Get the base path where to for all config and resource files
 * @return The base path for all config and resource files to be loaded. "." if
 * none configured.
 */
+ (OFString *)dataDir;

/**
 * @brief Set the base path for all config and resource files to be loaded.
 * This method is going to set it to "." if it won't find expected dirs
 * at the location given.
 * @param dataDir The path as string
 */
+ (void)setDataDir:(OFString *)dataDir;

/**
 * @brief Returns the configuration value for the provided key.
 * @details The config value is extracted from the `global_conf.json` file as
 * found at the base path set via `dataDir`. This file is parsed once upon
 * startup.
 * @param key The key to get the configuration value for
 * @return The configuration value for the key provided
 * @see setDataDir
 */
+ (id)globalConfigValueFor:(OFString *)key;

/**
 * @brief Returns the configuration for the library specified.
 * @details The config value is extracted from the `library_conf.json` file as
 * found at the base path set via `dataDir`. This file is parsed once upon
 * startup.
 * @param libraryIdentifier The library to get the configurtion for, identified
 * by the string of the format `{namespaceName-versionNumber}`
 * @return The configuration value for the key provided
 * @see setDataDir
 */
+ (id)libraryConfigFor:(OFString *)libraryIdentifier;

@end
