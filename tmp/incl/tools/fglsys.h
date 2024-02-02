/*
 *   Licensed Materials - Property of IBM
 *
 *   "Restricted Materials of IBM"
 *
 *   IBM Informix 4GL
 *   Copyright IBM Corporation 2008.
 */
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
 *  Title:       fglsys.h
 *  Description: Declarations of 4GL internal library functions
 *
 *      These declarations are for the benefit of C compilers and most
 *      of these functions are not intended for direct use by C
 *      programmers.  The exceptions are the stack manipulation
 *      functions used by C code functions interfacing with I4GL.
 *
 ***************************************************************************
 */

#ifndef FGLSYS_H
#define FGLSYS_H

#ifndef TYPEDEF_FORM
#define TYPEDEF_FORM
typedef struct frmdesc _FORM;
#endif /* TYPEDEF_FORM */

#include <stdio.h>
#include "datetime.h"
#include "decimal.h"
#include "int8.h"
#include "fglrep.h"
#include "locator.h"
#include "sqlda.h"
#include "sqlfm.h"
#include "dynarr.h"

/* Old symbol mapping to new symbols */
#ifndef NO_RECOMPILE
#define c_rp                 ibm_lib4gl_currentReport
#endif /* NO_RECOMPILE */

/* Old function Mapping to New Functions */
#define ixrelhwm()                         ibm_lib4gl_releaseTssAndHwmStack()
#define doretalloc(n)                      ibm_lib4gl_allocSpaceForStrInTss(n)
#define ixrsthwm()                         ibm_lib4gl_relUnwantedTssEntries()
#define ixpophwm()                         ibm_lib4gl_restoreHwmState()
#define ixpshhwm(s)                        ibm_lib4gl_recordTssAndHwmState(s)
#define _zeroloc(l)                        ibm_lib4gl_zeroFilAndSaveLocator(l)
#define _locate(u, x, y, z)                ibm_lib4gl_locateBlob(u, x, y, z)
#define _freeloc(x, y)                     ibm_lib4gl_freeBlobLocator(x, y)
#define _autofree(n)                       ibm_lib4gl_autoFreeBlobLocators(n)
#define fgl_elog(x, y, z)                  ibm_lib4gl_fglLogError(x, y, z)
#define _ffexit()                          ibm_lib4gl_ExitFormMode()
#define fgl_fatal(x, y, z)                 ibm_lib4gl_fglFatalError(x, y, z)
#define fgl_nofatal(x, y, z)               ibm_lib4gl_fglNotFatalError(x, y, z)
#define fgl_warn()                         ibm_lib4gl_returnFglWarningNo()
#define b_chk(w, x, y, z)                  ibm_lib4gl_arrayBoundCheck(w, x, y, z)
#define wwleftmargin(x)                    ibm_lib4gl_printTmpLeftMargin(x)
#define topmargin()                        ibm_lib4gl_printTopMargin()
#define _bottommargin()                    ibm_lib4gl_printBottomMargin()
#define arnewline(x)                       ibm_lib4gl_printNewLine(x)
#define outtopofpg()                       ibm_lib4gl_printUsrSpecTopOfPage()
#define maybelmarg()                       ibm_lib4gl_printLeftMarginIfNeed()
#define _popgoto(x)                        ibm_lib4gl_printPopGoto(x)
#define _pshgoto(x)                        ibm_lib4gl_printPushGoto(x)
#define _gotoinit()                        ibm_lib4gl_printInitGotoIndex()
#define _efpipemode(x)                     ibm_lib4gl_ifPipeMode(x)
#define openoutput(x, y, z)                ibm_lib4gl_openOutFileOrPipe(x, y, z)
#define closeoutput()                      ibm_lib4gl_closeOutFileOrPipe()
#define printlist(x, y)                    ibm_lib4gl_printListToFile(x, y)
#define nprintlist(x, y, z)                ibm_lib4gl_printNListToFile(x, y, z)
#define _initaggs(x)                       ibm_lib4gl_reportInitAggregates(x)
#define _evalagg(x)                        ibm_lib4gl_reportEvalAggregates(x)
#define _pushagg(x)                        ibm_lib4gl_reportPushAggregates(x)
#define _zerogaggs(x, y)                   ibm_lib4gl_reportSetGAggreToZero(x, y)
#define _setbreak(x, y)                    ibm_lib4gl_reportSetBreak(x, y)
#define _dopause(x, y)                     ibm_lib4gl_reportDoPause(x, y)
#define fgl_init(x, y)                     ibm_lib4gl_fglInitialize(x, y)
#define fgl_siginit()                      ibm_lib4gl_initSignalHandeler()
#define pushnull()                         ibm_lib4gl_pushNull()
#define pushint(x)                         ibm_lib4gl_pushMInt(x)
#define pushshort(x)                       ibm_lib4gl_pushInt2(x)
#define pushlong(x)                        ibm_lib4gl_pushInt4(x)
#define pushdate(x)                        ibm_lib4gl_pushDate(x)
#define pushmoney(x, y)                    ibm_lib4gl_pushMoney(x, y)
#define pushflo(x)                         ibm_lib4gl_pushFloat(x)
#define pushdub(x)                         ibm_lib4gl_pushDouble(x)
#define pushstrdec(x)                      ibm_lib4gl_pushStrDecimal(x)
#define pushlvqs(x, y, z)                  ibm_lib4gl_pushLValueQuotedStr(x, y, z)
#define pushquote(x, y)                    ibm_lib4gl_pushQuotedStr(x, y)
#define pushvchar(x, y)                    ibm_lib4gl_pushVarChar(x, y)
#define pushdec(x, y)                      ibm_lib4gl_pushDecimal(x, y)
#define pushdtstr(x, y)                    ibm_lib4gl_pushStrDate(x, y)
#define pushivstr(x, y)                    ibm_lib4gl_pushStrInterval(x, y)
#define pushlocator(x)                     ibm_lib4gl_pushBlobLocator(x)
#define pushdtime(x)                       ibm_lib4gl_pushDateTime(x)
#define pushinv(x)                         ibm_lib4gl_pushInterval(x)
#define _pshtoday()                        ibm_lib4gl_internalPshTodaysDt()
#define _pshtime()                         ibm_lib4gl_internalPshTime()
#define _pshdate()                         ibm_lib4gl_internalPshDate()
#define popint(x)                          ibm_lib4gl_popMInt(x)
#define popbool(x)                         ibm_lib4gl_popBoolean(x)
#define popshort(x)                        ibm_lib4gl_popInt2(x)
#define poplong(x)                         ibm_lib4gl_popInt4(x)
#define popdate(x)                         ibm_lib4gl_popDate(x)
#define popdub(x)                          ibm_lib4gl_popDouble(x)
#define popflo(x)                          ibm_lib4gl_popFloat(x)
#define popdec(x)                          ibm_lib4gl_popDecimal(x)
#define popdecvar(x, y)                    ibm_lib4gl_popDecimalVar(x, y)
#define popmon(x)                          ibm_lib4gl_popMoney(x)
#define popmonvar(x, y)                    ibm_lib4gl_popMoneyVar(x, y)
#define popstring(x, y)                    ibm_lib4gl_popString(x, y)
#define popquote(x, y)                     ibm_lib4gl_popQuotedStr(x, y)
#define popvchar(x, y)                     ibm_lib4gl_popVarChar(x, y)
#define poplocator(x)                      ibm_lib4gl_popBlobLocator(x)
#define popdtime(x, y)                     ibm_lib4gl_popDateTime(x, y)
#define popinv(x, y)                       ibm_lib4gl_popInterval(x, y)
#define popsubstr(x, y, z, a, b)           ibm_lib4gl_popSubString(x, y, z, a, b)
#define popdummy()                         ibm_lib4gl_popDummy()
#define _dounits()                         ibm_lib4gl_doOperUnits()
#define _doadd()                           ibm_lib4gl_doOperAdd()
#define _domult()                          ibm_lib4gl_doOperMultiply()
#define _dodiv()                           ibm_lib4gl_doOperDivide()
#define _doneg()                           ibm_lib4gl_doOperNegitive()
#define _dosub()                           ibm_lib4gl_doOperSubtract()
#define _doopeq()                          ibm_lib4gl_doOperEqualto()
#define _doeqnopop()                       ibm_lib4gl_doOperEqualtoNoPop()
#define _doopne()                          ibm_lib4gl_doOperNotEqualto()
#define _doopge()                          ibm_lib4gl_doOperGreaterOrEqlto()
#define _doopgt()                          ibm_lib4gl_doOperGreaterThan()
#define _doople()                          ibm_lib4gl_doOperLessOrEqlto()
#define _dooplt()                          ibm_lib4gl_doOperLessThan()
#define _dolike(x)                         ibm_lib4gl_doOperLike(x)
#define _domatches(x)                      ibm_lib4gl_doOperMatches(x)
#define skipnlines(x)                      ibm_lib4gl_skipNLines(x)
#define _dousing(x)                        ibm_lib4gl_doOperUsing(x)
#define _doclip()                          ibm_lib4gl_doOperClip()
#define _dosubstrg(x)                      ibm_lib4gl_doOperSubString(x)
#define _doletsub(x, y)                    ibm_lib4gl_doOperLeftSubString(x, y)
#define _dospace()                         ibm_lib4gl_doOperSpace()
#define _dormargin()                       ibm_lib4gl_doRightMargin()
#define _docurrent()                       ibm_lib4gl_doCurrent()
#define _doextend()                        ibm_lib4gl_doExtend()
#define _doandop()                         ibm_lib4gl_doOperAnd()
#define _doorop()                          ibm_lib4gl_doOperOr()
#define _donotop()                         ibm_lib4gl_doOperNot()
#define ld_int(x, y)                       ibm_lib4gl_loadMint(x, y)
#define ld_short(x, y)                     ibm_lib4gl_loadInt2(x, y)
#define ld_long(x, y)                      ibm_lib4gl_loadInt4(x, y)
#define ibm_lib4gl_loadint4(x, y)          ibm_lib4gl_loadInt4(x, y)
#define ld_date(x, y)                      ibm_lib4gl_loadDate(x, y)
#define ld_dub(x, y)                       ibm_lib4gl_loadDouble(x, y)
#define ld_flo(x, y)                       ibm_lib4gl_loadFloat(x, y)
#define ld_dec(x, y)                       ibm_lib4gl_loadDecimal(x, y)
#define ld_quote(x, y, z)                  ibm_lib4gl_loadQuotedString(x, y, z)
#define ld_vchar(x, y, z)                  ibm_lib4gl_loadVarChar(x, y, z)
#define ld_locator(x, y)                   ibm_lib4gl_loadBlobLocator(x, y)
#define ld_dtime(x, y, z)                  ibm_lib4gl_loadDateTime(x, y, z)
#define ld_inv(x, y, z)                    ibm_lib4gl_loadInterval(x, y, z)
#define ld_substr(x, y, z, a, b)           ibm_lib4gl_loadSubString(x, y, z, a, b)
#define mark_stack()                       ibm_lib4gl_markStack()
#define rest_stack(x)                      ibm_lib4gl_resetStack(x)
#define retint(x)                          ibm_lib4gl_returnMInt(x)
#define retshort(x)                        ibm_lib4gl_returnInt2(x)
#define retlong(x)                         ibm_lib4gl_returnInt4(x)
#define retdate(x)                         ibm_lib4gl_returnDate(x)
#define retflo(x)                          ibm_lib4gl_returnFloat(x)
#define retdub(x)                          ibm_lib4gl_returnDouble(x)
#define retquote(x)                        ibm_lib4gl_returnQuotedStr(x)
#define retstring(x)                       ibm_lib4gl_returnString(x)
#define retdec(x)                          ibm_lib4gl_returnDecimal(x)
#define retdtime(x)                        ibm_lib4gl_returnDateTime(x)
#define retinv(x)                          ibm_lib4gl_returnInterval(x)
#define retvchar(x)                        ibm_lib4gl_returnVarChar(x)
#define isnull()                           ibm_lib4gl_isNull()
#define snullint(x)                        ibm_lib4gl_setNullMInt(x)
#define snullshort(x)                      ibm_lib4gl_setNullInt2(x)
#define snulllong(x)                       ibm_lib4gl_setNullInt4(x)
#define snulldub(x)                        ibm_lib4gl_setNullDouble(x)
#define snullflo(x)                        ibm_lib4gl_setNullFloat(x)
#define snulldec(x)                        ibm_lib4gl_setNullDecimal(x)
#define snullquote(x, y)                   ibm_lib4gl_setNullQuotedStr(x, y)
#define snullvchar(x)                      ibm_lib4gl_setNullVarChar(x)
#define snulllocator(x)                    ibm_lib4gl_setNullBlobLocator(x)
#define snulldtime(x)                      ibm_lib4gl_setNullDateTime(x)
#define snullinv(x)                        ibm_lib4gl_setNullInterval(x)
#define _doexpo()                          ibm_lib4gl_doOperExponent()
#define _domod()                           ibm_lib4gl_doOperModulo()
#define _doord()                           ibm_lib4gl_doOperORD()
#define _doconcat(x, y)                    ibm_lib4gl_doConcat(x, y)
#define dovalidate(x)                      ibm_lib4gl_doOperValidate(x)
#define _doday()                           ibm_lib4gl_doOperDay()
#define _domonth()                         ibm_lib4gl_doOperMonth()
#define _doyear()                          ibm_lib4gl_doOperYear()
#define _dotime()                          ibm_lib4gl_doOperTime()
#define _dodate()                          ibm_lib4gl_doOperDate()
#define _doweekday()                       ibm_lib4gl_doOperWeekDay()
#define _domdy()                           ibm_lib4gl_doOperMDY()
#define _popstack(x)                       ibm_lib4gl_popStack(x)
#define doruncmd(x, y, z)                  ibm_lib4gl_doRunCommand(x, y, z)
#define _docatop()                         ibm_lib4gl_doOperCat()
#define _efrunmode(x)                      ibm_lib4gl_setRunMode(x)
#define pushmodname(x)                     ibm_lib4gl_pushModuleName(x)
#define popmodname()                       ibm_lib4gl_popModuleName()
#define retmoney(x)                        ibm_lib4gl_returnMoney(x)
#define retmon(x)                          ibm_lib4gl_returnMon(x)
#define _openprt()                         ibm_lib4gl_printFileOpen()
#define _efc_init(x, y, z)                 ibm_efm_constructInit(x, y, z)
#define _efconstruct(a, b, x, y, z)        ibm_efm_formBoolExprPartOfQuerC(a, b, x, y, z)
#define _efconclean(a,b,x,y,z)             ibm_efm_exitConstruct(a,b,x,y,z)
#define _efclear(x)                        ibm_efm_clearFieldsInDispForm(x)
#define _efscroll(x, y, z)                 ibm_efm_scrollData(x, y, z)
#define _efdaclean()                       ibm_efm_exitDisplay()
#define _efadsply(a, b, x, y,z)            ibm_efm_displayAtC(a, b, x, y,z)
#define _nfardsply(a, b, c, d, w, x, y, z) ibm_efm_displayArrayExtendAttr(a, b, c, d, w, x, y, z)
#define _fardsply(a, b, c, d, x, y, z)     ibm_efm_displayArrayC(a, b, c, d, x, y, z)
#define _efdsply(a, b, x, y, z)            ibm_efm_displayToFormFieldsC(a, b, x, y, z)
#define _eflndsply(x, y)                   ibm_efm_displayToLineModeC(x, y)
#define _efcfrm()                          ibm_efm_clearForm()
#define _efdfrm(x, y)                      ibm_efm_displayForm(x, y)
#define _efcscrn()                         ibm_efm_clearScreen()
#define _efopen(x, y)                      ibm_efm_openForm(x, y)
#define _efclose(x)                        ibm_efm_closeForm(x)
#define _farinput(a, b, c, d, e, f, g)     ibm_efm_inputArrayC(a, b, c, d, e, f, g)
#define _efoptwrap(x)                      ibm_efm_optionInputWrap(x)
#define _efipclean(x, y, z)                ibm_efm_cleanupAfterInput(x, y, z)
#define _rstr_icb(x)                       ibm_efm_restoreIcb(x)
#define _finput(a, b, c, d, e)             ibm_efm_inputOrInputByNameC(a, b, c, d, e)
#define _efhlpkey(x)                       ibm_efm_setHelpKey(x)
#define _efinskey(x)                       ibm_efm_setInsertKey(x)
#define _efdelkey(x)                       ibm_efm_setDeleteKey(x)
#define _efnxtkey(x)                       ibm_efm_setNextPageKey(x)
#define _efprvkey(x)                       ibm_efm_setPreviousPageKey(x)
#define _efacckey(x)                       ibm_efm_setAcceptKey(x)
#define _efinpattr(x)                      ibm_efm_setInputAttribute(x)
#define _efdsplyattr(x)                    ibm_efm_setDisplayAttribute(x)
#define _ffunload(a, b, c, d, e)           ibm_efm_unloadInFormMode(a, b, c, d, e)
#define fgl_unload(a, b, c, d, e)          ibm_efm_fglUnload(a, b, c, d, e)
#define _efmsg(x, y, z)                    ibm_efm_printToMsgLineC(x, y, z)
#define _efemsg(x, y, z)                   ibm_efm_printMsgToErrWindowC(x, y, z)
#define _efprmpt(a, b, c, d, e)            ibm_efm_promptC(a, b, c, d, e)
#define _efidefer()                        ibm_efm_deferInterrupt()
#define _efqdefer()                        ibm_efm_deferQuit()
#define _efemode()                         ibm_efm_exitScreenMode()
#define _efcmtline(x)                      ibm_efm_setCommentLine(x)
#define _efmsgline(x)                      ibm_efm_setMsgLine(x)
#define _effrmline(x)                      ibm_efm_setFormLine(x)
#define _eferrline(x)                      ibm_efm_setErrorLine(x)
#define _efprline(x)                       ibm_efm_setPromptLine(x)
#define ibm_lib4gl_getelementaddressc(x, y, z, a, b) ibm_lib4gl_getElementAddressC(x, y, z, a, b)

extern void  _doascii(void);
extern void  _docolumn(void);
extern mint  _efaddhs(mint mno, mint hide, int1 *opt);
extern void  _efhlpfile(int1 *name);
extern mint  _efdohs(mint mno, _EFMENU *mnp);
extern void  _efmclean(_EFwindow *savwin);
extern mint  _efmenget(_EFMENU *x, mint *y);
extern mint  _efmenhide(_EFMENU *sm, int1 *name);
extern void  _efmeninit(_EFMENU *sm);
extern void  _efmennext(_EFMENU *sm, int1 **name);
extern mint  _efmenshow(_EFMENU *sm, int1 *name);
extern mint  _efsetmenl(mint menuline);
extern void  _fmenput(_EFMENU *x, mint val, _EFwindow **savwin);
extern void  _pghdrflush(int1 **phbuff, unsigned *phix, FILE *fp);
extern void  _pghdrfree(int1 **phbuff, unsigned *phsz, unsigned *phix);

extern mint  ibm_efm_clearForm(void);
extern mint  ibm_efm_clearFieldsInDispForm(_EFFIELD fldlst[]);
extern void  ibm_efm_clearWindow(_EFwindow *);
extern mint  ibm_efm_closeForm(_FORM **frmptr);
extern void  ibm_efm_closeWindow(_EFwindow **window);
extern mint  ibm_efm_clearScreen(void);
extern void  ibm_efm_cleanupAfterInput(_EFICB *icb, _EFFIELD *fldlist,
                                       mint colcnt);
extern mint  ibm_efm_constructInit(mint colcnt, _EFFIELD fldlst[], _EFICB *icb);
extern mint  ibm_efm_displayToLineModeC(mint cnt, struct sqlvar_struct *bindlst,
                                        mint linefdok);
extern mint  ibm_efm_displayAtC(mint cnt, struct sqlvar_struct *bindlst,
                                mint row, mint col, int4 attr);
extern mint  ibm_efm_displayForm(_FORM *form, int4 attr);
extern mint  ibm_efm_displayToFormFieldsC(mint bcnt,
                                           struct sqlvar_struct *bindlst,
                                           _EFFIELD fldlst[], int4 stmt_attr,
                                           mint stmt_type);
extern mint  ibm_efm_displayArrayExtendAttr(mint rowsize, mint incnt,
                                            struct sqlvar_struct *bindlst,
                                            _EFFIELD fldlst[], mint onkeys[],
                                            int4 attr, mint extend_attr,
                                            _EFARCB *arcb);
extern mint  ibm_efm_displayArrayC(mint rowsize, mint incnt,
                                  struct sqlvar_struct *bindlst,
                                  _EFFIELD fldlst[], mint onkeys[],
                                  int4 attr, _EFARCB *arcb);
extern void  ibm_efm_deferInterrupt(void);
extern void  ibm_efm_deferQuit(void);
extern mint  ibm_efm_exitConstruct(mint colcnt, struct sqlvar_struct *scollist,
                                   struct sqlvar_struct *outbind,
                                   _EFFIELD fldlst[], _EFICB *icb);
extern void  ibm_efm_exitDisplay(void);
extern void  ibm_efm_exitScreenMode(void);
extern void  ibm_efm_formBoolExprPartOfQuerC(mint colcnt,
                                             struct sqlvar_struct *scollist,
                                             struct sqlvar_struct *outbind,
                                             _EFFIELD fldlst[], _EFICB *icb);
extern void  ibm_efm_fglUnload(int1 *filename, int1 *delimiter, int1 **sqltxt,
                                mint numbind, struct sqlvar_struct *sqibind);
extern mint  ibm_efm_getFieldBuf(_EFFIELD *fldnames, _EFICB *icb);
extern mint  ibm_efm_isInField(int1 *userfld);
extern void  ibm_efm_inputOrInputByNameC(mint cnt,
                                         struct sqlvar_struct *bindlst,
                                         _EFFIELD fldlst[], mint nodefault,
                                         _EFICB *icb);
extern void  ibm_efm_inputArrayC(mint rowcnt, mint rowsize, mint bcnt,
                                 struct sqlvar_struct *bindlst,
                                 _EFFIELD *fldlst, mint nodefault, _EFICB *icb);
extern void  ibm_efm_loadInFormMode(int1 *filename, int1 *delimiter,
                                    int1 *insert_stmt);
extern void  ibm_efm_makeWindowCurrrent(_EFwindow *);
extern mint  ibm_efm_openForm(_FORM **frmptr, int1 *formname);
extern void  ibm_efm_openWindow( _EFwindow **window, int1 *formname, mint row,
                                 mint column , mint rows, mint columns,
                                 mint bordered, mint messopt, mint cmtopt,
                                 mint prmptopt, mint formopt, mint menuopt,
                                 mint color);
extern void  ibm_efm_optionInputWrap(mint i);
extern void  ibm_efm_printMsgToErrWindowC(mint cnt,
                                          struct sqlvar_struct *bindlst,
                                          int4 attr);
extern void  ibm_efm_printToMsgLineC(mint cnt, struct sqlvar_struct *bindlst,
                                     int4 attr);
extern void  ibm_efm_promptC(mint incnt, struct sqlvar_struct *bindlst,
                             mint hasinvar, struct sqlvar_struct *outbind,
                             _EFICB *icb);
extern void  ibm_efm_restoreIcb(_EFICB *_sqicb);
extern void  ibm_efm_setMsgLine(mint i);
extern void  ibm_efm_setNextPageKey(mint c);
extern void  ibm_efm_setCommentLine(mint i);
extern void  ibm_efm_setDeleteKey(mint c);
extern void  ibm_efm_setDisplayAttribute(int4 c);
extern void  ibm_efm_setErrorLine(mint i);
extern void  ibm_efm_setFormLine(mint i);
extern void  ibm_efm_setHelpKey(mint c);
extern void  ibm_efm_setInputAttribute(int4 c);
extern void  ibm_efm_setInsertKey(mint c);
extern void  ibm_efm_setPromptLine(mint i);
extern void  ibm_efm_setPreviousPageKey(mint c);
extern mint  ibm_efm_scrollData(_EFFIELD fldlst[], mint dir, mint inc);
extern void  ibm_efm_setAcceptKey(mint c);
extern void  ibm_efm_setcurrline0(mint rowsize, struct sqlvar_struct *bindlst,
                                  _EFFIELD *fldlst, _EFICB *icb, _EFARCB *arcb);
extern void  ibm_efm_unloadInFormMode(int1 *filename, int1 *delimiter,
                                      int1 *slct_stmt, mint numbind,
                                      struct sqlvar_struct *sqibind);

extern mint  ibm_lib4gl_autoFreeBlobLocators(mint nlocs);
extern mint  ibm_lib4gl_arrayBoundCheck(int1 *ibminfxprogname, mint lineno,
                                        mint elemindex, mint limit);
extern void  ibm_lib4gl_allocSpaceForStrInTss(mint n);
extern void  ibm_lib4gl_allocDynArrC(int4,  struct FGLArray *, int4,
                                     int4, int4);
extern void  ibm_lib4gl_allocateDA(int4, int4, int4, int4);
extern void  ibm_lib4gl_closeOutFileOrPipe(void);
extern void  ibm_lib4gl_Connect(void);
extern void  ibm_lib4gl_deallocDynArrC(int4, struct FGLArray *);
extern void  ibm_lib4gl_deallocateDA(int4);
extern void  ibm_lib4gl_doOperAdd(void);
extern void  ibm_lib4gl_doOperAnd(void);
extern void  ibm_lib4gl_doOperClip(void);
extern void  ibm_lib4gl_doConcat(mint nelems, mint substrflg);
extern void  ibm_lib4gl_doOperCat(void);
extern void  ibm_lib4gl_doCurrent(void);
extern void  ibm_lib4gl_doOperDate(void);
extern void  ibm_lib4gl_doOperDay(void);
extern void  ibm_lib4gl_doOperDivide(void);
extern void  ibm_lib4gl_doOperEqualtoNoPop(void);
extern void  ibm_lib4gl_doOperExponent(void);
extern void  ibm_lib4gl_doExtend(void);
extern void  ibm_lib4gl_doOperLeftSubString(mint n, mint srccnt);
extern void  ibm_lib4gl_doOperLike(mint esc);
extern void  ibm_lib4gl_doOperMatches(mint esc);
extern void  ibm_lib4gl_doOperMDY(void);
extern void  ibm_lib4gl_doOperModulo(void);
extern void  ibm_lib4gl_doOperMonth(void);
extern void  ibm_lib4gl_doOperMultiply(void);
extern void  ibm_lib4gl_doOperNegitive(void);
extern void  ibm_lib4gl_doOperNot(void);
extern void  ibm_lib4gl_doOperEqualto(void);
extern void  ibm_lib4gl_doOperGreaterOrEqlto(void);
extern void  ibm_lib4gl_doOperGreaterThan(void);
extern void  ibm_lib4gl_doOperLessOrEqlto(void);
extern void  ibm_lib4gl_doOperLessThan(void);
extern void  ibm_lib4gl_doOperNotEqualto(void);
extern void  ibm_lib4gl_doOperORD(void);
extern void  ibm_lib4gl_doOperOr(void);
extern void  ibm_lib4gl_doRightMargin(void);
extern void  ibm_lib4gl_doOperSpace(void);
extern void  ibm_lib4gl_doOperSubtract(void);
extern void  ibm_lib4gl_doOperSubString(mint n);
extern void  ibm_lib4gl_doOperTime(void);
extern void  ibm_lib4gl_doOperUnits(void);
extern void  ibm_lib4gl_doOperUsing(mint newformat);
extern void  ibm_lib4gl_doOperWeekDay(void);
extern void  ibm_lib4gl_doOperYear(void);
extern void  ibm_lib4gl_doRunCommand(int1 *module, mint lineno, mint run_mode);
extern void  ibm_lib4gl_doOperValidate(mint npairs);
extern void  ibm_lib4gl_Disconnect(void);
extern void  ibm_lib4gl_ExitFormMode(void);
extern void  ibm_lib4gl_fglPrepare(int1 *stmtname, int4 inode, int1 *cstmt);
extern void  ibm_lib4gl_fglLogError(int1 *prognm, mint lineno, mint errnum);
extern void  ibm_lib4gl_fglFatalError(int1 *prognm, mint lineno, mint errnum);
extern void  ibm_lib4gl_fglInitialize(mint argc, int1 **argv);
extern void  ibm_lib4gl_fglNotFatalError(int1 *prognm, mint lineno,
                                         mint errnum);
extern void  ibm_lib4gl_freeAllBlobLocator(void);
extern mint  ibm_lib4gl_freeBlobLocator(ifx_loc_t *locp, mint mode);
extern void *ibm_lib4gl_getElementAddressC(int4, struct FGLArray *, int4,
                                           int4, int4);
extern int4  ibm_lib4gl_getExtentSize(int4, struct FGLArray *, int4);
extern void *ibm_lib4gl_getDataAddressDA(int4, int4, int4, int4);
extern int4  ibm_lib4gl_getExtentSizeDA(int4, int4);
extern int4  ibm_lib4gl_getDataSizeDA(int4);
extern void  ibm_lib4gl_ifPipeMode(mint n);
extern void  ibm_lib4gl_initSignalHandeler(void);
extern mint  ibm_lib4gl_locateBlob(ifx_loc_t *locp, mint blobtype,
                                  mint storage, int1 *file);
extern void  ibm_lib4gl_loadDate(mint n, int4 *lp);
extern void  ibm_lib4gl_loadDecimal(mint n, dec_t *dd);
extern void  ibm_lib4gl_loadDateTime(mint n, dtime_t *dtvar, mint qual);
extern void  ibm_lib4gl_loadDouble(mint n, double *dp);
extern void  ibm_lib4gl_loadFloat(mint n, float *df);
extern void  ibm_lib4gl_loadMint(mint n, mint *ip);
extern void  ibm_lib4gl_loadInterval(mint n, intrvl_t *invvar, mint qual);
extern void  ibm_lib4gl_loadBlobLocator(mint n, ifx_loc_t **blob);
extern void  ibm_lib4gl_loadInt4(mint n, int4 *lp);
extern void  ibm_lib4gl_loadInt8(mint n, ifx_int8_t *bi);
extern void  ibm_lib4gl_loadQuotedString(mint n, int1 *str, mint len);
extern void  ibm_lib4gl_loadInt2(mint n, int2 *is);
extern void  ibm_lib4gl_loadSubString(mint n, int1 *str, mint start,
                                      mint len, mint buflen);
extern void  ibm_lib4gl_loadVarChar(mint n, int1 *vc, mint len);
extern FILE *ibm_lib4gl_printFileOpen(void);
extern void  ibm_lib4gl_printInitGotoIndex(void);
extern void  ibm_lib4gl_printBottomMargin(void);
extern void  ibm_lib4gl_printPopGoto(mint *pretloc);
extern void  ibm_lib4gl_popStack(mint nelems);
extern void  ibm_lib4gl_printPushGoto(mint retloc);
extern void  ibm_lib4gl_printNewLine(mint n);
extern void  ibm_lib4gl_printLeftMarginIfNeed(void);
extern mint  ibm_lib4gl_printNListToFile(repdesc_t *rep, mint n, wwdesc_t *wwd);
extern void  ibm_lib4gl_printUsrSpecTopOfPage(void);
extern void  ibm_lib4gl_printTopMargin(void);
extern void  ibm_lib4gl_printTmpLeftMargin(mint i);
extern void  ibm_lib4gl_printListToFile(FILE *fp, mint n);
extern mint  ibm_lib4gl_popBoolean(mint *ip);
extern void  ibm_lib4gl_popDate(int4 *lp);
extern void  ibm_lib4gl_popDecimal(dec_t *dd);
extern void  ibm_lib4gl_popDecimalVar(dec_t *dd, mint attlen);
extern void  ibm_lib4gl_popDateTime(dtime_t *dtvar, mint qual);
extern void  ibm_lib4gl_popDouble(double *dp);
extern void  ibm_lib4gl_popDummy(void);
extern void  ibm_lib4gl_popFloat(float *df);
extern void  ibm_lib4gl_popMInt(mint *ip);
extern void  ibm_lib4gl_popInterval(intrvl_t *invvar, mint qual);
extern void  ibm_lib4gl_popBlobLocator(ifx_loc_t **blob);
extern void  ibm_lib4gl_popInt4(int4 *lp);
extern void  ibm_lib4gl_popInt8(ifx_int8_t *bi);
extern void  ibm_lib4gl_popModuleName(void);
extern void  ibm_lib4gl_popMoney(dec_t *dd);
extern void  ibm_lib4gl_popMoneyVar(dec_t *dd, mint attlen);
extern void  ibm_lib4gl_popQuotedStr(int1 *str, mint len);
extern void  ibm_lib4gl_popInt2(int2 *is);
extern void  ibm_lib4gl_popString(int1 *str, mint len);
extern void  ibm_lib4gl_popSubString(int1 *str, mint start, mint len,
                                     mint buflen, mint type);
extern void  ibm_lib4gl_popVarChar(int1 *vc, mint len);
extern void  ibm_lib4gl_popDynArray(int4, struct FGLArray *);
extern void  ibm_lib4gl_popDA(int4 *);
extern void  ibm_lib4gl_pushDate(int4 l);
extern void  ibm_lib4gl_pushDecimal(dec_t *pd, mint prec);
extern void  ibm_lib4gl_pushDateTime(dtime_t *dtvar);
extern void  ibm_lib4gl_pushStrDate(int1 *str, mint dtqual);
extern void  ibm_lib4gl_pushStrInt8(int1 *str);
extern void  ibm_lib4gl_pushDouble(double *dp);
extern void  ibm_lib4gl_pushFloat(float *fp);
extern void  ibm_lib4gl_pushMInt(mint i);
extern void  ibm_lib4gl_pushInterval(intrvl_t *invvar);
extern void  ibm_lib4gl_pushStrInterval(int1 *str, mint dtqual);
extern void  ibm_lib4gl_pushBlobLocator(ifx_loc_t *blob);
extern void  ibm_lib4gl_pushInt4(int4 l);
extern void  ibm_lib4gl_pushInt8(ifx_int8_t *bi);
extern void  ibm_lib4gl_pushLValueQuotedStr(int1 *s, mint len, mint type);
extern void  ibm_lib4gl_pushModuleName(int1 *name);
extern void  ibm_lib4gl_pushMoney(dec_t *pd, mint len);
extern void  ibm_lib4gl_pushNull(void);
extern void  ibm_lib4gl_pushQuotedStr(int1 *s, mint len);
extern void  ibm_lib4gl_pushInt2(int2 s);
extern void  ibm_lib4gl_pushStrDecimal(int1 *str);
extern void  ibm_lib4gl_pushDynArray(int4, struct FGLArray *);
extern void  ibm_lib4gl_pushVarChar(int1 *s, mint len);
extern int2  ibm_lib4gl_isAllocatedDA(int4);
extern void  ibm_lib4gl_initDynArr(int4 *, int4, int2, int2, int2);
extern void  ibm_lib4gl_internalPshDate(void);
extern void  ibm_lib4gl_internalPshTime(void);
extern void  ibm_lib4gl_internalPshTodaysDt(void);
extern void  ibm_lib4gl_isNull(void);
extern void  ibm_lib4gl_reportEvalAggregates(mint aggnum);
extern void  ibm_lib4gl_reportInitAggregates(mint numaggs);
extern void  ibm_lib4gl_reportPushAggregates(mint aggnum);
extern mint  ibm_lib4gl_reportSetBreak(mint numparms, mint numsorts);
extern void  ibm_lib4gl_reportSetGAggreToZero(mint numaggs, mint breaklevel);
extern void  ibm_lib4gl_reportDoPause(mint rptdest, int1 *pausestr);
extern mint  ibm_lib4gl_returnFglWarningNo(void);
extern void  ibm_lib4gl_restoreHwmState(void);
extern void  ibm_lib4gl_recordTssAndHwmState(char *name);  /* bug11302 */
extern void  ibm_lib4gl_releaseTssAndHwmStack(void);
extern void  ibm_lib4gl_relUnwantedTssEntries(void);
extern void  ibm_lib4gl_SetConnect(void);
extern mint  ibm_lib4gl_markStack(void);
extern void  ibm_lib4gl_openOutFileOrPipe(mint rptdest, int1 *ofname,
                                          mint onstackflg);
extern void  ibm_lib4gl_resetStack(mint n);
extern void  ibm_lib4gl_returnDate(int4 l);
extern void  ibm_lib4gl_returnDecimal(dec_t *pd);
extern void  ibm_lib4gl_returnDateTime(dtime_t *dtvar);
extern void  ibm_lib4gl_returnDouble(double *dp);
extern void  ibm_lib4gl_returnFloat(float *fp);
extern void  ibm_lib4gl_returnMInt(mint i);
extern void  ibm_lib4gl_returnInterval(intrvl_t *invvar);
extern void  ibm_lib4gl_returnInt4(int4 l);
extern void  ibm_lib4gl_returnInt8(ifx_int8_t *bi);
extern void  ibm_lib4gl_returnMon(dec_t *pd);
extern void  ibm_lib4gl_returnMoney(dec_t *pd);
extern void  ibm_lib4gl_returnQuotedStr(int1 *s);
extern void  ibm_lib4gl_returnInt2(int2 s);
extern void  ibm_lib4gl_returnString(int1 *s);
extern void  ibm_lib4gl_returnVarChar(int1 *vc);
extern void  ibm_lib4gl_recordDynArrStack(void);
extern void  ibm_lib4gl_releaseDynArrStack(void);
extern void  ibm_lib4gl_resizeDynArrC(int4, struct FGLArray *,
                                      int4, int4, int4);
extern void  ibm_lib4gl_resizeDA(int4, int4, int4, int4);
extern void  ibm_lib4gl_skipNLines(mint n);
extern void  ibm_lib4gl_setNullDecimal(dec_t *dd);
extern void  ibm_lib4gl_setNullDateTime(dtime_t *dtvar);
extern void  ibm_lib4gl_setNullDouble(double *dp);
extern void  ibm_lib4gl_setNullFloat(float *df);
extern void  ibm_lib4gl_setNullMInt(mint *ip);
extern void  ibm_lib4gl_setNullInterval(intrvl_t *invvar);
extern mint  ibm_lib4gl_setNullBlobLocator(ifx_loc_t *blob);
extern void  ibm_lib4gl_setNullInt4(int4 *lp);
extern void  ibm_lib4gl_setNullInt8(ifx_int8_t *bi);
extern void  ibm_lib4gl_setNullQuotedStr(int1 *str, mint len);
extern void  ibm_lib4gl_setNullInt2(int2 *is);
extern void  ibm_lib4gl_setNullVarChar(int1 *vc);
extern void  ibm_lib4gl_setRunMode(mint n);
extern void  ibm_lib4gl_loadDynArray(mint, int4, struct FGLArray *);
extern mint  ibm_lib4gl_zeroFilAndSaveLocator(ifx_loc_t *locp);

extern mint  i4gl_end(void);
extern mint  i4gl_exitfm(void);
extern mint  i4gl_start(void);

#endif /* FGLSYS_H */
