! $Id$
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
    program ESMF_FieldCommEx

!------------------------------------------------------------------------------
!ESMF_MULTI_PROC_EXAMPLE        String used by test script to count examples.
!==============================================================================
! !PROGRAM: ESMF_FieldCommEx - Field level communication routines
!
! !DESCRIPTION:
!
! Example/test code which does communication operations on Fields,
! including examples of using Redist, Halo, and Regrid on a Field.
! Also see the Programming Model section of this document.
!-----------------------------------------------------------------------------

#include "ESMF.h"
#include "ESMF_Macros.inc"
#undef ESMF_METHOD
#define ESMF_METHOD "ESMF_FieldCommEx"

    ! ESMF Framework module
    use ESMF
    use ESMF_TestMod

    implicit none
    
!------------------------------------------------------------------------------
! The following line turns the CVS identifier string into a printable variable.
    character(*), parameter :: version = &
    '$Id$'
!------------------------------------------------------------------------------

    ! Local variables
    integer :: rc, finalrc

    ! local arguments used to create field etc
    type(ESMF_Field)                            :: field
    type(ESMF_Grid)                             :: grid
    type(ESMF_DistGrid)                         :: distgrid
    type(ESMF_VM)                               :: vm
    type(ESMF_Array)                            :: array
    integer                                     :: localrc, lpe, i, j

    integer, allocatable                        :: farray(:,:)
    integer, allocatable                        :: farrayDst(:,:)
    integer, allocatable                        :: farraySrc(:,:)
    integer                                     :: fa_shape(2)
    integer, pointer                            :: fptr(:,:)

    rc = ESMF_SUCCESS
    finalrc = ESMF_SUCCESS
!------------------------------------------------------------------------------
    call ESMF_Initialize(defaultlogfilename="FieldCommEx.Log", &
                    logkindflag=ESMF_LOGKIND_MULTI, rc=rc)
    if (rc /= ESMF_SUCCESS) call ESMF_Finalize(endflag=ESMF_END_ABORT)

    if (.not. ESMF_TestMinPETs(4, ESMF_SRCLINE)) &
        call ESMF_Finalize(endflag=ESMF_END_ABORT)
!------------------------------------------------------------------------------
!BOE
! \subsubsection{Gather Field data onto root PET}
! \label{sec:field:usage:gather_2dptr}
!
! User can use {\tt ESMF\_FieldGather} interface to gather Field data from multiple
! PETS onto a single root PET. This interface is overloaded by type, kind, and rank.
!
! Note that the implementation of Scatter and Gather is not seqence index based.
! If the Field is built on arbitrarily distributed Grid, Mesh, LocStream or XGrid, 
! Gather will not gather data to rootPet 
! from source data points corresponding to the sequence index on the rootPet. 
! Instead Gather will gather a contiguous memory range from source PET to
! rootPet. The size of the memory range is equal to the number of 
! data elements on the source PET. Vice versa for the Scatter operation. 
! In this case, the user should use {\tt ESMF\_FieldRedist} to achieve
! the same data operation result. For examples how to use {\tt ESMF\_FieldRedist}
! to perform Gather and Scatter, please refer to
! \ref{sec:field:usage:redist_gathering} and
! \ref{sec:field:usage:redist_scattering}.
! 
! In this example, we first create a 2D Field, then use {\tt ESMF\_FieldGather} to
! collect all the data in this Field into a data pointer on PET 0.
!EOE
!BOC 
    ! Get current VM and pet number
    call ESMF_VMGetCurrent(vm, rc=rc)
    if(rc .ne. ESMF_SUCCESS) finalrc = ESMF_FAILURE

    call ESMF_VMGet(vm, localPet=lpe, rc=rc)
    if(rc .ne. ESMF_SUCCESS) finalrc = ESMF_FAILURE

    ! Create a 2D Grid and use this grid to create a Field
    ! farray is the Fortran data array that contains data on each PET.
    grid = ESMF_GridCreateNoPeriDim(minIndex=(/1,1/), maxIndex=(/10,20/), &
        regDecomp=(/2,2/), &
        name="grid", rc=rc)
    if(rc .ne. ESMF_SUCCESS) finalrc = ESMF_FAILURE

    field = ESMF_FieldCreate(grid, typekind=ESMF_TYPEKIND_I4, rc=localrc)
    if(rc .ne. ESMF_SUCCESS) finalrc = ESMF_FAILURE

    call ESMF_FieldGet(field, farrayPtr=fptr, rc=localrc)
    if(rc .ne. ESMF_SUCCESS) finalrc = ESMF_FAILURE
    !---------Initialize pet specific field data----------------
    !    1        5         10
    ! 1  +--------+---------+
    !    |        |         |
    !    |   0    |    1    |
    !    |        |         |
    ! 10 +--------+---------+
    !    |        |         |
    !    |   2    |    3    |
    !    |        |         |
    ! 20 +--------+---------+
    fptr = lpe

    ! allocate the Fortran data array on PET 0 to store gathered data
    if(lpe .eq. 0) allocate(farrayDst(10,20))
    call ESMF_FieldGather(field, farrayDst, rootPet=0, rc=rc)
    if(rc .ne. ESMF_SUCCESS) finalrc = ESMF_FAILURE

    ! check that the values gathered on rootPet are correct
    if(lpe .eq. 0) then
       do i = 1, 2
          do j = 1, 2
             if(farrayDst(i, j) .ne. (i-1)+(j-1)*2) localrc=ESMF_FAILURE
             if(farrayDst(i*5, j*10) .ne. (i-1)+(j-1)*2) localrc=ESMF_FAILURE
          enddo
       enddo
      if(rc .ne. ESMF_SUCCESS) finalrc = ESMF_FAILURE
    endif

    ! destroy all objects created in this example to prevent memory leak
    call ESMF_FieldDestroy(field, rc=rc)
    if(rc .ne. ESMF_SUCCESS) finalrc = ESMF_FAILURE
    call ESMF_GridDestroy(grid, rc=rc)
    if(rc .ne. ESMF_SUCCESS) finalrc = ESMF_FAILURE
    if(lpe .eq. 0) deallocate(farrayDst)
!EOC

!------------------------------------------------------------------------------
!BOE
! \subsubsection{Scatter Field data from root PET onto its set of joint PETs}
! \label{sec:field:usage:scatter_2dptr}
!
! User can use {\tt ESMF\_FieldScatter} interface to scatter Field data from root
! PET onto its set of joint PETs. This interface is overloaded by type, kind, and rank.
! 
! In this example, we first create a 2D Field, then use {\tt ESMF\_FieldScatter} to
! scatter the data from a data array located on PET 0 onto this Field.
!EOE
!BOC 
    ! Create a 2D Grid and use this grid to create a Field
    ! farray is the Fortran data array that contains data on each PET.
    grid = ESMF_GridCreateNoPeriDim(minIndex=(/1,1/), maxIndex=(/10,20/), &
        regDecomp=(/2,2/), &
        name="grid", rc=rc)
    if(rc .ne. ESMF_SUCCESS) finalrc = ESMF_FAILURE

    field = ESMF_FieldCreate(grid, typekind=ESMF_TYPEKIND_I4, rc=localrc)
    if(rc .ne. ESMF_SUCCESS) finalrc = ESMF_FAILURE

    ! initialize values to be scattered
    !    1        5         10
    ! 1  +--------+---------+
    !    |        |         |
    !    |   0    |    1    |
    !    |        |         |
    ! 10 +--------+---------+
    !    |        |         |
    !    |   2    |    3    |
    !    |        |         |
    ! 20 +--------+---------+
    if(lpe .eq. 0) then
        allocate(farraySrc(10,20))
        farraySrc(1:5,1:10) = 0
        farraySrc(6:10,1:10) = 1
        farraySrc(1:5,11:20) = 2
        farraySrc(6:10,11:20) = 3
    endif

    ! scatter the data onto individual PETs of the Field
    call ESMF_FieldScatter(field, farraySrc, rootPet=0, rc=rc)
    if(rc .ne. ESMF_SUCCESS) finalrc = ESMF_FAILURE

    call ESMF_FieldGet(field, localDe=0, farrayPtr=fptr, rc=rc)
    if(rc .ne. ESMF_SUCCESS) finalrc = ESMF_FAILURE

    ! verify that the scattered data is properly distributed
    do i = lbound(fptr, 1), ubound(fptr, 1)
        do j = lbound(fptr, 2), ubound(fptr, 2)
            if(fptr(i, j) .ne. lpe) localrc = ESMF_FAILURE
        enddo
        if(rc .ne. ESMF_SUCCESS) finalrc = ESMF_FAILURE
    enddo

    ! destroy all objects created in this example to prevent memory leak
    call ESMF_FieldDestroy(field, rc=rc)
    if(rc .ne. ESMF_SUCCESS) finalrc = ESMF_FAILURE
    call ESMF_GridDestroy(grid, rc=rc)
    if(rc .ne. ESMF_SUCCESS) finalrc = ESMF_FAILURE
    if(lpe .eq. 0) deallocate(farraySrc)
!EOC
!------------------------------------------------------------------------------
    if (finalrc.EQ.ESMF_SUCCESS) then
       print *, "PASS: ESMF_FieldCommEx.F90"
    else
       print *, "FAIL: ESMF_FieldCommEx.F90"
    end if

    call ESMF_Finalize(rc=rc)

    end program ESMF_FieldCommEx
    
!\end{verbatim}
