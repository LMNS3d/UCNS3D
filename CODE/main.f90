PROGRAM UCNS3D
USE MPIINFO
USE TRANSLATE
use DECLARATION
USE MEMORY
USE COMMUNICATIONS
USE IO
USE PARTITION
USE LIBRARY
USE TRANSFORM
USE FLUXES
USE INITIALISATION
USE BOUNDARY
USE ADVANCE
USE RECON
USE LOCAL
USE FLUXES_V
USE PROFILE
USE FLOW_OPERATIONS
USE GRADIENTS
USE BASIS
USE PRESTORE
USE RIEMANN
USE SOURCE
USE implicit_time
USE implicit_FLUXES


IMPLICIT NONE
! CALL MPIINIT(N,ISIZE,MPI_COMM_WORLD,IERROR)

EXTERNAL METIS_PartMeshDual
EXTERNAL ParMETIS_V3_PartMeshKway
!CALL MPI_INIT(IERROR)
CALL MPI_INIT_THREAD(MPI_THREAD_FUNNELED,PROVIDED,IERROR)
CALL MPI_COMM_SIZE(MPI_COMM_WORLD,ISIZE,IERROR)
CALL MPI_COMM_RANK(MPI_COMM_WORLD,N,IERROR)

CALL OPEN_INPUT1(N,ITT)
CALL READ_UCNS3D

 CALL CLOSE_INPUT1(N,ITT)


IF (N.EQ.0)THEN
  CALL TRANSLATE_MESH

 END IF
 CALL MPI_BARRIER(MPI_COMM_WORLD, IERROR)
 CALL TOLERANCES

CALL TIMING(N,CPUX1,CPUX2,CPUX3,CPUX4,CPUX5,CPUX6,TIMEX1,TIMEX2,TIMEX3,TIMEX4,TIMEX5,TIMEX6)
 CPUX1(1)=MPI_WTIME()
!**************************DEVELOPED BY PANAGIOTIS TSOUTSANIS**************************!
!*****************************FMACS RESEARCH GROUP CRANFIELD **************************!
!*****************************___CRANFIELD_____UNIVERSITY____**************************!
!print *, 'Number of tasks=',ISIZE,' My rank=',N
! IF (N.EQ.0)THEN
! OPEN(63,FILE='history.txt',FORM='FORMATTED',STATUS='new',ACTION='WRITE')
! CLOSE(63)
! END IF
!---------------------------------------------------------------!
!		       I/O OPERATIONS 				!
!---------------------------------------------------------------!



 CALL OPEN_ARBITRARY(N,IMAXE,IMAXN,IMAXB)


CALL SHALLOCATION(IESHAPE,IMAXE)

  CALL MPI_BARRIER(MPI_COMM_WORLD, IERROR)

CALL FIND_SHAPE(N,IMAXE,IESHAPE)		!THREAD FRIENDLY



IF ((TURBULENCE.EQ.1).OR.(PASSIVESCALAR.GT.0))THEN
 CALL  ALLOCATETURB(N,EDDYFL,EDDYFR)
END IF
CALL CHECKRES

CALL XMPIALLOCATE(XMPIE,XMPIL,XMPIN,XMPIELRANK,XMPINRANK,IMAXE,IMAXN,NPROC)



 
CALL MPI_BARRIER(MPI_COMM_WORLD, IERROR)
   
    if (emetis.lt.6)then
    if (n.eq.0) then
	
	If (emetis.eq.1)then
          Call Partitioner1(n,IMAXE,imaxn,XMPIE,ieshape)
        end if
        If (emetis .eq.2)then
	  
	  Call Partitioner2(n,IMAXE,imaxn,XMPIE,ieshape)
	  
	end if
	If (emetis .eq. 3) then
	  Call Partitioner3(n,IMAXE,imaxn,XMPIE,ieshape)
	end if
	If (emetis .eq. 4) then
	  Call Partitioner4(n,IMAXE,imaxn,XMPIE,ieshape)
	end if
	if (emetis.eq.5)then
	  Call Partitioner5(n,IMAXE,imaxn,XMPIE,ieshape)
	end if
! 	if (emetis.eq.6)then
! 	  Call Partitioner5(n,IMAXE,imaxn,XMPIE,ieshape)
! 	end if
	
	
    end if
    
      call MPI_BCAST(XMPIE,IMAXE,MPI_INTEGER,0,MPI_COMM_WORLD,IERROR) 
      
   else
    
    if (emetis.eq.6)then
	  Call Partitioner6(n,IMAXE,imaxn,XMPIE,ieshape)
	end if
    end if
    


CALL MPI_BARRIER(MPI_COMM_WORLD, IERROR)


CALL XMPIFIND(XMPIE,XMPIN,XMPIELRANK,XMPINRANK,IMAXE,IMAXN,NPROC)

call ELALLOCATION(N,XMPIE,XMPIELRANK,IELEM,IMAXE,IESHAPE,ITESTCASE,IMAXB,IBOUND,XMIN,XMAX,YMIN,YMAX,ZMIN,ZMAX)



CALL READ_INPUT(N,XMPIELRANK,XMPINRANK,XMPIE,XMPIN,IELEM,INODE,IMAXN,IMAXE,IBOUND,IMAXB,XMPINNUMBER,SCALER,INODER)

 CALL DETERMINE_SIZE(N,IORDER,ISELEM,ISELEMT,IOVERST,IOVERTO,ILX,NUMNEIGHBOURS,IDEGFREE,IMAXDEGFREE,IEXTEND)
!$OMP PARALLEL DEFAULT(SHARED)
 CALL GAUSSIANPOINTS(IGQRULES,NUMBEROFPOINTS,NUMBEROFPOINTS2)
 CALL VERTALLOCATION(N,VEXT,LEFTV,RIGHTV,VISCL,LAML)
  CALL ALLOCATE1(N)
 call QUADALLOC(QPOINTS,QPOINTS2D,WEQUA2D,WEQUA3D,NUMBEROFPOINTS,NUMBEROFPOINTS2)
 CALL allocate6_1
CALL allocate7_1
 compwrt=0
!$OMP END PARALLEL 
!$OMP BARRIER

 CALL SHDEALLOCATION(IESHAPE,IMAXE)


CALL MPI_BARRIER(MPI_COMM_WORLD,IERROR)
 if (n.eq.0) then 
   CPUX3(1) = MPI_Wtime()
   WRITE(100+N,*)"TIMEI_1",CPUX3(1)-CPUX1(1)
end if

call ALLOCATE2
CALL NEIGHBOURSS(N,IELEM,IMAXE,IMAXN,XMPIE,XMPIN,XMPIELRANK,RESTART,INODEr)!MUST BE THREAD FRIENDLY
 call ALLOCATE3
CALL MPI_BARRIER(MPI_COMM_WORLD,IERROR)


 if (n.eq.0) then 
   CPUX3(1) = MPI_Wtime()
   WRITE(100+N,*)"TIMEI_2",CPUX3(1)-CPUX1(1)
end if
   

  IF (DIMENSIONA.EQ.3)THEN
  CALL VOLUME_CALCULATOR3(N)!MUST BE THREAD FRIENDLY
  CALL SURFACE_CALCULATOR3(N)
  CALL CENTRE(N)
  CALL EDGE_CALCULATOR(N)
  ELSE
  CALL VOLUME_CALCULATOR2(N)!MUST BE THREAD FRIENDLY
  CALL SURFACE_CALCULATOR2(N)
  CALL CENTRE(N)
  CALL EDGE_CALCULATOR(N)
  END IF

 CALL MPI_BARRIER(MPI_COMM_WORLD,IERROR)
 if (n.eq.0)  then
   CPUX3(1) = MPI_Wtime()
   WRITE(100+N,*)"TIMEI_3",CPUX3(1)-CPUX1(1)
end if

CALL READ_BOUND(N,IMAXB,IBOUND,XMPIELRANK)




!$OMP BARRIER
!$OMP PARALLEL DEFAULT(SHARED)
   CALL APPLY_BOUNDARY(N,XPER,YPER,ZPER,IPERIODICITY,XMPIELRANK)
!$OMP BARRIER
!$OMP END PARALLEL 
				CALL MPI_BARRIER(MPI_COMM_WORLD,IERROR)
				!$OMP MASTER
				IF (N.EQ.0)THEN
				
				  OPEN(63,FILE='history.txt',FORM='FORMATTED',STATUS='old',ACTION='WRITE',POSITION='APPEND')
				  WRITE(63,*)"finished applying boundary conditions"
				  CPUX3(1) = MPI_Wtime()
				  WRITE(63,*)"time1=",CPUX3(1)-cpux1(1)
				  CLOSE(63)
				  END IF
				  !$OMP END MASTER
				CALL MPI_BARRIER(MPI_COMM_WORLD,IERROR)
  CALL XMPILOCAL
  call COUNT_WALLS
  !$OMP BARRIER
! CALL GLOBALIST(N,XMPIE,XMPIL,XMPIELRANK,IMAXE,ISIZE,CENTERR,GLNEIGH,IELEM)
!$OMP MASTER
IF (LOWMEM.EQ.0)CALL GLOBALISTX(N,XMPIE,XMPIL,XMPIELRANK,IMAXE,ISIZE,CENTERR,GLNEIGH,IELEM)
IF (LOWMEM.EQ.1)CALL GLOBALIST(N,XMPIE,XMPIL,XMPIELRANK,IMAXE,ISIZE,CENTERR,GLNEIGH,IELEM)
 !$OMP END MASTER
!$OMP BARRIER
CALL MPI_BARRIER(MPI_COMM_WORLD,IERROR)

				!$OMP MASTER
				IF (N.EQ.0)THEN
				  OPEN(63,FILE='history.txt',FORM='FORMATTED',STATUS='old',ACTION='WRITE',POSITION='APPEND')
				  WRITE(63,*)"finished obtaining neighbours within my cpu"
				  CPUX3(1) = MPI_Wtime()
				  WRITE(63,*)"time2=",CPUX3(1)-cpux1(1)
				  CLOSE(63)
				  END IF
				  !$OMP END MASTER


 if (dimensiona.eq.3)then
 CALL CONS(N,ICONR,ICONS,IPERIODICITY,XMPIELRANK,ISIZE,ICONRPA,ICONRPM,ICONSPO,XPER,YPER,ZPER,ICONRPF,NUMNEIGHBOURS,TYPESTEN)
 else
CALL CONS2d(N,ICONR,ICONS,IPERIODICITY,XMPIELRANK,ISIZE,ICONRPA,ICONRPM,ICONSPO,XPER,YPER,ZPER,ICONRPF,NUMNEIGHBOURS,TYPESTEN)
 end if
				!$OMP MASTER
				IF (N.EQ.0)THEN
				  OPEN(63,FILE='history.txt',FORM='FORMATTED',STATUS='old',ACTION='WRITE',POSITION='APPEND')
				  WRITE(63,*)"finished obtaining neighbours within my cpu"
				  CPUX3(1) = MPI_Wtime()
				  WRITE(63,*)"time22=",CPUX3(1)-cpux1(1)
				  CLOSE(63)
				  END IF
				  !$OMP END MASTER

  IF (LOWMEM.EQ.0)CALL GLOBALISTX2(N,XMPIE,XMPIL,XMPIELRANK,IMAXE,ISIZE,CENTERR,GLNEIGH,IELEM)
 
  IF (LOWMEM.EQ.1)CALL GLOBALIST2(N,XMPIE,XMPIL,XMPIELRANK,IMAXE,ISIZE,CENTERR,GLNEIGH,IELEM)
				  !$OMP MASTER
				  IF (N.EQ.0)THEN
				  OPEN(63,FILE='history.txt',FORM='FORMATTED',STATUS='old',ACTION='WRITE',POSITION='APPEND')
				  WRITE(63,*)"finished obtaining neighbours across all cpu"
				  CPUX3(1) = MPI_Wtime()
				  WRITE(63,*)"time3=",CPUX3(1)-cpux1(1)
				  CLOSE(63)
				  END IF
				  !$OMP END MASTER


IF (ISCHEME.GT.1)THEN
 CALL MPI_BARRIER(MPI_COMM_WORLD,IERROR)
  CPUX3(1)=MPI_WTIME()
 CALL allocate5
  !$OMP PARALLEL DEFAULT(SHARED)
 IF (LOWMEM.EQ.0)CALL DETSTENX(N,ISIZE,IELEM,ISELEMT,XMPIELRANK,ILOCALALLS,TYPESTEN,ILOCALALLELG,STCON,STCONC,STCONS,STCONG,ISOSA,IX,&
 IISTART,IFSAT,PARE,DOSE,PAREEL,DOSEEL,PARES,SOSEEL,XMPIE,IFIN,TFIN,XMPIL,GLNEIGH)
 IF (LOWMEM.EQ.1)CALL DETSTEN(N,ISIZE,IELEM,ISELEMT,XMPIELRANK,ILOCALALLS,TYPESTEN,ILOCALALLELG,STCON,STCONC,STCONS,STCONG,ISOSA,IX,&
 IISTART,IFSAT,PARE,DOSE,PAREEL,DOSEEL,PARES,SOSEEL,XMPIE,IFIN,TFIN,XMPIL,GLNEIGH)
 !$OMP END PARALLEL 
 
 


 !$OMP PARALLEL DEFAULT(SHARED)
 
 CALL allocate6_2

 !$OMP END PARALLEL
 
 
 
 
				  !$OMP MASTER
				  IF (N.EQ.0)THEN
				  OPEN(63,FILE='history.txt',FORM='FORMATTED',STATUS='old',ACTION='WRITE',POSITION='APPEND')
				  WRITE(63,*)"finished obtaining the central stencils across all cpu"
				  CPUX3(1) = MPI_Wtime()
				  WRITE(63,*)"time4=",CPUX3(1)-cpux1(1)
				  CLOSE(63)
				  END IF
				  !$OMP END MASTER
 
 
  CALL LOCALSTALLOCATION(N,XMPIELRANK,ILOCALSTENCIL,TYPESTEN,NUMNEIGHBOURS)
! CALL MPI_BARRIER(MPI_COMM_WORLD,IERROR)



CALL MPI_BARRIER(MPI_COMM_WORLD,IERROR)
 if (n.eq.0)  then
   CPUX3(1) = MPI_Wtime()
   WRITE(100+N,*)"TIME_I4",CPUX3(1)-CPUX1(1)
end if


!$OMP PARALLEL DEFAULT(SHARED)
    
  IF ((EES.EQ.0).OR.(EES.GE.4))THEN
  IF (LOWMEM.EQ.0)CALL STENCIILSX(N,IELEM,ILOCALALLELG,TYPESTEN,ILOCALSTENCIL,NUMNEIGHBOURS,ISELEMT,XMPIE,XMPIELRANK,ISIZE,BC,VC,VG,ISATISFIED,&
  IWHICHSTEN,IPERIODICITY,XPER,YPER,ZPER,ISSF,ISHYAPE,XMPIL,CENTERR)
  IF (LOWMEM.EQ.1)CALL STENCIILS(N,IELEM,ILOCALALLELG,TYPESTEN,ILOCALSTENCIL,NUMNEIGHBOURS,ISELEMT,XMPIE,XMPIELRANK,ISIZE,BC,VC,VG,ISATISFIED,&
  IWHICHSTEN,IPERIODICITY,XPER,YPER,ZPER,ISSF,ISHYAPE,XMPIL,CENTERR)
  end if
  if ((ees.gt.0).and.(ees.le.2))then
  IF (LOWMEM.EQ.0)CALL STENCIILS_EESX(N,IELEM,ILOCALALLELG,TYPESTEN,ILOCALSTENCIL,NUMNEIGHBOURS,ISELEMT,XMPIE,XMPIELRANK,ISIZE,BC,VC,VG,ISATISFIED,&
  IWHICHSTEN,IPERIODICITY,XPER,YPER,ZPER,ISSF,ISHYAPE,XMPIL,CENTERR)
  IF (LOWMEM.EQ.1)CALL STENCIILS_EES(N,IELEM,ILOCALALLELG,TYPESTEN,ILOCALSTENCIL,NUMNEIGHBOURS,ISELEMT,XMPIE,XMPIELRANK,ISIZE,BC,VC,VG,ISATISFIED,&
  IWHICHSTEN,IPERIODICITY,XPER,YPER,ZPER,ISSF,ISHYAPE,XMPIL,CENTERR)
  
  END IF
!$OMP END PARALLEL 

   if (ees.eq.3)then
      CALL STENCILS3(N,IELEM,IMAXE,XMPIE,XMPIELRANK,ILOCALSTENCIL,TYPESTEN,NUMNEIGHBOURS,RESTART)
  
   end if
!$OMP PARALLEL DEFAULT(SHARED)
   CALL allocate7_2
!$OMP END PARALLEL 


  DEALLOCATE(ILOCALALLELG)
  CALL GLOBALDEA


 CALL STENCILS(N,IELEM,IMAXE,XMPIE,XMPIELRANK,ILOCALSTENCIL,TYPESTEN,NUMNEIGHBOURS,RESTART)
  IF (IADAPT.EQ.1)THEN
  CALL ADAPT_CRITERION
  END IF

END IF


				  !$OMP MASTER
				  IF (N.EQ.0)THEN
				  OPEN(63,FILE='history.txt',FORM='FORMATTED',STATUS='old',ACTION='WRITE',POSITION='APPEND')
				  WRITE(63,*)"finished obtaining the directional stencils across all cpu"
				  CPUX3(1) = MPI_Wtime()
				  WRITE(63,*)"time5=",CPUX3(1)-cpux1(1)
				  CLOSE(63)
				  END IF
				  !$OMP END MASTER



 

! CALL MPI_BARRIER(MPI_COMM_WORLD,IERROR)
  CALL ESTABEXHANGE(N,IELEM,IMAXE,XMPIE,XMPIN,XMPIELRANK,ILOCALSTENCIL,IEXCHANGER,IEXCHANGES,IRECEXR,IRECEXS,&
NUMNEIGHBOURS,ISCHEME,ISIZE,IPERIODICITY,TYPESTEN,XMPIL)
!

 CALL RENUMBER_NEIGHBOURS(N,IELEM,XMPIE,XMPIELRANK,IEXCHANGER,IEXCHANGES)
! 

! 


CALL MPI_BARRIER(MPI_COMM_WORLD,IERROR)
 if (n.eq.0)  then
   CPUX3(1) = MPI_Wtime()
  WRITE(100+N,*)"TIMEI_5",CPUX3(1)-CPUX1(1)
end if



CALL DEALLOCATEMPI1(N)

if (NPROBES.GT.0)THEN
CALL PROBEPOS(N,PROBEI)
END IF

 !memory allocation for transformation to computational domain!
 
				!$OMP MASTER
				  IF (N.EQ.0)THEN
				  OPEN(63,FILE='history.txt',FORM='FORMATTED',STATUS='old',ACTION='WRITE',POSITION='APPEND')
				  WRITE(63,*)"started presotring reconstruction matrices"
				  CPUX3(1) = MPI_Wtime()
				  WRITE(63,*)"time6=",CPUX3(1)-cpux1(1)
				  CLOSE(63)
				  END IF
				  !$OMP END MASTER
 
!$OMP PARALLEL DEFAULT(SHARED)
 if ((fastest.ne.1).and.(ischeme.ge.2))then
 CALL LOCAL_ELALLOCATION(N,ILOCAL_ELEM)
 CALL LOCAL_NALLOCATION(N,ILOCAL_NODE)
 end if
  if (iweno.eq.1)then
 CALL ALLWEFF(WEFF,IDEGFREE)
 end if
!$OMP END PARALLEL 



CALL MPI_BARRIER(MPI_COMM_WORLD,IERROR)
 if (n.eq.0) then 
   CPUX3(1) = MPI_Wtime()
WRITE(100+N,*)"TIMEI_6",CPUX3(1)-CPUX1(1)
end if






CALL LOCAL_RECONALLOCATION3(N,ILOCAL_RECON3)


 CALL MPI_BARRIER(MPI_COMM_WORLD,IERROR)


CALL EXCH_CORDS(N)



CALL MPI_BARRIER(MPI_COMM_WORLD,IERROR)

if (rungekutta.GE.10)then
call EXCH_CORDS2(N,ISIZE,IEXBOUNDHIRi,IEXBOUNDHISi,ITESTCASE,NUMBEROFPOINTS2,IEXCHANGER,IEXCHANGES)
end if



if ((fastest.ne.1).and.(ischeme.ge.2))then
CALL ALLOCATE_BASIS_FUNCTION(N,INTEG_BASIS,XMPIELRANK,IDEGFREE)
end if



!$OMP PARALLEL DEFAULT(SHARED)
 CALL MEMORY1
!$OMP END PARALLEL


CALL MPI_BARRIER(MPI_COMM_WORLD,IERROR)
 if (n.eq.0)  then
   CPUX3(1) = MPI_Wtime()
WRITE(100+N,*)"TIMEI_7",CPUX3(1)-CPUX1(1)
end if





  IF (STENCIL_IO.EQ.1)THEN
   call stenprint(n)
  END IF

 
if (fastest.eq.1)then
call SOLEX_ALLOC(N)
if (rungekutta.ge.10)then
if (dimensiona.eq.3)then
CALL direct_side(n)
ELSE
CALL direct_side2d(n)
END IF
end if
end if

CALL MPI_BARRIER(MPI_COMM_WORLD,IERROR)



CALL EXCH_CORD3(N)
if (iperiodicity.eq.1)then
CALL READ_INPUT_PERIOD(N,XMPIELRANK,XMPINRANK,XMPIE,XMPIN,IELEM,INODE,IMAXN,IMAXE,IBOUND,IMAXB,XMPINNUMBER,SCALER)
end if
 deallocate(inoder2)

CALL MPI_BARRIER(MPI_COMM_WORLD,IERROR)

if ((fastest.ne.1).and.(ischeme.ge.2))then
call walls_higher(n)
end if
 


CALL MPI_BARRIER(MPI_COMM_WORLD,IERROR)
   CPUX2(1) = MPI_Wtime()
  
  


  CALL MPI_BARRIER(MPI_COMM_WORLD,IERROR)
 if (n.eq.0)  then
   CPUX3(1) = MPI_Wtime()
 WRITE(100+N,*)"TIMEI_8",CPUX3(1)-CPUX1(1)
end if
  
  					!$OMP MASTER
				  IF (N.EQ.0)THEN
				  OPEN(63,FILE='history.txt',FORM='FORMATTED',STATUS='old',ACTION='WRITE',POSITION='APPEND')
				  WRITE(63,*)"started prestoring reconstruction matrices 1"
				  CPUX3(1) = MPI_Wtime()
				  WRITE(63,*)"time7=",CPUX3(1)-cpux1(1)
				  CLOSE(63)
				  END IF
				  !$OMP END MASTER
  

 if ((fastest.ne.1).and.(ischeme.ge.2))then

call PRESTORE_1(N)
end if




					!$OMP MASTER
				  IF (N.EQ.0)THEN
				  OPEN(63,FILE='history.txt',FORM='FORMATTED',STATUS='old',ACTION='WRITE',POSITION='APPEND')
				  WRITE(63,*)"started prestoring reconstruction matrices 1"
				  CPUX3(1) = MPI_Wtime()
				  WRITE(63,*)"time8=",CPUX3(1)-cpux1(1)
				  CLOSE(63)
				  END IF
				  !$OMP END MASTER

 



CALL DEALCORDINATES2


CALL MPI_BARRIER(MPI_COMM_WORLD,IERROR)


 



   if ((fastest.ne.1).and.(ischeme.ge.2))then
!    call check_fs
  CALL MEMORY11
CALL LOCALSDEALLOCATION(N,XMPIELRANK,ILOCALSTENCIL,TYPESTEN,NUMNEIGHBOURS)
CALL DEALLOCATEMPI2(N)
CALL DEALCORDINATES1(N,IEXCORDR,IEXCORDS)
 end if

CALL MPI_BARRIER(MPI_COMM_WORLD,IERROR)
  



IF (ISCHEME.GE.2)THEN

CALL LOCAL_DELALLOCATION(ILOCAL_ELEM)
CALL LOCAL_DNALLOCATION(ILOCAL_NODE)


END IF

				
  
  IF (TURBULENCE.EQ.1)THEN
    if (dimensiona.eq.3)then
    call WallDistance(N,ielem,imaxe,XMPIELRANK)
    else
    call WallDistance2d(N,ielem,imaxe,XMPIELRANK)
    end if
  END IF

  
!$OMP PARALLEL DEFAULT(SHARED)
  CALL share_ALLOCATION(N)
  call local_reconallocation5(n)
!$OMP END PARALLEL

CALL MPI_BARRIER(MPI_COMM_WORLD,IERROR)


				  !$OMP MASTER
				  IF (N.EQ.0)THEN
				  OPEN(63,FILE='history.txt',FORM='FORMATTED',STATUS='old',ACTION='WRITE',POSITION='APPEND')
				  WRITE(63,*)"started prestoring geometry information"
				  CPUX3(1) = MPI_Wtime()
				  WRITE(63,*)"time9=",CPUX3(1)-cpux1(1)
				  CLOSE(63)
				  END IF
				  !$OMP END MASTER

CALL MPI_BARRIER(MPI_COMM_WORLD,IERROR)
 if (n.eq.0)then  
   CPUX3(1) = MPI_Wtime()
  WRITE(100+N,*)"TIMEI_9",CPUX3(1)-CPUX1(1)
end if

  if (ischeme.lt.2)then
  IF (DIMENSIONA.EQ.3)THEN
  
  do iconsi=1,xmpielrank(n)
  call CHECKGRADS(N,ICONSI)
 call FIND_ROT_ANGLES(N,ICONSI)
  end do
  ELSE
   do iconsi=1,xmpielrank(n)
  call CHECKGRADS2D(N,ICONSI)
 call FIND_ROT_ANGLES2D(N,ICONSI)
  end do
  

  
  
  END IF
  end if
	  !$OMP MASTER
				  IF (N.EQ.0)THEN
				  OPEN(63,FILE='history.txt',FORM='FORMATTED',STATUS='old',ACTION='WRITE',POSITION='APPEND')
				  WRITE(63,*)"allocating solution  and flux variables"
				  CPUX3(1) = MPI_Wtime()
				  WRITE(63,*)"time10=",CPUX3(1)-cpux1(1)
				  CLOSE(63)
				  END IF
				  !$OMP END MASTER


  CALL U_C_ALLOCATION(N,XMPIELRANK,U_C,U_E,ITESTCASE,U_CT)
  
 
  
   if (dimensiona.eq.3)then
   CALL INITIALISE (N)
   
   else
   CALL INITIALISE2d(N)
   end if
 
  IF (RESTART.GT.0)THEN
   CALL REST_READ(N)
   
   END IF
 
 


 CALL GLOBALDEA2(XMPIL,XMPIE)

 CALL SUMFLUX_ALLOCATION(N)

 
 

 
 
 if (rungekutta.GE.10)then
 
  call IMPALLOCATE(N)
 
  
 end if
! 
! 
! 
! ! !----------------------------------------------------------------!
! ! !		ADVANCEMENT OF SOLUTION IN TIME			 !
! ! !           DIFFERENT OPTIONS AVAILABLE DEPENDING ON SCHEME	 !
! ! !----------------------------------------------------------------!

 CALL MPI_BARRIER(MPI_COMM_WORLD,IERROR)
   CPUX6(1)=MPI_WTIME()
   
  CALL TIMERS(N,CPUX1,CPUX2,CPUX3,CPUX4,CPUX5,CPUX6,TIMEX1,TIMEX2,TIMEX3,TIMEX4,TIMEX5,TIMEX6)


!$OMP PARALLEL DEFAULT(SHARED)
  CALL MEMORY2
!$OMP END PARALLEL
 




  IF (sTATISTICS.EQ.1)THEN
  IF (N.EQ.0)THEN
  
  
    OPEN(133,FILE='STATISTICS.txt',FORM='FORMATTED',STATUS='REPLACE',ACTION='WRITE')
    WRITE(133,*)"T_TIME,T_COMM,T_HALO,T_BOUND,T_COMP,T_RECON,T_FLUX,T_UPDATE,GFLOPS"
    CLOSE(133)
    
  
  
  END IF
  END IF
  
 


 
 IF (FASTEST_Q.EQ.1)THEN
 CALL MEMORY_FAST(N)
 END IF

 call NEW_ARRAYS(N)


CALL MPI_BARRIER(MPI_COMM_WORLD,IERROR)

  call EXCH_CORDS_opt(N)
  if (dimensiona.eq.3)then
   CALL LOCAL_RECONALLOCATION4(N)
   else
   CALL LOCAL_RECONALLOCATION42d(N)
   end if
   
   
   if (fastest.ne.1)then
 CALL EXCHANGE_HIGHER_pre(N)
    end if
  CPUX3(1) = MPI_Wtime()
!  CALL CPU_TIME(CPUX3(1))

  if (n.eq.0)  WRITE(100+N,*)CPUX3(1)-CPUX2(1)

   CPUX2(1) = MPI_Wtime()

 if (n.eq.0)print*,"UCNS3D Running"
   
   if (dimensiona.eq.3)then
!$OMP PARALLEL DEFAULT(SHARED)
CALL TIME_MARCHING(N)
!$OMP END PARALLEL

else
!$OMP PARALLEL DEFAULT(SHARED)
CALL TIME_MARCHING2(N)
!$OMP END PARALLEL

end if


CALL MPI_BARRIER(MPI_COMM_WORLD,IERROR)
  CPUX3(1) = MPI_Wtime()

  if (n.eq.0)  WRITE(100+N,*)"TOTAL TIME TAKEN=",CPUX3(1)-CPUX2(1),"SECONDS"

CALL MPI_BARRIER(MPI_COMM_WORLD,IERROR)
CALL MPI_FINALIZE(IERROR)
STOP


END PROGRAM UCNS3D
