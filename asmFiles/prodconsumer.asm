#----------------------------------
# Producer Consumer parallel algorithm
# Sheik Dawood, Everett Berry
#---------------------------------

######### PRODUCER P0 #########
  org   0x0000
  ori   $sp, $zero, 0x3ffc
  jal   mainp0
  halt
#-producer-------------------------------------------------


######### CONSUMER P1 #########
  org   0x200
  ori   $sp, $zero, 0x7ffc
  jal   mainp1
  halt
#-consumer-------------------------------------------------

######### MIN and MAX #########
# REGISTERS a0-1,v0,t0
# a0 = a
# a1 = b
# v0 = result

#-max (a0=a,a1=b) returns v0=max(a,b)--------------
max:
  push  $ra
  push  $a0
  push  $a1
  or    $v0, $0, $a0
  slt   $t0, $a0, $a1
  beq   $t0, $0, maxrtn
  or    $v0, $0, $a1
maxrtn:
  pop   $a1
  pop   $a0
  pop   $ra
  jr    $ra

#-min (a0=a,a1=b) returns v0=min(a,b)--------------
min:
  push  $ra
  push  $a0
  push  $a1
  or    $v0, $0, $a0
  slt   $t0, $a1, $a0
  beq   $t0, $0, minrtn
  or    $v0, $0, $a1
minrtn:
  pop   $a1
  pop   $a0
  pop   $ra
  jr    $ra
#-min-max-------------------------------------------------


######### CRC #########
#REGISTERS
#at $1 at
#v $2-3 function returns
#a $4-7 function args
#t $8-15 temps
#s $16-23 saved temps (callee preserved)
#t $24-25 temps
#k $26-27 kernel
#gp $28 gp (callee preserved)
#sp $29 sp (callee preserved)
#fp $30 fp (callee preserved)
#ra $31 return address

# USAGE random0 = crc(seed), random1 = crc(random0)
#       randomN = crc(randomN-1)
#------------------------------------------------------
# $v0 = crc32($a0)
crc32:
  lui $t1, 0x04C1
  ori $t1, $t1, 0x1DB7
  or $t2, $0, $0
  ori $t3, $0, 32

l1:
  slt $t4, $t2, $t3
  beq $t4, $zero, l2

  srl $t4, $a0, 31
  sll $a0, $a0, 1
  beq $t4, $0, l3
  xor $a0, $a0, $t1
l3:
  addiu $t2, $t2, 1
  j l1
l2:
  or $v0, $a0, $0
  jr $ra
#-crc-----------------------------------------------------


######### DIVIDE #########
# REGISTERS a0-1,v0-1,t0
# a0 = Numerator
# a1 = Denominator
# v0 = Quotient
# v1 = Remainder

#-divide(N=$a0,D=$a1) returns (Q=$v0,R=$v1)--------
divide:               # setup frame
  push  $ra           # saved return address
  push  $a0           # saved register
  push  $a1           # saved register
  or    $v0, $0, $0   # Quotient v0=0
  or    $v1, $0, $a0  # Remainder t2=N=a0
  beq   $0, $a1, divrtn # test zero D
  slt   $t0, $a1, $0  # test neg D
  bne   $t0, $0, divdneg
  slt   $t0, $a0, $0  # test neg N
  bne   $t0, $0, divnneg
divloop:
  slt   $t0, $v1, $a1 # while R >= D
  bne   $t0, $0, divrtn
  addiu $v0, $v0, 1   # Q = Q + 1
  subu  $v1, $v1, $a1 # R = R - D
  j     divloop
divnneg:
  subu  $a0, $0, $a0  # negate N
  jal   divide        # call divide
  subu  $v0, $0, $v0  # negate Q
  beq   $v1, $0, divrtn
  addiu $v0, $v0, -1  # return -Q-1
  j     divrtn
divdneg:
  subu  $a0, $0, $a1  # negate D
  jal   divide        # call divide
  subu  $v0, $0, $v0  # negate Q
divrtn:
  pop $a1
  pop $a0
  pop $ra
  jr  $ra
#-divide--------------------------------------------


######### LOCKS #########
# pass in an address to lock function in argument register 0
# returns when lock is available
lock:
aquire:
  ll    $t0, 0($a0)         # load lock location
  bne   $t0, $0, aquire     # wait on lock to be open
  addiu $t0, $t0, 1
  sc    $t0, 0($a0)
  beq   $t0, $0, lock       # if sc failed retry
  jr    $ra


# pass in an address to unlock function in argument register 0
# returns when lock is free
unlock:
  sw    $0, 0($a0)
  jr    $ra
#-locks-------------------------------------------------


######### MAIN P0 #########
mainp0:
  ori   $s0, $zero, 256          # loop total
  ori   $s1, $zero, 0            # loop counter
  ori   $t3, $zero, 0            # test starting val for stack
  ori   $t4, $zero, 10           # stack full value
  ori   $t5, $zero, s_count      # size of stack
  ori   $t7, $zero, s_ptr        # stack pointer

loop0:
  # get lock
loop0_lock:
  push  $ra                      # save return addr
  ori   $a0, $zero, s_lock       # move lock to arg register
  jal   lock                     # acquire lock

  # have lock
  lw    $t6, 0($t5)              # get stack size
  beq   $t6, $t4, stack_full     # if stack size == 9 -> stack_full
  addi  $t3, $t3, 1              # incr value to push to stack
  lw    $t6, 0($t7)              # get stack ptr
  addi  $t6, $t6, 4              # increment stack ptr
  sw    $t3, 0($t6)              # store onto stack
  sw    $t6, 0($t7)              # update stack ptr
  lw    $t6, 0($t5)              # get stack size
  addi  $t6, $t6, 1              # incr stack size
  sw    $t6, 0($t5)              # update stack size

  # release lock
  ori   $a0, $zero, s_lock       # move lock to arg reg
  jal   unlock                   # release lock
  pop   $ra                      # get return addr

  addi  $s1, $s1, 1              # incr loop ctr
  bne   $s1, $s0, loop0          # end loop0

  # end main p0
  jr    $ra

# when stack is full - unlock and give p1 a chance to acquire
# WARNING: infinite loop if nothing is being popped
stack_full:
  ori   $a0, $zero, s_lock       # move lock to arg reg
  jal   unlock                   # release lock
  pop   $ra                      # get return addr
  j     loop0_lock               # try again for stack
#-mainp0-------------------------------------------------


######### MAIN P1 #########
mainp1:
  ori   $s0, $zero, 257          # loop total
  ori   $s1, $zero, 0            # loop counter
  ori   $s2, $zero, 0            # running sum
  ori   $s4, $zero, s_count
  ori   $s5, $zero, s_ptr
  ori   $s6, $zero, s_top
  lw    $s3, 0($s6)

loop1:
  # get lock
  push  $ra                      # save return addr
  ori   $a0, $zero, s_lock       # move lock to arg register
  jal   lock                     # acquire lock

  # have lock
  lw    $t5, 0($s5)              # get stack ptr
  lw    $t6, 0($t5)              # get val at top of stack
  add   $s2, $s2, $t6            # add val to running total
  beq   $s3, $t5, p1_unlock      # don't decrement if stack empty
  lw    $t6, 0($s4)              # get stack size
  addi  $t6, $t6, -1             # dec stack size
  sw    $t6, 0($s4)              # update stack size
  addi  $t5, $t5, -4             # dec stack ptr
  sw    $t5, 0($s5)              # update stack ptr

p1_unlock:
  ori   $a0, $zero, s_lock       # move lock to arg reg
  jal   unlock                   # release lock
  pop   $ra                      # get return addr

  addi  $s1, $s1, 1              # incr loop ctr
  bne   $s1, $s0, loop1          # end loop1

  jr    $ra
#-mainp1-------------------------------------------------


######### STACK #########
org 0xA00
s_lock:
  cfw   0
s_count:
  cfw   0
s_ptr:
  cfw   stack
stack:
  cfw   0
  cfw   0
  cfw   0
  cfw   0
  cfw   0
  cfw   0
  cfw   0
  cfw   0
  cfw   0
  cfw   0
s_top:
  cfw   stack
#-stack-------------------------------------------------
