function init()
	math.randomseed( os.time() )
	
	require("FluidDynamicField")
	
	paletteNumber = 0

	-- Load Palette
	for i=5,0,-1 do
		palette = loadImage("Palette" .. i .. ".png", 1)
	end
	
	totalPaletteNumber = 5
	
	-- Some images
	img = {}
	
	-- Game state
	state = 'intro'
	
	-- Key state
	isDown = {}
	
	konamiCounter = 0
	playMode = false
	gameEnded = false
	gameWon = false
	
end

function update()
	
	if state == 'intro' then
		blitImage(paletteNumber)
		if playMode then putPixel(0,0,0) end
	
	elseif state == 'intro-fade' then
		
		--for i = 1,1000 do
			--local x,y = math.random(WIDTH) - 1, math.random(HEIGHT) - 1
			--local col = math.floor(gausRandom(1, COLORS-1))
			--putPixel(col,x,y)
		--end

	
	elseif state == 'game' then
		update_game()
	end
	
	
end

function down(k)
	
	if state == 'intro' then
		if (k == START and not (konamiCounter == 10)) then
			init_game()
			state = 'game'
		end
		
		if k == UP then
			paletteNumber = (paletteNumber - 1) % totalPaletteNumber
			loadImage("Palette" .. paletteNumber .. ".png", 2)
		end
		
		if k == DOWN then
			paletteNumber = (paletteNumber + 1) % totalPaletteNumber
			loadImage("Palette" .. paletteNumber .. ".png", 2)			
		end
		
		handleCode(k)
		
	elseif state == 'game' then
		down_game(k)
	end
	
end

function down_game(k)
	
	isDown[k] = true
	
	if k == START then
		if pointScored then
			resetGame()
		elseif gameEnded then
			state = 'intro'
		else
			pause = not pause
		end
	
	elseif k == B then
		--setPalette()	-- reset default palette
	end
	
end

function up(k)
	isDown[k] = false
	if state == 'intro' then
		
	elseif state == 'game' then
		up_game(k)
	end
end

function up_game(k)
	if k == B then
		if leftPaddle.boomcharge > 0 then
			injectLeftPaddleBoom(leftPaddle.boomcharge)
			leftPaddle.boomcharge = 0
		end
	end
end


--[[ The real game ]]

function init_game()

	leftPaddle = {}	
	rightPaddle = {}
	ball = {}
	player1Score = 0
	player2Score = 0
	pointScored = false
	gameEnded = false
	gameWon = false
	
	initField(WIDTH/2, HEIGHT/2, 0.0, 0.0) -- diff and visc?
	
	--movePaddle()
	--moveBall()
	fluidTick(1/FPS)
	resetGame()
end

function resetGame()
	leftPaddle = {x = 10, y = HEIGHT/2, width = 2, height = 20, xSpeed = 0, ySpeed = 0, maxYspeed = 20,  accelSpeed = 4, decelRate = 0.5, prevX = x, prevY = y, boomcharge = 0, 	boomchargeMax = 2000}
	rightPaddle = {x = WIDTH-10, y = HEIGHT/2, width = 2, height = 20, xSpeed = 0, ySpeed = 0, maxYspeed = 2, accelSpeed = 0.5, decelRate = 0.5, prevX = x, prevY = y, boomcharge = 0, 	boomchargeMax = 2000}
	
	
	ball = {x = WIDTH/2, y = HEIGHT/2, xSpeed = gausRandom(-4, 4), ySpeed = gausRandom(-5, 5), xAccel = 0, yAccel = 0, radius = 1, ejectDensity = 4, mass = 20, prevX = x, prevY = y}
	if ball.xSpeed < 0.8 and ball.xSpeed >=0 then ball.xSpeed = 0.8
	elseif ball.xSpeed < 0 and ball.xSpeed > -0.8 then ball.xSpeed = -0.8
	end
	
	pause = true
	pointScored = false
	resetField()
	injectGoDens()
	injectScoreDens()
end

function evenRandom(minimum, maximum)
	return minimum + (maximum - minimum) * (math.random(100)/100.0)
end

function gausRandom(minimum, maximum)
	return (minimum + (maximum - minimum) * ((math.random(25)+math.random(25)+math.random(25)+math.random(25))/100.0))
end

function update_game()
	
	if pause then
		drawGame()
		return
	end
		
	--[[ Update state ]]
		
	if isDown[LEFT] then
		if playMode then
			vaccume()
		end
	end
	
	if isDown[RIGHT] then
		if playMode then
			blow()
		end		
	end
	
	if isDown[B] then
		if leftPaddle.boomcharge < leftPaddle.boomchargeMax then
			leftPaddle.boomcharge = leftPaddle.boomcharge + 20
		end
	end
	
	moveLeftPaddle()
	moveRightPaddle()
	moveBall()
	
	if isDown[A] then
		if playMode then resetGame() end
	end
			
	fluidTick(1/FPS)
	
	--[[ Draw ]]
	drawGame()
	
	
end

function drawGame()

	-- Fluid
	draw_dens()
		
	-- Left Paddle
	fillRect(0, leftPaddle.x - leftPaddle.width/2, leftPaddle.y - leftPaddle.height/2, leftPaddle.width, leftPaddle.height)
	-- Paddle charge meter
	fillRect(0, leftPaddle.x - leftPaddle.width/2 -2, leftPaddle.y - leftPaddle.height/2, 1, math.floor((leftPaddle.height/2)*leftPaddle.boomcharge/leftPaddle.boomchargeMax))
	fillRect(0, leftPaddle.x - leftPaddle.width/2 -2, leftPaddle.y + leftPaddle.height/2 - math.floor((leftPaddle.height/2)*leftPaddle.boomcharge/leftPaddle.boomchargeMax), 1, math.floor((leftPaddle.height/2)*leftPaddle.boomcharge/leftPaddle.boomchargeMax))
	
	-- Right Paddle
	fillRect(0, rightPaddle.x - rightPaddle.width/2, rightPaddle.y - rightPaddle.height/2, rightPaddle.width, rightPaddle.height)
	-- Paddle charge meter
	fillRect(0, rightPaddle.x + rightPaddle.width/2 +1, rightPaddle.y - rightPaddle.height/2, 1, math.floor((rightPaddle.height/2)*rightPaddle.boomcharge/rightPaddle.boomchargeMax))
	fillRect(0, rightPaddle.x + rightPaddle.width/2 +1, rightPaddle.y + rightPaddle.height/2 - math.floor((rightPaddle.height/2)*rightPaddle.boomcharge/rightPaddle.boomchargeMax), 1, math.floor((leftPaddle.height/2)*rightPaddle.boomcharge/rightPaddle.boomchargeMax))
	
	-- Ball
	fillRect(0, ball.x - ball.radius, ball.y - ball.radius, ball.radius * 2, ball.radius * 2)
	
	if gameEnded then drawWinLose() end
end

function moveLeftPaddle()
	leftPaddle.prevX = leftPaddle.x
	leftPaddle.prevY = leftPaddle.y
	
	if isDown[UP] then
		leftPaddle.ySpeed = math.max( -leftPaddle.maxYspeed, leftPaddle.ySpeed - leftPaddle.accelSpeed)
	end
	
	if isDown[DOWN] then
		leftPaddle.ySpeed = math.min( leftPaddle.maxYspeed, leftPaddle.ySpeed + leftPaddle.accelSpeed)
	end
	
	if not isDown[Down] and not isDown[Up] then
		leftPaddle.ySpeed = leftPaddle.ySpeed*leftPaddle.decelRate
	end
	
	leftPaddle.y = leftPaddle.y + leftPaddle.ySpeed
	
	if leftPaddle.y < 0 + leftPaddle.height/2 then leftPaddle.y = leftPaddle.height/2 
	elseif leftPaddle.y > HEIGHT - leftPaddle.height/2 then leftPaddle.y = HEIGHT - leftPaddle.height/2 
	else
		inject_velocity(math.ceil(leftPaddle.x/2), math.ceil(leftPaddle.y/2), leftPaddle.xSpeed, leftPaddle.ySpeed)
		inject_velocity(math.ceil(leftPaddle.x/2), math.ceil(leftPaddle.y/2 + leftPaddle.height/4), leftPaddle.xSpeed, leftPaddle.ySpeed)
		inject_velocity(math.ceil(leftPaddle.x/2), math.ceil(leftPaddle.y/2 - leftPaddle.height/4), leftPaddle.xSpeed, leftPaddle.ySpeed)
	end
end

function moveRightPaddle()
	rightPaddle.prevX = rightPaddle.x
	rightPaddle.prevY = rightPaddle.y
	
	-- Need to make the computer paddle not so good :/
	if ball.xSpeed > 0 then
		if ball.y < rightPaddle.y - rightPaddle.height/3 then
			rightPaddle.ySpeed = math.max( -leftPaddle.maxYspeed, rightPaddle.ySpeed - rightPaddle.accelSpeed)
		elseif ball.y > rightPaddle.y + rightPaddle.height/3 then
			rightPaddle.ySpeed = math.min( leftPaddle.maxYspeed, rightPaddle.ySpeed + rightPaddle.accelSpeed)
		else
			rightPaddle.ySpeed = rightPaddle.ySpeed*rightPaddle.decelRate
		end
	else
		if HEIGHT/2 < rightPaddle.y - rightPaddle.height/3 then
			rightPaddle.ySpeed = math.max( -leftPaddle.maxYspeed, rightPaddle.ySpeed - rightPaddle.accelSpeed)
		elseif HEIGHT/2 > rightPaddle.y + rightPaddle.height/3 then
			rightPaddle.ySpeed = math.min( leftPaddle.maxYspeed, rightPaddle.ySpeed + rightPaddle.accelSpeed)
		else
			rightPaddle.ySpeed = rightPaddle.ySpeed*rightPaddle.decelRate
		end
	end
	
	rightPaddle.y = rightPaddle.y + rightPaddle.ySpeed
	
	if rightPaddle.y < 0 + rightPaddle.height/2 then rightPaddle.y = rightPaddle.height/2
	elseif rightPaddle.y > HEIGHT - rightPaddle.height/2 then rightPaddle.y = HEIGHT - rightPaddle.height/2 
	else	
		inject_velocity(math.ceil(rightPaddle.x/2), math.ceil(rightPaddle.y/2), rightPaddle.xSpeed, rightPaddle.ySpeed)
		inject_velocity(math.ceil(rightPaddle.x/2), math.ceil(rightPaddle.y/2 + rightPaddle.height/4), rightPaddle.xSpeed, rightPaddle.ySpeed)
		inject_velocity(math.ceil(rightPaddle.x/2), math.ceil(rightPaddle.y/2 - rightPaddle.height/4), rightPaddle.xSpeed, rightPaddle.ySpeed)
	end
end


function moveBall()	
	ball.prevX = ball.x
	ball.prevY = ball.y

	-- Adjust ball accel with an average of the area around it
	ball.xAccel = ((u[IX(math.ceil(ball.x/2)-1, math.ceil(ball.y/2)-1)]/ball.mass + u[IX(math.ceil(ball.x/2), math.ceil(ball.y/2)-1)]/ball.mass + u[IX(math.ceil(ball.x/2)+1, math.ceil(ball.y/2)-1)]/ball.mass + 
					u[IX(math.ceil(ball.x/2)-1, math.ceil(ball.y/2))]/ball.mass + u[IX(math.ceil(ball.x/2), math.ceil(ball.y/2))]/ball.mass + u[IX(math.ceil(ball.x/2)+1, math.ceil(ball.y/2))]/ball.mass + 
					u[IX(math.ceil(ball.x/2)-1, math.ceil(ball.y/2)+1)]/ball.mass + u[IX(math.ceil(ball.x/2), math.ceil(ball.y/2)+1)]/ball.mass + u[IX(math.ceil(ball.x/2)+1, math.ceil(ball.y/2)+1)]/ball.mass)/9)
	ball.yAccel = ((v[IX(math.ceil(ball.x/2)-1, math.ceil(ball.y/2)-1)]/ball.mass + v[IX(math.ceil(ball.x/2), math.ceil(ball.y/2)-1)]/ball.mass + v[IX(math.ceil(ball.x/2+1), math.ceil(ball.y/2)-1)]/ball.mass + 
					v[IX(math.ceil(ball.x/2)-1, math.ceil(ball.y/2))]/ball.mass + v[IX(math.ceil(ball.x/2), math.ceil(ball.y/2))]/ball.mass + v[IX(math.ceil(ball.x/2)+1, math.ceil(ball.y/2))]/ball.mass + 
					v[IX(math.ceil(ball.x/2)-1, math.ceil(ball.y/2)+1)]/ball.mass + v[IX(math.ceil(ball.x/2), math.ceil(ball.y/2)+1)]/ball.mass + v[IX(math.ceil(ball.x/2)+1, math.ceil(ball.y/2)+1)]/ball.mass)/9)
	
	ball.xSpeed = ball.xSpeed + ball.xAccel
	ball.ySpeed = ball.ySpeed + ball.yAccel
	
	ball.x = ball.x + ball.xSpeed
	ball.y = ball.y + ball.ySpeed
	
	
	--Check leftPaddle hit
	if ball.x <= leftPaddle.x and ball.prevX > leftPaddle.x and not (ball.prevX-ball.x == 0) then
		local yIntercept = ball.prevY + (ball.prevX - leftPaddle.x) * (ball.prevY - ball.y) / (ball.prevX - ball.x)
		local minPaddleY = math.min(leftPaddle.y-leftPaddle.height/2, leftPaddle.prevY-leftPaddle.height/2)
		local maxPaddleY = math.max(leftPaddle.y+leftPaddle.height/2, leftPaddle.prevY+leftPaddle.height/2)
		if yIntercept > minPaddleY and yIntercept < maxPaddleY then
			ball.x =  leftPaddle.x - (ball.x - leftPaddle.x)
			ball.xSpeed = -ball.xSpeed
			
			--Modify ball.ySpeed according to where it hit the paddle
			ball.ySpeed = ball.ySpeed + 2.0*(yIntercept - leftPaddle.y)/leftPaddle.height
		end
	end
	
		--Check rightPaddle hit
	if ball.x >= rightPaddle.x and ball.prevX < rightPaddle.x and not (ball.prevX-ball.x == 0) then
		local yIntercept = ball.prevY + (ball.prevX - rightPaddle.x) * (ball.prevY - ball.y) / (ball.prevX - ball.x)
		local minPaddleY = math.min(rightPaddle.y-rightPaddle.height/2, rightPaddle.prevY-rightPaddle.height/2)
		local maxPaddleY = math.max(rightPaddle.y+rightPaddle.height/2, rightPaddle.prevY+rightPaddle.height/2)
		if yIntercept > minPaddleY and yIntercept < maxPaddleY then
			ball.x =  rightPaddle.x - (ball.x - rightPaddle.x)
			ball.xSpeed = -ball.xSpeed
			
			--Modify ball.ySpeed according to where it hit the paddle
			ball.ySpeed = ball.ySpeed + 2.0*(yIntercept - rightPaddle.y)/rightPaddle.height
		end
	end
	
	--Check top and bottom hit
	if ball.y < 0 then
		ball.y = -ball.y
		ball.ySpeed = -ball.ySpeed
	elseif ball.y >= HEIGHT then
		ball.y = HEIGHT - (ball.y - HEIGHT)
		ball.ySpeed = -ball.ySpeed
	end
	
	--Check side hit
	if playMode then
		if ball.x >= WIDTH then
			ball.x = WIDTH - (ball.x - WIDTH)
			ball.xSpeed = -ball.xSpeed
		elseif ball.x < 0 then
			ball.x =  -ball.x
			ball.xSpeed = -ball.xSpeed
		end
	else
		if ball.x >= WIDTH then
			player1Score = player1Score + 1
			pause = true
			pointScored = true
		elseif ball.x < 0 then
			player2Score = player2Score + 1
			pause = true
			pointScored = true
		end
		if player1Score >= 7 then
			pointScored = false
			gameEnded = true
			gameWon = true
		elseif player2Score >= 7 then
			pointScored = false
			gameEnded = true
			gameWon = false
		end
	end
	
	inject_velocity(math.floor(ball.x/2), math.floor(ball.y/2), ball.xSpeed, ball.ySpeed)
	inject_dens(math.floor(ball.x/2), math.floor(ball.y/2), ball.ejectDensity)
end

function vaccume()
	for y=-6,6 do
		inject_velocity(8, math.floor((leftPaddle.y + y)/2), -10, -y/6)
		remove_dens(3,math.floor((leftPaddle.y + y)/2))
		remove_dens(4,math.floor((leftPaddle.y + y)/2))
		remove_dens(5,math.floor((leftPaddle.y + y)/2))
		remove_dens(6,math.floor((leftPaddle.y + y)/2))
		remove_dens(7,math.floor((leftPaddle.y + y)/2))
	end
end

function blow()
	for y=-6,6 do
		inject_velocity(2, math.floor((leftPaddle.y + y)/2), 10, y/6)
		inject_dens(3,math.floor((leftPaddle.y + y)/2), 1)
		inject_dens(4,math.floor((leftPaddle.y + y)/2), 1)
		inject_dens(5,math.floor((leftPaddle.y + y)/2), 1)
		inject_dens(6,math.floor((leftPaddle.y + y)/2), 1)
		inject_dens(7,math.floor((leftPaddle.y + y)/2), 1)
	end
end

function injectLeftPaddleBoom(boom)
	local boomMagnitude = boom
	local boomInject = 10
	--[[
	local slices = 20
	local minAngle = 10
	local maxAngle = 170
	for angle=minAngle,maxAngle, (maxAngle - minAngle)/slices do
		inject_dens(math.ceil((0 + math.sin(math.rad(angle)) * 0.9*leftPaddle.height/2)/2), math.ceil((leftPaddle.y - math.cos(math.rad(angle)) * 0.9*leftPaddle.height/2)/2), boomInject*boom/leftPaddle.boomchargeMax)
		inject_velocity(math.ceil((0 + math.sin(math.rad(angle)) * 0.9*leftPaddle.height/2)/2), math.ceil((leftPaddle.y - math.cos(math.rad(angle)) * 0.9*leftPaddle.height/2)/2), boomMagnitude*math.sin(math.rad(angle))/slices , boomMagnitude*math.sin(math.rad(-angle))/slices)
	end	
	]]--
	
	for y=-9,9 do
		inject_dens(2,math.floor((leftPaddle.y + y)/2), boomInject*boom/leftPaddle.boomchargeMax)
		inject_velocity(0,math.floor((leftPaddle.y + y)/2), boomMagnitude/18, 0)
		inject_velocity(1,math.floor((leftPaddle.y + y)/2), boomMagnitude/18, 0)
	end
end

function drawWinLose()
	if gameWon then
		fillRect(0, 44, 32, 3, 27)
		fillRect(0, 56, 35, 3, 24)
		fillRect(0, 69, 32, 3, 27)
		fillRect(0, 47, 59, 22, 3)
		
		
		fillRect(0, 75, 32, 13, 3)
		fillRect(0, 80, 35, 3, 24)
		fillRect(0, 75, 59, 13, 3)
		
		fillRect(0, 91, 32, 3, 30)
		fillRect(0, 94, 38, 3, 6)
		fillRect(0, 97, 44, 3, 6)
		fillRect(0, 100, 50, 3, 6)
		fillRect(0, 103, 32, 3, 30)
		
		fillRect(0, 109, 32, 3, 24)
		fillRect(0, 109, 59, 3, 3)
		
	else
		fillRect(0, 41, 32, 3, 27)
		fillRect(0, 44, 59, 10, 3)
		
		fillRect(0, 59, 32, 10, 3)
		fillRect(0, 56, 35, 3, 24)
		fillRect(0, 59, 59, 10, 3)
		fillRect(0, 69, 35, 3, 24)
		
		fillRect(0, 78, 32, 12, 3)
		fillRect(0, 75, 35, 3, 11)
		fillRect(0, 78, 46, 12, 3)
		fillRect(0, 90, 49, 3, 10)
		fillRect(0, 78, 59, 12, 3)
		
		fillRect(0, 96, 35, 3, 24)
		fillRect(0, 99, 32, 12, 3)
		fillRect(0, 99, 46, 12, 3)
		fillRect(0, 99, 59, 12, 3)
		
		fillRect(0, 114, 32, 3, 24)
		fillRect(0, 114, 59, 3, 3)
	end
end

function injectGoDens()
	local ammountToInject = 18
	inject_dens(31, 18, ammountToInject)
	inject_dens(32, 18, ammountToInject)
	inject_dens(33, 18, ammountToInject)
	inject_dens(34, 18, ammountToInject)
	inject_dens(35, 18, ammountToInject)
	
	inject_dens(41, 18, ammountToInject)
	inject_dens(42, 18, ammountToInject)
	inject_dens(43, 18, ammountToInject)
	inject_dens(44, 18, ammountToInject)
	
	inject_dens(49, 18, ammountToInject)
	inject_dens(50, 18, ammountToInject);
	
	inject_dens(30, 19, ammountToInject)
	inject_dens(31, 19, ammountToInject)
	
	inject_dens(35, 19, ammountToInject)
	inject_dens(36, 19, ammountToInject)
	
	inject_dens(40, 19, ammountToInject)
	inject_dens(41, 19, ammountToInject)
	
	inject_dens(44, 19, ammountToInject)
	inject_dens(45, 19, ammountToInject)
	
	inject_dens(49, 19, ammountToInject)
	inject_dens(50, 19, ammountToInject);
	
	inject_dens(29, 20, ammountToInject)
	inject_dens(30, 20, ammountToInject)
	
	inject_dens(36, 20, ammountToInject)
	
	inject_dens(39, 20, ammountToInject)
	inject_dens(40, 20, ammountToInject)
	
	inject_dens(45, 20, ammountToInject)
	inject_dens(46, 20, ammountToInject)
	
	inject_dens(49, 20, ammountToInject)
	inject_dens(50, 20, ammountToInject);
	
	inject_dens(29, 21, ammountToInject)
	inject_dens(30, 21, ammountToInject)
	
	inject_dens(39, 21, ammountToInject)
	inject_dens(40, 21, ammountToInject)
	
	inject_dens(45, 21, ammountToInject)
	inject_dens(46, 21, ammountToInject)
	
	inject_dens(49, 21, ammountToInject)
	inject_dens(50, 21, ammountToInject);
	
	inject_dens(29, 22, ammountToInject)
	inject_dens(30, 22, ammountToInject)
	
	inject_dens(39, 22, ammountToInject)
	inject_dens(40, 22, ammountToInject)
	
	inject_dens(45, 22, ammountToInject)
	inject_dens(46, 22, ammountToInject)
	
	inject_dens(49, 22, ammountToInject)
	inject_dens(50, 22, ammountToInject);
	
	inject_dens(29, 23, ammountToInject)
	inject_dens(30, 23, ammountToInject)
	
	inject_dens(33, 23, ammountToInject)
	inject_dens(34, 23, ammountToInject)
	inject_dens(35, 23, ammountToInject)
	inject_dens(36, 23, ammountToInject)
	
	inject_dens(39, 23, ammountToInject)
	inject_dens(40, 23, ammountToInject)
	
	inject_dens(45, 23, ammountToInject)
	inject_dens(46, 23, ammountToInject)
	
	inject_dens(49, 23, ammountToInject)
	inject_dens(50, 23, ammountToInject);
	
	inject_dens(29, 24, ammountToInject)
	inject_dens(30, 24, ammountToInject)
	
	inject_dens(35, 24, ammountToInject)
	inject_dens(36, 24, ammountToInject)
	
	inject_dens(39, 24, ammountToInject)
	inject_dens(40, 24, ammountToInject)
	
	inject_dens(45, 24, ammountToInject)
	inject_dens(46, 24, ammountToInject)
	
	inject_dens(49, 24, ammountToInject)
	inject_dens(50, 24, ammountToInject);
	
	inject_dens(29, 25, ammountToInject)
	inject_dens(30, 25, ammountToInject)
	
	inject_dens(35, 25, ammountToInject)
	inject_dens(36, 25, ammountToInject)
	
	inject_dens(39, 25, ammountToInject)
	inject_dens(40, 25, ammountToInject)
	
	inject_dens(45, 25, ammountToInject)
	inject_dens(46, 25, ammountToInject);
	
	inject_dens(30, 26, ammountToInject)
	inject_dens(31, 26, ammountToInject)
	
	inject_dens(35, 26, ammountToInject)
	inject_dens(36, 26, ammountToInject)
	
	inject_dens(40, 26, ammountToInject)
	inject_dens(41, 26, ammountToInject)
	
	inject_dens(44, 26, ammountToInject)
	inject_dens(45, 26, ammountToInject)
	
	inject_dens(49, 26, ammountToInject)
	inject_dens(50, 26, ammountToInject);
	
	inject_dens(31, 27, ammountToInject)
	inject_dens(32, 27, ammountToInject)
	inject_dens(33, 27, ammountToInject)
	inject_dens(34, 27, ammountToInject)
	
	inject_dens(36, 27, ammountToInject)
	
	inject_dens(41, 27, ammountToInject)
	inject_dens(42, 27, ammountToInject)
	inject_dens(43, 27, ammountToInject)
	inject_dens(44, 27, ammountToInject)
	
	inject_dens(49, 27, ammountToInject)
	inject_dens(50, 27, ammountToInject)
end

function injectScoreDens()
	local ammountToInject = 18
	player1ScorePos = {x = 32, y = 5}
	player2ScorePos = {x = 44, y = 5}
	--Add dash
	inject_dens(39, 8, ammountToInject)
	inject_dens(40, 8, ammountToInject)
	
	--Add player 1 score
	if player1Score == 0 then
		inject0Dens(player1ScorePos.x, player1ScorePos.y)
	elseif player1Score == 1 then
		inject1Dens(player1ScorePos.x, player1ScorePos.y)
	elseif player1Score == 2 then
		inject2Dens(player1ScorePos.x, player1ScorePos.y)
	elseif player1Score == 3 then
		inject3Dens(player1ScorePos.x, player1ScorePos.y)
	elseif player1Score == 4 then
		inject4Dens(player1ScorePos.x, player1ScorePos.y)
	elseif player1Score == 5 then
		inject5Dens(player1ScorePos.x, player1ScorePos.y)
	elseif player1Score == 6 then
		inject6Dens(player1ScorePos.x, player1ScorePos.y)
	elseif player1Score == 7 then
		inject7Dens(player1ScorePos.x, player1ScorePos.y)
	end
	
	--Add player 2 score
	if player2Score == 0 then
		inject0Dens(player2ScorePos.x, player2ScorePos.y)
	elseif player2Score == 1 then
		inject1Dens(player2ScorePos.x, player2ScorePos.y)
	elseif player2Score == 2 then
		inject2Dens(player2ScorePos.x, player2ScorePos.y)
	elseif player2Score == 3 then
		inject3Dens(player2ScorePos.x, player2ScorePos.y)
	elseif player2Score == 4 then
		inject4Dens(player2ScorePos.x, player2ScorePos.y)
	elseif player2Score == 5 then
		inject5Dens(player2ScorePos.x, player2ScorePos.y)
	elseif player2Score == 6 then
		inject6Dens(player2ScorePos.x, player2ScorePos.y)
	elseif player2Score == 7 then
		inject7Dens(player2ScorePos.x, player2ScorePos.y)
	end
end

function inject0Dens(x, y)
	local ammountToInject = 18
	inject_dens(x + 1, y + 0, ammountToInject)
	inject_dens(x + 2, y + 0, ammountToInject)
	
	inject_dens(x + 0, y + 1, ammountToInject)
	inject_dens(x + 3, y + 1, ammountToInject)
	
	inject_dens(x + 0, y + 2, ammountToInject)
	inject_dens(x + 3, y + 2, ammountToInject)
	
	inject_dens(x + 0, y + 3, ammountToInject)
	inject_dens(x + 3, y + 3, ammountToInject)
	
	inject_dens(x + 0, y + 4, ammountToInject)
	inject_dens(x + 3, y + 4, ammountToInject)
	
	inject_dens(x + 0, y + 5, ammountToInject)
	inject_dens(x + 3, y + 5, ammountToInject)
	
	inject_dens(x + 1, y + 6, ammountToInject)
	inject_dens(x + 2, y + 6, ammountToInject)
end

function inject1Dens(x, y)
	local ammountToInject = 18
	inject_dens(x + 2, y + 0, ammountToInject)
	
	inject_dens(x + 1, y + 1, ammountToInject)
	inject_dens(x + 2, y + 1, ammountToInject)
	
	inject_dens(x + 2, y + 2, ammountToInject)
	
	inject_dens(x + 2, y + 3, ammountToInject)
	
	inject_dens(x + 2, y + 4, ammountToInject)
	
	inject_dens(x + 2, y + 5, ammountToInject)
	
	inject_dens(x + 2, y + 6, ammountToInject)
end

function inject2Dens(x, y)
	local ammountToInject = 18
	inject_dens(x + 1, y + 0, ammountToInject)
	inject_dens(x + 2, y + 0, ammountToInject)
	
	inject_dens(x + 0, y + 1, ammountToInject)
	inject_dens(x + 3, y + 1, ammountToInject)
	
	inject_dens(x + 3, y + 2, ammountToInject)
	
	inject_dens(x + 2, y + 3, ammountToInject)
	
	inject_dens(x + 1, y + 4, ammountToInject)
	
	inject_dens(x + 0, y + 5, ammountToInject)
	
	inject_dens(x + 0, y + 6, ammountToInject)
	inject_dens(x + 1, y + 6, ammountToInject)
	inject_dens(x + 2, y + 6, ammountToInject)
	inject_dens(x + 3, y + 6, ammountToInject)
end

function inject3Dens(x, y)
	local ammountToInject = 18
	inject_dens(x + 1, y + 0, ammountToInject)
	inject_dens(x + 2, y + 0, ammountToInject)
	
	inject_dens(x + 0, y + 1, ammountToInject)
	inject_dens(x + 3, y + 1, ammountToInject)
	
	inject_dens(x + 3, y + 2, ammountToInject)
	
	inject_dens(x + 2, y + 3, ammountToInject)
	
	inject_dens(x + 3, y + 4, ammountToInject)
	
	inject_dens(x + 0, y + 5, ammountToInject)
	inject_dens(x + 3, y + 5, ammountToInject)
	
	inject_dens(x + 1, y + 6, ammountToInject)
	inject_dens(x + 2, y + 6, ammountToInject)
end

function inject4Dens(x, y)
	local ammountToInject = 18
	inject_dens(x + 3, y + 0, ammountToInject)
	
	inject_dens(x + 2, y + 1, ammountToInject)
	inject_dens(x + 3, y + 1, ammountToInject)
	
	inject_dens(x + 1, y + 2, ammountToInject)
	inject_dens(x + 3, y + 2, ammountToInject)
	
	inject_dens(x + 1, y + 3, ammountToInject)
	inject_dens(x + 3, y + 3, ammountToInject)
	
	inject_dens(x + 0, y + 4, ammountToInject)
	inject_dens(x + 3, y + 4, ammountToInject)
	
	inject_dens(x + 0, y + 5, ammountToInject)
	inject_dens(x + 1, y + 5, ammountToInject)
	inject_dens(x + 2, y + 5, ammountToInject)
	inject_dens(x + 3, y + 5, ammountToInject)
	
	inject_dens(x + 3, y + 6, ammountToInject)
end

function inject5Dens(x, y)
	local ammountToInject = 18
	inject_dens(x + 0, y + 0, ammountToInject)
	inject_dens(x + 1, y + 0, ammountToInject)
	inject_dens(x + 2, y + 0, ammountToInject)
	inject_dens(x + 3, y + 0, ammountToInject)
	
	inject_dens(x + 0, y + 1, ammountToInject)
	
	inject_dens(x + 0, y + 2, ammountToInject)
	
	inject_dens(x + 1, y + 3, ammountToInject)
	inject_dens(x + 2, y + 3, ammountToInject)
	
	inject_dens(x + 3, y + 4, ammountToInject)
	
	inject_dens(x + 0, y + 5, ammountToInject)
	inject_dens(x + 3, y + 5, ammountToInject)
	
	inject_dens(x + 1, y + 6, ammountToInject)
	inject_dens(x + 2, y + 6, ammountToInject)
end

function inject6Dens(x, y)
	local ammountToInject = 18
	inject_dens(x + 1, y + 0, ammountToInject)
	inject_dens(x + 2, y + 0, ammountToInject)
	
	inject_dens(x + 0, y + 1, ammountToInject)
	inject_dens(x + 3, y + 1, ammountToInject)
	
	inject_dens(x + 0, y + 2, ammountToInject)
	
	inject_dens(x + 0, y + 3, ammountToInject)
	inject_dens(x + 1, y + 3, ammountToInject)
	inject_dens(x + 2, y + 3, ammountToInject)
	
	inject_dens(x + 0, y + 4, ammountToInject)
	inject_dens(x + 3, y + 4, ammountToInject)
	
	inject_dens(x + 0, y + 5, ammountToInject)
	inject_dens(x + 3, y + 5, ammountToInject)
	
	inject_dens(x + 1, y + 6, ammountToInject)
	inject_dens(x + 2, y + 6, ammountToInject)
end

function inject7Dens(x, y)
	local ammountToInject = 18
	inject_dens(x + 0, y + 0, ammountToInject)
	inject_dens(x + 1, y + 0, ammountToInject)
	inject_dens(x + 2, y + 0, ammountToInject)
	inject_dens(x + 3, y + 0, ammountToInject)
	
	inject_dens(x + 3, y + 1, ammountToInject)
	
	inject_dens(x + 3, y + 2, ammountToInject)
	
	inject_dens(x + 2, y + 3, ammountToInject)
	
	inject_dens(x + 2, y + 4, ammountToInject)
	
	inject_dens(x + 1, y + 5, ammountToInject)
	
	inject_dens(x + 1, y + 6, ammountToInject)
end

function inject8Dens(x, y)
	local ammountToInject = 18
	inject_dens(x + 1, y + 0, ammountToInject)
	inject_dens(x + 2, y + 0, ammountToInject)
	
	inject_dens(x + 0, y + 1, ammountToInject)
	inject_dens(x + 3, y + 1, ammountToInject)
	
	inject_dens(x + 0, y + 2, ammountToInject)
	inject_dens(x + 3, y + 2, ammountToInject)
	
	inject_dens(x + 1, y + 3, ammountToInject)
	inject_dens(x + 2, y + 3, ammountToInject)
	
	inject_dens(x + 0, y + 4, ammountToInject)
	inject_dens(x + 3, y + 4, ammountToInject)
	
	inject_dens(x + 0, y + 5, ammountToInject)
	inject_dens(x + 3, y + 5, ammountToInject)
	
	inject_dens(x + 1, y + 6, ammountToInject)
	inject_dens(x + 2, y + 6, ammountToInject)
end

function inject9Dens(x, y)
	local ammountToInject = 18
	inject_dens(x + 1, y + 0, ammountToInject)
	inject_dens(x + 2, y + 0, ammountToInject)
	
	inject_dens(x + 0, y + 1, ammountToInject)
	inject_dens(x + 3, y + 1, ammountToInject)
	
	inject_dens(x + 0, y + 2, ammountToInject)
	inject_dens(x + 3, y + 2, ammountToInject)
	
	inject_dens(x + 1, y + 3, ammountToInject)
	inject_dens(x + 2, y + 3, ammountToInject)
	inject_dens(x + 3, y + 3, ammountToInject)
	
	inject_dens(x + 3, y + 4, ammountToInject)
	
	inject_dens(x + 0, y + 5, ammountToInject)
	inject_dens(x + 3, y + 5, ammountToInject)
	
	inject_dens(x + 1, y + 6, ammountToInject)
	inject_dens(x + 2, y + 6, ammountToInject)
end

function handleCode(k)
	if konamiCounter == 0 then
		if k == UP then
			konamiCounter = 1
		else
			konamiCounter = 0
		end
	elseif konamiCounter == 1 then
		if k == UP then
			konamiCounter = 2
		else
			konamiCounter = 0
		end
	elseif konamiCounter == 2 then
		if k == DOWN then
			konamiCounter = 3
		elseif k == UP then
			konamiCounter = 2
		else
			konamiCounter = 0
		end
	elseif konamiCounter == 3 then
		if k == DOWN then
			konamiCounter = 4
		else
			konamiCounter = 0
		end
	elseif konamiCounter == 4 then
		if k == LEFT then
			konamiCounter = 5
		else
			konamiCounter = 0
		end
	elseif konamiCounter == 5 then
		if k == RIGHT then
			konamiCounter = 6
		else
			konamiCounter = 0
		end
	elseif konamiCounter == 6 then
		if k == LEFT then
			konamiCounter = 7
		else
			konamiCounter = 0
		end
	elseif konamiCounter == 7 then
		if k == RIGHT then
			konamiCounter = 8
		else
			konamiCounter = 0
		end
	elseif konamiCounter == 8 then
		if k == B then
			konamiCounter = 9
		else
			konamiCounter = 0
		end
	elseif konamiCounter == 9 then
		if k == A then
			konamiCounter = 10
		else
			konamiCounter = 0
		end
	elseif konamiCounter == 10 then
		if k == START then
			playMode = not playMode
			totalPaletteNumber = 6
			konamiCounter = 0
			paletteNumber = totalPaletteNumber -1
			loadImage("Palette" .. paletteNumber .. ".png", 2)		
		else
			konamiCounter = 0
		end
	end

end
