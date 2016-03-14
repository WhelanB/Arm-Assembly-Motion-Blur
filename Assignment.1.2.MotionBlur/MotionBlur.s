	AREA	MotionBlur, CODE, READONLY
	IMPORT	main
	IMPORT	getPicAddr
	IMPORT	putPic
	IMPORT	getPicWidth
	IMPORT	getPicHeight
	EXPORT	start

start

	BL	getPicAddr	; load the start address of the image in R4
	MOV	R4, R0
	BL	getPicHeight	; load the height of the image (rows) in R5
	MOV	R5, R0
	BL	getPicWidth	; load the width of the image (columns) in R6
	MOV	R6, R0
	
	MOV R0, R4
	MOV R2, R6
	MOV R3, R5
	MOV R1, #10
;R0 - Start address
;R1 - Radius
;R2 - Picture Width
;R3 - Picture Height 

blur
	MOV R4, R0
	MOV R5, R2
	MOV R6, R3
	MOV R7, #0 ;X
	MOV R8, #0 ;Y
	MOV R9, R1
OuterLoop
	
	CMP R7, R5 ;If the outer X position (x in the image) has not reached the edge
	BNE startInnerLoop ;Start the inner loop 
	MOV R7, #0 ;Else, set X to 0
	ADD R8, #1 ;Add 1 to Y
	CMP R8, R6 ;If we've reached the bottom of the image
	BEQ putPicture ;Display the picture

startInnerLoop ;The inner loop handles the diagonal line through each picture which calculates the value for the current pixel
	MOV R0, R7 
	MOV R1, R8
	STMFD sp!, {R0-R1} ;Store the current global pixel's coordinates
	SUB R7, R9 ;Subtract the radius from X
	SUB R8, R9 ;Subtract the radius from Y
	MOV R3, #0 ;Set the number of values sampled to 0
	MOV R10, #0 ;Set the current red total to 0
	MOV R11, #0 ;Set the current green total to 0
	MOV R12, #0 ;Set the current blue total to 0
innerLoop
	CMP R7, #0 ;If the pixel is out of the bounds of the image, don't include it in the blur
	BLT skipPixel
	CMP R7, R5
	BGE skipPixel
	CMP R8, #0
	BLT skipPixel
	CMP R8, R6
	BGE skipPixel
	MUL R2, R8, R5
	ADD R2, R2, R7
	LDR R1, [R4, R2, LSL #2] ;Load the pixel from the current position in the diagonal line
	MOV R0, R1 
	BL getRed ;Get the red component of the color
	ADD R10, R0
	MOV R0, R1
	BL getGreen ;Get the green component
	ADD R11, R0
	MOV R0, R1
	BL getBlue ;Get the blue component
	ADD R12, R0
	ADD R3, #1 ;The number of values taken so the average can be found
skipPixel
	ADD R7, #1 ;Go to the next pixel in the diagonal line
	ADD R8, #1
	LDMFD sp, {R0-R1} ;Load the global X and Y coordinates
	ADD R2, R0, R9 ;Add the radius to the global X coordinate to get the end position of the diagonal line
	CMP R7, R2
	BGT endInner ;If greater, end the inner loop and move to the next pixel in the image
	B innerLoop ;Else, move to the next pixel in the diagonal line
endInner
	STMFD sp!, {R0-R1} ;Store the global X, Y coordinates
	MOV R1, R10 
	MOV R2, R3
	BL divide ;Divide the red total by the number of values sampled to get the average
	MOV R10, R0
	MOV R1, R11
	MOV R2, R3
	BL divide ;Divide the green total by the number of values sampled to get the average
	MOV R11, R0
	MOV R1, R12
	MOV R2, R3
	BL divide ;Divide the green total by the number of values sampled to get the average
	MOV R12, R0
	MOV R0, R12
	MOV R1, #0
	MOV R2, #0x000000FF
	BL clamp ;Clamp the red component between 0-255
	MOV R12, R0
	MOV R0, R11
	BL clamp ;Clamp the green component between 0-255
	MOV R11, R0
	MOV R0, R10
	BL clamp ;Clamp the blue component between 0-255
	MOV R10, R0
	LSL R11, #8 ;Shift the green component
	LSL R12, #16 ;Shift the blue component
	ADD R10, R11
	ADD R10, R12 ;Add the resulting components together to form the final color
	LDMFD sp!, {R0-R1} ;Load the global X,Y coordinates
	MUL R2, R1, R5
	ADD R2, R0, R2
	STR R10, [R4, R2, LSL #2] ;Store the calculated color into the image
	MOV R7, R0 
	MOV R8, R1
	ADD R7, #1 ;Move to the next pixel
	B OuterLoop ;Start the loop again
	
putPicture
	BL	putPic		; re-display the updated image
	B stop
	
;Clamp
;Clamps a value between a given minimum and maximum
;R0 - Value, R1 - Minimum, R2 - Maximum
;Returns clamped value in R0
clamp
	CMP R0, R1
	BGE checkMax
	MOV R0, R1
checkMax
	CMP R0, R2
	BLE endClamp
	MOV R0, R2
endClamp
	BX lr

;getRed
;Returns the red component value of a colour
;Parameters: Colour: R0, Returns R value in R0
getRed
	AND R0, #0x000000FF
	BX lr
	
;getGreen
;Returns the red component value of a colour
;Parameters: Colour: R0, Returns G value in R0
getGreen
	AND R0, #0x0000FF00
	LSR R0, #8
	BX lr
	
;getBlue
;Returns the blue component value of a colour
;Parameters: Colour: R0, Returns B value in R0
getBlue
	AND R0, #0x00FF0000
	LSR R0, #16
	BX lr
	
;Divide
;Divides A by B
;Parameters: A : R1, B : R2  Returns quotient in R0
divide
	MOV R0, #0
whilediv
	CMP R1, R2
	BLO stopdivide
	ADD R0, #1
	SUB R1, R2
	B whilediv
stopdivide
	BX lr
stop	B	stop


	END	