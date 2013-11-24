//
//  ResourcesHelper.h
//  Warp Vector
//
//  Created by Santiago Gonzalez on 9/12/13.
//  Copyright (c) 2013 MapleBit. All rights reserved.
//

#pragma once


#ifdef __APPLE__
#include "MacResourcePath.hpp"
#endif

#ifndef __APPLE_
////////////////////////////////////////////////////////////
/// \brief Return the path to the resource folder.
///
/// \return The path to the resource folder associate
/// with the main bundle or an empty string is there is no bundle.
///
////////////////////////////////////////////////////////////
#include <string>
std::string resourcePath(void);
#endif
