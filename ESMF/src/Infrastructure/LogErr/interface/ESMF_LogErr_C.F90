!  $Id: ESMF_LogErr_C.F90,v 1.1.5.1 2013-01-11 20:23:44 mathomp4 Exp $
!
! Earth System Modeling Framework
! Copyright 2002-2012, University Corporation for Atmospheric Research, 
! Massachusetts Institute of Technology, Geophysical Fluid Dynamics 
! Laboratory, University of Michigan, National Centers for Environmental 
! Prediction, Los Alamos National Laboratory, Argonne National Laboratory, 
! NASA Goddard Space Flight Center.
! Licensed under the University of Illinois-NCSA License.
!
!==============================================================================
!
! F77 interface files for C++ layer calling into F90 implementation layer.
!  This cannot use any F90 modules.
!
!==============================================================================
!
!------------------------------------------------------------------------------
! INCLUDES
#include "ESMF.h"
!==============================================================================
!------------------------------------------------------------------------------
! The following line turns the CVS identifier string into a printable variable.
!      character(*), parameter, private :: version = &
!      '$Id: ESMF_LogErr_C.F90,v 1.1.5.1 2013-01-11 20:23:44 mathomp4 Exp $'
!==============================================================================

  subroutine f_esmf_logwrite0(msg,logmsgList,rc)
    use ESMF_UtilTypesMod    ! ESMF base class
    use ESMF_BaseMod         ! ESMF base class
    use ESMF_LogErrMod
    
    implicit none
    
    character(len=*), intent(in)                :: msg
    type(ESMF_LogMsg_Flag), intent(in)              :: logmsgList
    integer, intent(out)                        :: rc

    ! Initialize return code; assume routine not implemented
    rc = ESMF_RC_NOT_IMPL

    call ESMF_LogWrite(msg, logmsgList, rc=rc)

  end subroutine f_esmf_logwrite0

  subroutine f_esmf_logwrite1(msg,logmsgList,line,file,method,rc)
    use ESMF_UtilTypesMod    ! ESMF base class
    use ESMF_BaseMod         ! ESMF base class
    use ESMF_LogErrMod
    
    implicit none

    character(len=*), intent(in)                :: msg
    type(ESMF_LogMsg_Flag), intent(in)              :: logmsgList
    integer, intent(in)                         :: line
    character(len=*), intent(in)                :: file
    character(len=*), intent(in)                :: method
    integer, intent(out)                        :: rc

    ! Initialize return code; assume routine not implemented
    rc = ESMF_RC_NOT_IMPL

    call ESMF_LogWrite(msg, logmsgList,  &
                       line=line, file=file, method=method, rc=rc)

  end subroutine f_esmf_logwrite1
