(define
 (problem pfile_10_10)
 (:domain robot)
 (:objects o1 o2 o3 o4 o5 o6 o7 o8 o9 o10 - PACKAGE
           c r1 r2 r3 r4 r5 r6 r7 r8 r9 r10 - ROOM
           d24 d34 d35 d310 d15 d610 d710 d78 d89 d04 - ROOMDOOR)
 (:init
  (rloc c)
  (armempty)
  (door c r4 d04)
  (door r1 r5 d15)
  (door r2 r4 d24)
  (door r3 r4 d34)
  (door r3 r5 d35)
  (door r3 r10 d310)
  (door r4 c d04)
  (door r4 r2 d24)
  (door r4 r3 d34)
  (door r5 r1 d15)
  (door r5 r3 d35)
  (door r6 r10 d610)
  (door r7 r8 d78)
  (door r7 r10 d710)
  (door r8 r7 d78)
  (door r8 r9 d89)
  (door r9 r8 d89)
  (door r10 r3 d310)
  (door r10 r6 d610)
  (door r10 r7 d710)
  (closed d24)
  (closed d34)
  (closed d35)
  (closed d310)
  (closed d610)
  (closed d710)
  (closed d04)
  (in o1 r8)
  (in o2 r10)
  (in o3 r2)
  (in o4 r2)
  (in o5 r8)
  (in o6 r3)
  (in o7 r2)
  (in o8 r3)
  (in o9 r1)
  (in o10 r4))
 (:goal (and
         (in o1 r2)
         (in o2 r10)
         (in o3 r3)
         (in o4 r9)
         (in o5 r10)
         (in o6 r9)
         (in o7 r8)
         (in o8 r4)
         (in o9 r1)
         (in o10 r4))))