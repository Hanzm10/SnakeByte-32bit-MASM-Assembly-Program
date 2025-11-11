.386
.model flat, stdcall
.stack 4096
ExitProcess PROTO, dwExitCode: DWORD
INCLUDE Irvine32.inc

.data
; wall character and wall representation
wallChar EQU 219
; create a string of wall characters for drawing horizontal walls
xWall BYTE 70 DUP(wallChar),0

; Variables for DrawScoreboard PROC
strScore BYTE "Score: ",0
score WORD 0

; Variables for YouDied PROC
strTryAgain BYTE "Try Again?  1=yes, 0=no",0
invalidInput BYTE "invalid input",0
strPoints BYTE " point(s)",0
blank BYTE "                                     ",0
titleName BYTE "SNAKEBYTE",0

; New death reason strings
strWallDeath  BYTE "You hit the wall!",0
strBodyDeath  BYTE "You hit your own body!",0
strCollision  BYTE "You hit the hazard block!",0


; Variables for FinishedGame PROC
strFinishedGame BYTE "Congratulations! You finished the game!",0
strNoMoreSpace BYTE "There's no more available space to place coin!",0

; Snake representation
snake BYTE ">", 104 DUP("*")
snakeBodyInit DWORD 4		; initial length of snake body (excluding head)

; Arrays to hold the x and y positions of each snake segment
xPos BYTE 45,44,43,42,41, 500 DUP(wallChar)
yPos BYTE 15,15,15,15,15, 500 DUP(wallChar)

; Wall positions
xPosWall BYTE 25,25,95,95		;position of upperLeft, lowerLeft, upperRight, lowerRignt wall 
yPosWall BYTE 5,25,5,25

; Coin position
xCoinPos BYTE ?
yCoinPos BYTE ?

; Input handling
inputChar BYTE ?					; + denotes the start of the game
lastInputChar BYTE ?				

; Speed control
baseSpeed   DWORD 120        ; starting delay in milliseconds
topSpeed    DWORD 10         ; fastest possible delay
speed       DWORD ?          ; current speed (changes dynamically)
strSpeed    BYTE "Speed: ",0 ; optional display label

; Hazard block variables
hazardActive   BYTE 0      ; 0 = none, 1 = drawn and active
hazardOrient   BYTE 0      ; 0 = horizontal, 1 = vertical
hazardX        BYTE 0      ; base X
hazardY        BYTE 0      ; base Y
HAZARD_LEN     EQU 15
HAZARD_CLOSE_DIST EQU 6  

; Multiple hazard blocks
MAX_HAZARDS   EQU 5
hazCount      BYTE 0
hazXs         BYTE MAX_HAZARDS DUP(0)
hazYs         BYTE MAX_HAZARDS DUP(0)
hazOrients    BYTE MAX_HAZARDS DUP(0)   ; 0 = horiz, 1 = vert

.code
main PROC
	call DrawWall			;draw walls

	mov eax, baseSpeed      ; puts the base speed which is 120 into eax
	mov speed, eax          ; puts the 120(now in eax) to speed variable

	call DrawScoreboard		;draw scoreboard

    mov esi,0               ; initialize index to 0
	mov ecx,5               ; loop 5 times to draw initial snake

drawSnake:
	call DrawPlayer			;draw snake(start with 5 units)
	inc esi                 ; increment index to draw next character(used by DrawPlayer PROC)
    loop drawSnake          ; loop until ecx is 0 to draw all 5 characters

	call CreateRandomCoin   ; generate random coin position
	call DrawCoin			;set up finish

	gameLoop::
		mov dl,106						;move cursor to coordinates
		mov dh,1
		call Gotoxy

		; get user key input
		call ReadKey
        jz noKey						;jump if no key is entered
		mov bl, inputChar
		mov lastInputChar, bl
		mov inputChar,al				;assign variables

		noKey:
		cmp inputChar,"x"	
		je exitgame						;exit game if user input x

		cmp inputChar,"w"
		je checkTop

		cmp inputChar,"s"
		je checkBottom

		cmp inputChar,"a"
		je checkLeft

		cmp inputChar,"d"
		je checkRight
		jne gameLoop					; reloop if no meaningful key was entered


		; check whether can continue moving
		checkBottom:	
		mov snake[0], 'v'
		cmp lastInputChar, "w"
		je dontChgDirection		;cant go down immediately after going up
		mov cl, yPosWall[1]
		dec cl					;one unit ubove the y-coordinate of the lower bound
		cmp yPos[0],cl
		jl moveDown
		je diedWall					;die if crash into the wall

		checkLeft:		
		mov snake[0], '<'
		cmp lastInputChar, "+"	;check whether its the start of the game
		je dontGoLeft
		cmp lastInputChar, "d"
		je dontChgDirection
		mov cl, xPosWall[0]
		inc cl
		cmp xPos[0],cl
		jg moveLeft
		je diedWall					; check for left	

		checkRight:		
		mov snake[0], '>'
		cmp lastInputChar, "a"
		je dontChgDirection
		mov cl, xPosWall[2]
		dec cl
		cmp xPos[0],cl
		jl moveRight
		je diedWall					; check for right	

		checkTop:		
		mov snake[0], '^'
		cmp lastInputChar, "s"
		je dontChgDirection
		mov cl, yPosWall[0]
		inc cl
		cmp yPos,cl
		jg moveUp
		je diedWall			; check for up	
		
		moveUp:		
		mov eax, speed		;slow down the moving
		;add eax, speed
		call delay

		mov esi, 0			;index 0(snake head)
		call UpdatePlayer
		
		mov ah, yPos[esi]	
		mov al, xPos[esi]	;alah stores the pos of the snake's next unit 

		dec yPos[esi]		;move the head up

		call DrawPlayer		

		call DrawBody

		mov esi, 0	;added
		call CheckSnake

		
		moveDown:			;move down
		mov eax, speed
		call delay

		mov esi, 0
		call UpdatePlayer

		mov ah, yPos[esi]	
		mov al, xPos[esi]

		inc yPos[esi]

		call DrawPlayer

		call DrawBody

		mov esi, 0	 ;added
		call CheckSnake


		moveLeft:			;move left
		mov eax, speed
		call delay

		mov esi, 0
		call UpdatePlayer

		mov ah, yPos[esi]	
		mov al, xPos[esi]

		dec xPos[esi]

		call DrawPlayer

		call DrawBody

		mov esi, 0	 ;added
		call CheckSnake


		moveRight:			;move right
		mov eax, speed
		call delay

		mov esi, 0
		call UpdatePlayer

		mov ah, yPos[esi]	
		mov al, xPos[esi]

		inc xPos[esi]

		call DrawPlayer

		call DrawBody

		mov esi, 0	;added
		call CheckSnake

	; getting points
		checkcoin::
		mov esi,0
		mov bl,xPos[0]
		cmp bl,xCoinPos
		jne gameloop			;reloop if snake is not intersecting with coin
		mov bl,yPos[0]
		cmp bl,yCoinPos
		jne gameloop			;reloop if snake is not intersecting with coin

		call EatingCoin			;call to update score, append snake and generate new coin	

jmp gameLoop					;reiterate the gameloop


	dontChgDirection:		;dont allow user to change direction
	mov inputChar, bl		;set current inputChar as previous
	jmp noKey				;jump back to continue moving the same direction 

	dontGoLeft:				;forbids the snake to go left at the begining of the game
	mov	inputChar, "+"		;set current inputChar as "+"
	jmp gameLoop			;restart the game loop

	diedWall::
	call YouDiedWall          ; wall death handler

	diedBody::
	call YouDiedBody          ; body death handler
	 
	playagn::			
	call ReinitializeGame			;reinitialise everything
	
	exitgame::
	exit
INVOKE ExitProcess,0
main ENDP



DrawWall PROC
    mov eax, red + (black * 16)     ; puts red color value in eax because SetTextColor uses eax
    call SetTextColor       ; set text color to red

    ; Upper
    mov dl, xPosWall[0]     ; puts the value of the first element of xPosWall into dl(which is 10)
    mov dh, yPosWall[0]     ; puts the value of the first element of yPosWall into dh(which is 5)
    call Gotoxy     ; move cursor to (10,5)
    mov edx, OFFSET xWall   ; puts the xWall(which is a duplicate of WallChar for 100x) into edx
    call WriteString    ; writes the wall horizontally

    ; Lower
    mov dl, xPosWall[1]     ; puts the value of the second element of xPosWall into dl(which is 10)
    mov dh, yPosWall[1]     ; puts the value of the second element of yPosWall into dh(which is 25)
    call Gotoxy     ; move cursor to (10,25)
    mov edx, OFFSET xWall   ; puts the xWall(which is a duplicate of WallChar for 100x) into edx
    call WriteString    ; writes the wall horizontally

    ; Right vertical (use local endY = yPosWall[1])
    mov dl, xPosWall[2]     ; puts the value of the third element of xPosWall into dl(which is 110)
    mov dh, yPosWall[2]     ; puts the value of the third element of yPosWall into dh(which is 5)
    mov al, wallChar    ;puts wallChar into al because WriteChar uses al
    mov bl, yPosWall[1]       ; puts the value of the second element of yPosWall into bl(which is 25)
L11:
    call Gotoxy     ; move cursor to (110, 5)
    call WriteChar  ; writes the wallChar 
    inc dh      ; increment dh to move down vertically
    cmp dh, bl  ; compares dh value(that starts with 5, now 6 because of increment) to bl(which is 25)
    jle L11     ; It will jump back to L11 if dh is less than or equal to bl(25)

    ; Left vertical
    mov dl, xPosWall[0]     ; puts the value of the first element of xPosWall into dl(which is 10)
    mov dh, yPosWall[0]     ; puts the value of the first element of yPosWall into dh(which is 5)
    mov al, wallChar        ; puts wallChar into al because WriteChar uses al
L12:
    call Gotoxy     ; move cursor to (10, 5)
    call WriteChar  ; writes the wallChar
    inc dh      ; increment dh to move down vertically
    cmp dh, yPosWall[1]  ; compares dh value(that starts with 5, now 6 because of increment) to yPosWall[1](which is 25)
    jle L12     ; It will jump back to L12 if dh is less than or equal to yPosWall[1](25)

    mov eax, white + (black * 16)  ; puts white color value in eax because SetTextColor uses eax
    call SetTextColor        ; reset text color to white on black
    ret     ; return from procedure
DrawWall ENDP


DrawScoreboard PROC				;procedure to draw scoreboard

    mov eax, yellow + (black*16)     ; puts white color value in eax because SetTextColor uses eax
	call SetTextColor			; reset text color to white on black

    mov dl, 56		; puts 52 in dl to set x coordinate for the separator
    mov dh, 2		; puts 3 in dh to set y coordinate for the separator
    call Gotoxy     ; move cursor to (52,3)
    mov edx, OFFSET titleName    ; puts the string "SNAKEBYTE" into edx
    call WriteString    ; writes "SNAKEBYTE"

	mov dl, xPosWall[0]        ; puts 10 in dl to set x coordinate
	mov dh,4        ; puts 4 in dh to set y coordinate
	call Gotoxy     ; move cursor to (10,4)

	mov edx,OFFSET strScore     ; puts the string "Score: " into edx
	call WriteString    ; writes "Score: "

	mov ax, score       ; puts score value into ax
	call WriteInt		; writes the score value after "Score: "

    call ShowSpeed      ; display speed level at the far right side

    mov eax, white + (black*16)     ; puts white color value in eax because SetTextColor uses eax
	call SetTextColor			; reset text color to white on black

	ret         ;return from procedure
DrawScoreboard ENDP

ShowSpeed PROC
    mov dl, xPosWall[2] ; puts 110 into dl to set x coordinate for speed display
	sub dl, 8        ; adjust left by 8 for spacing
    mov dh, 4   ; set y coordinate for speed display
    call Gotoxy     ; move cursor to (102,4)

    mov edx, OFFSET strSpeed    ; puts "Speed: " into edx because WriteString uses edx
    call WriteString        ; writes "Speed: "
    
    ; Calculate speed level: (baseSpeed - currentSpeed) / 10
    ; This shows 0 at start, then 1, 2, 3... as you get faster
    mov eax, baseSpeed        ; puts the value of the baseSpeed(120) into eax
    sub eax, speed            ; subs the current speed from baseSpeed
    mov ecx, 10         ; puts 10 into ecx for division
    xor edx, edx        ; clear edx before division
    div ecx                   ; divides eax by ecx(10), so the result is not big like 120, but smaller, starting from 0,1,2...
    call WriteInt             ; Writes the speed level from eax
    
    ret     ;return from procedure
ShowSpeed ENDP

UpdateSpeed PROC
    ; Update speed every 3 points
    movzx eax, score          ; Load score (now WORD)
    mov ecx, 3
    xor edx, edx
    div ecx                   ; eax = score / 3, edx = remainder
    cmp edx, 0
    jne skipUpdate            ; Only update when score is divisible by 5

    ; Decrease delay by 10ms (makes game faster)
    mov eax, speed
    cmp eax, topSpeed         ; Check BEFORE subtracting
    jle skipUpdate            ; Already at max speed, don't go lower
    
    sub eax, 10               ; Reduce delay = increase speed
    mov speed, eax

skipUpdate:
    ret
UpdateSpeed ENDP


DrawPlayer PROC			    ; draw player at (xPos,yPos)

	push eax                ; pushes the value of eax(the current color) onto the stack
	push edx                ; pushes the value of edx(the current position) onto the stack
	
	mov eax, lightGreen + (black * 16)  ; puts light green color value in eax
	call SetTextColor       ; set text color: green on black 

	mov dl,xPos[esi]        ; puts the x position of the snake segment at index esi into dl
	mov dh,yPos[esi]        ; puts the y position of the snake segment at index esi into dh
	call Gotoxy             ; move cursor to (xPos, yPos)

	mov dl, al              ; puts al value() into dl to temporarily save it
	mov al, snake[esi]      ; puts the character representing the snake segment at index esi into al because WriteChar uses al
	call WriteChar          ; writes the character at (xPos, yPos)
	mov al, dl	            ; restores al from dl

	mov eax, white + (black*16) ; puts white color value in eax because SetTextColor uses eax
	call SetTextColor		; reset text color to white on black
		
	pop edx                 ; pop the previous position from the stack into edx
	pop eax                 ; pop the previous color from the stack into eax
	ret
DrawPlayer ENDP

UpdatePlayer PROC		    ; erase player the old position of the snake segment

	mov dl, xPos[esi]       ; puts the x position of the snake segment at index esi into dl
	mov dh,yPos[esi]        ; puts the y position of the snake segment at index esi into dh
	call Gotoxy             ; move cursor to (xPos, yPos)
	mov dl, al			    ;temporarily save al in dl
	mov al, " "             ; puts whitespace into al to erase the character
	call WriteChar          ; writes whitespace at (xPos, yPos)
	mov al, dl              ; restores al from dl
	ret                     ; return from procedure
UpdatePlayer ENDP

DrawCoin PROC				;procedure to draw coin
	mov eax,brown + (cyan * 16) ; puts brown color value in eax because SetTextColor uses eax
	call SetTextColor		;set color to brown with cyan background for coin
	mov dl,xCoinPos         ; puts the x position of the coin into dl
	mov dh,yCoinPos         ; puts the y position of the coin into dh
	call Gotoxy             ; move cursor to (xCoinPos, yCoinPos)
	mov al, '0'             ; puts character '0' into al because WriteChar uses al
	call WriteChar          ; writes '0' at (xCoinPos, yCoinPos)
	mov eax,white + (black * 16); puts white color value in eax because SetTextColor uses eax	
	call SetTextColor       ;reset color to black and white 
	ret
DrawCoin ENDP

CreateRandomCoin PROC
    ; Compute interior bounds (exclusive of walls)
    mov dl, xPosWall[0]    ; puts first element of xPosWall(10) into dl
    inc dl                 ; increment dl to get leftInner to avoid generating on wall
    mov dh, xPosWall[2]    ; puts third element of xPosWall(110) into dh
    dec dh                 ; decrement dh to get rightInner to avoid generating on wall
    mov bl, yPosWall[0]    ; puts first element of yPosWall(5) into bl
    inc bl                 ; increment bl to get topInner to avoid generating on wall
    mov bh, yPosWall[1]    ; puts second element of yPosWall(25) into bh
    dec bh                 ; decrement bh to get bottomInner to avoid generating on wall


    ; width  = rightInner - leftInner + 1  (store in ESI)
    movzx esi, dh          ;puts rightInner into esi to calculate width
    movzx eax, dl          ; puts leftInner into eax to calculate width
    sub esi, eax           ; subtract leftInner from rightInner
    inc esi                ; increment esi so that width is inclusive

    ; height = bottomInner - topInner + 1  (store in EDI)
    movzx edi, bh          ; puts bottomInner into edi to calculate height
    movzx eax, bl          ; puts topInner into eax to calculate height
    sub edi, eax           ; subtract topInner from bottomInner
    inc edi                ; increment edi so that height is inclusive

    ; attempts = width * height (store in EBP)
    mov eax, esi           ; puts esi(width) into eax so we can multiply
    imul eax, edi          ; multiply eax(width) by edi(height) and store result in eax
    mov ebp, eax           ; puts eax(total unique cells within the walls) into ebp 
    mov ecx, ebp           ; puts ebp to ecx to use as attempts counter

CR_try_random:
    ; Random X
    push edx               ; save boundaries
    push ebx
    mov eax, esi           ; puts esi(width) into eax so we can get random in that range(RandomRange only accepts eax)
    call RandomRange       ; picks random number in range 0..width-1 and stores in EAX
    pop ebx                ; restore boundaries
    pop edx
    add al, dl             ; adds leftInner so that random is within inner bounds
    mov xCoinPos, al       ; store result in xCoinPos

    ; Random Y
    push edx
    push ebx
    mov eax, edi           ; puts edi(height) into eax so we can get random in that range(RandomRange only accepts eax)
    call RandomRange       ; picks random number in range 0..height-1 and stores in EAX
    pop ebx
    pop edx
    add al, bl             ; adds topInner so that random is within inner bounds
    mov yCoinPos, al       ; store result in yCoinPos

    ; Check snake overlap
    mov esi, 0  ; initialize index to 0
    mov edx, snakeBodyInit ; initial segments
    movzx eax, score
    add edx, eax
CR_scan_snake:
    mov al, xPos[esi]
    cmp al, xCoinPos
    jne CR_next_seg
    mov al, yPos[esi]
    cmp al, yCoinPos
    je CR_retry_random

CR_next_seg:
    inc esi
    cmp esi, edx
    jle CR_scan_snake

    ; Check hazard overlap (ALL existing hazards)
    movzx edi, hazCount
    test edi, edi
    jz CR_success
    push ecx                 ; preserve attempts counter
    xor esi, esi             ; hazard index
CR_hz_loop:
    xor cl, cl               ; cell index
CR_hz_cell_loop:
    mov al, hazXs[esi]
    mov ah, hazYs[esi]
    mov bl, hazOrients[esi]
    cmp bl, 0
    jne CR_hz_vert
    add al, cl               ; horiz cell
    jmp CR_hz_have
CR_hz_vert:
    add ah, cl               ; vert cell
CR_hz_have:
    cmp al, xCoinPos
    jne CR_hz_next_cell
    cmp ah, yCoinPos
    je CR_hz_hit_all
CR_hz_next_cell:
    inc cl
    cmp cl, HAZARD_LEN
    jl CR_hz_cell_loop
    inc esi
    cmp esi, edi
    jl CR_hz_loop
    pop ecx
    jmp CR_success

CR_hz_hit_all:
    pop ecx                  ; restore attempts before retry
    jmp CR_retry_random

CR_success:
    ret

CR_retry_random:
    dec ecx                 ; decrement attempts counter which has the total unique cells within the walls to avoid infinite loop
    jnz CR_try_random       ; if not zero, jump back to try again

    ; Fallback deterministic scan if total attempts counter is already 0
    mov ecx, ebp            ; gets the total unique cells within the walls again into ecx
    mov al, dl              ; puts dl which has a value of 10(leftInner) into al
    mov xCoinPos, al        ; puts the value of al(10) into xCoinPos
    mov al, bl              ; puts bl which has a value of 5(topInner) into al
    mov yCoinPos, al        ; puts the value of al(5) into yCoinPos

CR_scan_fallback:
    ; Snake overlap check ; almost the same as CR_scan_snake
    mov esi, 0              ; puts 0 into esi to start checking from first segment
    mov edx, snakeBodyInit  ; puts 4 into edx for initial segments
    movzx eax, score        ; puts current score into eax
    add edx, eax            ; adds eax(score) to edx(total segments) to get total snake segments
CR_fb_snake:
    mov al, xPos[esi]       ; puts the first element of xPos into al(because esi is 0)
    cmp al, xCoinPos        ; compare coin x position with snake segment x position
    jne CR_fb_next_seg      ; jump if not same(not ovelapping each other), check next segment
    mov al, yPos[esi]       ; puts y position of snake segment at index esi into al
    cmp al, yCoinPos        ; compare coin y position with snake segment y position
    je CR_fb_advance        ; if equal, overlap detected, advance coin position

CR_fb_next_seg: ; next segment
    inc esi                 ; increment index to check next segment
    cmp esi, edx            ; compare esi now incremented by 1 with total segments
    jle CR_fb_snake         ; jump back to scan next segment if index <= total segments to check all snake segments

    ; Hazard overlap check
    cmp hazardActive, 0
    je CR_fb_done
    push ecx                ; preserve scan counter
    xor cl, cl
CR_fb_h_loop:
    mov al, hazardX
    mov ah, hazardY
    cmp hazardOrient, 0
    jne CR_fb_h_vert
    add al, cl
    jmp CR_fb_h_have
CR_fb_h_vert:
    add ah, cl
CR_fb_h_have:
    cmp al, xCoinPos
    jne CR_fb_h_next
    cmp ah, yCoinPos
    je CR_fb_h_hit
CR_fb_h_next:
    inc cl
    cmp cl, HAZARD_LEN
    jb CR_fb_h_loop
    pop ecx
    jmp CR_fb_done

CR_fb_h_hit:
    pop ecx                ; restore scan counter before advancing
    jmp CR_fb_advance

CR_fb_done:
    ret

CR_fb_advance:
    ; Advance to next cell (row-major)
    mov al, xCoinPos        ; puts current xCoinPos into al
    inc al                  ; increment al to move the coin right
    cmp al, dh              ; compare new al with dh which has a value of 110(rightInner)
    jbe CR_set_x            ; jump to CR_set_x if dh is below or equal to new xCoinPos 
    mov al, dl              ; puts dl which has a value of 10(leftInner) into al
    mov xCoinPos, al        ; puts the value of al(10) into xCoinPos
    mov al, yCoinPos        ; puts current yCoinPos into al
    inc al                  ; increment al to move the coin down
    cmp al, bh              ; compare new al with bh which has a value of 25(bottomInner)
    jbe CR_set_y            ; jump to CR_set_y if bh is below or equal to new yCoinPos
    mov al, bl              ; puts bl which has a value of 5(topInner) into al
CR_set_y:
    mov yCoinPos, al        ; puts the value of al(5) into yCoinPos
    jmp CR_after_adv        ; jump to CR_after_adv
CR_set_x:
    mov xCoinPos, al
CR_after_adv:               ; after advancing position
    dec ecx                 ; decrement scan counter which has the total unique cells within the walls
    jnz CR_scan_fallback    ; if not zero, jump back to scan again
    ; If all cells overlapped (board full), notify and end game
    CALL FinishedGame

    ret
CreateRandomCoin ENDP


FinishedGame PROC
    Call ClrScr

    mov dl, 50
    mov dh, 10
    call Gotoxy
    mov edx, OFFSET strFinishedGame
    call WriteString

    mov dl, 50
    mov dh, 12
    call Gotoxy
    mov edx, OFFSET strNoMoreSpace
    call WriteString

    mov dl,	56              ; centered at (56,14)
	mov dh, 14
	call Gotoxy             ; Puts the cursor at (56,14)
	mov ax, score           ;gets the score and put it into ax
	call WriteInt           ; Writes the integer score in position (56,14)
	mov edx, OFFSET strPoints; puts the score in edx because WriteString uses edx
	call WriteString        ; Writes the string " point(s)"

	mov dl,	50              ; centered at (50,18)
	mov dh, 18
	call Gotoxy             ; Puts the cursor at (50,18)
	mov edx, OFFSET strTryAgain ;puts the value of strTryAgain into edx because WriteString uses edx
	call WriteString		; Writes the string "Play again? (1 = Yes, 0 = No): "

	retry:
	mov dh, 19              ;centered at (56,19)
	mov dl,	56      
	call Gotoxy             ; Puts the cursor at (56,19)
	call ReadInt			;get user input
	cmp al, 1               ; compared the user input which is in al with 1
	je playagn		        ; if true (jump if equal), go to playagn
	cmp al, 0               ;compared the user input which is in al with 0
	je exitgame		        ; if true (jump if equal), go to exitgame

	mov dh,	17              ; centered at (56,17)
	call Gotoxy             ; Puts the cursor at (56,17)
	mov edx, OFFSET invalidInput	; puts the value of invalidInput into edx because WriteString uses edx
	call WriteString		; Writes the string "Invalid input! Please enter 1 or 0."
	mov dl,	56              ; centered at (56,19)
	mov dh, 19     
	call Gotoxy             ; Puts the cursor at (56,19)
	mov edx, OFFSET blank	;puts the value of blank into edx because WriteString uses edx
	call WriteString        ; Writes blank(which is just whitespaces) to erase previous input
	jmp retry			    ;let the user input again by jumping back to retry

    ret
FinishedGame ENDP

CheckSnake PROC				;check whether the snake head collides w its body 
	mov al, xPos[0]         ; puts the first element of xPos which is the snake's head into al
	mov ah, yPos[0]         ; puts the first element of yPos which is the snake's head into ah
	mov esi,snakeBodyInit	; puts 4 into esi to start checking from the 5th segment of the snake
	mov ecx,1               ; puts 1 into ecx to use as loop counter
	movzx edx, score        ; puts score into edx
	add ecx, edx            ; adds edx(score) to ecx to get total segments to check

checkXposition:
	cmp xPos[esi], al		;compares the xPos of the current segment(xPos[esi]) with the head's xPos(al)
	je XposSame             ; if same, jump to XposSame to check yPos
	contloop:
	inc esi                 ; increment index to check next segment
loop checkXposition
	
    call CheckBlockCollision; Also check hazard block collision before returning to main    

	jmp checkcoin           ; reloop if no collision detected

	XposSame:				; if xpos same, check for ypos
	cmp yPos[esi], ah       ; compares the yPos of the current segment(yPos[esi]) with the head's yPos(ah)
	je diedBody					;if same, jump to died(calls YouDied PROC)
	jmp contloop            ; else, continue loop
CheckSnake ENDP


DrawBody PROC				; procedure to print body of the snake
	mov ecx, snakeBodyInit  ; initial snake body length
	add cx, score		    ; add score to to snake body get total segments
	printbodyloop:	
	inc esi				    ; increment esi to point to next unit of the snake body
	call UpdatePlayer       ; erase previous position of the unit
	mov dl, xPos[esi]       ; puts the new x position of the snake segment at index esi into dl
	mov dh, yPos[esi]	    ; puts the new y position of the snake segment at index esi into dh
	mov yPos[esi], ah       ; puts ah (which has the previous y position) into yPos[esi]
	mov xPos[esi], al	    ; puts al (which has the previous x position) into xPos[esi]
	mov al, dl              ; puts dl (new x position) into al
	mov ah,dh			    ; puts dh (new y position) into ah
	call DrawPlayer         ; draw the unit at new position
	cmp esi, ecx            ; compare esi with ecx(total segments)
	jl printbodyloop        ; if esi < ecx(total segments), jump back to printbodyloop
	ret
DrawBody ENDP




EatingCoin PROC
	; snake is eating coin
	inc score


	mov ebx, snakeBodyInit  ; initial snake body length
	movzx eax, score        ; Load score into EAX (zero-extended)
	add ebx, eax            ; add score to ebx to get new snake length
	mov esi, ebx            ; put new snake length into esi for indexing
	mov ah, yPos[esi-1]     ; put the yPos of the old tail into ah
	mov al, xPos[esi-1]	    ; put the xPos of the old tail into al
	mov xPos[esi], al		; put pos of new tail into the pos of old tail
	mov yPos[esi], ah		; put pos of new tail into the pos of old tail

	cmp xPos[esi-2], al		; compare the old tail and the unit before so we know which direction to add the new tail
	jne checky				; jump to checky if they are not on the same xAxis

	cmp yPos[esi-2], ah		; compare the old tail and the unit before so we know which direction to add the new tail
	jl incy			        ; jump to incy if less than
	jg decy                 ; jump to decy if greater than

	incy:					; inc if below
	inc yPos[esi]           ; increment yPos of new tail
	jmp continue            ; jump to continue

	decy:					;dec if above
	dec yPos[esi]           ; decrement yPos of new tail
	jmp continue

	checky:					; check yAxis
	cmp yPos[esi-2], ah		; compare the old tail and the unit before so we know which direction to add the new tail
	jl incx                 ; jump to incx if less than
	jg decx                 ; jump to decx if greater than

	incx:					; inc if right
	inc xPos[esi]			; increment xPos of new tail
	jmp continue            ; jump to continue

	decx:					; dec if left
	dec xPos[esi]           ; decrement xPos of new tail

	continue:				;add snake tail and update new coin
	call DrawPlayer		    ; draw new tail at (xPos,yPos)
	call CreateRandomCoin   ; create new coin
	call DrawCoin           ; draw new coin at (xCoinPos,yCoinPos)
	call UpdateSpeed        ; update speed based on score
	call DrawScoreboard     ; redraw scoreboard
    call MaybeSpawnHazardBlock  ; spawn hazard every 5 points
	
	ret
EatingCoin ENDP


MaybeSpawnHazardBlock PROC
    ; Trigger only on multiples of 5 (change ecx to 5 if you want that cadence)
    movzx eax, score
    mov ecx, 3
    xor edx, edx
    div ecx
    cmp edx, 0
    jne MSP_done

    ; Create candidate strictly between head and coin or randomized
    call CreateBetweenOrRandomHazardBlock
    cmp hazardActive, 0
    je MSP_done

    ; If full, evict oldest and shift left
    mov al, hazCount
    cmp al, MAX_HAZARDS
    jb MSP_space

    mov bl, 0
    call ClearHazardAt

    mov ecx, MAX_HAZARDS - 1
    mov esi, 0
MSP_shift:
    mov al, hazXs[esi+1]
    mov hazXs[esi], al
    mov al, hazYs[esi+1]
    mov hazYs[esi], al
    mov al, hazOrients[esi+1]
    mov hazOrients[esi], al
    inc esi
    loop MSP_shift
    mov hazCount, (MAX_HAZARDS - 1)

MSP_space:
    ; Append candidate stored in hazardX/Y/Orient
    movzx ebx, hazCount
    mov al, hazardX
    mov hazXs[ebx], al
    mov al, hazardY
    mov hazYs[ebx], al
    mov al, hazardOrient
    mov hazOrients[ebx], al

    mov al, hazCount
    inc al
    mov hazCount, al

    mov bl, al
    dec bl
    call DrawHazardAt
MSP_done:
    ret
MaybeSpawnHazardBlock ENDP


CreateMidpointHazardBlock PROC
    mov hazardActive, 0

    ; Head & coin positions
    movzx eax, xPos[0]        ; sx
    movzx ebx, yPos[0]        ; sy
    movzx ecx, xCoinPos       ; cx
    movzx edx, yCoinPos       ; cy

    ; dx, dy (signed in ESI/EDI)
    mov esi, ecx
    sub esi, eax              ; dx
    mov edi, edx
    sub edi, ebx              ; dy

    ; |dx| -> EAX
    mov eax, esi
    cdq
    xor eax, edx
    sub eax, edx              ; EAX = |dx|

    ; |dy| -> ECX
    mov ecx, edi
    mov edx, ecx
    sar edx, 31
    xor ecx, edx
    sub ecx, edx              ; ECX = |dy|

    ; Centers: ESI = centerX, EDI = centerY
    movzx esi, xPos[0]
    movzx edx, xCoinPos
    add esi, edx
    shr esi, 1

    movzx edi, yPos[0]
    movzx edx, yCoinPos
    add edi, edx
    shr edi, 1

    ; Orientation: vertical if |dx| >= |dy|
    cmp eax, ecx
    jl HZ_mid_horiz

    ; ---------------- Vertical ----------------
    mov hazardOrient, 1

    ; Interior bounds (32-bit)
    movzx ebx, xPosWall[0]
    inc ebx                    ; leftInner
    movzx ecx, xPosWall[2]
    dec ecx                    ; rightInner
    movzx edx, yPosWall[0]
    inc edx                    ; topInner
    movzx ebp, yPosWall[1]
    dec ebp                    ; bottomInner

    ; startY = centerY - 7, clamp to [topInner .. bottomInner-(LEN-1)]
    mov eax, edi               ; EAX = centerY
    sub eax, ((HAZARD_LEN-1)/2)
    mov ebx, ebp               ; EBX = bottomInner
    sub ebx, (HAZARD_LEN-1)    ; EBX = bottomStartMax
    cmp eax, edx
    jge V_low_ok
    mov eax, edx
V_low_ok:
    cmp eax, ebx
    jle V_hi_ok
    mov eax, ebx
V_hi_ok:
    mov hazardY, al

    ; hazardX = clamp(centerX, leftInner..rightInner)
    mov eax, esi
    movzx ebx, xPosWall[0]
    inc ebx
    movzx edx, xPosWall[2]
    dec edx
    cmp eax, ebx
    jge VX_low_ok
    mov eax, ebx
VX_low_ok:
    cmp eax, edx
    jle VX_hi_ok
    mov eax, edx
VX_hi_ok:
    mov hazardX, al
    jmp HZ_validate

    ; ---------------- Horizontal ----------------
HZ_mid_horiz:
    mov hazardOrient, 0

    ; Interior bounds (32-bit)
    movzx ebx, xPosWall[0]
    inc ebx                    ; leftInner
    movzx ecx, xPosWall[2]
    dec ecx                    ; rightInner
    movzx edx, yPosWall[0]
    inc edx                    ; topInner
    movzx ebp, yPosWall[1]
    dec ebp                    ; bottomInner

    ; startX = centerX - 7, clamp to [leftInner .. rightInner-(LEN-1)]
    mov eax, esi               ; EAX = centerX
    sub eax, ((HAZARD_LEN-1)/2)
    mov ecx, ecx               ; ECX = rightInner (already)
    sub ecx, (HAZARD_LEN-1)    ; ECX = rightStartMax
    cmp eax, ebx
    jge H_low_ok
    mov eax, ebx
H_low_ok:
    cmp eax, ecx
    jle H_hi_ok
    mov eax, ecx
H_hi_ok:
    mov hazardX, al

    ; hazardY = clamp(centerY, topInner..bottomInner)
    mov eax, edi
    cmp eax, edx
    jge HY_low_ok
    mov eax, edx
HY_low_ok:
    cmp eax, ebp
    jle HY_hi_ok
    mov eax, ebp
HY_hi_ok:
    mov hazardY, al

    ; ---------------- Validate cells ----------------
HZ_validate:
    xor ecx, ecx               ; i = 0..HAZARD_LEN-1
HZ_cell_loop3:
    mov al, hazardX
    mov ah, hazardY
    cmp hazardOrient, 0
    jne HZ_cell_v3
    add al, cl                 ; horizontal
    jmp HZ_cell_have3
HZ_cell_v3:
    add ah, cl                 ; vertical
HZ_cell_have3:
    ; Bounds check using 32-bit compares
    movzx eax, al
    movzx edx, xPosWall[0]
    inc edx
    cmp eax, edx
    jb HZ_fail2
    movzx edx, xPosWall[2]
    dec edx
    cmp eax, edx
    ja HZ_fail2

    movzx eax, ah
    movzx edx, yPosWall[0]
    inc edx
    cmp eax, edx
    jb HZ_fail2
    movzx edx, yPosWall[1]
    dec edx
    cmp eax, edx
    ja HZ_fail2

    ; Snake overlap?
    mov esi, 0
    mov edx, snakeBodyInit          ; initial segments
    movzx ebp, score
    add edx, ebp
HZ_snake_scan3:
    mov bl, xPos[esi]
    cmp bl, al                      ; al contains current hazard cell X
    jne HZ_next_seg3
    mov bl, yPos[esi]
    cmp bl, ah                      ; ah contains current hazard cell Y
    je HZ_fail2                     ; if overlap detected, fail this hazard
HZ_next_seg3:
    inc esi
    cmp esi, edx
    jle HZ_snake_scan3

    ; Coin overlap?
    mov bl, xCoinPos
    cmp bl, al
    jne HZ_coin_ok3
    mov bl, yCoinPos
    cmp bl, ah
    je HZ_fail2
HZ_coin_ok3:
    inc ecx
    cmp ecx, HAZARD_LEN
    jl HZ_cell_loop3

    mov hazardActive, 1
    ret

HZ_fail2:
    mov hazardActive, 0
    ret
CreateMidpointHazardBlock ENDP


CreateRandomHazardBlock PROC
    ; Tries up to 64 random placements
    mov hazardActive, 0

    mov ecx, 64          ; attempt counter

CRH_try:
    ; Interior bounds (use 8-bit regs as before)
    mov al, xPosWall[0]
    inc al                ; leftInner
    mov bl, xPosWall[2]
    dec bl                ; rightInner
    mov ah, yPosWall[0]
    inc ah                ; topInner
    mov bh, yPosWall[1]
    dec bh                ; bottomInner

    ; Random orientation (0 = horiz, 1 = vert)
    mov eax, 2
    call RandomRange
    mov hazardOrient, al

    ; Choose base (hazardX/hazardY) so the 10 cells fit
    cmp hazardOrient, 0
    jne CRH_vert

    ; Horizontal: x in [leftInner .. rightInner-(HAZARD_LEN-1)]
    movzx edx, bl
    movzx eax, al         ; leftInner in AL -> zero-extend
    sub edx, eax
    sub edx, (HAZARD_LEN-1)
    inc edx               ; range width
    mov eax, edx
    call RandomRange
    add al, xPosWall[0]
    inc al
    mov hazardX, al

    ; Y any interior row
    movzx edx, bh
    movzx eax, ah
    sub edx, eax
    inc edx
    mov eax, edx
    call RandomRange
    add al, yPosWall[0]
    inc al
    mov hazardY, al
    jmp CRH_validate

CRH_vert:
    ; Vertical: y in [topInner .. bottomInner-(HAZARD_LEN-1)]
    movzx edx, bh
    movzx eax, ah
    sub edx, eax
    sub edx, (HAZARD_LEN-1)
    inc edx
    mov eax, edx
    call RandomRange
    add al, yPosWall[0]
    inc al
    mov hazardY, al

    ; X any interior column
    movzx edx, bl
    movzx eax, xPosWall[0]
    inc eax
    sub edx, eax
    inc edx
    mov eax, edx
    call RandomRange
    add al, xPosWall[0]
    inc al
    mov hazardX, al

CRH_validate:
    xor edx, edx          ; i=0..HAZARD_LEN-1 in DL
CRH_loop_cells:
    mov al, hazardX
    mov ah, hazardY
    cmp hazardOrient, 0
    jne CRH_v_add
    add al, dl
    jmp CRH_have
CRH_v_add:
    add ah, dl
CRH_have:
    ; Bounds (already ensured by construction, but keep safety)
    mov bl, xPosWall[0]
    inc bl
    cmp al, bl
    jb CRH_fail_attempt
    mov bl, xPosWall[2]
    dec bl
    cmp al, bl
    ja CRH_fail_attempt

    mov bl, yPosWall[0]
    inc bl
    cmp ah, bl
    jb CRH_fail_attempt
    mov bl, yPosWall[1]
    dec bl
    cmp ah, bl
    ja CRH_fail_attempt

    ; Snake overlap? (per hazard cell, check all segments; avoid EBX corruption)
    push edx                  ; save DL (cell index)
    push eax                  ; save AL/AH (cell coords)
    mov esi, 0
    mov edi, snakeBodyInit
    movzx eax, score
    add edi, eax              ; edi = total segments
    pop eax                   ; restore AL/AH (cell coords)
CRH_snake_scan_cell:
    push ebx                  ; we'll use BL for comparisons
    mov bl, xPos[esi]
    cmp bl, al
    jne CRH_snake_next_cell
    mov bl, yPos[esi]
    cmp bl, ah
    pop ebx
    pop edx                   ; restore DL before failing
    je CRH_fail_attempt       ; overlap with this cell
    push edx
    jmp CRH_snake_cont_cell
CRH_snake_next_cell:
    pop ebx
CRH_snake_cont_cell:
    inc esi
    cmp esi, edi
    jl CRH_snake_scan_cell
    pop edx                   ; restore DL

    ; Coin overlap?
    mov bl, xCoinPos
    cmp bl, al
    jne CRH_coin_ok
    mov bl, yCoinPos
    cmp bl, ah
    je CRH_fail_attempt
CRH_coin_ok:
    inc dl
    cmp dl, HAZARD_LEN
    jb CRH_loop_cells

    mov hazardActive, 1
    ret

CRH_fail_attempt:
    dec ecx
    jnz CRH_try
    mov hazardActive, 0
    ret
CreateRandomHazardBlock ENDP



CreateBetweenOrRandomHazardBlock PROC
    ; Compute Manhattan distance between head and coin: |dx| + |dy|
    movzx eax, xPos[0]        ; sx
    movzx ebx, yPos[0]        ; sy
    movzx ecx, xCoinPos       ; cx
    movzx edx, yCoinPos       ; cy

    mov esi, ecx
    sub esi, eax              ; dx = cx - sx
    mov edi, edx
    sub edi, ebx              ; dy = cy - sy

    ; |dx| -> EAX
    mov eax, esi
    cdq
    xor eax, edx
    sub eax, edx

    ; |dy| -> ECX
    mov ecx, edi
    mov edx, ecx
    sar edx, 31
    xor ecx, edx
    sub ecx, edx

    add eax, ecx              ; manhattan = |dx| + |dy|
    cmp eax, HAZARD_CLOSE_DIST
    jbe CBR_random            ; too close -> randomize

    ; Try strict midpoint barrier (already validates bounds/snake/coin)
    call CreateMidpointHazardBlock
    cmp hazardActive, 0
    je CBR_random

    ; Ensure barrier lies strictly between head and coin along the perpendicular axis.
    ; If vertical barrier, its X must be between head.x and coin.x.
    ; If horizontal barrier, its Y must be between head.y and coin.y.
    mov al, hazardOrient
    cmp al, 0
    jne CBR_vert_check

    ; Horizontal barrier -> check hazardY between min(sy,cy) .. max(sy,cy)
    mov al, yPos[0]
    mov ah, yCoinPos
    mov bl, al
    mov bh, ah
    cmp bl, bh
    jbe CBR_h_haveBounds
    xchg bl, bh
CBR_h_haveBounds:
    mov al, hazardY
    cmp al, bl
    jb CBR_random            ; outside “between” slab -> randomize
    cmp al, bh
    ja CBR_random
    ret

CBR_vert_check:
    ; Vertical barrier -> check hazardX between min(sx,cx) .. max(sx,cy)
    mov al, xPos[0]
    mov ah, xCoinPos
    mov bl, al
    mov bh, ah
    cmp bl, bh
    jbe CBR_v_haveBounds
    xchg bl, bh
CBR_v_haveBounds:
    mov al, hazardX
    cmp al, bl
    jb CBR_random
    cmp al, bh
    ja CBR_random
    ret

CBR_random:
    ; Fallback: random orientation/position fully inside bounds
    call CreateRandomHazardBlock
    ret
CreateBetweenOrRandomHazardBlock ENDP


; Draw one hazard from arrays at index BL
DrawHazardAt PROC
    push eax
    push ebx
    push ecx
    push edx

    mov eax, black + (red * 16)
    call SetTextColor

    movzx ebx, bl
    xor ecx, ecx              ; i = 0..HAZARD_LEN-1
DHA_loop:
    ; base
    mov dl, hazXs[ebx]
    mov dh, hazYs[ebx]
    mov al, hazOrients[ebx]
    cmp al, 0
    jne DHA_v
    add dl, cl                ; horizontal
    jmp DHA_have
DHA_v:
    add dh, cl                ; vertical
DHA_have:
    ; never draw over walls
    cmp dl, xPosWall[0]
    je DHA_skip
    cmp dl, xPosWall[2]
    je DHA_skip
    cmp dh, yPosWall[0]
    je DHA_skip
    cmp dh, yPosWall[1]
    je DHA_skip

    push ecx
    call Gotoxy
    mov al, '#'
    call WriteChar
    pop ecx

DHA_skip:
    inc ecx
    cmp ecx, HAZARD_LEN
    jl DHA_loop

    mov eax, white + (black * 16)
    call SetTextColor

    pop edx
    pop ecx
    pop ebx
    pop eax
    ret
DrawHazardAt ENDP


; Clear one hazard from arrays at index BL
ClearHazardAt PROC
    push eax
    push ebx
    push ecx
    push edx

    movzx ebx, bl
    xor ecx, ecx              ; i = 0..HAZARD_LEN-1
CHA_loop:
    ; base
    mov dl, hazXs[ebx]
    mov dh, hazYs[ebx]
    mov al, hazOrients[ebx]
    cmp al, 0
    jne CHA_v
    add dl, cl                ; horizontal
    jmp CHA_have
CHA_v:
    add dh, cl                ; vertical
CHA_have:
    ; never erase wall cells
    cmp dl, xPosWall[0]
    je CHA_skip
    cmp dl, xPosWall[2]
    je CHA_skip
    cmp dh, yPosWall[0]
    je CHA_skip
    cmp dh, yPosWall[1]
    je CHA_skip

    push ecx
    call Gotoxy
    mov al, ' '
    call WriteChar
    pop ecx

CHA_skip:
    inc ecx
    cmp ecx, HAZARD_LEN
    jl CHA_loop

    pop edx
    pop ecx
    pop ebx
    pop eax
    ret
ClearHazardAt ENDP



CheckBlockCollision PROC        ; Die if snake head is on any cell of any active hazard.  
    movzx edi, hazCount         ; puts hazCount into edi
    test edi, edi               ; to check if there is 0 hazards
    jz CBC_done                 ; if hazard count is 0, jump to CBC_done

    mov dl, xPos[0]             ; puts snake head X into dl
    mov dh, yPos[0]             ; puts snake head Y into dh

    xor esi, esi                ; makes esi = 0 to use as hazard index. Hazard index is used to iterate through each hazard
CBC_h_loop:
    xor ecx, ecx                ; makes ecx = 0 to use as cell index. Cell index is used to iterate through each cell of the hazard

CBC_c_loop:
    ; load base of current hazard
    mov al, hazXs[esi]          ; puts hazard's first x element into al
    mov ah, hazYs[esi]          ; puts hazard's first y element into ah
    mov bl, hazOrients[esi]     ; puts hazard's orientation into bl(1 for vertical, 0 for horizontal)
    cmp bl, 0                   ; compares orientation with 0(which is horizontal)
    jne CBC_vert                ; if not equal, jump to CBC_vert
    add al, cl                  ; add cl to al and store in al so that al = baseX + i
    jmp CBC_have                ; jump to CBC_have
CBC_vert:
    add ah, cl                  ; add cl to ah and store in ah so that ah = baseY + i
CBC_have:
    ; compare with head (dl,dh)
    cmp dl, al                  ; compare headX with cellX
    jne CBC_next_cell           ; if not equal, jump to next cell
    cmp dh, ah                  ; else, compare headY with cellY
    jne CBC_next_cell           ; if not equal, jump to next cell
    call YouDiedHazard          ; else, if equal, collision, dead

CBC_next_cell:
    inc ecx                     ; increment cell index
    cmp ecx, HAZARD_LEN         ; compare cell index with HAZARD_LEN(15)
    jl CBC_c_loop               ; if cell index < HAZARD_LEN, jump back to CBC_c_loop. This loops through all cells of the hazard

    inc esi                     ; increment hazard index
    cmp esi, edi                ; compare hazard index with hazCount
    jl CBC_h_loop               ; if hazard index < hazCount, jump back to CBC_h_loop. This loops through all hazards

CBC_done:
    ret
CheckBlockCollision ENDP


YouDiedHazard PROC
	mov eax, 1000
	call delay
	Call ClrScr
	
    mov dl, 50
	mov dh, 12
	call Gotoxy
	mov edx, OFFSET strCollision
	call WriteString

	mov dl, 56
	mov dh, 14
	call Gotoxy
	mov ax, score
	call WriteInt
	mov edx, OFFSET strPoints
	call WriteString

	mov dl, 50
	mov dh, 18
	call Gotoxy
	mov edx, OFFSET strTryAgain
	call WriteString

	retryHaz:
	mov dh, 19
	mov dl, 56
	call Gotoxy
	call ReadInt
	cmp al, 1
	je playagn
	cmp al, 0
	je exitgame

	mov dh, 17
	call Gotoxy
	mov edx, OFFSET invalidInput
	call WriteString
	mov dl, 56
	mov dh, 19
	call Gotoxy
	mov edx, OFFSET blank
	call WriteString
	jmp retryHaz
YouDiedHazard ENDP

YouDiedWall PROC
	mov eax, 1000
	call delay
	Call ClrScr
	
    mov dl, 53
	mov dh, 12
	call Gotoxy
	mov edx, OFFSET strWallDeath
	call WriteString

	mov dl, 56
	mov dh, 14
	call Gotoxy
	mov ax, score
	call WriteInt
	mov edx, OFFSET strPoints
	call WriteString

	mov dl, 50
	mov dh, 18
	call Gotoxy
	mov edx, OFFSET strTryAgain
	call WriteString

	retryWall:
	mov dh, 19
	mov dl, 56
	call Gotoxy
	call ReadInt
	cmp al, 1
	je playagn
	cmp al, 0
	je exitgame

	mov dh, 17
	call Gotoxy
	mov edx, OFFSET invalidInput
	call WriteString
	mov dl, 56
	mov dh, 19
	call Gotoxy
	mov edx, OFFSET blank
	call WriteString
	jmp retryWall
YouDiedWall ENDP

YouDiedBody PROC
	mov eax, 1000
	call delay
	Call ClrScr
	
    mov dl, 52
	mov dh, 12
	call Gotoxy
	mov edx, OFFSET strBodyDeath
	call WriteString

	mov dl, 56
	mov dh, 14
	call Gotoxy
	mov ax, score
	call WriteInt
	mov edx, OFFSET strPoints
	call WriteString

	mov dl, 50
	mov dh, 18
	call Gotoxy
	mov edx, OFFSET strTryAgain
	call WriteString

	retryBody:
	mov dh, 19
	mov dl, 56
	call Gotoxy
	call ReadInt
	cmp al, 1
	je playagn
	cmp al, 0
	je exitgame

	mov dh, 17
	call Gotoxy
	mov edx, OFFSET invalidInput
	call WriteString
	mov dl, 56
	mov dh, 19
	call Gotoxy
	mov edx, OFFSET blank
	call WriteString
	jmp retryBody
YouDiedBody ENDP

ReinitializeGame PROC            ;procedure to reinitialize everything
    ; reset snake start position
    mov xPos[0], 45
    mov xPos[1], 44
    mov xPos[2], 43
    mov xPos[3], 42
    mov xPos[4], 41
    mov yPos[0], 15
    mov yPos[1], 15
    mov yPos[2], 15
    mov yPos[3], 15
    mov yPos[4], 15

    mov score, 0
    mov lastInputChar, 0
    mov inputChar, 0

    ; clear single-candidate hazard state
    mov hazardActive, 0
    mov hazardX, 0
    mov hazardY, 0
    mov hazardOrient, 0
    mov hazCount, 0
    cld                     ; ensure forward direction for stosb

    mov ecx, MAX_HAZARDS
    mov al, 0
    lea edi, hazXs
    rep stosb

    mov ecx, MAX_HAZARDS
    mov al, 0
    lea edi, hazYs
    rep stosb

    mov ecx, MAX_HAZARDS
    mov al, 0
    lea edi, hazOrients
    rep stosb

    Call ClrScr
    jmp main
ReinitializeGame ENDP

END main