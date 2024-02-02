
/***************************************************************************
 *
 *                         INFORMIX SOFTWARE, INC.
 *
 *                            PROPRIETARY DATA
 *
 *      THIS DOCUMENT CONTAINS TRADE SECRET DATA WHICH IS THE PROPERTY OF
 *      INFORMIX SOFTWARE, INC.  THIS DOCUMENT IS SUBMITTED TO RECIPIENT IN
 *      CONFIDENCE.  INFORMATION CONTAINED HEREIN MAY NOT BE USED, COPIED OR
 *      DISCLOSED IN WHOLE OR IN PART EXCEPT AS PERMITTED BY WRITTEN AGREEMENT
 *      SIGNED BY AN OFFICER OF INFORMIX SOFTWARE, INC.
 *
 *      THIS MATERIAL IS ALSO COPYRIGHTED AS AN UNPUBLISHED WORK UNDER
 *      SECTIONS 104 AND 408 OF TITLE 17 OF THE UNITED STATES CODE.
 *      UNAUTHORIZED USE, COPYING OR OTHER REPRODUCTION IS PROHIBITED BY LAW.
 *
 *  Title:      dynarr.h
 *  Description:
 *              Declarations of 4GL Dynamic array structure
 *
 *              These declarations are for the benefit of C compilers and
 *              the functions and structures declared are not intended for
 *              direct use by C programmers.
 *
 ***************************************************************************
 */

#ifndef DYNARR_H
#define DYNARR_H


struct FGLArray {
    int2 numExtents;      
    int4 extentValues[3];
    int2 elemType;      
    void *startPtr;   
    int2 nodeSize[3];    
    int2 offset[3];
    int4 numNodes[3];
    int2 elemSize; 
};

#endif /* DYNARR_H */

