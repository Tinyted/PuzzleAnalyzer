//
//  PuzzleManager.m
//  PuzzleAnalyzer
//
//  Created by Wong Shing Chi Teddy on 23/12/15.
//  Copyright © 2015 Wong Shing Chi Teddy. All rights reserved.
//

#import "PuzzleManager.h"

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

@end
