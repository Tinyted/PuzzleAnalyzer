//
//  PuzzleManager.h
//  PuzzleAnalyzer
//
//  Created by Wong Shing Chi Teddy on 23/12/15.
//  Copyright © 2015 Wong Shing Chi Teddy. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum
{
    oFire,
    oWater,
    oGrass,
    oLight,
    oDark,
    oHeart,
    oUndefined
} ElementType;

struct AreaSize
{
    int width;
    int height;
};

struct OriginPoint
{
    int x;
    int y;
};

struct Orb
{
    struct OriginPoint origin;
    ElementType element;
};

/*
    Current code has it so X,Y starts at bottom left
 */
struct Board
{
    struct Orb **orbs; //
    struct AreaSize size;
};

struct OrbPattern
{
    struct Orb *orbs;
    ElementType elementType;
    uint orbCount;
    struct AreaSize size;
    struct OriginPoint origin;
};

struct ComplicatedOrbPattern
{//Use first pattern's origin and size
    struct OrbPattern *patterns;
    uint patternAmt;
};

@interface PuzzleManager : NSObject
{
    struct Board *currentBoard;
}


- (void)generateBoard:(int **)data width:(int)width height:(int)height;
- (void)generatePatterns; //Will perform on separate thread

@end
