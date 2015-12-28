//
//  PuzzleManager.m
//  PuzzleAnalyzer
//
//  Created by Wong Shing Chi Teddy on 23/12/15.
//  Copyright © 2015 Wong Shing Chi Teddy. All rights reserved.
//

#import "PuzzleManager.h"

struct PatternList
{
    struct OrbPattern *pattern;
    struct PatternList *next;
};

@implementation PuzzleManager

- (void)generateBoard:(int **)data width:(int)width height:(int)height
{
    
    struct Board *board = malloc(sizeof(struct Board));
    board->size.height = height;
    board->size.width = width;
    
    struct Orb **orbs = malloc(sizeof(struct Orb *)*width);
    for (int i=0; i<width; i++)
    {
        struct Orb *orb_column = malloc(sizeof(struct Orb)*height);
        orbs[i]=orb_column;
    }
    board->orbs = orbs;
    
    for (int x=0; x<width; x++)
    {
        int *data_column = data[x];
        struct Orb *orb_column = orbs[x];
        for (int y=0; y<height; y++)
        {
            orb_column[y].element = data_column[y];
            orb_column[y].origin.x = x;
            orb_column[y].origin.y = y;
        }
    }
    
    if (currentBoard)
    {
        [self freeBoard:currentBoard];
        currentBoard = NULL;
    }
    
    currentBoard = board;
}

- (void)freeBoard:(struct Board *)board
{
    struct Orb **orbs = board->orbs;
    for (int x=0; x<board->size.width; x++)
    {
        struct Orb *orb_column = orbs[x];
        free(orb_column);
    }
    free(orbs);
    free(board);
}

- (void)generatePatterns
{
    [self performSelectorInBackground:@selector(async_generatePatterns) withObject:nil];
}

struct PatternList *getEndOfPatternList(struct PatternList *patternlist)
{
    struct PatternList *traversal = patternlist;
    while (traversal->next) {
        traversal = traversal->next;
    }
    return traversal;
}


- (void)async_generatePatterns
{
    //iterate through all possible sizes and origin within the board, with the exception of 1,1 sizes
    //if the size contains two or more elements of the same type, create it as a pattern unless
    //unless it is not at its simplest form, as in there is wasted space.
    
    NSLog(@"Starting Generating Patterns {%i,%i}",currentBoard->size.width,currentBoard->size.height);
    
    struct PatternList *startinglist = NULL;
    struct PatternList *currentlist = NULL;
    for (int x = 0; x < currentBoard->size.width; x++)
    {
        for (int y = 0; y < currentBoard->size.height; y++)
        {
            //Create all possible patterns by increasing width and height based on X,Y origin
            struct OriginPoint origin;
            origin.x = x;
            origin.y = y;
            
            for (int areax = 1; areax <= currentBoard->size.width - x; areax++)
            {
                for (int areay = 1; areay <= currentBoard->size.height - y; areay++)
                {
                    if (areax != 1 && areay != 1)
                    {
                        struct AreaSize areasize;
                        areasize.width = areax;
                        areasize.height = areay;
                        
                        struct PatternList *patternlist = [self patternsForBoard:currentBoard origin:origin size:areasize];
                        if (startinglist == NULL || !startinglist)
                        {
                            startinglist = patternlist;
                            currentlist = patternlist;
                        }
                        else
                        {
                            getEndOfPatternList(currentlist)->next = patternlist; //add to end of current
                            currentlist = patternlist; //set to current
                        }
                    }
                }
            }
        }
    }
    
    NSLog(@"Done Generating Patterns {%i,%i}",currentBoard->size.width,currentBoard->size.height);
}

- (struct PatternList *)patternsForBoard:(struct Board *)board origin:(struct OriginPoint)origin size:(struct AreaSize)size
{
    struct PatternList *startinglist = malloc(sizeof(struct PatternList));
    startinglist->pattern = NULL;
    
    struct PatternList *currentlist = startinglist;
    
    uint patternAmount = 0;
    
    NSLog(@"-Start Pattern Search for [%i,%i] {%i,%i}",origin.x,origin.y,size.width,size.height);
    
    //Get orb types in area
    for (int i = 0; i < oUndefined; i++)
    {
        uint count = [self orbCountForElement:i board:board origin:origin size:size];
        if (count >= 2)
        {
            //For any orb type with >= 2 amt
            //Create pattern for said orb type
            struct OrbPattern *pattern = [self patternForElement:i board:board origin:origin size:size expectAmt:count];
            if (pattern)
            {
                if (currentlist->pattern == NULL)
                {
                    currentlist->pattern = pattern;
                    patternAmount++;
                }
                else
                {
                    struct PatternList *list = malloc(sizeof(struct PatternList));
                    list->pattern = pattern;
                    currentlist->next = list;
                    currentlist = list;
                    patternAmount++;
                }
            }
        }
    }
    NSLog(@"-End Pattern Amount:%i [%i,%i] {%i,%i}",patternAmount,origin.x,origin.y,size.width,size.height);
    
    return startinglist;
}

- (uint)orbCountForElement:(ElementType)element board:(struct Board *)board origin:(struct OriginPoint)origin size:(struct AreaSize)size
{
    uint count = 0;
    for (int x = origin.x; x < origin.x + size.width; x++)
    {
        struct Orb *orbcolumn = board->orbs[x];
        for (int y = origin.y; y < origin.y + size.height; y++)
        {
            //Get Orb
            if (orbcolumn[y].element == element)
                count++;
        }
    }
    return count;
}

- (struct OrbPattern *)patternForElement:(ElementType)element board:(struct Board *)board origin:(struct OriginPoint)origin size:(struct AreaSize)size expectAmt:(int)expect
{
    struct OrbPattern *pattern = malloc(sizeof(struct OrbPattern));
    pattern->elementType = element;
    
    struct Orb *orbs = malloc(sizeof(struct Orb) * expect);
    
    //WARNING REUSED CODE
    uint index = 0;
    bool onsides = false;
    for (int x = origin.x; x < origin.x + size.width; x++)
    {
        struct Orb *orbcolumn = board->orbs[x];
        for (int y = origin.y; y < origin.y + size.height; y++)
        {
            //Get Orb
            if (orbcolumn[y].element == element)
            {
                orbs[index].element = element;
                orbs[index].origin.x = x;
                orbs[index].origin.y = y;
                if (x == size.width-1 || y == size.height-1)
                {
                    onsides = true;
                }
                index++;
            }
        }
    }
    
    //Check if pattern utilizes the full area
    if (!onsides)
    {
        return nil;
    }
    pattern->orbs = orbs;
    pattern->orbCount = expect;
    pattern->size = size;
    pattern->origin = origin;
    
//    NSLog(@"--Pattern for [%@] count:%i",[self stringForElement:element],expect);
    
    for (int i=0; i<expect; i++)
    {
//        NSLog(@"[%@] [%i,%i]",[self stringForElement:element],pattern->orbs[i].origin.x,pattern->orbs[i].origin.y);
    }
    
//    NSLog(@"--");
    
    return pattern;
}

- (NSString *)stringForElement:(ElementType)element
{
    switch (element) {
        case oFire:
            return @"Fire";
            break;
        case oWater:
            return @"Water";
            break;
        case oGrass:
            return @"Grass";
            break;
        case oDark:
            return @"Dark";
            break;
        case oLight:
            return @"Light";
            break;
        case oHeart:
            return @"Heart";
            break;
        case oUndefined:
            return @"Undefined";
            break;
        default:
            break;
    }
}

@end
